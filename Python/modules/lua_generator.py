"""
Lua generation functions.
"""

import re
from modules.utils import DEH_ID_MAPS, CUTSCENE_GRAPHICS

def lua_literal_from_bytes(b: bytes) -> str:
    """Return a Lua expression that builds the byte string."""
    parts = []
    run = bytearray()
    
    def flush_run():
        nonlocal run
        if not run:
            return
        s = run.decode('latin-1').replace('\\', '\\\\').replace('"', '\\"')
        parts.append(f'"{s}"')
        run = bytearray()
    
    for byte in b:
        if 32 <= byte <= 126 and byte not in (34, 92):
            run.append(byte)
        else:
            flush_run()
            parts.append(f'string.char({byte})')
    
    flush_run()
    if not parts:
        return '""'
    return " .. ".join(parts)

def parse_endoom_and_build_lua(data: bytes) -> bytes:
    """
    ENDOOM is 80x25 pairs (char, attr) = 4000 bytes.
    Build a Lua file that sets doom.endoom.text and doom.endoom.colors.
    """
    if len(data) < 4000:
        data = data + b'\x00' * (4000 - len(data))

    lines_lua = []
    colors_lua = []
    off = 0
    for row in range(25):
        chars = []
        attrs = []
        for col in range(80):
            ch = data[off]
            attr = data[off + 1]
            off += 2
            chars.append(ch)
            attrs.append(attr)
        
        trimmed_len = 80
        while trimmed_len > 0 and chars[trimmed_len - 1] in (0x00, 0x20):
            trimmed_len -= 1
        line_bytes = bytes(chars[:trimmed_len])
        
        lines_lua.append(lua_literal_from_bytes(line_bytes))
        
        rle_segments = []
        current_attr = attrs[0]
        count = 1
        for attr in attrs[1:]:
            if attr == current_attr:
                count += 1
            else:
                rle_segments.append(f"{{{current_attr},{count}}}")
                current_attr = attr
                count = 1
        rle_segments.append(f"{{{current_attr},{count}}}")
        
        colors_lua.append("{" + ",".join(rle_segments) + "}")

    lua_lines = [
        'if not doom then',
        '\terror("This WAD is meant for the DOOM SRB2 port and should NOT be loaded first!")',
        'end',
        '',
        'doom.endoom = doom.endoom or {}',
        'doom.endoom.text = {'
    ]
    for expr in lines_lua:
        lua_lines.append('    ' + expr + ',')
    lua_lines.append('}')
    lua_lines.append('')
    lua_lines.append('doom.endoom.colors = {')
    for cexpr in colors_lua:
        lua_lines.append('    ' + cexpr + ',')
    lua_lines.append('}')
    lua_lines.append('')
    return ("\n".join(lua_lines)).encode("utf-8")

def _maybe_translate_token(token: str, mode: str = None) -> str:
    """If token is an integer and a mapping exists in DEH_ID_MAPS, return the quoted symbolic name."""
    t = token.strip()
    try:
        n = int(t, 10)
    except Exception:
        return t
    if not mode:
        return t
    modemap = DEH_ID_MAPS.get(mode)
    if not modemap:
        return t
    sym = modemap.get(n)
    return sym if sym is not None else t

def _make_safe_lua_long_bracket_for_bytes(b: bytes) -> str:
    """Return a Lua long-bracket literal for the given raw bytes."""
    s = b.decode('latin-1')
    n = 0
    while True:
        close_seq = ']' + ('=' * n) + ']'
        if close_seq not in s:
            open_seq = '[' + ('=' * n) + '['
            return f"{open_seq}{s}{close_seq}"
        n += 1

def build_lua_deh_table(mapping: dict) -> bytes:
    """
    Build a Lua lump that populates doom.dehacked.<KEY> = <value string>
    """
    lines = [
        'if not doom then',
        '\terror("This WAD is meant for the DOOM SRB2 port and should NOT be loaded first!")',
        'end',
        '',
        'doom.dehacked = doom.dehacked or {}',
        ''
    ]
    for key, raw in mapping.items():
        if re.match(r'^[A-Z_][A-Z0-9_]*$', key):
            lhs = f"doom.dehacked.{key}"
        else:
            lhs = f'doom.dehacked["{key}"]'

        bracket_literal = _make_safe_lua_long_bracket_for_bytes(raw)
        lines.append(f'{lhs} = {bracket_literal}')
    lines.append('')
    return ("\n".join(lines)).encode("utf-8")

