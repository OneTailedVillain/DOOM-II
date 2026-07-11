"""
DEHACKED and BEX parsing functions.
"""

import re

def parse_key_value_pairs_from_text(blob: bytes) -> dict:
	"""
	Parse classic LANGUAGE / DEHACKED style text and return KEY->value (bytes).
	"""
	txt = blob.decode('latin-1', errors='replace')
	results = {}

	bex_re = re.compile(r'([A-Z0-9_]+)\s*={3,}\s*(.*?)\s*={3,}', re.DOTALL)
	for m in bex_re.finditer(txt):
		key = m.group(1).strip()
		val = m.group(2)
		results[key] = val.encode('latin-1')

	n = len(txt)
	i = 0

	def skip_whitespace(j):
		while j < n and txt[j].isspace():
			j += 1
		return j

	while i < n:
		in_quote = False
		quote_ch = None
		in_bracket = False
		bracket_level = 0
		j = i
		eqpos = -1
		while j < n:
			ch = txt[j]
			if not in_quote and not in_bracket and txt.startswith('//', j):
				nl = txt.find('\n', j)
				j = n if nl == -1 else nl + 1
				continue
			if not in_quote and not in_bracket and txt.startswith('/*', j):
				end = txt.find('*/', j+2)
				j = n if end == -1 else end + 2
				continue

			if not in_quote:
				if txt.startswith('[[', j):
					in_bracket = True
					j += 2
					continue
				if in_bracket:
					if txt.startswith(']]', j):
						in_bracket = False
						j += 2
						continue
					j += 1
					continue

			if not in_quote and ch in ('"', "'"):
				in_quote = True
				quote_ch = ch
				j += 1
				continue
			if in_quote:
				if ch == '\\' and j+1 < n:
					j += 2
					continue
				if ch == quote_ch:
					in_quote = False
					quote_ch = None
				j += 1
				continue

			if ch == '=':
				eqpos = j
				break
			j += 1

		if eqpos == -1:
			break

		line_start = txt.rfind('\n', 0, eqpos) + 1
		left = txt[line_start:eqpos].strip()
		if not left:
			i = eqpos + 1
			continue

		mkey = re.search(r'([A-Z][A-Z0-9_]*)\s*$', left.upper())
		if not mkey:
			key = left.strip().upper()
		else:
			key = mkey.group(1).strip().upper()

		segs = []
		k = eqpos + 1
		while k < n:
			if txt[k].isspace():
				k += 1
				continue

			if txt.startswith('//', k):
				nl = txt.find('\n', k)
				k = n if nl == -1 else nl + 1
				continue
			if txt.startswith('/*', k):
				end = txt.find('*/', k+2)
				k = n if end == -1 else end + 2
				continue

			ch = txt[k]
			if txt.startswith('[[' , k):
				k2 = txt.find(']]', k+2)
				if k2 == -1:
					content = txt[k+2:]
					segs.append(('bracket', content))
					k = n
					break
				content = txt[k+2:k2]
				segs.append(('bracket', content))
				k = k2 + 2
				continue

			if ch in ('"', "'"):
				quotech = ch
				k += 1
				start_q = k
				buf = []
				while k < n:
					c = txt[k]
					if c == '\\' and k+1 < n:
						buf.append('\\')
						buf.append(txt[k+1])
						k += 2
						continue
					if c == quotech:
						k += 1
						break
					buf.append(c)
					k += 1
				segs.append(('quote', ''.join(buf)))
				continue

			if ch == ';':
				k += 1
				break

			start_r = k
			while k < n and not txt[k].isspace() and txt[k] not in ';':
				if txt.startswith('//', k) or txt.startswith('/*', k) or txt.startswith('[[', k):
					break
				k += 1
			rawtok = txt[start_r:k]
			if rawtok:
				segs.append(('raw', rawtok))

		parts = []
		for typ, content in segs:
			if typ in ('quote', 'bracket'):
				parts.append(content.encode('latin-1'))
			else:
				ct = content.strip()
				if ct:
					parts.append(ct.encode('latin-1'))
		if parts:
			valbytes = b"".join(parts)
		else:
			valbytes = b""
		results[key] = valbytes

		i = k

	return results

