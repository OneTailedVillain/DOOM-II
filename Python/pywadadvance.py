#!/usr/bin/env python3
"""
Python script for preparing WADs for use in the SRB2 DOOM port.

Usage:
    python pywadadvance.py <source_wad_or_pk3> <output_pwad_or_pk3> [deh_file ...]
    python pywadadvance.py <deh_file> [bex_file ...] <output_pwad_or_pk3>

Features:
- Creates FWATER1..FWATER16 from FWATER1..FWATER4
- Converts ExMx -> MAPnn (E1M1..E1M9 -> MAP01..MAP41, etc)
- Renames D_E* music lumps to Doom2 music names
- Adds marker for Doom 1 WADs
- Converts all MUS format lumps to MIDI format
- Writes a PWAD with converted content
- Processes PK3 files with Lua generation and UDMF namespace handling
- Converts flats to cutscene graphics for intermission screens
- Supports external DEHACKED/BEX files
"""

import sys
import os
import re
import struct
import math
import zipfile
import json
import tempfile
import shutil
from pathlib import Path

# Attempt to import OMGIFOL (yes that's its name)
try:
    from omg import WAD, WadIO, Lump, Flat, Graphic
except Exception as e:
    raise SystemExit("Please install omgifol (pip install omgifol). Import error: %s" % e)

DESIRED_COLORMAP_SIZE = 256 * 32  # 8192 bytes (256*32)

def lua_literal_from_bytes(b: bytes) -> str:
    """
    Return a Lua expression that builds the byte string, using quoted runs
    for safe ASCII and ..string.char(0xNN).. for bytes that aren't safe ASCII.
    This preserves exact bytes for >0x7F.
    """
    parts = []
    run = bytearray()
    def flush_run():
        nonlocal run
        if not run:
            return
        # escape backslash and double-quote in run
        s = run.decode('latin-1').replace('\\', '\\\\').replace('"', '\\"')
        parts.append(f'"{s}"')
        run = bytearray()
    for byte in b:
        if 32 <= byte <= 126 and byte not in (34, 92):  # printable ASCII except " and \
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
    Build a Lua file that sets doom.endoom.text (25 strings) and doom.endoom.colors (25 tables of RLE segments)
    Text lines are trimmed of trailing spaces or nulls, but colors preserve all 80 attributes.
    Nonprintable and >127 bytes encoded with string.char(...) pieces.
    Returns bytes suitable for Lump(...).
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
        
        # Only trim text content, keep all 80 color attributes
        trimmed_len = 80
        while trimmed_len > 0 and chars[trimmed_len - 1] in (0x00, 0x20):
            trimmed_len -= 1
        line_bytes = bytes(chars[:trimmed_len])
        
        lines_lua.append(lua_literal_from_bytes(line_bytes))
        
        # Build RLE segments for all 80 attributes (no truncation)
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

def parse_key_value_pairs_from_text(blob: bytes) -> dict:
    """
    Parse classic LANGUAGE / DEHACKED style text and return KEY->value (bytes).
    - Handles BEX STARTUP boxes of form KEY====...==== (keeps previous behavior).
    - Parses classic KEY = "value"; style where ; terminates the statement.
    - Treats ; inside "quotes", 'single-quotes', or [[bracket-strings]] as part of the string.
    - Concatenated quoted fragments are joined (e.g. "a" "b" -> "ab").
    - Unquoted RHS tokens (like $$OTHER_ID or $MY_REF) are preserved literally.
    Returned values are bytes encoded latin-1 (so original byte-by-byte content is kept).
    """
    txt = blob.decode('latin-1', errors='replace')
    results = {}

    # Keep the old BEX box-style capture (STARTUP1..5 etc)
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
        # find next '=' that's outside any string/bracket/comment
        in_quote = False
        quote_ch = None
        in_bracket = False
        bracket_level = 0
        j = i
        eqpos = -1
        while j < n:
            ch = txt[j]
            # handle C-style block comments and line comments (best-effort)
            if not in_quote and not in_bracket and txt.startswith('//', j):
                # skip to end of line
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
                # handle escapes inside quoted strings
                if ch == '\\' and j+1 < n:
                    j += 2
                    continue
                if ch == quote_ch:
                    in_quote = False
                    quote_ch = None
                j += 1
                continue

            # at top-level and not in a string/bracket -> check for '='
            if ch == '=':
                eqpos = j
                break
            j += 1

        if eqpos == -1:
            # no more assignments found
            break

        # Determine left-hand side: take text from line start up to '='
        line_start = txt.rfind('\n', 0, eqpos) + 1
        left = txt[line_start:eqpos].strip()
        # skip empty lefts
        if not left:
            i = eqpos + 1
            continue

        # The left may be prefixed with $ifgame(...) or similar; we want the identifier token
        # We'll extract the last uppercase-like token from left as the key.
        mkey = re.search(r'([A-Z][A-Z0-9_]*)\s*$', left.upper())
        if not mkey:
            # fallback: use full left stripped upcased (safe)
            key = left.strip().upper()
        else:
            key = mkey.group(1).strip().upper()

        # Parse right-hand side until an unquoted semicolon (;) terminator.
        segs = []  # list of tuples ('raw'|'quote'|'bracket', content)
        k = eqpos + 1
        while k < n:
            # skip whitespace
            if txt[k].isspace():
                k += 1
                continue

            # line or block comment handling outside strings/brackets
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
                # bracket string
                k2 = txt.find(']]', k+2)
                if k2 == -1:
                    # unterminated bracket -> take rest
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
                        # keep escapes exactly as written: store backslash and next char
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
                # after closing quote, skip optional whitespace and allow another quoted fragment
                continue

            # If we hit a semicolon at top-level -> terminate statement
            if ch == ';':
                k += 1
                break

            # Otherwise, gather an unquoted raw token until whitespace or ; or comment
            start_r = k
            while k < n and not txt[k].isspace() and txt[k] not in ';':
                # stop if comment start encountered
                if txt.startswith('//', k) or txt.startswith('/*', k) or txt.startswith('[[', k):
                    break
                k += 1
            rawtok = txt[start_r:k]
            if rawtok:
                segs.append(('raw', rawtok))
            # loop continues until semicolon or break

        # Assemble value bytes: join quoted/bracket inner contents, and raw tokens as-is
        parts = []
        for typ, content in segs:
            if typ in ('quote', 'bracket'):
                # keep the content exactly as-present (backslashes preserved above)
                parts.append(content.encode('latin-1'))
            else:  # raw
                # raw tokens (like $$ID or $ID) should be preserved literally
                ct = content.strip()
                if ct:
                    parts.append(ct.encode('latin-1'))
        if parts:
            valbytes = b"".join(parts)
        else:
            valbytes = b""
        results[key] = valbytes

        # continue scanning after the semicolon we consumed (k)
        i = k

    return results

# Useful ML_ flag constants
ML_IMPASSIBLE      = 0x0001
ML_BLOCKMONSTERS   = 0x0002
ML_TWOSIDED        = 0x0004
ML_DONTPEGTOP      = 0x0008   # Upper Unpegged
ML_DONTPEGBOTTOM   = 0x0010   # Lower Unpegged
ML_EFFECT1         = 0x0020
ML_NOCLIMB         = 0x0040
ML_EFFECT3         = 0x0100   # Peg Midtexture
ML_EFFECT4         = 0x0200
ML_EFFECT5         = 0x0400

CUTSCENE_GRAPHICS = [
    ('FLOOR7_2', 'BRDR_C'),
    ('FLOOR4_8', 'EP1CUTSC'), 
    ('SFLR6_1', 'EP2CUTSC'),
    ('MFLR8_4', 'EP3CUTSC'),
    ('MFLR8_3', 'EP4CUTSC'),
    ('SLIME16', 'M06CUTSC'),
    ('RROCK14', 'M11CUTSC'),
    ('RROCK07', 'M20CUTSC'),
    ('RROCK17', 'M30CUTSC'),
    ('RROCK13', 'M15CUTSC'),
    ('RROCK19', 'M31CUTSC'),
    ('BOSSBACK', 'ENDCUTSC')
]

DEH_ID_MAPS = globals().get("DEH_ID_MAPS", {})