def build_structured_lua_deh(structured_deh: dict) -> bytes:
    """Build nested Lua tables from the structured_deh dict."""
    lines = [
        'if not doom then',
        '\terror("This WAD is meant for the DOOM SRB2 port and should NOT be loaded first!")',
        'end',
        'doom.dehacked = doom.dehacked or {}',
        ''
    ]

    initialized_tables = set()
    
    for mode, entries in structured_deh.items():
        if mode.upper() == "GLOBAL":
            continue
            
        if mode.upper() == "STRINGS":
            if "strings" not in initialized_tables:
                lines.append('doom.dehacked.strings = doom.dehacked.strings or {}')
                initialized_tables.add("strings")
            for entry in entries:
                fields = entry.get('fields', {})
                if 'RAW' in fields:
                    from modules.dehacked_parser import parse_dehacked_strings_section
                    string_pairs = parse_dehacked_strings_section(fields['RAW'])

                    for key, value in string_pairs.items():
                        safe_value = _make_safe_lua_long_bracket_for_bytes(value)
                        lines.append(f'doom.dehacked.strings["{key}"] = {safe_value}')
                else:
                    for key, value in fields.items():
                        if key != 'id' and not key.startswith('LINE') and key != '_ORIGINAL_LINE':
                            safe_value = _make_safe_lua_long_bracket_for_bytes(value)
                            lines.append(f'doom.dehacked.strings["{key}"] = {safe_value}')
            lines.append('')
            continue
        
        # SPECIAL HANDLING FOR TEXT ENTRIES
        if mode.upper() == "TEXT":
            if "text" not in initialized_tables:
                lines.append('doom.dehacked.text = doom.dehacked.text or {}')
                lines.append('doom.dehacked.text.entries = doom.dehacked.text.entries or {}')
                initialized_tables.add("text")
            
            for entry_idx, entry in enumerate(entries):
                fields = entry.get('fields', {})
                original_len = int(fields.get('ORIGINAL_LENGTH', b'0').decode('latin-1'))
                new_len = int(fields.get('NEW_LENGTH', b'0').decode('latin-1'))
                original_str = fields.get('ORIGINAL', b'')
                new_str = fields.get('NEW', b'')
                
                # Store as a table entry
                lines.append(f'doom.dehacked.text.entries[{entry_idx}] = {{')
                lines.append(f'\toriginal_length = {original_len},')
                lines.append(f'\tnew_length = {new_len},')
                
                # Store the original and new strings properly
                safe_original = _make_safe_lua_long_bracket_for_bytes(original_str)
                safe_new = _make_safe_lua_long_bracket_for_bytes(new_str)
                lines.append(f'\toriginal = {safe_original},')
                lines.append(f'\tnew = {safe_new},')
                lines.append('}')
            lines.append('')
            continue

        mode_mapping = {
            "THING": "things",
            "AMMO": "ammo", 
            "WEAPON": "weapons",
            "SOUND": "sounds",
            "FRAME": "frames",
            "SPRITE": "sprites",
            "POINTER": "pointers",
            "CHEAT": "cheats",
            "MISC": "misc",
            "PARS": "pars",
            "CODEPTR": "codeptrs",
            "MUSIC": "music",
            "SPRITES": "sprites",
            "SOUNDS": "sounds",
            "INCLUDE": "includes"
        }
        
        lua_table = mode_mapping.get(mode.upper(), mode.lower())
        
        if lua_table not in initialized_tables:
            lines.append(f'doom.dehacked.{lua_table} = doom.dehacked.{lua_table} or {{}}')
            initialized_tables.add(lua_table)
            lines.append('')

        for entry in entries:
            idx = entry.get('id')
            if idx is None:
                continue
                
            fields = entry.get('fields', {})
            
            comment_name = ""
            if '_ORIGINAL_LINE' in fields:
                original_line = fields['_ORIGINAL_LINE'].decode('latin-1', errors='replace').strip()
                name_match = re.search(r'\(([^)]+)\)', original_line)
                if name_match:
                    comment_name = f" -- {name_match.group(1)}"
                else:
                    name_parts = original_line.split()
                    if len(name_parts) > 2:
                        comment_name = f" -- {' '.join(name_parts[2:])}"
            
            # SPECIAL HANDLING FOR POINTERS: Key by FRAME number instead of pointer index
            if mode.upper() == "POINTER":
                # Extract frame number from fields (assuming it's stored in a field like 'FRAME' or 'INDEX')
                # We need to look for the frame number in the fields
                frame_idx = None
                for k, v in fields.items():
                    if k.upper() in ['FRAME', 'FRAME NUMBER', 'FRAMENUMBER', 'INDEX']:
                        if isinstance(v, (bytes, bytearray)):
                            try:
                                frame_idx = int(v.decode('latin-1').strip())
                            except (ValueError, AttributeError):
                                frame_idx = idx  # Fall back to original idx if can't parse
                        else:
                            try:
                                frame_idx = int(str(v).strip())
                            except ValueError:
                                frame_idx = idx
                        break
                
                # If no explicit frame field found, assume the id is the frame number
                # (since in DEHACKED, Pointer sections are indexed by frame number)
                if frame_idx is None:
                    frame_idx = idx
                
                lines.append(f'doom.dehacked.{lua_table}[{frame_idx}] = {{{comment_name}')
            else:
                lines.append(f'doom.dehacked.{lua_table}[{idx}] = {{{comment_name}')
            
            for k, v in fields.items():
                if k.startswith('LINE') or k == '_ORIGINAL_LINE' or k in ['ORIGINAL_LENGTH', 'NEW_LENGTH', 'ORIGINAL', 'NEW']:
                    # Skip these for non-TEXT entries
                    continue

                key_lower = k.lower().replace(' ', '')
                if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', key_lower):
                    safe_key = k.lower().replace('"', '\\"')
                    key_lua = f'["{safe_key}"]'
                else:
                    key_lua = key_lower

                # Handle byte content (the common case for DEH strings)
                if isinstance(v, (bytes, bytearray)):
                    raw = bytes(v)  # keep as raw bytes for bracket literal if needed
                    # decode for numeric checks and simple quoted strings
                    vs = raw.decode('latin-1', errors='replace')

                    # try numeric (int or float) without stripping
                    try:
                        if '.' in vs:
                            num_val = float(vs)
                            lines.append(f'\t{key_lua} = {num_val},')
                            continue
                        else:
                            num_val = int(vs)
                            lines.append(f'\t{key_lua} = {num_val},')
                            continue
                    except (ValueError, TypeError):
                        pass

                    # Prefer long-bracket literal when the content contains newlines,
                    # control characters, or quotes/backslashes that would require escaping.
                    needs_bracket = (b'\n' in raw
                                     or any(b < 0x20 and b not in (0x09, 0x0A, 0x0D) for b in raw)
                                     or b'"' in raw
                                     or b'\\' in raw)
                    if needs_bracket:
                        safe_value = _make_safe_lua_long_bracket_for_bytes(raw)
                        lines.append(f'\t{key_lua} = {safe_value},')
                    else:
                        # simple printable ASCII -> keep as quoted string, with escapes
                        escaped_val = vs.replace('\\', '\\\\').replace('"', '\\"')
                        lines.append(f'\t{key_lua} = "{escaped_val}",')

                else:
                    # Non-bytes fallback (should be rare)
                    str_val = str(v).replace('\\', '\\\\').replace('"', '\\"')
                    lines.append(f'\t{key_lua} = "{str_val}",')
            
            lines.append('}')
            lines.append('')
    
    if "GLOBAL" in structured_deh:
        global_entries = structured_deh["GLOBAL"]
        if global_entries:
            lines.append('-- Global DEHACKED settings')
            for entry in global_entries:
                fields = entry.get('fields', {})
                for k, v in fields.items():
                    if k.startswith('LINE'):
                        continue
                        
                    key_lower = k.lower().replace(' ', '')
                    if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', key_lower):
                        safe_key = k.lower().replace('"', '\\"')
                        key_lua = f'["{safe_key}"]'
                    else:
                        key_lua = key_lower
                    
                    if isinstance(v, (bytes, bytearray)):
                        vs = v.decode('latin-1', errors='replace').strip()
                        try:
                            if '.' in vs:
                                num_val = float(vs)
                                lines.append(f'doom.dehacked.{key_lua} = {num_val}')
                            else:
                                num_val = int(vs)
                                lines.append(f'doom.dehacked.{key_lua} = {num_val}')
                        except (ValueError, TypeError):
                            escaped_val = vs.replace('"', '\\"')
                            lines.append(f'doom.dehacked.{key_lua} = "{escaped_val}"')
                    else:
                        str_val = str(v).replace('"', '\\"')
                        lines.append(f'doom.dehacked.{key_lua} = "{str_val}"')
            lines.append('')

    return ("\n".join(lines)).encode("utf-8")