def parse_dehacked_structured(blob: bytes) -> dict:
	"""
	More robust parser for classic .deh and .bex.
	"""
	txt = blob.decode('latin-1', errors='replace')
	lines = txt.splitlines()

	MODE_WORDS = set(["THING","SOUND","FRAME","SPRITE","AMMO","WEAPON","POINTER","CHEAT","MISC","TEXT","STRINGS","PARS","CODEPTR","MUSIC","SPRITES","SOUNDS","INCLUDE"])

	results = {}
	current_mode = None
	current_entry = None
	current_frame_id = None
	
	def push_entry():
		nonlocal current_mode, current_entry, current_frame_id, results
		if not current_mode or current_entry is None:
			return
		results.setdefault(current_mode, []).append(current_entry)
		current_entry = None
		current_frame_id = None

	i = 0
	while i < len(lines):
		raw = lines[i]
		s = raw.strip()
		i += 1
		
		if s == "" or s.startswith('#'):
			continue

		# Handle bracketed sections like [CODEPTR]
		if s.startswith('[') and s.endswith(']'):
			push_entry()
			current_mode = s[1:-1].strip()
			current_entry = {'id': None, 'fields': {}}
			current_frame_id = None
			continue

		if current_mode and current_mode.upper() == "CODEPTR":
			# If we're in CODEPTR mode and see a line like "FRAME 1131 = Scream"
			codepointer_match = re.match(r'^\s*FRAME\s+(\d+)\s*=\s*(.+)$', s, re.IGNORECASE)
			if codepointer_match:
				frame_num = int(codepointer_match.group(1))
				codepointer_name = codepointer_match.group(2).strip()
				
				# Create entry for this frame
				entry = {
					'id': frame_num,
					'fields': {
						'_ORIGINAL_LINE': raw.encode('latin-1'),
						'CODEPOINTER': codepointer_name.encode('latin-1')
					}
				}
				results.setdefault(current_mode, []).append(entry)
				continue

		# Handle SPRITES section
		if current_mode and current_mode.upper() == "SPRITES":
			sprite_match = re.match(r'^\s*(\d+)\s*=\s*([A-Z0-9_]+)\s*$', s)
			if sprite_match:
				sprite_id = int(sprite_match.group(1))
				sprite_name = sprite_match.group(2).strip()
				
				entry = {
					'id': sprite_id,
					'fields': {
						'_ORIGINAL_LINE': raw.encode('latin-1'),
						'SPRITE_NAME': sprite_name.encode('latin-1')
					}
				}
				results.setdefault("SPRITES", []).append(entry)
				continue

		# Handle SOUNDS section
		if current_mode and current_mode.upper() == "SOUNDS":
			sound_match = re.match(r'^\s*(\d+)\s*=\s*([A-Z0-9_]+)\s*$', s)
			if sound_match:
				sound_id = int(sound_match.group(1))
				sound_name = sound_match.group(2).strip()
				
				entry = {
					'id': sound_id,
					'fields': {
						'_ORIGINAL_LINE': raw.encode('latin-1'),
						'SOUND_NAME': sound_name.encode('latin-1')
					}
				}
				results.setdefault("SOUNDS", []).append(entry)
				continue

		# Match a section like: WORD 123 [optional second number]
		m = re.match(
			r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)(?:\s+(-?\d+))?\s*$',
			s
		)

		if not m:
			# Only match partial headers if they are NOT followed by '='
			m = re.match(
				r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)(?!\s*=)',
				s
			)

		if m:
			push_entry()
			mode_word = m.group(1).strip()
			
			# SPECIAL CASE: TEXT
			if mode_word.upper() == "TEXT":
				current_mode = "TEXT"
				orig_len = int(m.group(2))
				new_len = int(m.group(3)) if m.lastindex and m.lastindex >= 3 and m.group(3) is not None else None
				
				if new_len is None:
					print(f"WARNING: TEXT header with only one number: {s}")
					continue
				
				# Read ALL subsequent lines until next section or EOF
				string_lines = []
				while i < len(lines):
					next_line = lines[i]
					next_stripped = next_line.strip()
					
					# Stop if we hit another bracketed section
					if next_stripped.startswith('[') and next_stripped.endswith(']'):
						break
					
					# Stop ONLY if we hit a known section header
					section_match = re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)(?:\s+(-?\d+))?\s*$', next_stripped)
					if section_match:
						potential_mode = section_match.group(1).upper()
						if potential_mode in MODE_WORDS:
							break
					
					string_lines.append(next_line)
					i += 1
				
				if string_lines:
					string_data = '\n'.join(string_lines).rstrip('\n')
					string_data_bytes = string_data.encode('latin-1')
					
					if len(string_data_bytes) < orig_len + new_len:
						print(f"WARNING: TEXT data too short. Expected {orig_len + new_len} bytes, got {len(string_data_bytes)}")
						string_data_bytes = string_data_bytes.ljust(orig_len + new_len, b' ')
					
					original_bytes = string_data_bytes[:orig_len]
					new_bytes = string_data_bytes[orig_len:orig_len + new_len]
					
					entry = {
						'id': 0,
						'fields': {
							'ORIGINAL_LENGTH': str(orig_len).encode('latin-1'),
							'NEW_LENGTH': str(new_len).encode('latin-1'),
							'ORIGINAL': original_bytes,
							'NEW': new_bytes,
							'_ORIGINAL_LINE': raw.encode('latin-1')
						}
					}
					results.setdefault("TEXT", []).append(entry)
				continue

			# For other modes
			start_id = int(m.group(2))
			end_id = int(m.group(3)) if m.lastindex and m.lastindex >= 3 and m.group(3) is not None else start_id

			mode_key = mode_word.upper() if mode_word.upper() in MODE_WORDS else mode_word
			current_mode = mode_key

			current_entry = {'id': start_id, 'fields': {'_ORIGINAL_LINE': raw.encode('latin-1')}}
			if end_id != start_id:
				for idx in range(start_id, end_id + 1):
					entry = {'id': idx, 'fields': {'_ORIGINAL_LINE': raw.encode('latin-1')}}
					results.setdefault(current_mode, []).append(entry)
				current_entry = None
			continue

		# Handle key=value pairs
		if '=' in raw:
			left, right = raw.split('=', 1)
			key = left.strip().upper()
			val = right.strip()
			
			# If we're currently processing a frame, add to its fields
			if current_frame_id is not None and current_entry is not None:
				current_entry['fields'][key] = val.encode('latin-1')
				continue
			
			# Otherwise handle as global or section data
			if current_entry is None:
				current_mode = "GLOBAL"
				current_entry = {'id': None, 'fields': {}}
			current_entry['fields'][key] = val.encode('latin-1')
			continue

		# Handle miscellaneous lines
		if current_entry is None:
			current_mode = "GLOBAL"
			current_entry = {'id': None, 'fields': {}}
		
		# For frame data without explicit fields, store the raw line
		if current_frame_id is not None and current_entry is not None:
			# If this is a line after a frame definition but without '=', store it as raw
			idx = 1
			while f"LINE{idx}" in current_entry['fields']:
				idx += 1
			current_entry['fields'][f"LINE{idx}"] = raw.encode('latin-1')
		else:
			idx = 1
			while f"LINE{idx}" in current_entry['fields']:
				idx += 1
			current_entry['fields'][f"LINE{idx}"] = raw.encode('latin-1')

	push_entry()
	return results

