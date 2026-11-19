"""Hash Doom map data and resolve known map titles."""

import hashlib
import json
import re
import struct
from pathlib import Path


MAP_NAMES_PATH = Path(__file__).resolve().parent.parent / "data" / "map_names.json"


def hash_map_data(map_data) -> str:
	"""Return a SHA-256 digest for a map's named lump contents."""
	hasher = hashlib.sha256()

	for lump_name in sorted(name for name in map_data if name.upper() != "_HEADER_"):
		lump = map_data[lump_name]
		data = lump.data
		if not isinstance(data, bytes):
			raise TypeError(f"Map lump {lump_name!r} data must be bytes")

		name_bytes = lump_name.upper().encode("ascii")
		hasher.update(struct.pack(">I", len(name_bytes)))
		hasher.update(name_bytes)
		hasher.update(struct.pack(">Q", len(data)))
		hasher.update(data)

	return hasher.hexdigest()


def load_map_name_hashes(path: Path = MAP_NAMES_PATH) -> dict[str, str]:
	"""Load the SHA-256-to-level-title registry from map_names.json."""
	with path.open("r", encoding="utf-8") as map_names_file:
		data = json.load(map_names_file)

	if not isinstance(data, dict):
		raise ValueError(f"Map names file {path} must contain a JSON object")

	map_hashes = {
		key: value
		for key, value in data.items()
		if isinstance(key, str) and len(key) == 64
	}

	for digest, title in map_hashes.items():
		if (
			not isinstance(digest, str)
			or len(digest) != 64
			or any(character not in "0123456789abcdefABCDEF" for character in digest)
		):
			raise ValueError(f"Invalid SHA-256 map hash in {path}: {digest!r}")
		if (
			not isinstance(title, str)
			or not title.strip()
			or "\n" in title
			or "\r" in title
		):
			raise ValueError(f"Map title for hash {digest!r} in {path} must be a non-empty single-line string")

	return {digest.lower(): title.strip() for digest, title in map_hashes.items()}


def get_hash_based_map_names(wad, map_hashes: dict[str, str] | None = None) -> dict[str, str]:
	"""Return known map titles keyed by the map names in a WAD."""
	if map_hashes is None:
		map_hashes = load_map_name_hashes()

	maps = getattr(wad, "maps", wad)
	map_digests = {
		map_name: hash_map_data(map_data)
		for map_name, map_data in maps.items()
	}
	return resolve_map_names(map_digests, map_hashes)


def resolve_map_names(map_digests: dict[str, str], map_hashes: dict[str, str]) -> dict[str, str]:
	"""Resolve map names from already-computed map digests."""
	matches = {}
	for map_name, digest in map_digests.items():
		title = map_hashes.get(digest)
		if title is not None:
			matches[map_name] = title
	return matches


def parse_soc_level_names(soc_content: bytes | str) -> dict[int, str]:
	"""Extract level numbers and names from generated SOC text."""
	if isinstance(soc_content, bytes):
		soc_content = soc_content.decode("utf-8")

	level_names = {}
	level_num = None
	for line in soc_content.splitlines():
		line = line.strip()
		level_match = re.fullmatch(r"Level\s+(\d+)", line, re.IGNORECASE)
		if level_match:
			level_num = int(level_match.group(1))
			continue

		if level_num is None or "=" not in line:
			continue
		key, value = (part.strip() for part in line.split("=", 1))
		if key.lower() == "levelname":
			level_names[level_num] = value

	return level_names


def parse_dehacked_level_names(structured_deh: dict) -> dict[int, str]:
	"""Extract Doom level titles from combined DeHackEd TEXT replacements."""
	level_names = {}
	level_prefix = re.compile(
		r"^\s*(?:level\s+(\d+)|e(\d+)m(\d+))\s*:\s*", re.IGNORECASE
	)

	def get_level_num(match):
		if match.group(1) is not None:
			return int(match.group(1))
		return (int(match.group(2)) - 1) * 9 + int(match.group(3))

	for entry in structured_deh.get("TEXT", []):
		fields = entry.get("fields", {})
		original = fields.get("ORIGINAL", b"").decode("latin-1", errors="replace")
		replacement = fields.get("NEW", b"").decode("latin-1", errors="replace")
		original_match = level_prefix.match(original)
		if original_match is None:
			continue

		level_num = get_level_num(original_match)
		replacement_match = level_prefix.match(replacement)
		if replacement_match is not None:
			if get_level_num(replacement_match) != level_num:
				continue
			replacement = replacement[replacement_match.end():]

		title = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", " ", replacement.strip())
		title = title.title()
		minor_words = re.compile(
			r"\b(?:a|an|and|as|at|but|by|for|in|nor|of|on|or|the|to|up|via)\b",
			re.IGNORECASE,
		)
		title = minor_words.sub(
			lambda match: (
				match.group(0).lower()
				if match.start() > 0 and match.end() < len(title)
				else match.group(0)
			),
			title,
		)
		title = re.sub(
			r"(\d+)(st|nd|rd|th)\b",
			lambda match: match.group(1) + match.group(2).lower(),
			title,
			flags=re.IGNORECASE,
		)
		if title:
			level_names[level_num] = title

	return level_names


def generate_soc_map_names(map_names: dict[str, str], base_templates: dict[int, dict[str, str]]) -> str:
	"""Generate complete SOC level entries, overriding only matched level names."""
	lines = []
	for map_name, title in map_names.items():
		match = re.fullmatch(r"MAP(\d+)", map_name.upper())
		if match is None:
			match = re.fullmatch(r"E(\d)M(\d{1,2})", map_name.upper())
			if match is None:
				continue
			level_num = (int(match.group(1)) - 1) * 9 + int(match.group(2))
		else:
			level_num = int(match.group(1))

		fields = dict(base_templates.get(level_num, {
			"NoTitleCard": "true",
			"SelectHeading": "Campaign",
			"NoVisitNeeded": "true",
			"TypeOfLevel": "Singleplayer,Doom,Co-op",
			"LevelSelect": "1",
			"Act": "0",
			"NoZone": "1",
			"Music": "",
		}))
		fields["Levelname"] = title

		lines.append(f"Level {level_num}")
		lines.extend(f"{key} = {value}" for key, value in fields.items())
		lines.append("")

	return "\n".join(lines).rstrip()


def has_mapinfo_lump(wad_or_wadio) -> bool:
	"""Return whether a WAD or WadIO contains MAPINFO or UMAPINFO."""
	entries = getattr(wad_or_wadio, "entries", None)
	if entries is not None:
		names = (
			entry.name if isinstance(entry.name, str) else entry.name.decode("ascii")
			for entry in entries
		)
	else:
		names = getattr(wad_or_wadio, "data", {}).keys()

	return any(name.upper().rstrip("\x00") in {"MAPINFO", "UMAPINFO"} for name in names)
