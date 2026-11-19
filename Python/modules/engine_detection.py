import os
import struct
from pathlib import Path


def _read_wad_lump_names(source_path):
    """Return the lump names from a PWAD/IWAD, if the file is a WAD."""
    path = Path(source_path)
    if not path.exists() or not path.is_file():
        return []

    try:
        with open(path, "rb") as handle:
            header = handle.read(12)
            if len(header) < 12:
                return []

            magic = header[:4]
            if magic not in {b"PWAD", b"IWAD"}:
                return []

            num_lumps = int.from_bytes(header[4:8], "little")
            dir_offset = int.from_bytes(header[8:12], "little")
            if num_lumps <= 0 or dir_offset <= 0:
                return []

            handle.seek(dir_offset)
            names = []
            for _ in range(num_lumps):
                entry = handle.read(16)
                if len(entry) < 16:
                    break
                name_bytes = entry[8:16]
                if not name_bytes:
                    continue
                name = name_bytes.split(b"\x00", 1)[0].decode("latin-1", errors="replace")
                if name:
                    names.append(name)
            return names
    except OSError:
        return []



def detect_engine_mode(source_path, force_engine=None):
    """Detect which engine should process a WAD.

    Order of precedence:
    1. explicit force_engine value
    2. content-based detection from known engine markers
    3. default to Doom
    """
    if force_engine:
        normalized = str(force_engine).strip().lower()

        if normalized in {"strife", "strife-engine", "strife_engine"}:
            return "strife"
        if normalized in {"heretic", "heretic-engine", "heretic_engine"}:
            return "heretic"
        if normalized in {"doom", "doom2", "srb2", "default", "auto"}:
            return "doom"

    if not source_path:
        return "doom"

    path = Path(source_path)
    if not path.exists():
        return "doom"

    if path.suffix.lower() not in {".wad", ".pwad", ".iwad"}:
        return "doom"

    lump_names = _read_wad_lump_names(path)
    if not lump_names:
        return "doom"

    normalized_names = [name.upper() for name in lump_names]

    strife_markers = {
        "SCRIPT00",
        "ENDSTRF",
    }

    heretic_markers = {
        "M_HTIC",
        "M_GAUNT",
        "M_WAND",
        "M_MACE",
        "M_CBOW",
        "M_GOLD",
        "M_SKL00",
    }

    if any(
        marker in name
        for marker in strife_markers
        for name in normalized_names
    ):
        return "strife"

    if any(name in heretic_markers for name in normalized_names):
        return "heretic"

    return "doom"