def parse_dehacked_structured(blob: bytes) -> dict:
    """
    More robust parser for classic .deh and .bex:
    - Recognizes BEX-style [SECTION] headers and collects lines until the next header.
    - Recognizes classic DeHackEd 'Mode <number>' lines (e.g. 'Thing 1', 'Weapon 3')
      and collects key/value pairs until the next mode line or blank line.
    Returns dict: { mode_name: [ { 'id': int|None, 'fields': { key: bytes } }, ... ], ... }
    Values are stored as bytes (latin-1) to preserve raw content.
    """
    txt = blob.decode('latin-1', errors='replace')
    lines = txt.splitlines()

    # Known classic mode names (case-insensitive). If other names appear we still accept them.
    MODE_WORDS = set(["THING","SOUND","FRAME","SPRITE","AMMO","WEAPON","POINTER","CHEAT","MISC","TEXT",
                      "STRINGS","PARS","CODEPTR","MUSIC","SPRITES","SOUNDS","INCLUDE"])

    results = {}
    current_mode = None
    current_entry = None  # dict with 'id' and 'fields'
    def push_entry():
        nonlocal current_mode, current_entry, results
        if not current_mode or current_entry is None:
            return
        results.setdefault(current_mode, []).append(current_entry)
        current_entry = None

    i = 0
    while i < len(lines):
        raw = lines[i]
        s = raw.strip()
        i += 1
        if s == "":
            # blank line separates entries in classic style
            push_entry()
            continue

        # BEX/INI-style section header
        if s.startswith('[') and s.endswith(']'):
            push_entry()
            current_mode = s[1:-1].strip()
            # start a single anonymous entry for whole bracket section; accumulate as 'raw' lines
            current_entry = {'id': None, 'fields': {}}
            # collect subsequent non-section lines into a single field "RAW" (preserve newlines)
            accum = []
            while i < len(lines):
                if lines[i].strip().startswith('[') and lines[i].strip().endswith(']'):
                    break
                accum.append(lines[i])
                i += 1
            current_entry['fields']['RAW'] = ("\n".join(accum)).encode('latin-1')
            push_entry()
            continue

        # Classic "Mode <number>" header (e.g. "Thing 1", "Frame 47") or "Mode <number> ..." (case-insensitive)
        m = re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)\s*$', s)
        if m:
            push_entry()
            mode_word = m.group(1).strip()
            mode_key = mode_word.upper() if mode_word.upper() in MODE_WORDS else mode_word
            current_mode = mode_key
            current_entry = {'id': int(m.group(2)), 'fields': {}}
            # After header, consume following lines until blank or next header
            while i < len(lines):
                nxt = lines[i].strip()
                # break if next is a new Mode header or a bracket header or empty
                if nxt == "":
                    i += 1
                    break
                if nxt.startswith('[') and nxt.endswith(']'):
                    break
                if re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)\s*$', nxt):
                    break
                # parse "Key = Value" or "Key Value" (classic DeHackEd uses "Key Value" often)
                line = lines[i]
                i += 1
                # skip comments beginning with '#'
                if line.lstrip().startswith('#'):
                    continue
                if '=' in line:
                    left, right = line.split('=', 1)
                    key = left.strip()
                    val = right.strip()
                else:
                    # split into first word and rest
                    sp = line.split(None, 1)
                    if len(sp) == 1:
                        key = sp[0].strip()
                        val = ""
                    else:
                        key, val = sp[0].strip(), sp[1].strip()
                current_entry['fields'][key] = val.encode('latin-1')
            push_entry()
            continue

        # Other lines: could be global "KEY = VALUE" lines (legacy LANGUAGE / BEX "KEY====...====" handled elsewhere)
        # Try to parse as KEY = "value" or KEY = value or "Key value"
        if '=' in raw:
            left, right = raw.split('=', 1)
            key = left.strip().upper()
            val = right.strip()
            # treat as a top-level anonymous mode (LANGUAGE/flat)
            # Use mode "GLOBAL" for collected key=values (so build will place them into doom.dehacked.GLOBAL)
            if current_entry is None:
                current_mode = "GLOBAL"
                current_entry = {'id': None, 'fields': {}}
            current_entry['fields'][key] = val.encode('latin-1')
            continue

        # As a last fallback: treat any other non-empty line as a single-line entry under GLOBAL
        if current_entry is None:
            current_mode = "GLOBAL"
            current_entry = {'id': None, 'fields': {}}
        # store raw line as numbered "LINE<n>"
        idx = 1
        while f"LINE{idx}" in current_entry['fields']:
            idx += 1
        current_entry['fields'][f"LINE{idx}"] = raw.encode('latin-1')

    # finalize
    push_entry()
    return results

def parse_dehacked_structured(blob: bytes) -> dict:
    """
    More robust parser for classic .deh and .bex:
    - Recognizes BEX-style [SECTION] headers and collects lines until the next header.
    - Recognizes classic DeHackEd 'Mode <number>' lines (e.g. 'Thing 1', 'Weapon 3')
      and collects key/value pairs until the next mode line or blank line.
    Returns dict: { mode_name: [ { 'id': int|None, 'fields': { key: bytes } }, ... ], ... }
    Values are stored as bytes (latin-1) to preserve raw content.
    """
    txt = blob.decode('latin-1', errors='replace')
    lines = txt.splitlines()

    # Known classic mode names (case-insensitive). If other names appear we still accept them.
    MODE_WORDS = set(["THING","SOUND","FRAME","SPRITE","AMMO","WEAPON","POINTER","CHEAT","MISC","TEXT",
                      "STRINGS","PARS","CODEPTR","MUSIC","SPRITES","SOUNDS","INCLUDE"])

    results = {}
    current_mode = None
    current_entry = None  # dict with 'id' and 'fields'
    
    def push_entry():
        nonlocal current_mode, current_entry, results
        if not current_mode or current_entry is None:
            return
        results.setdefault(current_mode, []).append(current_entry)
        current_entry = None

    i = 0
    while i < len(lines):
        raw = lines[i]
        s = raw.strip()
        i += 1
        
        # Skip empty lines and comments
        if s == "" or s.startswith('#'):
            continue

        # BEX/INI-style section header
        if s.startswith('[') and s.endswith(']'):
            push_entry()
            current_mode = s[1:-1].strip()
            # start a single anonymous entry for whole bracket section; accumulate as 'raw' lines
            current_entry = {'id': None, 'fields': {}}
            # collect subsequent non-section lines into a single field "RAW" (preserve newlines)
            accum = []
            while i < len(lines):
                if lines[i].strip().startswith('[') and lines[i].strip().endswith(']'):
                    break
                accum.append(lines[i])
                i += 1
            current_entry['fields']['RAW'] = ("\n".join(accum)).encode('latin-1')
            push_entry()
            continue

        # Classic "Mode <number>" header (e.g. "Thing 1", "Frame 47") or "Mode <number> ..." (case-insensitive)
        # More flexible regex to handle names in parentheses and other text after the number
        m = re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)(?:\s*\([^)]*\))?\s*$', s)
        if not m:
            # Try alternative pattern that allows any text after the number
            m = re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)\s*', s)
            
        if m:
            push_entry()
            mode_word = m.group(1).strip()
            mode_key = mode_word.upper() if mode_word.upper() in MODE_WORDS else mode_word
            current_mode = mode_key
            current_entry = {'id': int(m.group(2)), 'fields': {}}
            # Store the original line for comment extraction
            current_entry['fields']['_ORIGINAL_LINE'] = raw.encode('latin-1')
            
            # After header, consume following lines until blank or next header
            while i < len(lines):
                nxt_line = lines[i]
                nxt = nxt_line.strip()
                
                # break if next is empty, comment, or a new header
                if nxt == "":
                    i += 1
                    break
                if nxt.startswith('#'):
                    i += 1
                    continue
                if nxt.startswith('[') and nxt.endswith(']'):
                    break
                if re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)(?:\s*\([^)]*\))?\s*$', nxt):
                    break
                if re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)\s*', nxt):
                    break
                    
                # parse "Key = Value" or "Key Value" (classic DeHackEd uses "Key Value" often)
                line = lines[i]
                i += 1
                
                # skip comments beginning with '#'
                if line.lstrip().startswith('#'):
                    continue
                    
                # Handle both "Key = Value" and "Key Value" formats
                if '=' in line:
                    left, right = line.split('=', 1)
                    key = left.strip()
                    val = right.strip()
                else:
                    # split into first word and rest
                    sp = line.split(None, 1)
                    if len(sp) == 1:
                        key = sp[0].strip()
                        val = ""
                    else:
                        key, val = sp[0].strip(), sp[1].strip()
                        
                if key and val:  # Only add if we have both key and value
                    current_entry['fields'][key] = val.encode('latin-1')
            push_entry()
            continue

        # Other lines: could be global "KEY = VALUE" lines (legacy LANGUAGE / BEX "KEY====...====" handled elsewhere)
        # Try to parse as KEY = "value" or KEY = value or "Key value"
        if '=' in raw:
            left, right = raw.split('=', 1)
            key = left.strip().upper()
            val = right.strip()
            # treat as a top-level anonymous mode (LANGUAGE/flat)
            # Use mode "GLOBAL" for collected key=values (so build will place them into doom.dehacked.GLOBAL)
            if current_entry is None:
                current_mode = "GLOBAL"
                current_entry = {'id': None, 'fields': {}}
            current_entry['fields'][key] = val.encode('latin-1')
            continue

        # As a last fallback: treat any other non-empty line as a single-line entry under GLOBAL
        if current_entry is None:
            current_mode = "GLOBAL"
            current_entry = {'id': None, 'fields': {}}
        # store raw line as numbered "LINE<n>"
        idx = 1
        while f"LINE{idx}" in current_entry['fields']:
            idx += 1
        current_entry['fields'][f"LINE{idx}"] = raw.encode('latin-1')

    # finalize
    push_entry()
    return results

