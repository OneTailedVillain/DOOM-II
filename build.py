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
import re

# File names
DEFAULT_OUTPUT_WAD_NAME = "freedoom2.pk3"
DEFAULT_PYTHON_ZIP_NAME = "doompy.zip"

DEFAULT_PKG_PREFIX = "SL"
DEFAULT_PKG_NAME = "DoomII"
DEFAULT_MOD_PREFIX = "CL"
DEFAULT_MOD_NAME = "ExtraClasses"

def get_version():
    """Try to get version from git tag, fallback to '0.0.0'."""
    try:
        result = subprocess.run(
            ["git", "describe", "--tags", "--abbrev=0"],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.absolute(),
        )
        if result.returncode == 0:
            tag = result.stdout.strip()
            return tag[1:] if tag.startswith("v") else tag
    except Exception:
        pass
    return "0.0.0"


def needs_rebuild(output_file, source_paths):
    """Check if output file needs rebuilding based on source modification times."""
    if not output_file.exists():
        return True

    output_mtime = output_file.stat().st_mtime

    skip_dirs = {"__pycache__", ".pytest_cache", "build", ".git", ".vscode"}

    for source_path in source_paths:
        if not source_path.exists():
            continue

        if source_path.is_file():
            if source_path.stat().st_mtime > output_mtime:
                return True
            continue

        for root, dirs, files in os.walk(source_path):
            dirs[:] = [d for d in dirs if d not in skip_dirs]
            for file in files:
                file_path = Path(root) / file
                if file_path.stat().st_mtime > output_mtime:
                    return True

    return False


def tokenize(expr):
    """Tokenize a build-flag expression."""
    tokens = []
    i = 0
    while i < len(expr):
        ch = expr[i]
        if ch.isspace():
            i += 1
            continue
        if ch in "()":
            tokens.append(ch)
            i += 1
        elif ch == "!":
            tokens.append("!")
            i += 1
        elif expr[i : i + 2] == "&&":
            tokens.append("&&")
            i += 2
        elif expr[i : i + 2] == "||":
            tokens.append("||")
            i += 2
        else:
            j = i
            while j < len(expr) and (expr[j].isalnum() or expr[j] == "_"):
                j += 1
            if j > i:
                tokens.append(expr[i:j])
                i = j
            else:
                i += 1
    return tokens


def should_skip_meta(meta, key, defined_flags):
    """Return True if a skip meta expression evaluates true."""
    value = meta.get(key)

    if value is None:
        return False

    def eval_one(expr):
        # blank means unconditional skip
        if not expr:
            return True
        return evaluate_expression(expr, defined_flags)

    if isinstance(value, list):
        return any(eval_one(expr) for expr in value)

    return eval_one(value)


def evaluate_expression(expr, defined_flags):
    """Evaluate a build-flag expression."""
    tokens = tokenize(expr)
    processed = []
    for token in tokens:
        if token in defined_flags:
            processed.append("True")
        elif token == "&&":
            processed.append("and")
        elif token == "||":
            processed.append("or")
        elif token == "!":
            processed.append("not")
        elif token in {"(", ")"}:
            processed.append(token)
        else:
            processed.append("False")

    try:
        return bool(eval(" ".join(processed), {"__builtins__": {}}, {}))
    except Exception:
        return False


