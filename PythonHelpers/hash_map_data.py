#!/usr/bin/env python3
"""Print every map's SHA-256 hash for registering titles in map_names.json."""

import argparse
import sys
import tempfile
import zipfile
from pathlib import Path
import hashlib

from omg import WAD

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(WORKSPACE_ROOT))

from Python.modules.map_hashes import hash_map_data

def hash_mapset(maps):
	"""Generate a SHA-256 hash representing all maps in a WAD."""
	combined = hashlib.sha256()

	for map_name, map_data in sorted(maps.items()):
		combined.update(map_name.upper().encode("ascii"))
		combined.update(hash_map_data(map_data).encode("ascii"))

	return combined.hexdigest()

def get_wad_map_hashes(wad_path: Path) -> tuple[list[tuple[str, str]], str]:
	wad = WAD()
	wad.from_file(str(wad_path))
	maps = getattr(wad, "maps")

	map_hashes = [
		(map_name, hash_map_data(map_data))
		for map_name, map_data in maps.items()
	]

	return map_hashes, hash_mapset(maps)


def get_pk3_map_hashes(pk3_path: Path) -> list[tuple[str, str, str]]:
	"""Return (archive path, map name, hash) for maps in WADs inside a PK3."""
	results = []
	with zipfile.ZipFile(pk3_path, "r") as archive, tempfile.TemporaryDirectory() as temp_dir:
		map_wad_paths = [
			entry for entry in archive.namelist()
			if Path(entry).suffix.lower() == ".wad"
		]

		for index, entry in enumerate(map_wad_paths):
			wad_path = Path(temp_dir) / f"map_{index}.wad"
			wad_path.write_bytes(archive.read(entry))

			wad = WAD()
			wad.from_file(str(wad_path))
			maps = getattr(wad, "maps")
			for map_name, map_data in maps.items():
				results.append((entry, map_name, hash_map_data(map_data)))

	return results


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("archive", type=Path, help="Input .wad or .pk3 file")
	args = parser.parse_args()

	if not args.archive.is_file():
		parser.error(f"file not found: {args.archive}")

	extension = args.archive.suffix.lower()
	if extension == ".wad":
		map_hashes, mapset_hash = get_wad_map_hashes(args.archive)

		for map_name, digest in map_hashes:
			print(f"{map_name}\t{digest}")

		print(f"\nMapset SHA-256:\t{mapset_hash}")
		print(f"JSON key:\tmapset_{mapset_hash}")
	elif extension == ".pk3":
		map_hashes, mapset_hash = get_pk3_map_hashes(args.archive)

		for map_name, digest in map_hashes:
			print(f"{map_name}\t{digest}")

		print(f"\nMapset SHA-256:\t{mapset_hash}")
		print(f"JSON key:\tmapset_{mapset_hash}")
	else:
		parser.error("archive must have a .wad or .pk3 extension")

	return 0


if __name__ == "__main__":
	raise SystemExit(main())
