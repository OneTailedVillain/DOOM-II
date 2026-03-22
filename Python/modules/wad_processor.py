"""
Core WAD processing functions.
"""

import re
import struct
import math
import os
import json
import zipfile
import tempfile
import urllib.request
import urllib.error
import hashlib
from pathlib import Path
from omg import WAD, WadIO, Lump

from modules.utils import *
from modules.dehacked_parser import parse_key_value_pairs_from_text, parse_dehacked_structured
from modules.lua_generator import build_lua_deh_table, build_structured_lua_deh, parse_endoom_and_build_lua
from modules.midi_converter import convert_mus_to_midi

MUSIC_DEFINITIONS = None

REMOTE_MUSICDEF_URL = (
	"https://raw.githubusercontent.com/OneTailedVillain/DOOM-II/"
	"refs/heads/main/Python/data/music_definitions.json"
)

def _hash_bytes(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()

def try_update_music_definitions(local_path: Path, remote_url: str) -> None:
	"""
	Try to update local music_definitions.json if the remote version differs.
	Silent failure if offline or unreachable.
	"""

	try:
		with urllib.request.urlopen(remote_url, timeout=5) as resp:
			remote_bytes = resp.read()
	except (urllib.error.URLError, TimeoutError):
		# Offline / GitHub down, silently ignore
		return
	except Exception as e:
		print(f"Music definitions update failed: {e}")
		return

	remote_hash = _hash_bytes(remote_bytes)

	if local_path.exists():
		local_bytes = local_path.read_bytes()
		local_hash = _hash_bytes(local_bytes)

		if local_hash == remote_hash:
			return  # Already up to date

	# Write updated file
	try:
		local_path.parent.mkdir(parents=True, exist_ok=True)
		local_path.write_bytes(remote_bytes)
		print("Updated music_definitions.json from GitHub")
	except Exception as e:
		print(f"Failed to write updated music definitions: {e}")

def load_music_definitions(music_def_file=None):
	global MUSIC_DEFINITIONS

	if music_def_file is None:
		script_dir = Path(__file__).parent.parent
		music_def_file = script_dir / "data" / "music_definitions.json"

	music_def_path = Path(music_def_file)

	# Try live-update before loading
	try_update_music_definitions(
		music_def_path,
		REMOTE_MUSICDEF_URL
	)
	
	# Ensure it's a Path object
	music_def_path = Path(music_def_file)
	
	# Load definitions from file
	try:
		if music_def_path.exists():
			with open(music_def_path, 'r', encoding='utf-8') as f:
				MUSIC_DEFINITIONS = json.load(f)
			print(f"Loaded music definitions from: {music_def_path}")
		else:
			# Fallback to empty dict if file doesn't exist
			MUSIC_DEFINITIONS = {}
			print(f"Music definitions file not found: {music_def_path}")
	except Exception as e:
		print(f"Error loading music definitions: {e}")
		MUSIC_DEFINITIONS = {}
	
	# Ensure we have at least a default entry
	if "default" not in MUSIC_DEFINITIONS:
		MUSIC_DEFINITIONS["default"] = {
			"DM2TTL": {"Title": "Doom_II_Title", "Authors": "Bobby_Prince", 
					   "Soundtestpage": 1, "Soundtestcond": 0, "BPM": 140},
			"DM2INT": {"Title": "Doom_II_Intermission", "Authors": "Bobby_Prince",
					   "Soundtestpage": 1, "Soundtestcond": 0, "BPM": 120},
		}
	
	return MUSIC_DEFINITIONS

def create_musicdef_lump(endoom_md5, music_lumps, music_def_file=None):
	"""
	Create a MUSICDEF lump based on ENDOOM MD5 and available music lumps.
	
	Args:
		endoom_md5 (str): MD5 hash of ENDOOM lump or None if not available
		music_lumps (list): List of music lump names found in WAD
		music_def_file (str): Path to external music definitions file
		
	Returns:
		Lump: MUSICDEF lump with music definitions
	"""
	# Load music definitions
	music_defs = load_music_definitions(music_def_file)
	
	# Determine which music definition to use
	if not endoom_md5 or endoom_md5 not in music_defs:
		active_defs = music_defs.get("default", {})
		print("Using default music definitions")
	else:
		active_defs = music_defs.get(endoom_md5, music_defs.get("default", {}))
		print(f"Using custom music definitions for ENDOOM MD5: {endoom_md5[:8]}...")
	
	# Build MUSICDEF content
	musicdef_lines = []
	
	for lump_name in music_lumps:
		# Clean lump name (remove "D_" prefix if present, truncate to 6 chars)
		clean_name = lump_name.upper()
		if clean_name.startswith("D_"):
			clean_name = clean_name[2:]
		
		# Truncate to 6 characters (standard Doom lump name length)
		clean_name = clean_name[:6]
		
		# Look up definition
		if clean_name in active_defs:
			def_data = active_defs[clean_name]
			musicdef_lines.append(f"Lump {clean_name}")
			musicdef_lines.append(f"Title = {def_data['Title']}")
			musicdef_lines.append(f"Authors = {def_data['Authors']}")
			musicdef_lines.append(f"Soundtestpage = {def_data['Soundtestpage']}")
			musicdef_lines.append(f"Soundtestcond = {def_data['Soundtestcond']}")
			musicdef_lines.append(f"BPM = {def_data['BPM']}")
			musicdef_lines.append("")  # Empty line between entries
		else:
			# Create default entry for unknown music lumps
			musicdef_lines.append(f"Lump {clean_name}")
			musicdef_lines.append(f"Title = {clean_name}")
			musicdef_lines.append(f"Authors = Unknown")
			musicdef_lines.append(f"Soundtestpage = 1")
			musicdef_lines.append(f"Soundtestcond = 0")
			musicdef_lines.append(f"BPM = 120")
			musicdef_lines.append("")
	
	# Join lines and create lump
	musicdef_content = "\n".join(musicdef_lines)
	return Lump(musicdef_content.encode('utf-8'))

def get_endoom_md5(src_wadio):
	"""
	Calculate MD5 hash of ENDOOM lump if present.
	
	Args:
		src_wadio: WadIO object to read lumps from
		
	Returns:
		str: MD5 hash as hex string or None if no ENDOOM
	"""
	try:
		for entry in src_wadio.entries:
			lname = (entry.name if isinstance(entry.name, str) else entry.name.decode("ascii")).upper().rstrip("\x00")
			if lname in ("ENDOOM", "ENDBOOM"):
				data = src_wadio.read(lname)
				md5_hash = hashlib.md5(data).hexdigest()
				print(f"Found ENDOOM lump, MD5: {md5_hash}")
				return md5_hash
	except Exception as e:
		print(f"Error getting ENDOOM MD5: {e}")
	
	return None

def make_fw_sequence(src_wad, out_wad):
	"""Create FWATER1..FWATER16 from FWATER1..FWATER4."""
	src_flats = getattr(src_wad, "flats", {})
	out_flats = getattr(out_wad, "flats", {})

	# Remove existing FWATER1..FWATER16 in out
	for i in range(1, 17):
		fname = f"FWATER{i}"
		if fname in out_flats:
			del out_flats[fname]

	# collect FWATER1..4 bases
	base = {}
	for b in range(1, 5):
		bn = f"FWATER{b}"
		if bn in src_flats:
			base[b] = src_flats[bn].copy()
			print("Found base flat:", bn)
		else:
			print("Base flat missing:", bn)

	def base_for(n): return ((n - 1) // 4) + 1

	created = 0
	for n in range(1, 17):
		dest = f"FWATER{n}"
		b = base_for(n)
		if b in base:
			out_flats[dest] = base[b].copy()
			created += 1
			print(f"Created {dest} from FWATER{b}")
		else:
			print(f"Skipping {dest} (no FWATER{b} in source)")

	out_wad.flats = out_flats
	return created

def convert_exmx_maps(src_wad, out_wad, src_path, external_deh_data=None, music_def_file=None):
	"""
	Convert ExMx map names into MAPnn in out_wad.maps and copy D_E* lumps.
	Also convert MUS lumps to MIDI.
	"""
	ex_pattern = re.compile(r"^E(\d)M(\d{1,2})$", re.IGNORECASE)
	src_map_names = list(src_wad.maps.keys())
	src_wadio = WadIO(src_path)
	process_special_lumps(src_wad, out_wad, src_wadio, external_deh_data)
	ex_to_new_map = {}

	for oldname in src_map_names:
		m = ex_pattern.match(oldname.upper())
		if not m:
			continue
		ep = int(m.group(1))
		mp = int(m.group(2))

		mapnum = exmx_to_mapnum(ep, mp)
		target_name = f"MAP{mapnum:02d}"
		target_num = mapnum
		
		print(f"Converting {oldname} -> {target_name}")

		out_wad.maps[target_name] = src_wad.maps[oldname].copy()
		if oldname in out_wad.maps:
			try:
				del out_wad.maps[oldname]
			except Exception:
				pass

		ex_to_new_map[oldname.upper()] = (target_name, target_num)

	# Collect music lumps for MUSICDEF creation
	music_lumps = []
	
	for entry in src_wadio.entries:
		lname = (entry.name if isinstance(entry.name, str) else entry.name.decode("ascii")).upper().rstrip("\x00")
		
		data_bytes = src_wadio.read(lname)
		data_bytes = convert_mus_to_midi(data_bytes)
		lump_obj = Lump(data_bytes)
		lump_obj.name = lname

		if lname.startswith("D_"):
			out_wad.music[lname] = lump_obj
			music_lumps.append(lname)
			print(f"Copied music lump: {lname}")

	# Create MUSICDEF lump
	if music_lumps:
		endoom_md5 = get_endoom_md5(src_wadio)
		musicdef_lump = create_musicdef_lump(endoom_md5, music_lumps, music_def_file)
		out_wad.data["MUSICDEF"] = musicdef_lump
		print(f"Created MUSICDEF lump with {len(music_lumps)} entries")

	return len(ex_to_new_map)

def is_doom1_wad(wad):
	"""Check if WAD appears to be Doom 1 based by looking for ExMx maps"""
	ex_pattern = re.compile(r"^E(\d)M(\d{1,2})$", re.IGNORECASE)
	for mapname in wad.maps:
		if ex_pattern.match(mapname.upper()):
			return True
	return False

def convert_flat_to_graphic(flat_data, graphic_name):
	"""
	Convert a flat (64x64) to Doom patch format for use as a graphic.
	"""
	width = 64
	height = 64
	leftoffset = 0
	topoffset = 0
	
	columnofs = []
	patch_data = bytearray()
	header_size = 8 + (width * 4)
	
	for x in range(width):
		columnofs.append(header_size + len(patch_data))
		
		topdelta = 0
		length = height
		
		patch_data.append(topdelta)
		patch_data.append(length)
		patch_data.append(0)
		
		for y in range(height):
			pixel_index = y * width + x
			if pixel_index < len(flat_data):
				patch_data.append(flat_data[pixel_index])
			else:
				patch_data.append(0)
		
		patch_data.append(0)
		patch_data.append(0xFF)
	
	final_patch = bytearray()
	final_patch.extend(struct.pack('<HHhh', width, height, leftoffset, topoffset))
	
	for offset in columnofs:
		final_patch.extend(struct.pack('<I', offset))
	
	final_patch.extend(patch_data)
	
	return Lump(final_patch)

def create_cutscene_graphics(wad):
	"""Create cutscene graphics from flats."""
	created = 0
	
	for flat_name, graphic_name in CUTSCENE_GRAPHICS:
		print(f"Checking flatname {flat_name}...")
		if flat_name in wad.flats:
			flat_data = wad.flats[flat_name].data
			graphic_lump = convert_flat_to_graphic(flat_data, graphic_name)
			wad.graphics[graphic_name] = graphic_lump
			created += 1
			print(f"  Created graphic {graphic_name} from flat {flat_name}")
		else:
			print("  Flat does not exist in this WAD!")
	
	return created

def parse_texture_lump_to_text(pnames: list, lumps_bytes: bytes) -> str:
	"""
	Parse TEXTURE1/TEXTURE2 binary and emit a ZDoom-style TEXTURES text block.
	"""
	data = lumps_bytes
	if len(data) < 4:
		return ""
	numtextures = int.from_bytes(data[0:4], 'little')
	if numtextures <= 0 or numtextures > 10000:
		return ""
	offsets = []
	for i in range(numtextures):
		off = 4 + i*4
		if off+4 > len(data):
			break
		offsets.append(int.from_bytes(data[off:off+4], 'little'))
	out_lines = []
	out_lines.append("// Generated TEXTURES from TEXTURE lumps")
	out_lines.append("// NOTE: Generated by pywadadvance.py - verify in SLADE/whatever.")
	for off in offsets:
		if off <= 0 or off >= len(data):
			continue
		if off + 22 > len(data):
			continue
		name_raw = data[off:off+8]
		texname = name_raw.split(b'\x00', 1)[0].decode('ascii', errors='replace')
		if texname.upper() == "NULLTEXT":
			continue
		masked = int.from_bytes(data[off+8:off+12], 'little')
		width = int.from_bytes(data[off+12:off+14], 'little', signed=False)
		height = int.from_bytes(data[off+14:off+16], 'little', signed=False)
		patchcount = int.from_bytes(data[off+20:off+22], 'little')
		out_lines.append(f'WallTexture "{texname}", {width}, {height}')
		out_lines.append("{")
		p_off = off + 22
		for p in range(patchcount):
			if p_off + 10 > len(data):
				break
			originx = int.from_bytes(data[p_off+0:p_off+2], 'little', signed=True)
			originy = int.from_bytes(data[p_off+2:p_off+4], 'little', signed=True)
			patch_index = int.from_bytes(data[p_off+4:p_off+6], 'little', signed=False)
			p_off += 10
			patch_name = pnames[patch_index] if 0 <= patch_index < len(pnames) else f"PNAME_{patch_index}"
			out_lines.append(f'\tPatch "{patch_name}", {originx}, {originy}')
		out_lines.append("}")
		out_lines.append("")
	return "\n".join(out_lines)

def parse_pnames(lump_bytes: bytes) -> list:
	"""
	Parse a PNAMES lump and return a list of patch names.
	"""
	if not lump_bytes or len(lump_bytes) < 4:
		return []

	try:
		nummappatches = int.from_bytes(lump_bytes[0:4], "little", signed=False)
	except Exception:
		return []

	if nummappatches <= 0:
		return []

	available = (len(lump_bytes) - 4) // 8
	if available <= 0:
		return []

	if nummappatches > available:
		print(f"Warning: PNAMES header claims {nummappatches} names but only {available} entries present; clamping.")
		nummappatches = available

	names = []
	off = 4
	for i in range(nummappatches):
		raw = lump_bytes[off:off+8]
		if len(raw) < 8:
			raw = raw.ljust(8, b'\x00')
		name = raw.split(b'\x00', 1)[0].decode('ascii', errors='replace').rstrip(' ')
		name = name.upper()
		names.append(name)
		off += 8

	return names

def process_special_lumps(src_wad, out_wad, src_wadio, external_deh_data=None):
	"""
	Iterate source lumps and produce additional helper lumps for the PWAD.
	"""
	deh_mapping = {}
	src_data = getattr(src_wad, "data", {})

	demo_lumps = [
		name for name in list(out_wad.data.keys())
		if re.match(r"^DEMO\d+$", name.upper())
	]

	for name in demo_lumps:
		del out_wad.data[name]

	if demo_lumps:
		print(f"Cleaned out {len(demo_lumps)} demo lumps: {', '.join(demo_lumps)}")

	pnames_bytes = None
	if "PNAMES" in src_data:
		pnames_bytes = src_data["PNAMES"].data
	
	textures_bytes = []
	if "TEXTURE1" in src_data:
		textures_bytes.append(src_data["TEXTURE1"].data)
	if "TEXTURE2" in src_data:
		textures_bytes.append(src_data["TEXTURE2"].data)

	all_external_deh = []
	if external_deh_data:
		print(f"Processing {len(external_deh_data)} external DEH/BEX files")
		for name, data in external_deh_data:
			all_external_deh.append((name, data))

	for entry in getattr(src_wadio, "entries", []):
		name = (entry.name if isinstance(entry.name, str) else entry.name.decode("ascii", errors="ignore")).upper().rstrip("\x00")
		try:
			lump_bytes = src_wadio.read(name)
		except Exception:
			continue

		if name == "ENDOOM" or name == "ENDBOOM":
			try:
				lua_bytes = parse_endoom_and_build_lua(lump_bytes)
				out_name = "LUA_ENDM"
				safe_add_lump_to_data(out_wad, out_name, WadIO._LumpFromBytes(lua_bytes) if hasattr(WadIO, '_LumpFromBytes') else Lump(lua_bytes))
				print(f"Inserted {out_name} (ENDOOM -> Lua endoom)")
			except Exception as e:
				print(f"Failed to process ENDOOM: {e}")

		elif name in ("DEHACKED", "DEHACK", "DEH", "PATCH", "BEX"):
			all_external_deh.append((f"internal_{name}", lump_bytes))
			print(f"Found internal DEHACKED lump: {name}")

		elif name.startswith("LANGUAGE") or name.startswith("LANG") or name == "LANGUAGE":
			try:
				m = parse_key_value_pairs_from_text(lump_bytes)
				deh_mapping.update(m)
				print(f"Collected LANGUAGE strings from {name}")
			except Exception as e:
				print(f"Failed to parse LANGUAGE {name}: {e}")

		elif name == "PNAMES" and pnames_bytes is None:
			pnames_bytes = lump_bytes
			print("PNAMES found")

		elif name in ("TEXTURE1", "TEXTURE2"):
			textures_bytes.append(lump_bytes)
			print(f"{name} queued for TEXTURES conversion")

		elif name == "COLORMAP":
			try:
				translate_lump = create_translate_lump_from_colormap(lump_bytes)
				if len(translate_lump.data) > 0:
					out_wad.data["TRNSLATE"] = translate_lump
					print("Created TRNSLATE lump from COLORMAP rows")

				fixed = force_colormap_size(lump_bytes)
				out_wad.data["COLORMAP"] = Lump(fixed)
				print("Replaced/inserted fixed COLORMAP (256x32)")
			except Exception as e:
				print(f"COLORMAP processing failed: {e}")

	if all_external_deh:
		combined_structured_deh = {}
		for name, data in all_external_deh:
			try:
				structured_deh = parse_dehacked_structured(data)
				if structured_deh:
					for mode, entries in structured_deh.items():
						if mode not in combined_structured_deh:
							combined_structured_deh[mode] = []
						existing_ids = {entry['id'] for entry in combined_structured_deh[mode] if entry['id'] is not None}
						for entry in entries:
							if entry['id'] is not None and entry['id'] in existing_ids:
								combined_structured_deh[mode] = [e for e in combined_structured_deh[mode] if e['id'] != entry['id']]
							combined_structured_deh[mode].append(entry)
					print(f"Parsed structured DEHACKED from {name}")
				else:
					print(f"No structured DEHACKED data found in {name}")
			except Exception as e:
				print(f"Failed to parse {name} as structured DEHACKED: {e}")
		
		if combined_structured_deh:
			lua_deh = build_structured_lua_deh(combined_structured_deh)
			out_wad.data["LUA_DEH"] = Lump(lua_deh)
			print(f"Wrote combined LUA_DEH from {len(all_external_deh)} DEH/BEX sources")

	if deh_mapping and "LUA_DEH" not in out_wad.data:
		try:
			lua_deh = build_lua_deh_table(deh_mapping)
			out_wad.data["LUA_DEH"] = Lump(lua_deh)
			print("Wrote LUA_DEH from aggregated LANGUAGE entries")
		except Exception as e:
			print(f"Failed to write LUA_DEH: {e}")

	if pnames_bytes and textures_bytes:
		try:
			pnames = parse_pnames(pnames_bytes)
			combined_text = []
			for tb in textures_bytes:
				txt = parse_texture_lump_to_text(pnames, tb)
				if txt:
					combined_text.append(txt)
			if combined_text:
				text_blob = ("\n\n".join(combined_text)).encode("utf-8")
				out_wad.data["TEXTURES"] = Lump(text_blob)
				try:
					del out_wad.data["TEXTURE1"]
					del out_wad.data["TEXTURE2"]
					del out_wad.data["PNAMES"]
				except Exception:
					pass
				print("Wrote TEXTURES from TEXTURE1/TEXTURE2 + PNAMES")
		except Exception as e:
			print(f"TEXTURE -> TEXTURES conversion failed: {e}")

def force_colormap_size(blob: bytes) -> bytes:
	cur = len(blob)
	target = DESIRED_COLORMAP_SIZE
	if cur == target:
		return blob
	if cur > target:
		print(f"Trimming COLORMAP from {cur} -> {target} bytes")
		return blob[:target]
	
	if cur % 256 != 0:
		rows = math.ceil(cur / 256)
		padded = blob + b'\x00' * (rows*256 - cur)
	else:
		rows = cur // 256
		padded = blob
	output = bytearray()
	rows_bytes = [padded[i*256:(i+1)*256] for i in range(len(padded)//256)]
	i = 0
	while len(output) < target:
		output.extend(rows_bytes[i % len(rows_bytes)])
		i += 1
	print(f"Padded COLORMAP from {cur} -> {len(output)} bytes")
	return bytes(output[:target])

def detect_udmf_namespace(map_data):
	"""Detect UDMF namespace from map data."""
	if 'TEXTMAP' in map_data:
		textmap_data = map_data['TEXTMAP'].tostring().decode('latin-1')
		namespace_match = re.search(r'namespace\s*=\s*"([^"]+)"', textmap_data)
		if namespace_match:
			return namespace_match.group(1)
	return None

def process_udmf_map_linedefs(map_data, bump_amount=941):
	"""Process UDMF map linedefs and bump special values."""
	if 'TEXTMAP' not in map_data:
		return map_data
	
	textmap_content = map_data['TEXTMAP'].tostring().decode('latin-1')
	lines = textmap_content.split('\n')
	in_linedef = False
	linedef_content = []
	processed_lines = []
	
	for line in lines:
		stripped = line.strip()
		
		if stripped == 'linedef' or (stripped.startswith('linedef') and '{' in stripped):
			in_linedef = True
			linedef_content = [line]
		elif in_linedef and stripped == '}':
			in_linedef = False
			linedef_content.append(line)
			processed_linedef = process_single_udmf_linedef(linedef_content, bump_amount)
			processed_lines.extend(processed_linedef)
			linedef_content = []
		elif in_linedef:
			linedef_content.append(line)
		else:
			processed_lines.append(line)
	
	new_textmap = '\n'.join(processed_lines)
	map_data['TEXTMAP'] = Lump(new_textmap.encode('latin-1'))
	return map_data

def process_single_udmf_linedef(linedef_lines, bump_amount):
	"""Process a single UDMF linedef and bump its special value."""
	processed = []
	
	for line in linedef_lines:
		stripped = line.strip()
		if stripped.startswith('special') and '=' in stripped:
			special_match = re.search(r'special\s*=\s*(\d+)', stripped)
			if special_match:
				old_special = int(special_match.group(1))
				new_special = old_special + bump_amount
				line = re.sub(r'special\s*=\s*\d+', f'special = {new_special}', line)
		processed.append(line)
	
	return processed

def patch_linedefs_add(wad_obj, add_value=941):
	"""
	Add `add_value` to every linedef.action for classic Doom-linedef maps.
	"""
	from omg import Lump

	for mapname, mapgroup in list(wad_obj.maps.items()):
		try:
			if "LINEDEFS" not in mapgroup:
				continue

			ld_lump = mapgroup["LINEDEFS"]
			ld_data = bytearray(ld_lump.data)
			length = len(ld_data)

			if length % 14 == 0:
				count = length // 14
				for i in range(count):
					action_off = i * 14 + 6
					old_action = int.from_bytes(ld_data[action_off:action_off+2], "little")
					new_action = (old_action + add_value) & 0xFFFF
					ld_data[action_off:action_off+2] = new_action.to_bytes(2, "little")
				mapgroup["LINEDEFS"] = Lump(bytes(ld_data))
				print(f"Patched {count} linedefs in {mapname}: action += {add_value}")

			elif length % 16 == 0:
				print(f"Skipping {mapname}: LINEDEFS looks like ZLinedef (entry size 16). Not modified.")
				continue

			else:
				print(f"Unknown LINEDEFS entry size in {mapname} (len={length}). Skipping.")
				continue

		except Exception as e:
			print(f"Error patching LINEDEFS in {mapname}: {e}")
			continue

def normalize_pegging_flags_to_doom(wad_obj):
	"""
	Normalize pegging flags for SRB2 renderer compatibility.
	
	The pegging semantics differ between one-sided and two-sided linedefs:
	- One-sided: Lower Unpegged controls top-vs-bottom attachment
	- Two-sided: Lower Unpegged and Peg Midtexture have specific meanings for each texture layer
	
	This function ensures flags are set consistently for proper SRB2 rendering.
	"""
	modified_total = 0

	for mapname, mapgroup in list(wad_obj.maps.items()):
		try:
			if "LINEDEFS" not in mapgroup or "SIDEDEFS" not in mapgroup or "SECTORS" not in mapgroup:
				continue

			ld_data = bytearray(mapgroup["LINEDEFS"].data)
			sd_data = mapgroup["SIDEDEFS"].data
			sec_data = mapgroup["SECTORS"].data

			if len(ld_data) % 14 != 0 or len(sd_data) % 30 != 0 or len(sec_data) % 26 != 0:
				continue

			sidedef_count = len(sd_data) // 30
			linedef_count = len(ld_data) // 14

			changed = False
			changed_count_in_map = 0

			for li in range(linedef_count):
				base = li * 14
				flags_off = base + 4
				right_off = base + 10
				left_off = base + 12

				flags = int.from_bytes(ld_data[flags_off:flags_off+2], "little")
				right = int.from_bytes(ld_data[right_off:right_off+2], "little")
				left  = int.from_bytes(ld_data[left_off:left_off+2], "little")

				def valid_sid(idx):
					return 0 <= idx < sidedef_count

				right_idx = right if valid_sid(right) else None
				left_idx = left  if valid_sid(left)  else None
				two_sided = ((flags & ML_TWOSIDED) != 0) or (right_idx is not None and left_idx is not None)

				new_flags = flags
				
				# For two-sided linedefs, pegging flags have specific meanings and should be 
				# preserved as set by the mapper. Ensure the ML_TWOSIDED flag reflects reality.
				if two_sided and not (new_flags & ML_TWOSIDED):
					new_flags = new_flags | ML_TWOSIDED
				elif not two_sided and (new_flags & ML_TWOSIDED):
					new_flags = new_flags & ~ML_TWOSIDED

				if new_flags != flags:
					ld_data[flags_off:flags_off+2] = new_flags.to_bytes(2, "little")
					changed = True
					changed_count_in_map += 1

			if changed:
				mapgroup["LINEDEFS"] = Lump(bytes(ld_data))
				print(f"Normalized pegging flags in {mapname}: adjusted {changed_count_in_map} linedefs")
				modified_total += changed_count_in_map

		except Exception as e:
			print(f"Error normalizing pegging flags in {mapname}: {e}")
			continue

	print(f"Total pegging flag normalizations: {modified_total}")
	return modified_total

def create_translate_lump_from_colormap(colormap_data):
	"""Create a TRNSLATE lump based on each row of the COLORMAP."""
	total_bytes = len(colormap_data)
	num_rows = total_bytes // 256
	
	if num_rows == 0:
		print("Warning: COLORMAP is too small or empty")
		return Lump(b"")
	
	print(f"Creating TRNSLATE from COLORMAP with {num_rows} rows")
	
	translate_lines = []
	
	for row_num in range(num_rows):
		row_start = row_num * 256
		row_end = row_start + 256
		
		if row_end > len(colormap_data):
			break
			
		row_data = colormap_data[row_start:row_end]
		mappings = []
		for color_index in range(256):
			if color_index < len(row_data):
				dest_value = row_data[color_index]
				mapping = f"{color_index}:{color_index}={dest_value}:{dest_value}"
				mappings.append(mapping)
		
		row_mappings = ", ".join(f'"{m}"' for m in mappings)
		translate_lines.append(f"COLORMAPROW{row_num+1} = {row_mappings}")
	
	translate_text = "\n".join(translate_lines)
	return Lump(translate_text.encode('latin-1'))

def create_translate_lump_simple_identity(num_rows=34):
	"""Create a simpler TRNSLATE lump with identity mappings for testing."""
	print(f"Creating simple identity TRNSLATE with {num_rows} rows")
	
	translate_lines = []
	
	for row_num in range(num_rows):
		mappings = []
		for color_index in range(256):
			mapping = f"{color_index}:{color_index}={color_index}:{color_index}"
			mappings.append(mapping)
		
		row_mappings = ", ".join(f'"{m}"' for m in mappings)
		translate_lines.append(f"COLORMAPROW{row_num+1} = {row_mappings}")
	
	translate_text = "\n".join(translate_lines)
	return Lump(translate_text.encode('latin-1'))

def create_player_sprites_from_play_lumps(src_wad, out_wad, skin_name="johndoom", suppresserrors=False, usesrb2conventions=False):
	"""
	Create player sprite lumps from PLAY sprite lumps and add P_SKIN lump.
	Throws an error if angle sets are inconsistent (SRB2 behavior).
	"""
	skin_content = f"name = {skin_name}\n".encode("utf-8")
	out_wad.data["P_SKIN"] = Lump(skin_content)
	print(f"Created P_SKIN lump with name = {skin_name}")

	default_mapping = {
		"STND": "A",
		"WALK": "ABCD",
		"FIRE": "E",
		"FLSH": "F",
		"PAIN": "G",
		"DYIN": "HIJKLMN",
		"DEAD": "N",
		"GIBN": "OPQRSTUVW",
		"GIBD": "W",
	}

	srb2_mapping = {
		"STND": "A",
		"WAIT": "BC",
		"WALK": "DEFGHIJK",
		"SPIN": "LMNO",
		"SPNG": "P",
		"ROLL": "QRST",
		"SUPR": "UVWXYZ",
		"GASP": "[",
		"PAIN": "\\",
		"DEAD": "]",
		"EDGE": "^_",
		"FALL": "`ab"
		# TODO
	}

	def expand_mapping(mapping):
		expanded = {}
		for state_name, frames in mapping.items():
			if isinstance(frames, str):
				expanded[state_name] = [
					(src_frame, chr(ord('A') + i))
					for i, src_frame in enumerate(frames)
				]
			else:
				expanded[state_name] = frames
		return expanded

	frame_mapping = expand_mapping(srb2_mapping if usesrb2conventions else default_mapping)

	validframes_default = 'ABCDEFGHIJKLMNOPQRSTUVW'
	validframes_srb2 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`ab'

	validframes = validframes_srb2 if usesrb2conventions else validframes_default

	# Gather all PLAY lumps
	play_lumps = {}
	def is_valid_play_lump(name):
		return name.startswith("PLAY") and len(name) >= 5 and name[4] in validframes and name != 'PLAYPAL'

	def parse_play_suffix(suffix):
		if len(suffix) % 2 != 0:
			raise ValueError(f"Malformed PLAY lump suffix: {suffix}")

		pairs = [suffix[i:i+2] for i in range(0, len(suffix), 2)]
		frame = pairs[0][0]
		if any(p[0] != frame for p in pairs):
			raise ValueError(f"Inconsistent frame letters in suffix: {suffix}")

		angles = ''.join(p[1] for p in pairs)
		return frame, angles

	for lump_name, lump in {**src_wad.data, **getattr(src_wad, 'sprites', {})}.items():
		if is_valid_play_lump(lump_name):
			play_lumps[lump_name] = lump
			print(f"Found PLAY lump: {lump_name}")

	if not play_lumps:
		print("No valid PLAY lumps found in source WAD")
		return 0

	valid_angle_sets = [
		set("0"),
		set("12345678"),
		set("123456789ABCDEFG")
	]

	# Validate angles
	lump_groups = {}
	for lump_name in play_lumps:
		suffix = lump_name[4:]

		if len(suffix) % 2 != 0:
			raise ValueError(f"Malformed PLAY lump suffix: {suffix}")

		pairs = [suffix[i:i+2] for i in range(0, len(suffix), 2)]

		frame = pairs[0][0]

		angles = ''.join(p[1] for p in pairs)

		base_name = "PLAY" + frame

		if not any(set(angles).issubset(valid) for valid in valid_angle_sets):
			if not suppresserrors:
				raise ValueError(f"Invalid angle set '{angles}' in lump {lump_name}")

		if base_name not in lump_groups:
			lump_groups[base_name] = set()
		lump_groups[base_name].update(angles)

	# Check for completeness
	for base_name, angles_found in lump_groups.items():
		angles_found_str = ''.join(sorted(angles_found))
		if not any(all(c in s for c in angles_found_str) for s in valid_angle_sets):
			if not suppresserrors:
				raise ValueError(f"Incomplete or inconsistent angles for {base_name}: found {angles_found_str}")

	created_count = 0

	def process_condensed_name(source_name, play_frame, output_frame, state_name):
		suffix = source_name[4:]
		chars = list(suffix)
		for i in range(0, len(chars), 2):
			if i < len(chars) and chars[i] == play_frame:
				chars[i] = output_frame
		new_suffix = ''.join(chars)
		return f"{state_name}{new_suffix}"

	# Generate output lumps
	for state_name, frame_pairs in frame_mapping.items():
		for play_frame, output_frame in frame_pairs:
			base_play_name = f"PLAY{play_frame}"
			matching_lumps = [name for name in play_lumps if name.startswith(base_play_name)]

			if not matching_lumps:
				if not suppresserrors:
					raise ValueError(f"Missing PLAY lump for frame '{play_frame}' required by state '{state_name}'")

			for source_lump_name in matching_lumps:
				output_lump_name = process_condensed_name(
					source_lump_name, play_frame, output_frame, state_name
				).upper()
				out_wad.data[output_lump_name] = play_lumps[source_lump_name].copy()
				print(f"Created {output_lump_name} from {source_lump_name}")
				created_count += 1

	print(f"Created {created_count} player sprite lumps from PLAY lumps")
	return created_count

def append_stcfn_uppercase_to_lowercase(wad):
	stcfn_prefix = "STCFN"
	uppercase_range = range(65, 91)
	lowercase_range = range(97, 123)

	for upper, lower in zip(uppercase_range, lowercase_range):
		upper_name = f"{stcfn_prefix}{upper:03}"
		lower_name = f"{stcfn_prefix}{lower:03}"

		if upper_name in wad.graphics:
			# Deep copy the Graphic lump
			wad.graphics[lower_name] = wad.graphics[upper_name].copy()
			print(f"Copied {upper_name} → {lower_name}")
		else:
			print(f"Missing uppercase lump: {upper_name}")