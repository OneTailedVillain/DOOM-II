# modules/strife_dialogs.py
r"""
Strife SCRIPTxx parser -> Lua emitter.

Usage:
    from modules.strife_dialogs import parse_and_emit_strife_scripts

    parse_and_emit_strife_scripts(src_wad, out_wad, src_wadio, write_file=True)

This will add a lump "LUA_STRF" to out_wad.data containing a Lua table:
{
  scripts = { ["SCRIPT00"] = { dialogs = { ... } }, ... },
  logs = { [1] = "...", [2] = "...", ... }
}

Note: WAD lump names are limited to 8 characters; SRB2 forces a LUA_ prefix on user Lua lumps
in some toolchains. If you need a different target lump name, change OUT_LUMP_NAME below.
"""
import re
import struct
import os
from pathlib import Path

# Attempt to import Lump class used in your scriptbase
try:
    from omg import Lump
except Exception:
    # Fallback dummy if calling from a context where omg is not available.
    class Lump:
        def __init__(self, data: bytes):
            self.data = data
            self.name = None
        def copy(self):
            return Lump(bytes(self.data))

# Constants matching Strife's original structure
MAPDIALOG_SIZE = 0x5EC  # 1516 bytes (ORIG_MAPDIALOG_SIZE)
CHOICES_PER_DIALOG = 5

OUT_LUMP_NAME = "LUA_STRF"  # keep <= 8 chars; change if needed
OUT_FILE_NAME = "strife_dialogs.lua"

# ---------------------------------------------------------------------
# Helpers: binary parsing and Lua string escaping
# ---------------------------------------------------------------------
def _read_cstring(blob: bytes, offset: int, length: int) -> str:
    """Read fixed-length C-style string and return Python str (latin-1)."""
    raw = blob[offset:offset+length]
    part = raw.split(b'\x00', 1)[0]
    try:
        return part.decode('latin-1')
    except Exception:
        return part.decode('utf-8', errors='replace')

def _lua_quote(s: str) -> str:
    r"""
    Produce a single-quoted Lua literal for string s.
    Escapes: \, ', newline, carr return, tab, and non-printable bytes as \xNN.
    Keeps normal printable ASCII intact.
    """
    out = ["'"]
    for ch in s:
        o = ord(ch)
        if ch == "\\":
            out.append("\\\\")
        elif ch == "'":
            out.append("\\'")
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ch == "\t":
            out.append("\\t")
        elif 32 <= o <= 126:
            out.append(ch)
        else:
            # produce a hex escape sequence; string literal contains a backslash
            out.append("\\x{:02x}".format(o))
    out.append("'")
    return "".join(out)

# ---------------------------------------------------------------------
# Core parser
# ---------------------------------------------------------------------
def parse_script_lump_bytes(lump_bytes: bytes):
    """
    Parse a binary SCRIPTxx lump and return a list of dialog dicts.
    Each dict matches the layout:
    { speaker:int, dropitem:int, checkitem:[3], link:int, name:str, voice:str, backpic:str, text:str,
      choices: [ { giveitem, needitem[3], needamount[3], text, yes, link, log, no }, ... ] }
    """
    if not lump_bytes:
        return []

    total_len = len(lump_bytes)
    # Be permissive: parse as many full entries as present
    count = total_len // MAPDIALOG_SIZE

    dialogs = []
    off = 0
    for i in range(count):
        if off + MAPDIALOG_SIZE > total_len:
            break

        base = lump_bytes[off: off + MAPDIALOG_SIZE]
        idx = 0

        # helper to read a signed 4-byte little-endian integer
        def r_i():
            nonlocal idx
            val = struct.unpack_from('<i', base, idx)[0]
            idx += 4
            return val

        # read header fields
        speaker = r_i()
        dropitem = r_i()
        checkitem0 = r_i()
        checkitem1 = r_i()
        checkitem2 = r_i()
        link = r_i()

        name = _read_cstring(base, idx, 16); idx += 16
        voice = _read_cstring(base, idx, 8); idx += 8
        backpic = _read_cstring(base, idx, 8); idx += 8
        text = _read_cstring(base, idx, 320); idx += 320

        # read choices
        choices = []
        for c in range(CHOICES_PER_DIALOG):
            giveitem = r_i()
            need0 = r_i()
            need1 = r_i()
            need2 = r_i()
            needamount0 = r_i()
            needamount1 = r_i()
            needamount2 = r_i()

            text_choice = _read_cstring(base, idx, 32); idx += 32
            yes_msg = _read_cstring(base, idx, 80); idx += 80
            link_choice = r_i()
            logid = struct.unpack_from('<i', base, idx)[0]; idx += 4
            no_msg = _read_cstring(base, idx, 80); idx += 80

            choice = {
                "giveitem": giveitem,
                "needitem": [need0, need1, need2],
                "needamount": [needamount0, needamount1, needamount2],
                "text": text_choice,
                "yes": yes_msg,
                "link": link_choice,
                "log": logid,
                "no": no_msg
            }
            choices.append(choice)

        dialog = {
            "speaker": speaker,
            "dropitem": dropitem,
            "checkitem": [checkitem0, checkitem1, checkitem2],
            "link": link,
            "name": name,
            "voice": voice,
            "backpic": backpic,
            "text": text,
            "choices": choices
        }
        dialogs.append(dialog)
        off += MAPDIALOG_SIZE

    return dialogs