def parse_dehacked_pars_section(raw_bytes: bytes) -> dict:
	"""
	Parse DEHACKED PARS section specifically.
	Format is: par <gamemap> <partime>
	"""
	text = raw_bytes.decode('latin-1', errors='replace')
	results = {}
	
	for line in text.splitlines():
		line = line.strip()
		if not line or line.startswith('#'):
			continue
			
		parts = line.split()
		if len(parts) == 3 and parts[0].lower() == 'par':
			try:
				gamemap = int(parts[1])
				partime = int(parts[2])
				results[gamemap] = partime
			except ValueError:
				continue
	
	return results

def process_dehacked_escapes(text: str) -> str:
	"""Process DEHACKED escape sequences in strings."""
	result = []
	i = 0
	while i < len(text):
		if text[i] == '\\' and i + 1 < len(text):
			next_char = text[i + 1]
			if next_char == 'n':
				result.append('\n')
				i += 2
			elif next_char == 't':
				result.append('\t')
				i += 2
			elif next_char == '\\':
				result.append('\\')
				i += 2
			elif next_char == '"':
				result.append('"')
				i += 2
			else:
				result.append('\\')
				result.append(next_char)
				i += 2
		else:
			result.append(text[i])
			i += 1
	
	return ''.join(result)

def parse_dehacked_strings_section(raw_bytes: bytes) -> dict:
	"""Parse DEHACKED STRINGS section specifically."""
	text = raw_bytes.decode('latin-1', errors='replace')
	results = {}
	
	combined_lines = []
	current_line = ""
	
	for line in text.splitlines():
		line = line.rstrip()
		if not line or line.startswith('#'):
			if current_line:
				combined_lines.append(current_line)
				current_line = ""
			continue
			
		if line.endswith('\\'):
			current_line += line[:-1].rstrip()
		else:
			current_line += line
			combined_lines.append(current_line)
			current_line = ""
	
	if current_line:
		combined_lines.append(current_line)
	
	for line in combined_lines:
		line = line.strip()
		if not line:
			continue
			
		if '=' in line:
			key, value = line.split('=', 1)
			key = key.strip()
			value = value.strip()
			
			if key and value and not key.startswith('#'):
				value = process_dehacked_escapes(value)
				results[key] = value.encode('latin-1')
	
	return results