def build_soc_levels() -> bytes:
    """Builds the SOC_LVLS lump content with Doom level configurations."""
    level_data = [
        (1, "E1M1", "E1M1", 2),
        (2, "E1M2", "E1M2", 3),
        (3, "E1M3", "E1M3", 4),
        (4, "E1M4", "E1M4", 5),
        (5, "E1M5", "E1M5", 6),
        (6, "E1M6", "E1M6", 7),
        (7, "E1M7", "E1M7", 8),
        (8, "E1M8", "E1M8", 10),
        (10, "E2M1", "E2M1", 11),
        (11, "E2M2", "E2M2", 12),
        (12, "E2M3", "E2M3", 13),
        (13, "E2M4", "E2M4", 14),
        (14, "E2M5", "E2M5", 15),
        (15, "E2M6", "E2M6", 16),
        (16, "E2M7", "E2M7", 17),
        (17, "E2M8", "E2M8", 19),
        (19, "E3M1", "E3M1", 20),
        (20, "E3M2", "E3M2", 21),
        (21, "E3M3", "E3M3", 22),
        (22, "E3M4", "E3M4", 23),
        (23, "E3M5", "E3M5", 24),
        (24, "E3M6", "E3M6", 25),
        (25, "E3M7", "E3M7", 26),
        (26, "E3M8", "E3M8", 28),
        (28, "E4M1", "E3M4", 29),
        (29, "E4M2", "E3M2", 30),
        (30, "E4M3", "E3M3", 31),
        (31, "E4M4", "E1M5", 32),
        (32, "E4M5", "E2M7", 33),
        (33, "E4M6", "E2M4", 34),
        (34, "E4M7", "E2M6", 35),
        (35, "E4M8", "E2M5", 0),
        (9, "E1M9", "E1M9", 4),
        (18, "E2M9", "E2M9", 15),
        (27, "E3M9", "E3M9", 25),
        (36, "E4M9", "E1M9", 31),
    ]
    
    lines = []
    for level_num, level_name, music, next_level in level_data:
        lines.extend([
            f"Level {level_num}",
            f"levelname = {level_name}",
            "NoTitleCard = true",
            "TypeOfLevel = Singleplayer,Doom",
            "Act = 0",
            "NoZone = 1",
            f"Music = {music}",
            f"SkyNum = {(level_num // 9) + 1}"
        ])
        
        if next_level > 0:
            lines.append(f"NextLevel = {next_level}")
        
        lines.append("")
    
    if lines and lines[-1] == "":
        lines.pop()
    
    return "\n".join(lines).encode("utf-8")

