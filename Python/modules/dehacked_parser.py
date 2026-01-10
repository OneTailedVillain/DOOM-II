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

    MODE_WORDS = set(["THING","SOUND","FRAME","SPRITE","AMMO","WEAPON","POINTER","CHEAT","MISC","TEXT",
                      "STRINGS","PARS","CODEPTR","MUSIC","SPRITES","SOUNDS","INCLUDE"])

    results = {}
    current_mode = None
    current_entry = None
    
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
        
        if s == "" or s.startswith('#'):
            continue

        # Handle bracketed sections like [CODEPTR]
        if s.startswith('[') and s.endswith(']'):
            push_entry()
            current_mode = s[1:-1].strip()
            current_entry = {'id': None, 'fields': {}}
            accum = []
            
            # Accumulate all lines until next section or frame definition
            while i < len(lines):
                next_line = lines[i]
                next_stripped = next_line.strip()
                
                # Stop if we hit another bracketed section
                if next_stripped.startswith('[') and next_stripped.endswith(']'):
                    break
                    
                # Stop if we hit a new frame/thing definition (but allow CODEPTR assignments)
                if (next_stripped and 
                    not next_stripped.startswith('#') and
                    not '=' in next_stripped and  # CODEPTR lines have = signs
                    re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)(?:\s*\([^)]*\))?\s*$', next_stripped)):
                    break
                    
                accum.append(next_line)
                i += 1
                
            current_entry['fields']['RAW'] = ("\n".join(accum)).encode('latin-1')
            push_entry()
            continue

        # Match a section like: WORD 123 [optional second number]
        m = re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)(?:\s+(-?\d+))?\s*$', s)
        if not m:
            m = re.match(r'^\s*([A-Za-z\[\]_]+)\s+(-?\d+)\s*', s)

        if m:
            push_entry()
            mode_word = m.group(1).strip()
            
            # SPECIAL CASE: TEXT is not an index range, but a length specification
            if mode_word.upper() == "TEXT":
                current_mode = "TEXT"
                # The two numbers are original length and new length, not start/end indices
                orig_len = int(m.group(2))
                new_len = int(m.group(3)) if m.lastindex and m.lastindex >= 3 and m.group(3) is not None else None
                
                if new_len is None:
                    # If only one number, something's wrong with the format
                    print(f"WARNING: TEXT header with only one number: {s}")
                    continue
                
                # Read the concatenated original + new string data
                if i < len(lines):
                    # Get the next line which contains the concatenated string data
                    string_data_line = lines[i]
                    i += 1
                    
                    # The string data should be exactly orig_len + new_len characters
                    # But we need to handle it as bytes, not text
                    string_data_bytes = string_data_line.encode('latin-1')
                    
                    # Ensure we have enough bytes
                    if len(string_data_bytes) < orig_len + new_len:
                        print(f"WARNING: TEXT data too short. Expected {orig_len + new_len} bytes, got {len(string_data_bytes)}")
                        # Pad with spaces if needed
                        string_data_bytes = string_data_bytes.ljust(orig_len + new_len, b' ')
                    
                    # Split into original and new parts
                    original_bytes = string_data_bytes[:orig_len]
                    new_bytes = string_data_bytes[orig_len:orig_len + new_len]
                    
                    # Store as an entry
                    entry = {
                        'id': 0,  # Use 0 as ID since TEXT doesn't have indices
                        'fields': {
                            'ORIGINAL_LENGTH': str(orig_len).encode('latin-1'),
                            'NEW_LENGTH': str(new_len).encode('latin-1'),
                            'ORIGINAL': original_bytes,
                            'NEW': new_bytes,
                            '_ORIGINAL_LINE': raw.encode('latin-1')
                        }
                    }
                    results.setdefault("TEXT", []).append(entry)
                else:
                    print(f"WARNING: TEXT header without following string data: {s}")
                continue
            
            # For other modes, handle as before
            # if a second number was captured, m.group(3) is the end index
            start_id = int(m.group(2))
            end_id = int(m.group(3)) if m.lastindex and m.lastindex >= 3 and m.group(3) is not None else start_id

            mode_key = mode_word.upper() if mode_word.upper() in MODE_WORDS else mode_word
            current_mode = mode_key

            # The old TEXT paragraph parsing code should be REMOVED
            # since we handle TEXT specially above
            
            # For non-TEXT modes, create an entry with the index
            current_entry = {'id': start_id, 'fields': {'_ORIGINAL_LINE': raw.encode('latin-1')}}
            # If it's a range, we need to handle multiple entries
            if end_id != start_id:
                # Create multiple entries for the range
                for idx in range(start_id, end_id + 1):
                    entry = {'id': idx, 'fields': {'_ORIGINAL_LINE': raw.encode('latin-1')}}
                    results.setdefault(current_mode, []).append(entry)
                current_entry = None
            continue

        # Handle global key=value pairs
        if '=' in raw:
            left, right = raw.split('=', 1)
            key = left.strip().upper()
            val = right.strip()
            if current_entry is None:
                current_mode = "GLOBAL"
                current_entry = {'id': None, 'fields': {}}
            current_entry['fields'][key] = val.encode('latin-1')
            continue

        # Handle miscellaneous lines
        if current_entry is None:
            current_mode = "GLOBAL"
            current_entry = {'id': None, 'fields': {}}
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