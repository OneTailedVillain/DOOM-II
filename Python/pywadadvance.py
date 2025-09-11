#!/usr/bin/env python3
"""
Python script for preparing WADs for use in the SRB2 DOOM port.

Usage:
    python pywadadvance.py <source_wad> <output_pwad>

Features:
- Creates FWATER1..FWATER16 from FWATER1..FWATER4
- Converts ExMx -> MAPnn (E1M1..E1M9 -> MAP01..MAP41, etc)
- Renames D_E* music lumps to Doom2 music names
- Adds marker for Doom 1 WADs
- Converts all MUS format lumps to MIDI format
- Writes a PWAD with converted content
"""

import sys
import os
import re
import struct

# Attempt to import OMGIFOL (yes that's its name)
try:
    from omg import WAD, WadIO, Lump
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

# DEHACKED / LANGUAGE -> LUA_DEH
import re

def parse_key_value_pairs_from_text(blob: bytes) -> dict:
    """
    Generic approach: attempt to find KEY = "value" or KEY = value (unquoted) lines.
    Also catches BEX style STARTUP5====...==== blocks (very basic).
    Returns dict KEY->value (value as bytes, preserving raw).
    """
    txt = blob.decode('latin-1', errors='replace')
    results = {}
    # First: handle STARTUP5===...=== style BEX strings (STARTUP1..STARTUP5)
    # match sequences like STARTUP5====...====
    bex_re = re.compile(r'([A-Z0-9_]+)\s*={3,}\s*(.*?)\s*={3,}', re.DOTALL)
    for m in bex_re.finditer(txt):
        key = m.group(1).strip()
        val = m.group(2)
        # trim box drawing tailing separators which are often lines of '='
        results[key] = val.encode('latin-1')
    # Next: normal KEY = "value" or KEY = value lines
    kv_re = re.compile(r'^([A-Z0-9_]+)\s*=\s*(?:"([^"]*)"|(.*?)\s*)$', re.MULTILINE)
    for m in kv_re.finditer(txt):
        key = m.group(1)
        val = m.group(2) if m.group(2) is not None else m.group(3)
        if val is None:
            val = ""
        results[key] = val.encode('latin-1')
    return results

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

# TEXTURE conversion functions
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

# COLORMAP adjustment
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