def parse_weapon_definitions(raw_bytes: bytes) -> dict:
	"""
	Parse weapon definitions from the end of the file.
	Format: 
	Weapon 5 (Incinerator)
	Deselect frame = 1404
	Select frame = 1403
	...
	"""
	text = raw_bytes.decode('latin-1', errors='replace')
	results = {}
	
	current_weapon = None
	current_weapon_data = {}
	
	for line in text.splitlines():
		line = line.strip()
		if not line:
			continue
			
		# Check for weapon header
		weapon_match = re.match(r'^Weapon\s+(\d+)\s*\(([^)]+)\)$', line, re.IGNORECASE)
		if weapon_match:
			# Save previous weapon
			if current_weapon is not None:
				results[current_weapon] = current_weapon_data
				current_weapon_data = {}
			
			weapon_num = int(weapon_match.group(1))
			weapon_name = weapon_match.group(2).strip()
			current_weapon = weapon_num
			current_weapon_data['name'] = weapon_name
			continue
			
		# Parse weapon properties
		if current_weapon is not None and '=' in line:
			key, value = line.split('=', 1)
			key = key.strip()
			value = value.strip()
			
			# Try to convert to int if it looks like a number
			try:
				if key == 'Ammo per shot':
					# This is an integer
					current_weapon_data[key] = int(value)
				else:
					# Try to convert frame numbers to int
					int_value = int(value)
					current_weapon_data[key] = int_value
			except ValueError:
				# Keep as string if not a number
				current_weapon_data[key] = value
	
	# Save the last weapon
	if current_weapon is not None:
		results[current_weapon] = current_weapon_data
	
	return results