def preprocess_file(file_path, defined_flags, directive_prefix="--#",
                    preserve_line_numbers=True, collect_defines=None):
    """
    Preprocess a file with build flags and directives.
    If collect_defines is a set, any --#define FLAG encountered (in an active block)
    will have FLAG added to the set.
    """
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    active_stack = []
    block_stack = []

    # First pass: identify blocks that are "empty" (only comments/directives).
    to_remove = set()
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if stripped.startswith(directive_prefix):
            directive = stripped[len(directive_prefix) :].strip()
            parts = directive.split(None, 1)
            cmd = parts[0] if parts else ""
            expr = parts[1] if len(parts) > 1 else ""

            if cmd in ("ifdef", "ifndef"):
                cond = evaluate_expression(expr, defined_flags)
                if cmd == "ifndef":
                    cond = not cond
                block_stack.append([i, cond, [], False])
            elif cmd == "endif":
                if block_stack:
                    start_line, condition, content, has_alt_branch = block_stack.pop()

                    all_ignorable = True
                    for content_line in content:
                        content_stripped = content_line.strip()
                        if not content_stripped:
                            continue
                        if content_stripped.startswith(directive_prefix):
                            if content_stripped.startswith(f"{directive_prefix}ignoredir") or content_stripped.startswith(
                                f"{directive_prefix}ignorefile"
                            ):
                                continue
                            all_ignorable = False
                            break
                        if content_stripped.startswith("--") and directive_prefix != "--#":
                            continue
                        if content_stripped.startswith("#") and directive_prefix == "#":
                            continue
                        all_ignorable = False
                        break

                    if all_ignorable and not has_alt_branch:
                        to_remove.update(range(start_line, i + 1))
            elif cmd in ("elif", "else"):
                if block_stack:
                    block_stack[-1][3] = True
        else:
            if block_stack:
                block_stack[-1][2].append(line)

        i += 1

    # Second pass: actually process the file.
    output = []
    i = 0

    try:
        while i < len(lines):
            line = lines[i]

            if i in to_remove:
                if preserve_line_numbers:
                    output.append(" " * len(line.rstrip("\n")) + ("\n" if line.endswith("\n") else ""))
                i += 1
                continue

            stripped = line.strip()

            if stripped.startswith(directive_prefix):
                directive = stripped[len(directive_prefix) :].strip()
                parts = directive.split(None, 1)
                cmd = parts[0] if parts else ""
                expr = parts[1] if len(parts) > 1 else ""

                if cmd in ("ifdef", "ifndef"):
                    cond = evaluate_expression(expr, defined_flags)
                    if cmd == "ifndef":
                        cond = not cond
                    active_stack.append((cond, cond))
                    if preserve_line_numbers:
                        output.append(" " * len(line.rstrip("\n")) + ("\n" if line.endswith("\n") else ""))

                elif cmd == "elif":
                    if active_stack:
                        active, matched = active_stack[-1]
                        if matched:
                            active_stack[-1] = (False, True)
                        else:
                            cond = evaluate_expression(expr, defined_flags)
                            active_stack[-1] = (cond, matched or cond)
                    if preserve_line_numbers:
                        output.append(" " * len(line.rstrip("\n")) + ("\n" if line.endswith("\n") else ""))

                elif cmd == "else":
                    if active_stack:
                        active, matched = active_stack[-1]
                        active_stack[-1] = (not matched, True)
                    if preserve_line_numbers:
                        output.append(" " * len(line.rstrip("\n")) + ("\n" if line.endswith("\n") else ""))

                elif cmd == "endif":
                    if active_stack:
                        active_stack.pop()
                    if preserve_line_numbers:
                        output.append(" " * len(line.rstrip("\n")) + ("\n" if line.endswith("\n") else ""))

                elif cmd == "define":
                    # Record the flag if we are collecting defines and are in an active block
                    if collect_defines is not None and all(active for active, _ in active_stack):
                        flag_name = expr.split(None, 1)[0]  # everything before optional '='
                        collect_defines.add(flag_name)
                    # Preserve line numbers or skip the line entirely
                    if preserve_line_numbers:
                        output.append(" " * len(line.rstrip("\n")) + ("\n" if line.endswith("\n") else ""))
                    # else: skip the line (output nothing)

                else:
                    include = all(active for active, matched in active_stack)
                    if include:
                        output.append(line)

            else:
                include = all(active for active, matched in active_stack)
                if include:
                    output.append(line)

            i += 1

    except Exception as e:
        raise RuntimeError(
            f"Lua preprocessing error at line {i + 1} in {file_path}:\n"
            f"{type(e).__name__}: {e}\n"
            f"Line content: {lines[i].rstrip()}"
        ) from e

    return "".join(output)


def should_preprocess(file_path):
    """Return True for files that should be directive-processed."""
    return file_path.suffix.lower() == ".lua" or file_path.name in {"S_SKIN", "MUSICDEF.txt", "SOC_PLAY.ini", "ANIMDEFS.txt"}


def parse_ignores(content):
    """Parse ignore directives from preprocessed content."""
    ignored_dirs = set()
    ignored_files = set()

    for line in content.splitlines():
        stripped = line.strip()
        if stripped.startswith("--#ignoredir"):
            path = stripped[len("--#ignoredir") :].strip().strip('"')
            ignored_dirs.add(Path(path).as_posix().rstrip("/"))
        elif stripped.startswith("--#ignorefile"):
            path = stripped[len("--#ignorefile") :].strip().strip('"')
            ignored_files.add(Path(path).as_posix().rstrip("/"))

    return ignored_dirs, ignored_files