def build_structured_lua_deh(structured_deh: dict) -> bytes:
    """
    Build nested Lua tables from the structured_deh dict produced by parse_dehacked_structured().
    Special handling for STRINGS section to parse individual string replacements.
    Output format matches the desired style with comments and clean formatting.
    """
    lines = [
        'if not doom then',
        '\terror("This WAD is meant for the DOOM SRB2 port and should NOT be loaded first!")',
        'end',
        'doom.dehacked = $ or {}',
        ''
    ]

    # Initialize tables for different types
    initialized_tables = set()
    
    for mode, entries in structured_deh.items():
        # Skip GLOBAL mode for now - we'll handle it separately
        if mode.upper() == "GLOBAL":
            continue
            
        # Special handling for STRINGS section - parse into individual key-value pairs
        if mode.upper() == "STRINGS":
            if "strings" not in initialized_tables:
                lines.append('doom.dehacked.strings = doom.dehacked.strings or {}')
                initialized_tables.add("strings")
            for entry in entries:
                fields = entry.get('fields', {})
                # For STRINGS, the RAW field contains all the string definitions
                if 'RAW' in fields:
                    # Use specialized DEHACKED strings parser
                    string_pairs = parse_dehacked_strings_section(fields['RAW'])

                    for key, value in string_pairs.items():
                        safe_value = _make_safe_lua_long_bracket_for_bytes(value)
                        lines.append(f'doom.dehacked.strings["{key}"] = {safe_value}')
                else:
                    # If no RAW field, try to use individual fields as string definitions
                    for key, value in fields.items():
                        if key != 'id' and not key.startswith('LINE') and key != '_ORIGINAL_LINE':
                            safe_value = _make_safe_lua_long_bracket_for_bytes(value)
                            lines.append(f'doom.dehacked.strings["{key}"] = {safe_value}')
            lines.append('')
            continue

        # Map mode names to Lua table names and handle plurals
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
        
        # Initialize the table if we haven't yet
        if lua_table not in initialized_tables:
            lines.append(f'doom.dehacked.{lua_table} = doom.dehacked.{lua_table} or {{}}')
            initialized_tables.add(lua_table)
            lines.append('')

        # Process entries for this mode
        for entry in entries:
            idx = entry.get('id')
            if idx is None:
                # Skip entries without IDs
                continue
                
            fields = entry.get('fields', {})
            
            # Extract comment name if available
            comment_name = ""
            if '_ORIGINAL_LINE' in fields:
                original_line = fields['_ORIGINAL_LINE'].decode('latin-1', errors='replace').strip()
                # Look for pattern like "(Archvile)" or similar naming
                name_match = re.search(r'\(([^)]+)\)', original_line)
                if name_match:
                    comment_name = f" -- {name_match.group(1)}"
                else:
                    # Try to extract name from the line if it doesn't have parentheses
                    name_parts = original_line.split()
                    if len(name_parts) > 2:
                        # Assume the rest of the line after mode and number is the name
                        comment_name = f" -- {' '.join(name_parts[2:])}"
            
            # Start the table entry
            lines.append(f'doom.dehacked.{lua_table}[{idx}] = {{{comment_name}')
            
            # Process each field
            for k, v in fields.items():
                # Skip special fields and LINE fields as they're used for comments
                if k.startswith('LINE') or k == '_ORIGINAL_LINE':
                    continue
                    
                # Convert key to lowercase and handle spaces by using bracket notation
                key_lower = k.lower().replace(' ', '')  # Remove spaces for valid Lua identifiers
                
                # If the key still has invalid characters, use bracket notation
                if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', key_lower):
                    # Use the original key with spaces in bracket notation
                    safe_key = k.lower().replace('"', '\\"')
                    key_lua = f'["{safe_key}"]'
                else:
                    key_lua = key_lower
                
                # Handle the value
                if isinstance(v, (bytes, bytearray)):
                    vs = v.decode('latin-1', errors='replace').strip()
                    
                    # Try to convert to number if possible
                    try:
                        if '.' in vs:
                            # Float value
                            num_val = float(vs)
                            lines.append(f'\t{key_lua} = {num_val},')
                        else:
                            # Integer value
                            num_val = int(vs)
                            lines.append(f'\t{key_lua} = {num_val},')
                    except (ValueError, TypeError):
                        # String value - use quotes
                        escaped_val = vs.replace('"', '\\"')
                        lines.append(f'\t{key_lua} = "{escaped_val}",')
                else:
                    # Non-bytes value, convert to string
                    str_val = str(v).replace('"', '\\"')
                    lines.append(f'\t{key_lua} = "{str_val}",')
            
            # Close the table entry
            lines.append('}')
            lines.append('')
    
    # Handle GLOBAL entries separately (header info, etc.)
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

def _maybe_translate_token(token: str, mode: str = None) -> str:
    """
    If token is an integer and a mapping exists in DEH_ID_MAPS for this mode,
    return the quoted symbolic name. Otherwise return the original token (string).
    This function returns a Python string value (not Lua syntax).
    """
    t = token.strip()
    # try decimal integer
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
    """
    Return a Lua long-bracket literal for the given raw bytes.
    We decode bytes as latin-1 to preserve 1:1 mapping of bytes -> codepoints,
    then choose a level of '=' signs that doesn't appear in the content.
    (Maybe should consider using string.char in certain scenarios?)
    """
    s = b.decode('latin-1')
    # Find minimal '=' repetition such that closing sequence is not present
    n = 0
    while True:
        close_seq = ']' + ('=' * n) + ']'
        if close_seq not in s:
            open_seq = '[' + ('=' * n) + '['
            return f"{open_seq}{s}{close_seq}"
        n += 1
        # in pathological cases this grows, but practically n will be small

