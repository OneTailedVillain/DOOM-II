#!/usr/bin/env python3
"""
Build script for DOOM-II project.
Processes WAD files and creates distributable packages.
"""

import os
import sys
import shutil
import zipfile
import subprocess
from pathlib import Path
import argparse

# File names
output_wad_name = "freedoom2.pk3"
python_zip_name = "doompy.zip"

def get_version():
	"""Try to get version from git tag, fallback to '0.0.0'"""
	try:
		result = subprocess.run(
			['git', 'describe', '--tags', '--abbrev=0'],
			capture_output=True,
			text=True,
			cwd=Path(__file__).parent.absolute()
		)
		if result.returncode == 0:
			return result.stdout.strip()
	except Exception:
		pass
	return "0.0.0"

def needs_rebuild(output_file, source_dirs):
	"""Check if output file needs rebuilding based on source modification times"""
	if not output_file.exists():
		return True
	
	output_mtime = output_file.stat().st_mtime
	
	for source_dir in source_dirs:
		if not source_dir.exists():
			continue
		for root, dirs, files in os.walk(source_dir):
			# Skip cache directories
			dirs[:] = [d for d in dirs if d not in {'__pycache__', '.pytest_cache', 'build', '.git'}]
			for file in files:
				file_path = Path(root) / file
				if file_path.stat().st_mtime > output_mtime:
					return True
	
	return False

def resolve_output(default_path, override_arg, expected_ext):
	"""Return overridden output path if valid, otherwise default."""
	if override_arg and override_arg.strip():
		override = Path(override_arg)

		# Only accept override if it matches expected extension
		if override.suffix.lower() == expected_ext.lower():
			return override

	return default_path