def parse_meta(content):
    """Parse meta and branch directives."""
    meta = {}

    meta_re = re.compile(r"^--#meta\s+(\S+)(?:\s+(.*))?$")
    branch_re = re.compile(r"^--#(branchvar|branchpattern)\s+(.*)$")

    for line in content.splitlines():
        stripped = line.strip()

        match = meta_re.match(stripped)
        if match:
            key = match.group(1).lower()
            value = (match.group(2) or "").strip()

            if value and (
                (value.startswith('"') and value.endswith('"'))
                or (value.startswith("'") and value.endswith("'"))
            ):
                value = value[1:-1]

            if key in meta:
                if isinstance(meta[key], list):
                    meta[key].append(value)
                else:
                    meta[key] = [meta[key], value]
            else:
                meta[key] = value
            continue

        match = branch_re.match(stripped)
        if match:
            key = match.group(1).lower()
            value = match.group(2).strip()
            meta[key] = value

    return meta


def process_source_tree(source_root, defined_flags, ignore_buildflags=False, preserve_line_numbers=True):
    """Preprocess all relevant files under a source root."""
    processed_files = {}

    if ignore_buildflags:
        return processed_files

    exclude_dirs = {"__pycache__", ".pytest_cache", "build", ".git", ".vscode"}
    for root, dirs, files in os.walk(source_root):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        root_path = Path(root)
        for file in files:
            file_path = root_path / file
            if should_preprocess(file_path):
                directive_prefix = "--#" if file_path.suffix.lower() == ".lua" else "#"
                processed_files[file_path] = preprocess_file(
                    file_path,
                    defined_flags,
                    directive_prefix=directive_prefix,
                    preserve_line_numbers=preserve_line_numbers,
                )

    return processed_files


def resolve_branch_ignores(source_root, processed_files, meta):
    """
    Auto-ignore sibling directories using:
    --#branchvar doom.currentGame
    --#branchpattern Lua/*Data
    """
    branchvar = meta.get("branchvar")
    pattern = meta.get("branchpattern")

    if not branchvar or not pattern:
        return set()

    init_path = source_root / "init.lua"
    content = processed_files.get(init_path)
    if not content:
        return set()

    assign_re = re.compile(
        rf"{re.escape(branchvar)}\s*=\s*['\"]([^'\"]+)['\"]"
    )

    match = assign_re.search(content)
    if not match:
        return set()

    active_value = match.group(1)

    ignored = set()

    glob_pattern = str(source_root / pattern)

    for path in Path(source_root).glob(pattern):
        if not path.is_dir():
            continue

        name = path.name

        if "*" not in pattern:
            continue

        prefix, suffix = pattern.split("*", 1)

        if name == f"{active_value}{suffix}":
            continue

        ignored.add(path.relative_to(source_root).as_posix())

    return ignored


def rel_path_str(path, root):
    return path.relative_to(root).as_posix()


def is_relpath_under(path_str, parent_str):
    """True if path_str is exactly parent_str or lies underneath it."""
    path = Path(path_str)
    parent = Path(parent_str)
    return path == parent or path.is_relative_to(parent)


def build_pk3(
    source_root,
    output_path,
    defined_flags,
    default_prefix,
    default_name,
    default_forwho,
    default_forwhat,
    ignore_buildflags=False,
    preserve_line_numbers=True,
    extra_exclude_dirs=None,
    extra_exclude_extensions=None,
):
    """Build a PK3 from a source directory."""
    exclude_dirs = {"__pycache__", ".pytest_cache", "build", ".git", ".vscode"}
    if extra_exclude_dirs:
        exclude_dirs |= set(extra_exclude_dirs)

    exclude_extensions = {".pyc", ".pyo", ".pyd"}
    if extra_exclude_extensions:
        exclude_extensions |= set(extra_exclude_extensions)

    processed_files = process_source_tree(
        source_root,
        defined_flags,
        ignore_buildflags=ignore_buildflags,
        preserve_line_numbers=preserve_line_numbers,
    )

    meta = {}
    ignored_dirs = set()
    ignored_files = set()

    if not ignore_buildflags:
        init_path = source_root / "init.lua"
        if init_path in processed_files:
            init_content = processed_files[init_path]
            meta = parse_meta(init_content)
            ignored_dirs, ignored_files = parse_ignores(init_content)

            ignored_dirs |= resolve_branch_ignores(
                source_root,
                processed_files,
                meta,
            )

    prefix = meta.get("prefix", default_prefix)
    name = meta.get("name", default_name)
    forwho = meta.get("forwho", default_forwho)
    forwhat = meta.get("forwhat", default_forwhat)

    return {
        "processed_files": processed_files,
        "meta": meta,
        "ignored_dirs": ignored_dirs,
        "ignored_files": ignored_files,
        "prefix": prefix,
        "name": name,
        "forwho": forwho,
        "forwhat": forwhat,
        "exclude_dirs": exclude_dirs,
        "exclude_extensions": exclude_extensions,
    }