def build_lua_marker(is_doom1: bool) -> bytes:
    """Builds the LUA_DOOM lump content."""
    lines = [
        'if not doom then',
        '\terror("This WAD is meant for the DOOM SRB2 port and should NOT be loaded first!")',
        'end',
        ''
    ]
    if is_doom1:
        lines.append('doom.isdoom1 = true')
    return ("\n".join(lines)).encode("utf-8")

def generate_lua_for_pk3(wad, udmf_namespace="srb2"):
    """Generate Lua content for PK3 with UDMF namespace markers and UMAPINFO data."""
    lua_lines = ["-- Auto-generated Lua map data", "doom = doom or {}"]
    
    udmf_maps = []
    
    for map_name in wad.maps:
        if map_name.startswith('MAP'):
            try:
                map_num = int(map_name[3:])
            except ValueError:
                continue
            
            from modules.wad_processor import detect_udmf_namespace
            namespace = detect_udmf_namespace(wad.maps[map_name])
            if namespace:
                actual_namespace = namespace if namespace else udmf_namespace
                lua_lines.append(f"doom.udmfnamespaces = doom.udmfnamespaces or {{}}")
                lua_lines.append(f"doom.udmfnamespaces[{map_num}] = \"{actual_namespace}\"")
                udmf_maps.append((map_num, actual_namespace))
    
    if hasattr(wad, 'umapinfo_data') and wad.umapinfo_data:
        lua_lines.append("")
        lua_lines.append("-- UMAPINFO data")
        lua_lines.append("doom.umapinfo = doom.umapinfo or {}")
        
        for map_name, umapinfo in wad.umapinfo_data.items():
            lua_table_lines = []
            for key, value in umapinfo.items():
                if key == 'mapname':
                    continue
                    
                if isinstance(value, bool):
                    lua_value = "true" if value else "false"
                elif isinstance(value, int):
                    lua_value = str(value)
                elif isinstance(value, str):
                    escaped_value = value.replace('"', '\\"')
                    lua_value = f'"{escaped_value}"'
                elif isinstance(value, list):
                    list_items = []
                    for item in value:
                        if isinstance(item, str):
                            escaped_item = item.replace('"', '\\"')
                            list_items.append(f'"{escaped_item}"')
                        else:
                            list_items.append(str(item))
                    lua_value = "{" + ", ".join(list_items) + "}"
                elif value is None:
                    continue
                else:
                    lua_value = f'"{str(value)}"'
                
                lua_table_lines.append(f'    {key} = {lua_value}')
            
            if lua_table_lines:
                lua_lines.append(f'doom.umapinfo["{map_name}"] = {{')
                lua_lines.extend(lua_table_lines)
                lua_lines.append("}")
    
    from modules.wad_processor import is_doom1_wad
    if is_doom1_wad(wad):
        lua_lines.append("doom.isdoom1 = true")
    
    return '\n'.join(lua_lines)