# ---------------------------------------------------------------------
# Higher-level: scan WAD entries and build Lua text
# ---------------------------------------------------------------------
SCRIPT_RE = re.compile(r'^SCRIPT(\d{2})$', re.IGNORECASE)
LOG_RE = re.compile(r'^LOG(\d+)$', re.IGNORECASE)

def collect_script_and_log_lumps(src_wadio):
    """
    Walk src_wadio.entries and collect:
      - scripts: mapping "SCRIPT00" -> bytes
      - logs: mapping int -> text
    src_wadio must provide .entries (list-like) and .read(name) -> bytes
    """
    scripts = {}
    logs = {}

    for entry in getattr(src_wadio, "entries", []):
        name = (entry.name if isinstance(entry.name, str) else entry.name.decode("ascii", errors="ignore")).upper().rstrip("\x00")
        try:
            data = src_wadio.read(name)
        except Exception:
            continue

        m = SCRIPT_RE.match(name)
        if m:
            scripts[name] = data
            continue

        m2 = LOG_RE.match(name)
        if m2:
            lid = int(m2.group(1))
            try:
                txt = data.decode('latin-1').rstrip('\x00')
            except Exception:
                txt = data.decode('utf-8', errors='replace').rstrip('\x00')
            logs[lid] = txt
            continue

    return scripts, logs

def build_lua_from_parsed(scripts_parsed: dict, logs: dict) -> str:
    """
    Build a Lua source string representing the parsed data.
    scripts_parsed: dict of scriptname -> [list of dialog dicts]
    logs: dict of int -> text
    """
    lines = []
    lines.append("-- Generated by strife_dialogs.py")
    lines.append("-- Contains tables: scripts (indexed by SCRIPTxx) and logs (indexed by number).")
    lines.append("")
    lines.append("doom.scripts = {}")
    lines.append("")

    for sname in sorted(scripts_parsed.keys()):
        dialogs = scripts_parsed[sname]
        lines.append(f"doom.scripts[{_lua_quote(sname)}] = {{")
        lines.append("  dialogs = {")
        for d in dialogs:
            # header
            lines.append("    {")
            lines.append(f"      speaker = {d['speaker']},")
            lines.append(f"      dropitem = {d['dropitem']},")
            lines.append("      checkitem = {" + ", ".join(str(x) for x in d["checkitem"]) + "},")
            lines.append(f"      link = {d['link']},")
            lines.append(f"      name = {_lua_quote(d['name'])},")
            lines.append(f"      voice = {_lua_quote(d['voice'])},")
            lines.append(f"      backpic = {_lua_quote(d['backpic'])},")
            lines.append(f"      text = {_lua_quote(d['text'])},")
            # choices
            lines.append("      choices = {")
            for ch in d["choices"]:
                lines.append("        {")
                lines.append(f"          giveitem = {ch['giveitem']},")
                lines.append("          needitem = {" + ", ".join(str(x) for x in ch['needitem']) + "},")
                lines.append("          needamount = {" + ", ".join(str(x) for x in ch['needamount']) + "},")
                lines.append(f"          text = {_lua_quote(ch['text'])},")
                lines.append(f"          yes = {_lua_quote(ch['yes'])},")
                lines.append(f"          link = {ch['link']},")
                lines.append(f"          log = {ch['log']},")
                lines.append(f"          no = {_lua_quote(ch['no'])},")
                lines.append("        },")
            lines.append("      },")  # end choices
            lines.append("    },")  # end dialog
        lines.append("  },")  # end dialogs
        lines.append("}")  # end script entry
        lines.append("")

    # logs
    lines.append("strife.logs = {")
    for k in sorted(logs.keys()):
        lines.append(f"  [{k}] = {_lua_quote(logs[k])},")
    lines.append("}")
    lines.append("")
    lines.append("return strife")
    return "\n".join(lines)

# ---------------------------------------------------------------------
# Public convenience wrapper (call this from process_special_lumps)
# ---------------------------------------------------------------------
def parse_and_emit_strife_scripts(src_wad, out_wad, src_wadio, out_lump_name: str = OUT_LUMP_NAME):
    """
    Scan src_wadio for SCRIPTxx and LOG## lumps, parse them and add a Lua lump
    to out_wad.data with the generated Lua source. Optionally write a .lua file
    in the current working directory (OUT_FILE_NAME).
    Returns: tuple (num_scripts_parsed, num_logs_parsed)
    """
    scripts_bytes, logs = collect_script_and_log_lumps(src_wadio)

    if not scripts_bytes and not logs:
        print("No SCRIPTxx or LOG## lumps found.")
        return 0, 0

    scripts_parsed = {}
    for name, data in scripts_bytes.items():
        parsed = parse_script_lump_bytes(data)
        scripts_parsed[name.upper()] = parsed
        print(f"Parsed {len(parsed)} dialogs from {name}")

    lua_text = build_lua_from_parsed(scripts_parsed, logs)
    lua_bytes = lua_text.encode('utf-8')

    # add to out_wad.data
    try:
        out_wad.data[out_lump_name] = Lump(lua_bytes)
        out_wad.data[out_lump_name].name = out_lump_name
        print(f"Inserted {out_lump_name} into out_wad.data (size {len(lua_bytes)} bytes)")
    except Exception as e:
        print(f"Failed to insert {out_lump_name} into out_wad.data: {e}")

    return len(scripts_parsed), len(logs)