def write_pk3(source_root, output_path, package_info, verbose=True):
    """Write a PK3 zip archive from a source root and package info."""
    processed_files = package_info["processed_files"]
    ignored_dirs = package_info["ignored_dirs"]
    ignored_files = package_info["ignored_files"]
    exclude_dirs = package_info["exclude_dirs"]
    exclude_extensions = package_info["exclude_extensions"]

    if output_path.exists():
        output_path.unlink()

    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED, compresslevel=1) as zf:
        for root, dirs, files in os.walk(source_root):
            root_path = Path(root)
            rel_root = root_path.relative_to(source_root)

            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            if ignored_dirs:
                skip_dir = any(is_relpath_under(rel_root.as_posix(), ignored_dir) for ignored_dir in ignored_dirs)
                if skip_dir:
                    dirs[:] = []
                    continue

            for file in files:
                file_path = root_path / file
                arcname = file_path.relative_to(source_root).as_posix()

                if file_path.suffix.lower() in exclude_extensions:
                    continue
                if arcname in ignored_files:
                    continue

                if file_path in processed_files:
                    zf.writestr(arcname, processed_files[file_path])
                    if verbose:
                        print(f"  Processed file: {arcname}")
                else:
                    zf.write(file_path, arcname)

    return output_path


def resolve_output(default_path, override_arg, expected_ext):
    """Return overridden output path if valid, otherwise default."""
    if override_arg and override_arg.strip():
        override = Path(override_arg)
        if override.suffix.lower() == expected_ext.lower():
            return override
    return default_path


def build_versioned_pk3_name(prefix, name, version):
    """Build a PK3 filename using the common naming pattern."""
    return f"{prefix}_{name}-v{version}.pk3"