def generate_lua_for_wad(wad, udmf_namespace="srb2"):
    """Generate Lua content for WAD with UDMF namespace markers and UMAPINFO data."""
    lua_lines = []
    
    for map_name in wad.maps:
        if map_name.startswith('MAP'):
            try:
                map_num = int(map_name[3:])
            except ValueError:
                continue
            
            from modules.wad_processor import detect_udmf_namespace
            namespace = detect_udmf_namespace(wad.maps[map_name])
            if namespace:
                actual_namespace = namespace if namespace else udmf_namespace
                lua_lines.append(f"doom.udmfnamespaces[{map_num}] = \"{actual_namespace}\"")
    
    if hasattr(wad, 'umapinfo_data') and wad.umapinfo_data:
        if lua_lines:
            lua_lines.append("")
        
        lua_lines.append("-- UMAPINFO data")
        lua_lines.append("doom.umapinfo = doom.umapinfo or {}")
        
        for map_name, umapinfo in wad.umapinfo_data.items():
            lua_table_lines = []
            for key, value in umapinfo.items():
                if key == 'mapname':
                    continue
                    
                if isinstance(value, bool):
                    lua_value = "true" if value else "false"
                elif isinstance(value, int):
                    lua_value = str(value)
                elif isinstance(value, str):
                    escaped_value = value.replace('"', '\\"')
                    lua_value = f'"{escaped_value}"'
                elif isinstance(value, list):
                    list_items = []
                    for item in value:
                        if isinstance(item, str):
                            escaped_item = item.replace('"', '\\"')
                            list_items.append(f'"{escaped_item}"')
                        else:
                            list_items.append(str(item))
                    lua_value = "{" + ", ".join(list_items) + "}"
                elif value is None:
                    continue
                else:
                    lua_value = f'"{str(value)}"'
                
                lua_table_lines.append(f'    {key} = {lua_value}')
            
            if lua_table_lines:
                lua_lines.append(f'doom.umapinfo["{map_name}"] = {{')
                lua_lines.extend(lua_table_lines)
                lua_lines.append("}")
    
    return '\n'.join(lua_lines)