def main():
	parser = argparse.ArgumentParser(description='Build DOOM-II mod package')
	parser.add_argument('--output-dir', '-o', default='build', help='Output directory (default: build)')
	parser.add_argument('--python-exe', '-p', default=sys.executable, help='Python executable path')
	parser.add_argument('--version', '-v', default=None, help='Version number (auto-detects from git tag if not specified)')
	parser.add_argument('--force', '-f', action='store_true', help='Force rebuild everything (skip incremental checks)')
	parser.add_argument('--clean', action='store_true', help='Clean build directory before building')
	parser.add_argument(
		'--buildto',
		nargs=3,
		metavar=('WAD', 'PK3', 'PYTHON'),
		default=["", "", ""],
		help='Override output paths for (WAD, PK3, Python zip). Use "" to keep default.'
	)
	args = parser.parse_args()
	
	output_dir = Path(args.output_dir)
	script_dir = Path(__file__).parent.absolute()
	
	# Handle --clean flag
	if args.clean:
		if output_dir.exists():
			print(f"Cleaning {output_dir}...")
			shutil.rmtree(output_dir)
	
	# Get version
	version = args.version or get_version()
	output_pk3_name = f"SL_DOOMII-v{version}.pk3"
	moddex_pk3_name = f"CL_DOOMPortModdingExample-v{version}.pk3"
	
	# Configuration
	base_wad_dir = script_dir / "BaseWAD"
	python_dir = script_dir / "Python"
	wad_override, pk3_override, py_override = args.buildto

	output_wad = resolve_output(
		output_dir / output_wad_name,
		wad_override,
		".pk3"
	)

	output_pk3 = resolve_output(
		output_dir / output_pk3_name,
		pk3_override,
		".pk3"
	)

	moddex_pk3 = resolve_output(
		output_dir / moddex_pk3_name,
		pk3_override,
		".pk3"
	)

	python_zip = resolve_output(
		output_dir / python_zip_name,
		py_override,
		".zip"
	)

	# Ensure parent directories exist for overridden outputs
	for path in [output_wad, output_pk3, python_zip]:
		path.parent.mkdir(parents=True, exist_ok=True)

	print("\n" + "="*50)
	print("Build Script for the SRB2 Doom port")
	print("="*50)
	print(f"Version:		 {version}")
	print(f"Python:		  {args.python_exe}")
	print(f"Output Directory: {output_dir}")
	print(f"Incremental:	 {not args.force}")
	print()
	
	# Create output directory
	output_dir.mkdir(parents=True, exist_ok=True)
	
	# Step 1: Process Pre-packaged WAD
	# Do this so I don't FORGET next time I post to the Message Board. GOD
	print("[1/3] Processing pre-packaged WAD...")
	base_wad_file = next(base_wad_dir.glob("*.wad"), None)

	if not base_wad_file:
		print(f"ERROR: No WAD file found in {base_wad_dir}")
		return 1

	# Check dependencies for WAD processing
	wad_dependencies = [
		python_dir,					# Python converter scripts
		base_wad_file,				 # The source WAD file itself
	]

	# Check if rebuild needed (unless --force)
	if not args.force and not needs_rebuild(output_wad, wad_dependencies):
		print("✓ Skipped (output is up-to-date)\n")
	else:
		try:
			# Also consider if the base WAD itself changed
			if base_wad_file.stat().st_mtime > output_wad.stat().st_mtime:
				print(f"  Source WAD modified: {base_wad_file.name}")
			
			result = subprocess.run(
				[args.python_exe, str(python_dir / "pywadadvance_core.py"), 
				str(base_wad_file), str(output_wad)],
				cwd=script_dir,
				check=True,
				capture_output=False
			)
			print("WAD processing complete\n")
		except subprocess.CalledProcessError as e:
			print(f"ERROR: pywadadvance_core.py failed: {e}")
			return 1
		except Exception as e:
			print(f"ERROR: Failed to run pywadadvance_core.py: {e}")
			return 1
	
	# Check if rebuild needed (unless --force)
	# Check the **PYTHON DIR** instead of the base WAD dir,
	# Since touching the WAD builder needs to reflect upon the output WAD.
	if not args.force and not needs_rebuild(output_wad, [python_dir]):
		print("✓ Skipped (output is up-to-date)\n")
	else:
		try:
			result = subprocess.run(
				[args.python_exe, str(python_dir / "pywadadvance_core.py"), 
				 str(base_wad_file), str(output_wad)],
				cwd=script_dir,
				check=True,
				capture_output=False
			)
			print("WAD processing complete\n")
		except subprocess.CalledProcessError as e:
			print(f"ERROR: pywadadvance_core.py failed: {e}")
			return 1
		except Exception as e:
			print(f"ERROR: Failed to run pywadadvance_core.py: {e}")
			return 1
	
	# Step 2: Build PK3
	print("[2/3] Building PK3 package...")
	
	# Source directories for incremental check
	source_dirs = [
		script_dir / "src",
	]
	
	# Check if rebuild needed (unless --force)
	if not args.force and not needs_rebuild(output_pk3, source_dirs + [output_dir / output_wad_name]):
		print("✓ Skipped (output is up-to-date)\n")
	else:
		# Create temporary staging directory
		temp_pk3_dir = output_dir / "pk3_temp"
		if temp_pk3_dir.exists():
			shutil.rmtree(temp_pk3_dir)
		temp_pk3_dir.mkdir(parents=True)
		
		# Copy all contents from src/ to staging directory
		src_dir = script_dir / "src"
		if src_dir.exists():
			for item in src_dir.iterdir():
				if item.is_dir():
					shutil.copytree(item, temp_pk3_dir / item.name, ignore=shutil.ignore_patterns('__pycache__'))
					print(f"  Added folder: {item.name}")
				elif item.is_file():
					shutil.copy2(item, temp_pk3_dir / item.name)
					print(f"  Added file: {item.name}")
		else:
			print(f"WARNING: src/ directory not found at {src_dir}")
		
		# Create PK3 as ZIP
		try:
			if output_pk3.exists():
				output_pk3.unlink()
			
			with zipfile.ZipFile(output_pk3, 'w', zipfile.ZIP_DEFLATED) as zf:
				for root, dirs, files in os.walk(temp_pk3_dir):
					for file in files:
						file_path = Path(root) / file
						arcname = file_path.relative_to(temp_pk3_dir)
						zf.write(file_path, arcname)
			
			print(f"PK3 package created: {output_pk3.name}\n")
		except Exception as e:
			print(f"ERROR: Failed to create PK3: {e}")
			return 1
		finally:
			# Cleanup
			if temp_pk3_dir.exists():
				shutil.rmtree(temp_pk3_dir)
	
	# Step 2: Build PK3
	print("[2.5/3] Building Modding Example...")
	
	# Source directories for incremental check
	source_dirs = [
		script_dir / "Modding Example",
	]
	
	# Check if rebuild needed (unless --force)
	if not args.force and not needs_rebuild(moddex_pk3, source_dirs + [output_dir / output_wad_name]):
		print("✓ Skipped (output is up-to-date)\n")
	else:
		# Create temporary staging directory
		temp_pk3_dir = output_dir / "pk3_temp"
		if temp_pk3_dir.exists():
			shutil.rmtree(temp_pk3_dir)
		temp_pk3_dir.mkdir(parents=True)
		
		# Copy all contents from src/ to staging directory
		src_dir = script_dir / "Modding Example"
		if src_dir.exists():
			for item in src_dir.iterdir():
				if item.is_dir():
					shutil.copytree(item, temp_pk3_dir / item.name, ignore=shutil.ignore_patterns('__pycache__'))
					print(f"  Added folder: {item.name}")
				elif item.is_file():
					shutil.copy2(item, temp_pk3_dir / item.name)
					print(f"  Added file: {item.name}")
		else:
			print(f"WARNING: Modding Example/ directory not found at {src_dir}")
		
		# Create PK3 as ZIP
		try:
			if moddex_pk3.exists():
				moddex_pk3.unlink()
			
			with zipfile.ZipFile(moddex_pk3, 'w', zipfile.ZIP_DEFLATED) as zf:
				for root, dirs, files in os.walk(temp_pk3_dir):
					for file in files:
						file_path = Path(root) / file
						arcname = file_path.relative_to(temp_pk3_dir)
						zf.write(file_path, arcname)
			
			print(f"PK3 package created: {moddex_pk3.name}\n")
		except Exception as e:
			print(f"ERROR: Failed to create PK3: {e}")
			return 1
		finally:
			# Cleanup
			if temp_pk3_dir.exists():
				shutil.rmtree(temp_pk3_dir)
	
	# Step 3: Create Python archive
	print("[3/3] Creating Python archive...")
	
	# Check if rebuild needed (unless --force)
	if not args.force and not needs_rebuild(python_zip, [python_dir]):
		print("✓ Skipped (output is up-to-date)\n")
	else:
		try:
			if python_zip.exists():
				python_zip.unlink()
			
			with zipfile.ZipFile(python_zip, 'w', zipfile.ZIP_DEFLATED) as zf:
				for root, dirs, files in os.walk(python_dir):
					# Skip __pycache__ and other non-essential directories
					dirs[:] = [d for d in dirs if d not in {'__pycache__', '.pytest_cache'}]
					
					for file in files:
						if not file.endswith(('.pyc', '.pyo', '.pyd')):
							file_path = Path(root) / file
							arcname = file_path.relative_to(script_dir)
							zf.write(file_path, arcname)
			
			print(f"Python archive created: {python_zip.name}\n")
		except Exception as e:
			print(f"ERROR: Failed to create Python archive: {e}")
			return 1
	
	# Summary
	print("="*50)
	print("Build Complete!")
	print("="*50)
	print(f"Output files are in the {args.output_dir} directory:")
	print(f"  - {output_wad_name} (Pre-packaged WAD PK3)")
	print(f"  - {output_pk3_name} (DOOM Engine PK3)")
	print(f"  - {moddex_pk3_name} (Modding Example PK3)")
	print(f"  - {python_zip_name} (WAD processing Python scripts)")
	if args.force:
		print("\n(All steps rebuilt with --force)")
	print()
	
	return 0

if __name__ == "__main__":
	sys.exit(main())