# High-level processor
def process_special_lumps(src_wad, out_wad, src_wadio):
    """
    Iterate source lumps and produce additional helper lumps for the PWAD:
    - ENDOOM -> LUA_END
    - DEHACKED / LANGUAGE -> LUA_DEH (aggregated)
    - TEXTURE1/TEXTURE2 + PNAMES -> TEXTURES (text format)
    - COLORMAP -> force size
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

    # process entries using src_wadio.entries for exact order / raw bytes
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
            try:
                m = parse_key_value_pairs_from_text(lump_bytes)
                deh_mapping.update(m)
                print(f"Collected DEHACKED/BEX strings from {name}")
            except Exception as e:
                print(f"Failed to parse {name}: {e}")

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
                fixed = force_colormap_size(lump_bytes)
                # replace/insert into out_wad data
                out_wad.data["COLORMAP"] = Lump(fixed)
                print("Replaced/inserted fixed COLORMAP (256x32)")
            except Exception as e:
                print(f"COLORMAP processing failed: {e}")

    if deh_mapping:
        try:
            lua_deh = build_lua_deh_table(deh_mapping)
            out_wad.data["LUA_DEH"] = Lump(lua_deh)
            print("Wrote LUA_DEH from aggregated DEHACKED/LANGUAGE entries")
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

# MUS to MIDI conversion functions

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
        print(f"⚠️ MUS conversion error: {e}")
    return data


# WAD Processing Functions

# Doom2 music mapping (For Doom1 IWADs/PWADs)
DOOM2_MUSIC_BY_MAP = {
    1:  "D_RUNNIN", 2:  "D_STALKS", 3:  "D_COUNTD", 4:  "D_BETWEE",
    5:  "D_DOOM",   6:  "D_THE_DA", 7:  "D_SHAWN",  8:  "D_DDTBLU",
    9:  "D_IN_CIT", 10: "D_DEAD",   11: "D_STLKS2",12: "D_THEDA2",
    13: "D_DOOM2",  14: "D_DDTBL2",15: "D_RUNNI2",16: "D_DEAD2",
    17: "D_STLKS3", 18: "D_ROMERO", 19: "D_SHAWN2",20: "D_MESSAG",
    21: "D_COUNT2", 22: "D_DDTBL3", 23: "D_AMPIE", 24: "D_THEDA3",
    25: "D_ADRIAN", 26: "D_MESSG2", 27: "D_ROMER2",28: "D_TENSE",
    29: "D_SHAWN3", 30: "D_OPENIN", 31: "D_EVIL",  32: "D_ULTIMA",
    33: "D_READ_M",
}


def exmx_to_mapnum(episode: int, mapnum: int):
    return (episode - 1) * 8 + mapnum


def next_free_mapname(wad_obj, start=41, upper=99):
    for n in range(start, upper + 1):
        name = f"MAP{n:02d}"
        if name not in wad_obj.maps:
            return name, n
    return None, None


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


def build_lua_marker(is_doom1: bool) -> bytes:
    """Builds the LUA_DOOM lump content."""
    lines = [
        'if not doom then',
        '\terror("This WAD is meant for the DOOM SRB2 port and should NOT be loaded first!")',
        'end',
        'doom.basewad = false',
        ''
    ]
    if is_doom1:
        lines.append('doom.isdoom1 = true')
    return ("\n".join(lines)).encode("utf-8")

def convert_exmx_maps_and_rename_music(src_wad, out_wad, src_path):
    """
    Convert ExMx map names into MAPnn in out_wad.maps and rename/copy D_E* lumps
    into their Doom2 D_* names where applicable. Also convert MUS lumps to MIDI.
    """
    # Collect ExMx -> new MAP mapping so we know where each ExMx moved
    ex_pattern = re.compile(r"^E(\d)M(\d{1,2})$", re.IGNORECASE)
    src_map_names = list(src_wad.maps.keys())
    src_wadio = WadIO(src_path)
    process_special_lumps(src_wad, out_wad, src_wadio)
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
        m = re.match(r"^D_E(\d)M(\d{1,2})$", lname, re.IGNORECASE)
        
        # Read lump data by name
        data_bytes = src_wadio.read(lname)
        
        # Convert MUS to MIDI if applicable
        data_bytes = convert_mus_to_midi(data_bytes)
        lump_obj = Lump(data_bytes)
        lump_obj.name = lname
    
        if m:
            ep, mp = int(m.group(1)), int(m.group(2))
            exkey = f"E{ep}M{mp}"
            if exkey in ex_to_new_map:
                target_map_name, target_num = ex_to_new_map[exkey]
                doom2mus = DOOM2_MUSIC_BY_MAP.get(target_num)
                if mp != 9 and doom2mus:
                    used_name = safe_add_lump_to_data(out_wad, doom2mus, lump_obj)
                    print(f"Copied {lname} -> {used_name} (for {target_map_name})")
                else:
                    safe_add_lump_to_data(out_wad, lname, lump_obj)
                    print(f"Copied {lname} as-is (no Doom2 mapping)")
            # ADD THIS CONTINUE TO SKIP GENERAL D_* HANDLING
            continue
    
        # Only non-D_E* lumps reach here
        if lname.startswith("D_") and lname not in out_wad.data:
            out_wad.data[lname] = lump_obj
            print(f"Copied miscellaneous D_* lump: {lname}")

    return len(ex_to_new_map)

def is_doom1_wad(wad_obj):
    """Check if WAD appears to be Doom 1 based by looking for ExMx maps or Doom 1 music"""
    # Check for ExMx maps
    ex_pattern = re.compile(r"^E(\d)M(\d{1,2})$", re.IGNORECASE)
    for mapname in wad_obj.maps:
        if ex_pattern.match(mapname.upper()):
            return True
    
    # Check for Doom 1 music lumps
    for lumpname in wad_obj.data:
        if lumpname.upper().startswith("D_E") and lumpname.upper().endswith("M"):
            return True
    
    return False

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

# --- update main() to call the helper after maps are converted ---

def main(src_path: str, out_path: str): 
    print("Loading:", src_path)
    src_wad = WAD()
    src_wad.from_file(src_path)

    out_wad = WAD()
    out_wad += src_wad

    created = make_fw_sequence(src_wad, out_wad)
    print(f"FWATER created: {created}")

    converted = convert_exmx_maps_and_rename_music(src_wad, out_wad, src_path)
    print(f"Converted {converted} ExMx maps (where present).")

    # --- PATCH: add 940 to every linedef.action for classic LINEDEFS ---
    print("Patching linedefs: adding 941 to every classic linedef action...")
    patch_linedefs_add(out_wad, 941)

    # Append LUA_DOOM marker
    is_doom1 = is_doom1_wad(src_wad)
    if is_doom1:
        print("WAD seems to be based on Doom 1, appending marker...")
    else:
        print("Appending generic DOOM marker...")

    out_wad.data["LUA_DOOM"] = Lump(build_lua_marker(is_doom1))

    out_wad.to_file(out_path)
    print(f"Wrote PWAD to {out_path}")

    print("Done.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python make_fw_and_map_pwad.py <source_wad> <output_pwad>")
        sys.exit(1)
    src = sys.argv[1]
    dst = sys.argv[2]
    if not os.path.exists(src):
        print("Source WAD not found:", src)
        sys.exit(2)
    main(src, dst)