def build_lua_deh_table(mapping: dict) -> bytes:
    """
    Build a Lua lump that populates doom.dehacked.<KEY> = <value string>
    For LANGUAGE-style textual values we emit Lua long-bracket strings (e.g. [=[ ... ]=])
    so we don't need to escape quotes/backslashes, and so embedded \n stays literal text.
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
        # create LHS as earlier
        if re.match(r'^[A-Z_][A-Z0-9_]*$', key):
            lhs = f"doom.dehacked.{key}"
        else:
            lhs = f'doom.dehacked["{key}"]'

        # prefer long-bracket literal for readability / minimal escaping
        bracket_literal = _make_safe_lua_long_bracket_for_bytes(raw)
        # The bracket literal is formed from latin-1-decoded content; produce a line
        lines.append(f'{lhs} = {bracket_literal}')
    lines.append('')
    # encode as UTF-8 for the Lua file; content was built via latin-1 decoding so bytes are
    # preserved in a deterministic way if the original wasn't valid UTF-8.
    return ("\n".join(lines)).encode("utf-8")

def patch_linedefs_add(wad_obj, add_value=941):
    """
    Add `add_value` to every linedef.action for classic Doom-linedef maps
    (14-byte LINEDEFS entries). For ZLinedef / Hexen-style (16-byte) linedefs
    this function will skip modification and log a message.
    """
    from omg import Lump  # already available in the file, but safe to reference here

    for mapname, mapgroup in list(wad_obj.maps.items()):
        try:
            # Some NameGroup implementations expose lumps via mapping access
            if "LINEDEFS" not in mapgroup:
                continue

            ld_lump = mapgroup["LINEDEFS"]
            ld_data = bytearray(ld_lump.data)
            length = len(ld_data)

            # Classic doom linedef size = 14 bytes
            if length % 14 == 0:
                count = length // 14
                for i in range(count):
                    action_off = i * 14 + 6  # action at offset 6..7 (uint16 little-endian)
                    old_action = int.from_bytes(ld_data[action_off:action_off+2], "little")
                    new_action = (old_action + add_value) & 0xFFFF
                    ld_data[action_off:action_off+2] = new_action.to_bytes(2, "little")
                mapgroup["LINEDEFS"] = Lump(bytes(ld_data))
                print(f"Patched {count} linedefs in {mapname}: action += {add_value}")

            # ZLinedef (Hexen/ZDoom) size = 16 bytes; action is a single byte -> skipping
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
    modified_total = 0

    for mapname, mapgroup in list(wad_obj.maps.items()):
        try:
            if "LINEDEFS" not in mapgroup or "SIDEDEFS" not in mapgroup or "SECTORS" not in mapgroup:
                continue

            ld_data = bytearray(mapgroup["LINEDEFS"].data)
            sd_data = mapgroup["SIDEDEFS"].data
            sec_data = mapgroup["SECTORS"].data

            # Only operate on classic formats
            if len(ld_data) % 14 != 0 or len(sd_data) % 30 != 0 or len(sec_data) % 26 != 0:
                continue

            sidedef_count = len(sd_data) // 30
            sector_count = len(sec_data) // 26
            linedef_count = len(ld_data) // 14

            changed = False
            changed_count_in_map = 0

            for li in range(linedef_count):
                base = li * 14
                v1_off = base + 0
                v2_off = base + 2
                flags_off = base + 4
                action_off = base + 6
                sector_tag_off = base + 8
                right_off = base + 10
                left_off = base + 12

                flags = int.from_bytes(ld_data[flags_off:flags_off+2], "little")
                right = int.from_bytes(ld_data[right_off:right_off+2], "little")
                left  = int.from_bytes(ld_data[left_off:left_off+2], "little")

                # In classic maps, invalid sidedef index may be 0xFFFF or out-of-range; treat as None
                def valid_sid(idx):
                    return 0 <= idx < sidedef_count

                right_idx = right if valid_sid(right) else None
                left_idx = left  if valid_sid(left)  else None

                # Determine one-sided vs two-sided:
                two_sided = ((flags & ML_TWOSIDED) != 0) or (right_idx is not None and left_idx is not None)

                # KEY CHANGE: Only apply ML_EFFECT3 XOR when Lower Unpegged is set on two-sided linedefs
                # This ensures middle textures follow the same pegging behavior as in DOOM
                new_flags = flags
                
                if two_sided and (flags & ML_DONTPEGBOTTOM):
                    # For two-sided linedefs with Lower Unpegged set in DOOM maps,
                    # we need to XOR ML_EFFECT3 to make middle textures behave correctly in SRB2
                    new_flags = new_flags ^ ML_EFFECT3

                # Finally, write back if changed
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

def to_varlen(value):
    """Convert an integer to a variable-length quantity (MIDI format)."""
    if value == 0:
        return bytes([0])
    chunks = []
    while value:
        chunks.append(value & 0x7F)
        value >>= 7
    chunks.reverse()
    result = bytearray()
    for i in range(len(chunks)):
        if i < len(chunks) - 1:
            result.append(chunks[i] | 0x80)
        else:
            result.append(chunks[i])
    return bytes(result)

def read_varlen(data, offset):
    """Read a variable-length quantity from the data starting at offset."""
    value = 0
    while offset < len(data):
        b = data[offset]
        offset += 1
        value = (value << 7) | (b & 0x7F)
        if not (b & 0x80):
            break
    return value, offset

def mus_to_midi(mus_data):
    """Convert MUS file data to MIDI file data."""
    # To be honest, I can't be sure if some WAD down the street could manage to make a .mus lump with nonlinear event timings for some fuckin' reason, so
    # Try to play it safe here, I guess? Would love for someone to prove me wrong so I don't need to do that

    # Check MUS signature
    if len(mus_data) < 16 or mus_data[0:4] != b'MUS\x1a':
        raise ValueError("Invalid MUS file: signature mismatch")
    
    # Parse MUS header
    len_song = struct.unpack('<H', mus_data[4:6])[0]
    off_song = struct.unpack('<H', mus_data[6:8])[0]
    primary_channels = struct.unpack('<H', mus_data[8:10])[0]
    secondary_channels = struct.unpack('<H', mus_data[10:12])[0]
    num_instruments = struct.unpack('<H', mus_data[12:14])[0]
    reserved = struct.unpack('<H', mus_data[14:16])[0]
    
    # Read instrument list (each is UINT16LE)
    instruments = []
    pos = 16
    for _ in range(num_instruments):
        instruments.append(struct.unpack('<H', mus_data[pos:pos+2])[0])
        pos += 2
    
    # Extract song data
    song_data = mus_data[off_song:off_song+len_song]
    
    # Prepare MIDI events list: (absolute_time, [event_bytes])
    events = []
    
    # Add tempo event (meta event): 1000000 microseconds per quarter note (60 BPM)
    events.append((0, [0xFF, 0x51, 0x03, 0x0F, 0x42, 0x40]))
    
    # Set pitch bend range to 2 semitones for all non-percussion channels
    for c in range(primary_channels):
        midi_channel = c
        events.append((0, [0xB0 | midi_channel, 101, 0]))
        events.append((0, [0xB0 | midi_channel, 100, 0]))
        events.append((0, [0xB0 | midi_channel, 6, 2]))
        events.append((0, [0xB0 | midi_channel, 38, 0]))
    
    for c in range(10, 10 + secondary_channels):
        midi_channel = c
        events.append((0, [0xB0 | midi_channel, 101, 0]))
        events.append((0, [0xB0 | midi_channel, 100, 0]))
        events.append((0, [0xB0 | midi_channel, 6, 2]))
        events.append((0, [0xB0 | midi_channel, 38, 0]))
    
    # Initialize per-channel last note volume (for event type 1 without volume byte)
    last_note_volume = [100] * 16  # For 16 possible MUS channels
    
    # Process song data events
    current_time = 0  # Current time in ticks
    index = 0         # Current position in song_data
    size = len(song_data)
    break_loop = False
    
    while index < size and not break_loop:
        # Read event byte
        event_byte = song_data[index]
        index += 1
        
        last_flag = event_byte & 0x80
        event_type = (event_byte >> 4) & 0x07
        channel = event_byte & 0x0F  # MUS channel (0-15)
        
        # Map MUS channel to MIDI channel
        if channel == 15:
            midi_channel = 9  # Percussion (MIDI channel 10)
        elif channel < primary_channels:
            midi_channel = channel
        elif 10 <= channel < 10 + secondary_channels:
            midi_channel = channel
        else:
            midi_channel = 9  # Default to percussion for invalid channels
        
        # Handle event types
        if event_type == 0:  # Release note
            note_byte = song_data[index]
            index += 1
            note = note_byte & 0x7F
            events.append((current_time, [0x80 | midi_channel, note, 64]))
        
        elif event_type == 1:  # Play note
            note_byte = song_data[index]
            index += 1
            vol_flag = note_byte & 0x80
            note = note_byte & 0x7F
            if vol_flag:
                vol_byte = song_data[index]
                index += 1
                velocity = vol_byte & 0x7F
                last_note_volume[channel] = velocity
            else:
                velocity = last_note_volume[channel]
            events.append((current_time, [0x90 | midi_channel, note, velocity]))
        
        elif event_type == 2:  # Pitch bend
            bend_byte = song_data[index]
            index += 1
            bend_value = (bend_byte * 16383) // 255  # Convert to 14-bit MIDI value
            lsb = bend_value & 0x7F
            msb = (bend_value >> 7) & 0x7F
            events.append((current_time, [0xE0 | midi_channel, lsb, msb]))
        
        elif event_type == 3:  # System event
            sys_byte = song_data[index]
            index += 1
            controller = sys_byte & 0x7F
            # Map to MIDI controller numbers
            if controller == 10: cc = 120
            elif controller == 11: cc = 123
            elif controller == 12: cc = 126
            elif controller == 13: cc = 127
            elif controller == 14: cc = 121
            else: continue  # Skip unimplemented (15) and invalid
            events.append((current_time, [0xB0 | midi_channel, cc, 0]))
        
        elif event_type == 4:  # Controller
            ctrl_byte = song_data[index]
            index += 1
            ctrl_num = ctrl_byte & 0x7F
            val_byte = song_data[index]
            index += 1
            value = val_byte & 0x7F
            if ctrl_num == 0:  # Program change
                if midi_channel != 9:  # Skip percussion
                    events.append((current_time, [0xC0 | midi_channel, value]))
            else:
                events.append((current_time, [0xB0 | midi_channel, ctrl_num, value]))
        
        elif event_type == 5:  # End of measure (ignored)
            pass
        
        elif event_type == 6:  # Finish (end of song)
            break_loop = True
        
        elif event_type == 7:  # Unused event (skip one byte)
            if index < size:
                index += 1
        
        # Process delay if last_flag is set
        if last_flag and index < size:
            delay, index = read_varlen(song_data, index)
            current_time += delay
    
    # Add end of track meta event
    events.append((current_time, [0xFF, 0x2F, 0x00]))
    
    # Sort events by absolute time (though they should be in order)
    events.sort(key=lambda x: x[0])
    
    # Build MIDI track data
    track_data = bytearray()
    prev_time = 0
    for time, event_bytes in events:
        delta = time - prev_time
        track_data.extend(to_varlen(delta))
        track_data.extend(event_bytes)
        prev_time = time
    
    # Create MIDI header (format 0, 1 track, 140 ticks per quarter note)
    header = (
        b'MThd' +                   # Chunk type
        (6).to_bytes(4, 'big') +    # Chunk length
        (0).to_bytes(2, 'big') +    # Format 0
        (1).to_bytes(2, 'big') +    # One track
        (140).to_bytes(2, 'big')    # Ticks per quarter note
    )
    
    # Create track chunk
    track_chunk = (
        b'MTrk' +                   # Chunk type
        len(track_data).to_bytes(4, 'big') +
        track_data
    )
    
    return header + track_chunk

def convert_mus_to_midi(data):
    """Convert MUS data to MIDI format with error handling."""
    try:
        if len(data) >= 4 and data[0:4] == b'MUS\x1a':
            return mus_to_midi(data)
    except Exception as e:
        print(f"[!] MUS conversion error: {e}")
    return data

def safe_add_lump_to_data(dst_wad, name, lump_obj):
    name = name.upper()
    data = dst_wad.data
    if name not in data:
        data[name] = lump_obj  # don't copy
        return name
    i = 1
    while True:
        new_name = f"{name}_{i}"
        if new_name not in data:
            data[new_name] = lump_obj.copy()
            return new_name
        i += 1

def make_fw_sequence(src_wad, out_wad):
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

def build_soc_levels() -> bytes:
    """Builds the SOC_LVLS lump content with Doom level configurations."""
    
    level_data = [
        (1, "E1M1", "E1M1"),
        (2, "E1M2", "E1M2"),
        (3, "E1M3", "E1M3"),
        (4, "E1M4", "E1M4"),
        (5, "E1M5", "E1M5"),
        (6, "E1M6", "E1M6"),
        (7, "E1M7", "E1M7"),
        (8, "E1M8", "E1M8"),
        (9, "E2M1", "E2M1"),
        (10, "E2M2", "E2M2"),
        (11, "E2M3", "E2M3"),
        (12, "E2M4", "E2M4"),
        (13, "E2M5", "E2M5"),
        (14, "E2M6", "E2M6"),
        (15, "E2M7", "E2M7"),
        (16, "E2M8", "E2M8"),
        (17, "E3M1", "E3M1"),
        (18, "E3M2", "E3M2"),
        (19, "E3M3", "E3M3"),
        (20, "E3M4", "E3M4"),
        (21, "E3M5", "E3M5"),
        (22, "E3M6", "E3M6"),
        (23, "E3M7", "E3M7"),
        (24, "E3M8", "E3M8"),
        (25, "E4M1", "E3M4"),
        (26, "E4M2", "E3M2"),
        (27, "E4M3", "E3M3"),
        (28, "E4M4", "E1M5"),
        (29, "E4M5", "E2M7"),
        (30, "E4M6", "E2M4"),
        (31, "E4M7", "E2M6"),
        (32, "E4M8", "E2M5"),
        (41, "E1M9", "E1M9"),
        (42, "E2M9", "E2M9"),
        (43, "E3M9", "E3M9"),
        (44, "E4M9", "E1M9")
    ]
    
    lines = []
    for level_num, level_name, music in level_data:
        lines.extend([
            f"Level {level_num}",
            f"levelname = {level_name}",
            "NoTitleCard = true",
            "TypeOfLevel = Singleplayer,Doom",
            "Act = 0",
            "NoZone = 1",
            f"Music = {music}",
            ""  # Empty line between levels
        ])
    
    # Remove the last empty line to avoid trailing whitespace
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
    else:
        lines.append('doom.isdoom1 = false')
    return ("\n".join(lines)).encode("utf-8")

def convert_exmx_maps(src_wad, out_wad, src_path, external_deh_data=None):
    """
    Convert ExMx map names into MAPnn in out_wad.maps and copy D_E* lumps.
    Also convert MUS lumps to MIDI.
    
    Args:
        external_deh_data: List of (name, data) tuples from external DEH/BEX files
    """
    # Collect ExMx -> new MAP mapping so we know where each ExMx moved
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

        if mp == 9:
            target_name, target_num = next_free_mapname(out_wad, start=41)
            if target_name is None:
                print(f"ERROR: no free MAP slot for secret {oldname}, skipping.")
                continue
            print(f"Converting secret {oldname} -> {target_name}")
        else:
            mapnum = exmx_to_mapnum(ep, mp)
            target_name = f"MAP{mapnum:02d}"
            target_num = mapnum
            print(f"Converting {oldname} -> {target_name}")

        # copy map group
        out_wad.maps[target_name] = src_wad.maps[oldname].copy()
        # delete any residual ExMx in out_wad to avoid duplicates
        if oldname in out_wad.maps:
            try:
                del out_wad.maps[oldname]
            except Exception:
                pass

        ex_to_new_map[oldname.upper()] = (target_name, target_num)

    for entry in src_wadio.entries:
        lname = (entry.name if isinstance(entry.name, str) else entry.name.decode("ascii")).upper().rstrip("\x00")
        
        # Read lump data by name
        data_bytes = src_wadio.read(lname)
        
        # Convert MUS to MIDI if applicable
        data_bytes = convert_mus_to_midi(data_bytes)
        lump_obj = Lump(data_bytes)
        lump_obj.name = lname

        if lname.startswith("D_"):
            out_wad.music[lname] = lump_obj
            print(f"Copied music lump: {lname}")

    return len(ex_to_new_map)

def is_doom1_wad(wad):
    """Check if WAD appears to be Doom 1 based by looking for ExMx maps"""
    # Check for ExMx maps
    ex_pattern = re.compile(r"^E(\d)M(\d{1,2})$", re.IGNORECASE)
    for mapname in wad.maps:
        if ex_pattern.match(mapname.upper()):
            return True

def convert_flat_to_graphic(flat_data, graphic_name):
    """
    Convert a flat (64x64) to Doom patch format for use as a graphic.
    
    Patch format:
    - Header: width, height, leftoffset, topoffset, columnofs[]
    - Columns: posts with topdelta, length, data
    """
    width = 64
    height = 64
    leftoffset = 0
    topoffset = 0
    
    # Calculate column offsets
    columnofs = []
    patch_data = bytearray()
    
    # Header: 8 bytes + 4 bytes per column
    header_size = 8 + (width * 4)
    
    # Build column data - flats are 64x64, stored row-major
    for x in range(width):
        # Store current column offset
        columnofs.append(header_size + len(patch_data))
        
        # Create a single post for the entire column
        # For flats, we typically want solid columns with no transparency
        topdelta = 0
        length = height
        
        # Add post header
        patch_data.append(topdelta)        # topdelta (starting row)
        patch_data.append(length)          # length (number of pixels)
        patch_data.append(0)               # unused pad byte
        
        # Add pixel data for this column
        # Flats are stored row-major: to get column x, we take every 64th pixel
        for y in range(height):
            # Correct indexing: row y, column x
            pixel_index = y * width + x
            if pixel_index < len(flat_data):
                patch_data.append(flat_data[pixel_index])
            else:
                patch_data.append(0)  # Padding if needed
        
        patch_data.append(0)               # unused pad byte after data
        patch_data.append(0xFF)            # End of column marker
    
    # Build the complete patch
    final_patch = bytearray()
    
    # Write header
    final_patch.extend(struct.pack('<HHhh', width, height, leftoffset, topoffset))
    
    # Write column offsets
    for offset in columnofs:
        final_patch.extend(struct.pack('<I', offset))
    
    # Write column data
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
    This is a simplified conversion intended for editing / SLADE-like output.
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
        # ensure we have at least the header 22 bytes
        if off + 22 > len(data):
            continue
        name_raw = data[off:off+8]
        texname = name_raw.split(b'\x00', 1)[0].decode('ascii', errors='replace')
        if texname.upper() == "NULLTEXT":  # NullTexture variants; skip safely
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
            # skip stepdir and colormap
            p_off += 10
            patch_name = pnames[patch_index] if 0 <= patch_index < len(pnames) else f"PNAME_{patch_index}"
            out_lines.append(f'\tPatch "{patch_name}", {originx}, {originy}')
        out_lines.append("}")
        out_lines.append("")
    return "\n".join(out_lines)

def parse_pnames(lump_bytes: bytes) -> list:
    """
    Parse a PNAMES lump and return a list of patch names (strings).

    PNAMES format:
      int32 nummappatches (little-endian)
      nummappatches * 8-byte zero-padded ASCII names

    Behavior:
    - If lump_bytes is too small or missing, returns [].
    - If header's count is larger than available data, clamp to available entries.
    - Names are decoded with ASCII (errors -> replacement), NUL/space-trimmed and uppercased.
    """
    if not lump_bytes or len(lump_bytes) < 4:
        return []

    # read number of patch names (little-endian uint32)
    try:
        nummappatches = int.from_bytes(lump_bytes[0:4], "little", signed=False)
    except Exception:
        return []

    # guard against absurd values
    if nummappatches <= 0:
        return []

    # how many full 8-byte entries are actually present
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
        # ensure length 8 for safe splitting
        if len(raw) < 8:
            raw = raw.ljust(8, b'\x00')
        # split at first NUL, decode (ASCII preferred), trim trailing spaces
        name = raw.split(b'\x00', 1)[0].decode('ascii', errors='replace').rstrip(' ')
        # canonicalize to uppercase (WAD lump names are typically uppercase)
        name = name.upper()
        names.append(name)
        off += 8

    return names

def process_special_lumps(src_wad, out_wad, src_wadio, external_deh_data=None):
    """
    Iterate source lumps and produce additional helper lumps for the PWAD:
    - ENDOOM -> LUA_END
    - DEHACKED / LANGUAGE -> LUA_DEH (aggregated)
    - TEXTURE1/TEXTURE2 + PNAMES -> TEXTURES (text format)
    - COLORMAP -> force size
    
    Args:
        external_deh_data: List of (name, data) tuples from external DEH/BEX files
    """
    # aggregate mapping for DEHACKED / LANGUAGE -> single table
    deh_mapping = {}

    # get raw data dictionary if available (some WAD wrappers expose .data)
    src_data = getattr(src_wad, "data", {})

    # attempt to find PNAMES and texture lumps
    pnames_bytes = None
    if "PNAMES" in src_data:
        pnames_bytes = src_data["PNAMES"].data
    # We'll collect TEXTURE1 and TEXTURE2 bytes if present
    textures_bytes = []
    if "TEXTURE1" in src_data:
        textures_bytes.append(src_data["TEXTURE1"].data)
    if "TEXTURE2" in src_data:
        textures_bytes.append(src_data["TEXTURE2"].data)

    # Collect all DEH data from external files first
    all_external_deh = []
    if external_deh_data:
        print(f"Processing {len(external_deh_data)} external DEH/BEX files")
        for name, data in external_deh_data:
            all_external_deh.append((name, data))

    # Process entries using src_wadio.entries for exact order / raw bytes
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
            # Add internal DEH data to our collection
            all_external_deh.append((f"internal_{name}", lump_bytes))
            print(f"Found internal DEHACKED lump: {name}")

        elif name.startswith("LANGUAGE") or name.startswith("LANG") or name == "LANGUAGE":
            # LANGUAGE lumps are often text files with KEY = "value"
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
                # Create TRNSLATE lump from original colormap data (before truncation)
                translate_lump = create_translate_lump_from_colormap(lump_bytes)
                if len(translate_lump.data) > 0:
                    out_wad.data["TRNSLATE"] = translate_lump
                    print("Created TRNSLATE lump from COLORMAP rows")

                fixed = force_colormap_size(lump_bytes)
                # replace/insert into out_wad data
                out_wad.data["COLORMAP"] = Lump(fixed)
                print("Replaced/inserted fixed COLORMAP (256x32)")
            except Exception as e:
                print(f"COLORMAP processing failed: {e}")

    # Process all DEH data (external + internal) and combine them
    if all_external_deh:
        combined_structured_deh = {}
        for name, data in all_external_deh:
            try:
                # Try to parse as structured DEHACKED
                structured_deh = parse_dehacked_structured(data)
                if structured_deh:
                    # Merge with existing data (later files override earlier ones)
                    for mode, entries in structured_deh.items():
                        if mode not in combined_structured_deh:
                            combined_structured_deh[mode] = []
                        # For entries with IDs, we want to merge/override
                        existing_ids = {entry['id'] for entry in combined_structured_deh[mode] if entry['id'] is not None}
                        for entry in entries:
                            if entry['id'] is not None and entry['id'] in existing_ids:
                                # Replace existing entry with same ID
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

    # Convert textures if possible
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
                # TEXTURES is 8 chars; it's appropriate for ZDoom-style text
                out_wad.data["TEXTURES"] = Lump(text_blob)
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
    # cur < target: repeat rows (each row=256 bytes) until hitting target
    if cur % 256 != 0:
        # try to pad with zeros to multiple of 256 first
        rows = math.ceil(cur / 256)
        padded = blob + b'\x00' * (rows*256 - cur)
    else:
        rows = cur // 256
        padded = blob
    output = bytearray()
    # repeat rows in order
    rows_bytes = [padded[i*256:(i+1)*256] for i in range(len(padded)//256)]
    i = 0
    while len(output) < target:
        output.extend(rows_bytes[i % len(rows_bytes)])
        i += 1
    print(f"Padded COLORMAP from {cur} -> {len(output)} bytes")
    return bytes(output[:target])

def exmx_to_mapnum(episode: int, mapnum: int):
    return (episode - 1) * 8 + mapnum

def next_free_mapname(wad_obj, start=41, upper=99):
    for n in range(start, upper + 1):
        name = f"MAP{n:02d}"
        if name not in wad_obj.maps:
            return name, n
    return None, None

def detect_udmf_namespace(map_data):
    """Detect UDMF namespace from map data."""
    # Check for TEXTMAP lump (UDMF format)
    if 'TEXTMAP' in map_data:
        textmap_data = map_data['TEXTMAP'].tostring().decode('latin-1')
        # Look for namespace declaration
        namespace_match = re.search(r'namespace\s*=\s*"([^"]+)"', textmap_data)
        if namespace_match:
            return namespace_match.group(1)
    
    return None

def process_udmf_map_linedefs(map_data, bump_amount=941):
    """Process UDMF map linedefs and bump special values."""
    if 'TEXTMAP' not in map_data:
        return map_data
    
    textmap_content = map_data['TEXTMAP'].tostring().decode('latin-1')
    
    # Parse UDMF-like structure (simplified)
    lines = textmap_content.split('\n')
    in_linedef = False
    linedef_content = []
    processed_lines = []
    
    for line in lines:
        stripped = line.strip()
        
        # Detect linedef start/end
        if stripped == 'linedef' or (stripped.startswith('linedef') and '{' in stripped):
            in_linedef = True
            linedef_content = [line]
        elif in_linedef and stripped == '}':
            in_linedef = False
            linedef_content.append(line)
            
            # Process the linedef
            processed_linedef = process_single_udmf_linedef(linedef_content, bump_amount)
            processed_lines.extend(processed_linedef)
            linedef_content = []
        elif in_linedef:
            linedef_content.append(line)
        else:
            processed_lines.append(line)
    
    # Rebuild TEXTMAP with processed linedefs
    new_textmap = '\n'.join(processed_lines)
    map_data['TEXTMAP'] = Lump(new_textmap.encode('latin-1'))
    
    return map_data

def process_single_udmf_linedef(linedef_lines, bump_amount):
    """Process a single UDMF linedef and bump its special value."""
    processed = []
    
    for line in linedef_lines:
        stripped = line.strip()
        
        # Look for special property
        if stripped.startswith('special') and '=' in stripped:
            # Extract current special value
            special_match = re.search(r'special\s*=\s*(\d+)', stripped)
            if special_match:
                old_special = int(special_match.group(1))
                new_special = old_special + bump_amount
                # Replace the line with bumped special
                line = re.sub(r'special\s*=\s*\d+', f'special = {new_special}', line)
        
        processed.append(line)
    
    return processed

def generate_lua_for_pk3(wad, udmf_namespace="srb2"):
    """Generate Lua content for PK3 with UDMF namespace markers."""
    lua_lines = ["-- Auto-generated Lua map data", "doom = doom or {}"]
    
    # Track UDMF maps
    udmf_maps = []
    
    for map_name in wad.maps:
        # Extract map number from MAPxx format
        if map_name.startswith('MAP'):
            try:
                map_num = int(map_name[3:])
            except ValueError:
                continue
            
            # Check if this is UDMF
            namespace = detect_udmf_namespace(wad.maps[map_name])
            if namespace:
                # Use detected namespace or fall back to default
                actual_namespace = namespace if namespace else udmf_namespace
                lua_lines.append(f"doom.udmfnamespaces = doom.udmfnamespaces or {{}}")
                lua_lines.append(f"doom.udmfnamespaces[{map_num}] = \"{actual_namespace}\"")
                udmf_maps.append((map_num, actual_namespace))
    
    # Add Doom 1 marker if needed
    if is_doom1_wad(wad):
        lua_lines.append("doom.isdoom1 = true")
    
    return '\n'.join(lua_lines)

def generate_lua_for_wad(wad, udmf_namespace="srb2"):
    """Generate Lua content for WAD with UDMF namespace markers."""
    lua_lines = []
    
    for map_name in wad.maps:
        if map_name.startswith('MAP'):
            try:
                map_num = int(map_name[3:])
            except ValueError:
                continue
            
            namespace = detect_udmf_namespace(wad.maps[map_name])
            if namespace:
                actual_namespace = namespace if namespace else udmf_namespace
                lua_lines.append(f"doom.udmfnamespaces[{map_num}] = \"{actual_namespace}\"")
    
    return '\n'.join(lua_lines)

def search_pk3_files(pk3_path, search_patterns=None):
    """
    Search through PK3 files (renamed ZIPs) for key data points using ZDoom folder structure.
    
    Args:
        pk3_path: Path to PK3 file or directory containing PK3 files
        search_patterns: List of regex patterns to search for. If None, uses default patterns.
    
    Returns:
        Dictionary with search results
    """
    if search_patterns is None:
        # Default search patterns for common ZDoom assets - FIXED REGEX PATTERNS
        search_patterns = [
            r'.*\.wad$',                    # WAD files
            r'.*\.pk3$',                    # Nested PK3 files
            r'maps/.*\.wad$',               # Map WADs (Binary or UDMF? We don't know until we open them!)
            r'textures/.*\.(png|jpg|jpeg|pcx)$',  # Textures
            r'sprites/.*\.(png|jpg|jpeg|pcx)$',   # Sprites
            r'sounds/.*\.(wav|ogg|mp3|flac)$',    # Sounds
            r'music/.*\.(mid|mus|ogg|mp3|flac)$', # Music
            r'graphics/.*\.(png|jpg|jpeg|pcx)$',  # Graphics
            r'actors/.*\.(txt|decorate)$',        # Actor definitions
            r'zscript/.*\.(txt|zs)$',             # ZScript files
            r'acs/.*\.(src|o)$',                  # ACS scripts
            r'voices/.*\.(wav|ogg|mp3)$',         # Voice files
            r'patches/.*\.(png|jpg|jpeg|pcx)$',   # Patches
            r'flats/.*\.(png|jpg|jpeg|pcx)$',     # Flats
            r'hires/.*\.(png|jpg|jpeg|pcx)$',     # High-resolution textures
            r'models/.*\.(md2|md3|obj)$',         # 3D models
            r'shaders/.*\.(glsl|shader)$',        # Shaders
            r'.*\.deh$',                          # Dehacked files
            r'.*\.bex$',                          # BEX files
        ]
    
    results = {
        'pk3_files': [],
        'search_patterns': search_patterns,
        'matches': {},
        'file_types': {},
        'total_files': 0,
        'largest_files': []
    }
    
    # Compile regex patterns with error handling
    compiled_patterns = []
    for pattern in search_patterns:
        try:
            compiled_patterns.append(re.compile(pattern, re.IGNORECASE))
        except re.error as e:
            print(f"Warning: Invalid regex pattern '{pattern}': {e}")
            continue
    
    def search_single_pk3(pk3_file):
        """Search a single PK3 file"""
        pk3_results = {
            'file': str(pk3_file),
            'matches': [],
            'file_count': 0,
            'size': os.path.getsize(pk3_file)
        }
        
        try:
            with zipfile.ZipFile(pk3_file, 'r') as pk3_zip:
                file_list = pk3_zip.namelist()
                pk3_results['file_count'] = len(file_list)
                results['total_files'] += len(file_list)
                
                for file_path in file_list:
                    # Check against all patterns
                    for i, pattern in enumerate(compiled_patterns):
                        if pattern.search(file_path):
                            match_type = search_patterns[i]
                            pk3_results['matches'].append({
                                'path': file_path,
                                'type': match_type,
                                'size': None
                            })
                            
                            # Track file types
                            file_ext = Path(file_path).suffix.lower()
                            results['file_types'][file_ext] = results['file_types'].get(file_ext, 0) + 1
                            
                            # Track largest files
                            try:
                                zip_info = pk3_zip.getinfo(file_path)
                                results['largest_files'].append({
                                    'path': file_path,
                                    'pk3': str(pk3_file),
                                    'size': zip_info.file_size,
                                    'compressed_size': zip_info.compress_size
                                })
                            except KeyError:
                                # Some zip files might have issues with certain entries
                                pass
                            break
                
                # Sort largest files and keep top 20
                results['largest_files'].sort(key=lambda x: x['size'], reverse=True)
                results['largest_files'] = results['largest_files'][:20]
                
        except zipfile.BadZipFile:
            print(f"Warning: {pk3_file} is not a valid ZIP/PK3 file")
            return None
        except Exception as e:
            print(f"Error reading {pk3_file}: {e}")
            return None
            
        return pk3_results
    
    # Handle single PK3 file or directory
    if os.path.isfile(pk3_path) and pk3_path.lower().endswith('.pk3'):
        pk3_result = search_single_pk3(pk3_path)
        if pk3_result:
            results['pk3_files'].append(pk3_result)
            results['matches'][pk3_path] = pk3_result['matches']
    
    elif os.path.isdir(pk3_path):
        # Search all PK3 files in directory
        for file in os.listdir(pk3_path):
            if file.lower().endswith('.pk3'):
                full_path = os.path.join(pk3_path, file)
                pk3_result = search_single_pk3(full_path)
                if pk3_result:
                    results['pk3_files'].append(pk3_result)
                    results['matches'][file] = pk3_result['matches']
    
    else:
        print(f"Warning: {pk3_path} is not a PK3 file or directory")
    
    return results

def print_pk3_search_results(results):
    """Print formatted results from PK3 search"""
    if not results['pk3_files']:
        print("No PK3 files found or searched.")
        return
    
    print("\n" + "="*80)
    print("PK3 SEARCH RESULTS")
    print("="*80)
    
    for pk3_info in results['pk3_files']:
        print(f"\nPK3 File: {os.path.basename(pk3_info['file'])}")
        print(f"  Size: {pk3_info['size']:,} bytes")
        print(f"  Total files in PK3: {pk3_info['file_count']}")
        print(f"  Matching files: {len(pk3_info['matches'])}")
        
        # Group matches by type
        matches_by_type = {}
        for match in pk3_info['matches']:
            match_type = match['type']
            if match_type not in matches_by_type:
                matches_by_type[match_type] = []
            matches_by_type[match_type].append(match['path'])
        
        # Print matches by type
        for match_type, paths in matches_by_type.items():
            print(f"    {match_type}: {len(paths)} files")
            for path in paths[:5]:  # Show first 5 of each type
                print(f"      - {path}")
            if len(paths) > 5:
                print(f"      ... and {len(paths) - 5} more")
    
    # Print summary statistics
    if results['file_types']:
        print(f"\nFILE TYPE SUMMARY:")
        for file_type, count in sorted(results['file_types'].items(), key=lambda x: x[1], reverse=True):
            if file_type:  # Skip empty extensions
                print(f"  {file_type or 'no ext'}: {count} files")
    
    if results['largest_files']:
        print(f"\nLARGEST FILES (top {min(10, len(results['largest_files']))}):")
        for file_info in results['largest_files'][:10]:
            print(f"  {file_info['path']} ({file_info['size']:,} bytes)")

def create_translate_lump_from_colormap(colormap_data):
    """
    Create a TRNSLATE lump based on each row of the COLORMAP.
    
    Format: "COLORMAPROW1 = "1:1=7:7", "2:2=9:9", ... until 255:255"
    This creates translation tables where each color index maps to itself
    for each row of the colormap.
    
    Args:
        colormap_data: Raw bytes of the COLORMAP lump
        
    Returns:
        Lump object containing the TRNSLATE definitions
    """
    # Calculate number of rows (each row is 256 bytes)
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
            
        # Get the current row data
        row_data = colormap_data[row_start:row_end]
        
        # Create translation mappings for this row
        mappings = []
        for color_index in range(256):
            if color_index < len(row_data):
                # Map color_index to itself: "source_start:source_end=dest_start:dest_end"
                # Using the actual color value from the colormap row
                dest_value = row_data[color_index]
                mapping = f"{color_index}:{color_index}={dest_value}:{dest_value}"
                mappings.append(mapping)
        
        # Join all mappings for this row
        row_mappings = ", ".join(f'"{m}"' for m in mappings)
        translate_lines.append(f"COLORMAPROW{row_num+1} = {row_mappings}")
    
    # Join all rows and convert to bytes
    translate_text = "\n".join(translate_lines)
    return Lump(translate_text.encode('latin-1'))

def create_translate_lump_simple_identity(num_rows=34):
    """
    Create a simpler TRNSLATE lump with identity mappings for testing.
    This creates translation tables where each color index maps to itself.
    
    Args:
        num_rows: Number of translation rows to create
        
    Returns:
        Lump object containing the TRNSLATE definitions
    """
    print(f"Creating simple identity TRNSLATE with {num_rows} rows")
    
    translate_lines = []
    
    for row_num in range(num_rows):
        # Create identity mappings: 0:0=0:0, 1:1=1:1, ..., 255:255=255:255
        mappings = []
        for color_index in range(256):
            mapping = f"{color_index}:{color_index}={color_index}:{color_index}"
            mappings.append(mapping)
        
        # Join all mappings for this row
        row_mappings = ", ".join(f'"{m}"' for m in mappings)
        translate_lines.append(f"COLORMAPROW{row_num+1} = {row_mappings}")
    
    # Join all rows and convert to bytes
    translate_text = "\n".join(translate_lines)
    return Lump(translate_text.encode('latin-1'))

def process_pk3_file(src_pk3_path, out_pk3_path):
    """Process a PK3 file with WAD-like operations and Lua generation."""
    print(f"Processing PK3: {src_pk3_path}")
    
    # Create temporary directory for processing
    with tempfile.TemporaryDirectory() as temp_dir:
        # Extract PK3 to temporary directory
        with zipfile.ZipFile(src_pk3_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
        
        # Process WAD files found in the PK3
        wad_files_processed = 0
        lua_content_lines = []
        
        # Walk through extracted directory
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = os.path.join(root, file)
                
                # Process WAD files
                if file.lower().endswith('.wad'):
                    try:
                        print(f"  Processing WAD: {file}")
                        wad = WAD()
                        wad.from_file(file_path)
                        
                        # Apply WAD processing operations
                        created = make_fw_sequence(wad, wad)
                        if created > 0:
                            print(f"    Created {created} FWATER textures")
                        
                        converted = convert_exmx_maps(wad, wad, file_path)
                        if converted > 0:
                            print(f"    Converted {converted} ExMx maps")
                        
                        # Create cutscene graphics
                        graphics_created = create_cutscene_graphics(wad)
                        if graphics_created > 0:
                            print(f"    Created {graphics_created} cutscene graphics")
                        
                        # Patch linedefs
                        patch_linedefs_add(wad, 941)
                        print("    Patched linedef specials (+941)")
                        
                        # Process UDMF maps
                        for map_name in wad.maps:
                            wad.maps[map_name] = process_udmf_map_linedefs(wad.maps[map_name], 941)
                        
                        # Generate Lua content for this WAD
                        wad_lua = generate_lua_for_pk3(wad)
                        if wad_lua.strip():
                            lua_content_lines.append(f"-- From {file}")
                            lua_content_lines.append(wad_lua)
                            lua_content_lines.append("")  # Empty line between WADs
                        
                        # Save processed WAD back
                        wad.to_file(file_path)
                        wad_files_processed += 1
                        
                    except Exception as e:
                        print(f"    Error processing WAD {file}: {e}")
        
        # Create Lua directory if it doesn't exist and we have Lua content
        lua_dir = os.path.join(temp_dir, 'Lua')
        if lua_content_lines and not os.path.exists(lua_dir):
            os.makedirs(lua_dir)
        
        # Write MapData.lua if we have content
        if lua_content_lines:
            mapdata_content = '\n'.join(lua_content_lines)
            mapdata_path = os.path.join(temp_dir, 'MapData.lua')
            with open(mapdata_path, 'w') as f:
                f.write(mapdata_content)
            print(f"  Created MapData.lua with {len(lua_content_lines)} lines")
        
        # Also write individual Lua files in Lua/ directory
        if lua_content_lines:
            # For now, we'll write one file with all content
            # In a more advanced version, you could split this by WAD
            lua_file_path = os.path.join(lua_dir, 'AutoGeneratedMaps.lua')
            with open(lua_file_path, 'w') as f:
                f.write(mapdata_content)
            print(f"  Created Lua/AutoGeneratedMaps.lua")
        
        # Create Graphics directory for cutscene graphics from non-WAD flats
        graphics_dir = os.path.join(temp_dir, 'Graphics')
        if not os.path.exists(graphics_dir):
            os.makedirs(graphics_dir)
        
        # Look for loose flats in the PK3 and convert them to graphics
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = os.path.join(root, file)
                # Skip WAD files (already processed) and non-flat files
                if file.lower().endswith('.wad'):
                    continue
                    
                # Check if this file matches any of our flat names
                for flat_name, graphic_name in CUTSCENE_GRAPHICS.items():
                    if file.upper() == flat_name:
                        try:
                            # Read the flat data and convert to graphic
                            with open(file_path, 'rb') as f:
                                flat_data = f.read()
                            
                            if len(flat_data) >= 4096:  # Proper flat size
                                graphic_lump = convert_flat_to_graphic(flat_data, graphic_name)
                                graphic_path = os.path.join(graphics_dir, graphic_name)
                                with open(graphic_path, 'wb') as f:
                                    f.write(graphic_lump.data)
                                print(f"  Created Graphics/{graphic_name} from loose flat {file}")
                        except Exception as e:
                            print(f"  Error converting loose flat {file}: {e}")
        
        # Create new PK3 with processed content
        with zipfile.ZipFile(out_pk3_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(temp_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    # Calculate relative path for zip
                    arcname = os.path.relpath(file_path, temp_dir)
                    zipf.write(file_path, arcname)
        
        print(f"  Processed {wad_files_processed} WAD files")
        print(f"  Created PK3: {out_pk3_path}")

def wad_to_pk3(wad, pk3_path):
    """
    Convert a WAD to PK3 format with proper directory structure.
    SOC goes in SOC/*
    Lua goes in Lua/*
    Otherwise, do our due diligence and respect ZDoom structure.
    """
    print(f"Converting WAD to PK3: {pk3_path}")
    
    # Define path lookup for different lump types
    pathlookup = {
        'Sprites': 'Sprites/',
        'Patches': 'Patches/', 
        'Flats': 'Flats/',
        'Colormaps': 'Colormaps/',
        'Ztextures': 'Textures/',
        'Maps': 'Maps/',
        'GLMaps': 'Maps/',
        'Music': 'Music/',
        'Sounds': 'Sounds/',
        'Txdefs': '',
        'Graphics': 'Graphics/',
        'Data': ''
    }
    
    with tempfile.TemporaryDirectory() as temp_dir:
        with zipfile.ZipFile(pk3_path, 'w', zipfile.ZIP_DEFLATED) as pk3:
            # Process maps - create individual WAD files in Maps/ folder
            for map_name, map_data in wad.maps.items():
                # Create a temporary WAD for this map
                temp_wad = WAD()
                temp_wad.maps[map_name] = map_data
                temp_wad_path = os.path.join(temp_dir, f"{map_name}.wad")
                temp_wad.to_file(temp_wad_path)
                pk3.write(temp_wad_path, f"Maps/{map_name}.wad")
                print(f"  Added map: Maps/{map_name}.wad")
            
            # Process non-map lumps
            groups = {
                'Sprites': wad.sprites,
                'Patches': wad.patches,
                'Flats': wad.flats,
                'Colormaps': wad.colormaps,
                'Ztextures': wad.ztextures,
                'Music': wad.music,
                'Sounds': wad.sounds,
                'Txdefs': wad.txdefs,
                'Graphics': wad.graphics,
                'Data': wad.data
            }

            alt_lua_names = {
                'DOOM': 'DoomMarker',
                'ENDM': 'Endoom',
                'DEH': 'DehLanguageBex',
            }
            
            # Collect Lua lumps separately
            lua_lumps = {}
            soc_lumps = {}
            
            for group_name, group in groups.items():
                for lump_name, lump in group.items():
                    # Skip maps (already handled)
                    if group_name == 'maps':
                        continue
                    
                    # Handle SRB2's lumps specially
                    if lump_name.startswith('LUA_'):
                        lua_lumps[lump_name] = lump
                        continue
                    if lump_name.startswith('SOC_'):
                        soc_lumps[lump_name] = lump
                        continue
                    
                    # Determine path for this lump type
                    path_prefix = pathlookup.get(group_name, '')
                    if path_prefix:
                        full_path = f"{path_prefix}{lump_name}"
                    else:
                        full_path = lump_name
                    
                    # Write the lump
                    pk3.writestr(full_path, lump.data)
                    print(f"  Added {full_path}")
            
            # Now add the SRB2 lumps to the PK3
            for lua_name, lua_lump in lua_lumps.items():
                # Remove LUA_ prefix for filename
                lua_filename = lua_name[4:] if lua_name.startswith('LUA_') else lua_name
                if alt_lua_names[lua_filename]:
                    lua_filename = alt_lua_names[lua_filename]
                pk3.writestr(f"Lua/{lua_filename}.lua", lua_lump.data)
                print(f"  Added Lua/{lua_filename}.lua")
            for lua_name, lua_lump in soc_lumps.items():
                lua_filename = lua_name[4:] if lua_name.startswith('SOC_') else lua_name
                pk3.writestr(f"SOC/{lua_filename}", lua_lump.data)
                print(f"  Added SOC/{lua_filename}")
    
    print(f"Created PK3: {pk3_path}")

def parse_dehacked_pars_section(raw_bytes: bytes) -> dict:
    """
    Parse DEHACKED PARS section specifically.
    Format is: par <gamemap> <partime>
    Example: par 26 270
    """
    text = raw_bytes.decode('latin-1', errors='replace')
    results = {}
    
    for line in text.splitlines():
        line = line.strip()
        
        # Skip comments and empty lines
        if not line or line.startswith('#'):
            continue
            
        # Look for "par <number> <number>" pattern
        parts = line.split()
        if len(parts) == 3 and parts[0].lower() == 'par':
            try:
                gamemap = int(parts[1])
                partime = int(parts[2])
                results[gamemap] = partime
            except ValueError:
                # Skip lines that don't have valid numbers
                continue
    
    return results

def process_dehacked_escapes(text: str) -> str:
    """
    Process DEHACKED escape sequences in strings.
    Converts \n to actual newlines, \\ to single backslash, etc.
    """
    result = []
    i = 0
    while i < len(text):
        if text[i] == '\\' and i + 1 < len(text):
            # Escape sequence
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
                # Unknown escape, keep both characters
                result.append('\\')
                result.append(next_char)
                i += 2
        else:
            result.append(text[i])
            i += 1
    
    return ''.join(result)

def parse_dehacked_strings_section(raw_bytes: bytes) -> dict:
    """
    Parse DEHACKED STRINGS section specifically.
    Format is: KEY = value
    Handles line continuations with backslashes and escape sequences.
    """
    text = raw_bytes.decode('latin-1', errors='replace')
    results = {}
    
    # First, combine lines that end with backslash (line continuations)
    combined_lines = []
    current_line = ""
    
    for line in text.splitlines():
        line = line.rstrip()  # Remove trailing whitespace
        
        # Skip comments and empty lines
        if not line or line.startswith('#'):
            if current_line:  # If we have a current line, add it
                combined_lines.append(current_line)
                current_line = ""
            continue
            
        # Check for line continuation
        if line.endswith('\\'):
            # Remove the backslash and add to current line
            current_line += line[:-1].rstrip()
        else:
            # No continuation, complete the line
            current_line += line
            combined_lines.append(current_line)
            current_line = ""
    
    # Add any remaining line
    if current_line:
        combined_lines.append(current_line)
    
    # Now parse the combined lines
    for line in combined_lines:
        line = line.strip()
        if not line:
            continue
            
        # Look for KEY = value pattern
        if '=' in line:
            key, value = line.split('=', 1)
            key = key.strip()
            value = value.strip()
            
            # Only add if it looks like a valid string replacement
            if key and value and not key.startswith('#'):
                # Process escape sequences in the value
                value = process_dehacked_escapes(value)
                results[key] = value.encode('latin-1')
    
    return results

def _lua_val_from_bytes_or_str(v):
    """Convert bytes or string to Lua value representation."""
    if isinstance(v, (bytes, bytearray)):
        vs = v.decode('latin-1', errors='replace').strip()
        if re.fullmatch(r'-?\d+', vs):
            return vs
        elif re.fullmatch(r'[-0-9,\s]+', vs) and (',' in vs or ' ' in vs):
            parts = re.split(r'[,\s]+', vs.strip())
            out_parts = []
            for p in parts:
                if p == '': continue
                if re.fullmatch(r'-?\d+', p):
                    out_parts.append(p)
                else:
                    esc = str(p).replace('\\', '\\\\').replace('"', '\\"')
                    out_parts.append(f'"{esc}"')
            return '{' + ",".join(out_parts) + '}'
        else:
            if ']]' not in vs:
                return _make_safe_lua_long_bracket_for_bytes(v)
            else:
                return lua_literal_from_bytes(v)
    else:
        return f'"{str(v).replace(chr(92), chr(92)*2).replace(chr(34), chr(92)+chr(34))}"'

def create_deh_only_wad(deh_files, out_path):
    """
    Create a WAD containing only a LUA_DEH lump from external DEH/BEX files.
    
    Args:
        deh_files: List of (name, data) tuples from external DEH/BEX files
        out_path: Output WAD path
    """
    print(f"Creating DEH-only WAD from {len(deh_files)} external files")
    
    out_wad = WAD()
    
    # Process all external DEH/BEX files
    for name, data in deh_files:
        try:
            # Try to parse as structured DEHACKED
            structured_deh = parse_dehacked_structured(data)
            if structured_deh:
                lua_deh = build_structured_lua_deh(structured_deh)
                out_wad.data["LUA_DEH"] = Lump(lua_deh)
                print(f"Wrote structured LUA_DEH from external {name}")
            else:
                # structured parser found nothing meaningful — try flat/key=value parser
                m = parse_key_value_pairs_from_text(data)
                if m:
                    lua_deh = build_lua_deh_table(m)
                    out_wad.data["LUA_DEH"] = Lump(lua_deh)
                    print(f"Wrote flat LUA_DEH from external {name} (fallback)")
                else:
                    print(f"No DEHACKED data found in external {name}")
        except Exception as e:
            # If structured parsing throws, attempt the flat parser as a fallback
            print(f"Failed to parse external {name} as structured DEHACKED: {e}")
            try:
                m = parse_key_value_pairs_from_text(data)
                lua_deh = build_lua_deh_table(m)
                out_wad.data["LUA_DEH"] = Lump(lua_deh)
                print(f"Wrote flat LUA_DEH from external {name} (exception fallback)")
            except Exception as e2:
                print(f"Failed to parse external {name} as flat DEHACKED: {e2}")
    
    # Write the output WAD
    if "LUA_DEH" in out_wad.data:
        out_wad.to_file(out_path)
        print(f"Created DEH-only WAD: {out_path}")
    else:
        print("No DEHACKED data found in any external files, creating empty WAD")
        out_wad.to_file(out_path)

def main(src_path: str, out_path: str, deh_files=None): 
    """
    Main function with support for external DEH/BEX files.
    
    Args:
        src_path: Source WAD/PK3 path or directory
        out_path: Output WAD/PK3 path
        deh_files: List of (name, data) tuples from external DEH/BEX files
    """
    print("Loading:", src_path)
    
    # Handle DEH-only case (no WAD, just DEH/BEX files)
    if deh_files and not os.path.exists(src_path) and src_path.lower().endswith(('.deh', '.bex')):
        # Treat all arguments as DEH/BEX files going to output WAD
        all_deh_files = [(src_path, open(src_path, 'rb').read())]
        if deh_files:
            all_deh_files.extend(deh_files)
        create_deh_only_wad(all_deh_files, out_path)
        return
    
    # Check if we should process as PK3
    if src_path.lower().endswith('.pk3'):
        process_pk3_file(src_path, out_path)
        return
    
    # Check if we should search PK3 files instead of processing WAD
    if os.path.isdir(src_path):
        print("Directory detected - performing search...")
        results = search_pk3_files(src_path)
        print_pk3_search_results(results)
        return
    
    # Normal WAD processing
    src_wad = WAD()
    src_wad.from_file(src_path)

    out_wad = WAD()
    # Copy all data from source to output WAD
    out_wad.from_file(src_path)

    created = make_fw_sequence(src_wad, out_wad)
    print(f"FWATER created: {created}")

    converted = convert_exmx_maps(src_wad, out_wad, src_path, deh_files)
    print(f"Converted {converted} ExMx maps (where present).")

    # Create cutscene graphics from flats
    graphics_created = create_cutscene_graphics(out_wad)
    print(f"Created {graphics_created} cutscene graphics")

    # --- PATCH: add 940 to every linedef.action for classic LINEDEFS ---
    print("Patching linedefs: adding 941 to every classic linedef action...")
    patch_linedefs_add(out_wad, 941)

    # --- Process UDMF maps ---
    print("Processing UDMF maps...")
    for map_name in out_wad.maps:
        out_wad.maps[map_name] = process_udmf_map_linedefs(out_wad.maps[map_name], 941)

    # --- NEW: patch pegging flags (ensure DOOM-like midtexture behavior in SRB2) ---
    print("Normalizing pegging flags to canonical DOOM logic...")
    normalize_pegging_flags_to_doom(out_wad)

    # Add LUA_MAPS lump for WAD with UDMF namespace markers
    lua_maps_content = generate_lua_for_wad(out_wad)
    if lua_maps_content.strip():
        out_wad.data["LUA_MAPS"] = Lump(lua_maps_content.encode('latin-1'))
        print("Added LUA_MAPS lump with UDMF namespace markers")

    # Append LUA_DOOM marker
    is_doom1 = is_doom1_wad(src_wad)
    if is_doom1:
        print("WAD seems to be based on Doom 1, appending level SOC...")
        out_wad.data["SOC_LVLS"] = Lump(build_soc_levels())

    out_wad.data["LUA_DOOM"] = Lump(build_lua_marker(is_doom1))

    if out_path.lower().endswith('.pk3'):
        # Output as PK3
        wad_to_pk3(out_wad, out_path)
    else:
        # Output as WAD
        out_wad.to_file(out_path)
        print(f"Wrote PWAD to {out_path}")

    print("Done.")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python pywadadvance.py <source_wad> <output_pwad_or_pk3> [deh_file ...]")
        print("       python pywadadvance.py <deh_file> [bex_file ...] <output_pwad_or_pk3>")
        print("")
        print("Examples:")
        print("  python pywadadvance.py Sonic.wad Sonic.pk3")
        print("  python pywadadvance.py Sonic.wad Sonic.pk3 sonic.deh sonic.bex")
        print("  python pywadadvance.py sonic.deh sonic.bex Sonic_DEH.wad")
        sys.exit(1)
    
    # Parse command line arguments
    src = sys.argv[1]
    dst = sys.argv[2]
    
    # Check for DEH/BEX files in arguments
    deh_files = []
    for arg in sys.argv[3:]:
        if arg.lower().endswith(('.deh', '.bex')):
            if os.path.exists(arg):
                try:
                    with open(arg, 'rb') as f:
                        deh_files.append((os.path.basename(arg), f.read()))
                    print(f"Found external DEH/BEX file: {arg}")
                except Exception as e:
                    print(f"Error reading DEH/BEX file {arg}: {e}")
            else:
                print(f"DEH/BEX file not found: {arg}")
    
    if not os.path.exists(src) and src.lower().endswith(('.deh', '.bex')):
        # DEH-only mode - all arguments are DEH/BEX files
        if not deh_files:
            # Only one DEH file specified
            try:
                with open(src, 'rb') as f:
                    deh_files = [(os.path.basename(src), f.read())]
                # Use the last argument as output
                dst = sys.argv[-1]
                main(src, dst, deh_files)
            except Exception as e:
                print(f"Error: {e}")
                sys.exit(2)
        else:
            # Multiple DEH files specified, use last as output
            dst = sys.argv[-1]
            main(src, dst, deh_files)
    else:
        # Normal WAD processing with optional DEH files
        if not os.path.exists(src):
            print("Source WAD/PK3 not found:", src)
            sys.exit(2)
        main(src, dst, deh_files)