def main():
    parser = argparse.ArgumentParser(description="Build DOOM-II mod package")
    parser.add_argument("--output-dir", "-o", default="build", help="Output directory (default: build)")
    parser.add_argument("--python-exe", "-p", default=sys.executable, help="Python executable path")
    parser.add_argument("--version", "-v", default=None, help="Version number (auto-detects from git tag if not specified)")
    parser.add_argument("--force", "-f", action="store_true", help="Force rebuild everything (skip incremental checks)")
    parser.add_argument("--clean", action="store_true", help="Clean build directory before building")
    parser.add_argument(
        "--buildto",
        nargs=3,
        metavar=("WAD", "PK3", "PYTHON"),
        default=["", "", ""],
        help='Override output paths for (WAD, PK3, Python zip). Use "" to keep default.',
    )
    parser.add_argument("--define", "-D", action="append", default=[], help="Define build flags (can be used multiple times)")
    parser.add_argument("--no-preserve-linenums", action="store_true", help="Remove deleted lines instead of replacing them with whitespace")
    parser.add_argument("--ignore_buildflags", action="store_true", help="Ignore build flags and include all code (for debugging)")
    args = parser.parse_args()

    script_dir = Path(__file__).parent.absolute()
    init_path = script_dir / "src" / "init.lua"

    # Start with CLI defines
    defined_flags = set(args.define)

    # First pass: extract flags from init.lua by using the preprocessor with collect_defines
    if init_path.exists() and not args.ignore_buildflags:
        collect = set()
        # Preprocess init.lua with current flags (CLI only) but collect defines
        preprocess_file(
            init_path,
            defined_flags,
            directive_prefix="--#",
            preserve_line_numbers=not args.no_preserve_linenums,
            collect_defines=collect,
        )
        # Add all collected flags to defined_flags
        defined_flags.update(collect)

    if args.define:
        print(f"Command-line defines: {args.define}")
        print(f"Flags defined in init.lua: {sorted(defined_flags - set(args.define))}")
        print(f"Final defined flags: {sorted(defined_flags)}")
    else:
        print(f"Flags defined in init.lua: {sorted(defined_flags)}")

    output_dir = Path(args.output_dir)

    # Handle --clean flag
    if args.clean:
        if output_dir.exists():
            print(f"Cleaning {output_dir}...")
            shutil.rmtree(output_dir)

    # Get version
    version = args.version or get_version()

    # Configuration
    base_wad_dir = script_dir / "BaseWAD"
    python_dir = script_dir / "Python"
    src_dir = script_dir / "src"
    modding_dir = script_dir / "ExtraClasses"

    global_meta = {}

    if not args.ignore_buildflags:
        init_path = src_dir / "init.lua"
        if init_path.exists():
            processed_init = preprocess_file(
                init_path,
                defined_flags,
                directive_prefix="--#",
                preserve_line_numbers=not args.no_preserve_linenums,
            )
            global_meta = parse_meta(processed_init)

    wad_override, pk3_override, py_override = args.buildto

    output_wad = resolve_output(output_dir / DEFAULT_OUTPUT_WAD_NAME, wad_override, ".pk3")
    output_pk3_default_name = build_versioned_pk3_name(DEFAULT_PKG_PREFIX, DEFAULT_PKG_NAME, version)
    output_mod_default_name = build_versioned_pk3_name(DEFAULT_MOD_PREFIX, DEFAULT_MOD_NAME, version)

    output_pk3 = resolve_output(output_dir / output_pk3_default_name, pk3_override, ".pk3")
    modding_pk3 = resolve_output(output_dir / output_mod_default_name, pk3_override, ".pk3")
    python_zip = resolve_output(output_dir / DEFAULT_PYTHON_ZIP_NAME, py_override, ".zip")

    # Ensure parent directories exist for overridden outputs
    for path in [output_wad, output_pk3, modding_pk3, python_zip]:
        path.parent.mkdir(parents=True, exist_ok=True)

    print("\n" + "=" * 50)
    print("Build Script for the SRB2 Doom port")
    print("=" * 50)
    print(f"Version:\t\t {version}")
    print(f"Python:\t\t  {args.python_exe}")
    print(f"Output Directory: {output_dir}")
    print(f"Incremental:\t {not args.force}")
    print()

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    # Step 1: Process Pre-packaged WAD
    print("[1/4] Processing pre-packaged WAD...")

    if should_skip_meta(global_meta, "skipwad", defined_flags):
        print("✓ Skipped (--#meta skipwad matched)\n")
    else:
        base_wad_file = next(base_wad_dir.glob("*.wad"), None)

        if not base_wad_file:
            print(f"ERROR: No WAD file found in {base_wad_dir}")
            return 1

        wad_dependencies = [python_dir, base_wad_file]

        if not args.force and not needs_rebuild(output_wad, wad_dependencies):
            print("✓ Skipped (output is up-to-date)\n")
        else:
            try:
                result = subprocess.run(
                    [
                        args.python_exe,
                        str(python_dir / "pywadadvance_core.py"),
                        str(base_wad_file),
                        str(output_wad),
                    ],
                    cwd=script_dir,
                    check=True,
                    capture_output=False,
                )
                print("WAD processing complete\n")
            except subprocess.CalledProcessError as e:
                print(f"ERROR: pywadadvance_core.py failed: {e}")
                return 1
            except Exception as e:
                print(f"ERROR: Failed to run pywadadvance_core.py: {e}")
                return 1

    # Step 2: Build PK3
    print("[2/4] Building PK3 package...")

    if should_skip_meta(global_meta, "skippk3", defined_flags):
        print("✓ Skipped (--#meta skippk3 matched)\n")
    else:

        source_dirs = [src_dir]

        if not args.force and not needs_rebuild(output_pk3, source_dirs + [output_wad]):
            print("✓ Skipped (output is up-to-date)\n")
        else:
            try:
                package_info = build_pk3(
                    src_dir,
                    output_pk3,
                    defined_flags=defined_flags,
                    default_prefix=DEFAULT_PKG_PREFIX,
                    default_name=DEFAULT_PKG_NAME,
                    default_forwho="DOOM-II",
                    default_forwhat="project",
                    ignore_buildflags=args.ignore_buildflags,
                    preserve_line_numbers=not args.no_preserve_linenums,
                )

                # Rebuild filename from parsed meta unless explicitly overridden
                if not pk3_override:
                    output_pk3 = output_dir / build_versioned_pk3_name(
                        package_info["prefix"],
                        package_info["name"],
                        version,
                    )

                print(
                    f"Final config: {package_info['prefix']}_{package_info['name']} "
                    f"for {package_info['forwho']} ({package_info['forwhat']})"
                )

                write_pk3(src_dir, output_pk3, package_info, verbose=False)
                print(f"PK3 package created: {output_pk3.name}\n")
            except Exception as e:
                print(f"ERROR: Failed to create PK3: {e}")
                return 1

    # Step 3: Build Modding Example
    print("[3/4] Building ExtraClasses...")

    mod_meta = {}
    if not args.ignore_buildflags:
        mod_init = modding_dir / "init.lua"
        if mod_init.exists():
            mod_meta = parse_meta(
                preprocess_file(
                    mod_init,
                    defined_flags,
                    directive_prefix="--#",
                    preserve_line_numbers=not args.no_preserve_linenums,
                )
            )

    if should_skip_meta(mod_meta, "skipmod", defined_flags):
        print("✓ Skipped (--#meta skipmod matched)\n")
    else:

        source_dirs = [modding_dir]

        if not args.force and not needs_rebuild(modding_pk3, source_dirs + [output_wad]):
            print("✓ Skipped (output is up-to-date)\n")
        else:
            try:
                package_info = build_pk3(
                    modding_dir,
                    modding_pk3,
                    defined_flags=defined_flags,
                    default_prefix=DEFAULT_MOD_PREFIX,
                    default_name=DEFAULT_MOD_NAME,
                    default_forwho="DOOM-II",
                    default_forwhat="extra classes",
                    ignore_buildflags=args.ignore_buildflags,
                    preserve_line_numbers=not args.no_preserve_linenums,
                )

                if not args.ignore_buildflags:
                    print(
                        f"Final config: {package_info['prefix']}_{package_info['name']} "
                        f"for {package_info['forwho']} ({package_info['forwhat']})"
                    )

                write_pk3(modding_dir, modding_pk3, package_info, verbose=False)
                print(f"PK3 package created: {modding_pk3.name}\n")
            except Exception as e:
                print(f"ERROR: Failed to create PK3: {e}")
                return 1

    # Step 4: Create Python archive
    print("[4/4] Creating Python archive...")

    if not args.force and not needs_rebuild(python_zip, [python_dir]):
        print("✓ Skipped (output is up-to-date)\n")
    else:
        try:
            if python_zip.exists():
                python_zip.unlink()

            with zipfile.ZipFile(python_zip, "w", zipfile.ZIP_DEFLATED) as zf:
                for root, dirs, files in os.walk(python_dir):
                    dirs[:] = [d for d in dirs if d not in {"__pycache__", ".pytest_cache"}]

                    for file in files:
                        if not file.endswith((".pyc", ".pyo", ".pyd")):
                            file_path = Path(root) / file
                            arcname = file_path.relative_to(script_dir).as_posix()
                            zf.write(file_path, arcname)

            print(f"Python archive created: {python_zip.name}\n")
        except Exception as e:
            print(f"ERROR: Failed to create Python archive: {e}")
            return 1

    # Summary
    print("=" * 50)
    print("Build Complete!")
    print("=" * 50)
    print(f"Output files are in the {args.output_dir} directory:")
    print(f"  - {output_wad.name if 'output_wad' in locals() else DEFAULT_OUTPUT_WAD_NAME} (Pre-packaged WAD PK3)")
    print(f"  - {output_pk3.name if 'output_pk3' in locals() else output_pk3_default_name} (DOOM Engine PK3)")
    print(f"  - {modding_pk3.name if 'modding_pk3' in locals() else output_mod_default_name} (Modding Example PK3)")
    print(f"  - {python_zip.name if 'python_zip' in locals() else DEFAULT_PYTHON_ZIP_NAME} (WAD processing Python scripts)")
    if args.force:
        print("\n(All steps rebuilt with --force)")
    print()

    return 0


if __name__ == "__main__":
    sys.exit(main())