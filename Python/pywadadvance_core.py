#!/usr/bin/env python3
"""
Main script for preparing WADs for use in the SRB2 DOOM port.
Uses modular components for better organization.
"""

import sys
import os
import argparse
from pathlib import Path

# Import modular components
from modules.utils import *
# Stuff like this is getting messy with pyright, so ignore type issues here
# It's pretty much guaranteed that the modules exist in our modules/ directory
from modules.wad_processor import * # pyright: ignore[reportGeneralTypeIssues]
from modules.dehacked_parser import *
from modules.lua_generator import *
from modules.midi_converter import * # pyright: ignore[reportGeneralTypeIssues]
from modules.pk3_processor import *
from modules.umapinfo_processor import *
# Import PC speaker converter
from modules.pcspeaker_converter import replace_ds_with_dp

# Add UMAPINFO parser import
try:
    from wadmod_umapinfo import UmapInfoParser
    HAS_UMAPINFO = True
except ImportError:
    print("Warning: UMAPINFO parser module not found. UMAPINFO parsing will be disabled.")
    HAS_UMAPINFO = False

# Attempt to import OMGIFOL
try:
    from omg import WAD, WadIO, Lump, Flat, Graphic
except Exception as e:
    raise SystemExit("Please install omgifol (pip install omgifol). Import error: %s" % e)

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

def main(src_path: str, out_path: str, deh_files=None, options=None):
    """
    Main function with support for external DEH/BEX files and options.
    
    Args:
        src_path: Source WAD/PK3 path or directory
        out_path: Output WAD/PK3 path
        deh_files: List of (name, data) tuples from external DEH/BEX files
        options: Dictionary of options from GUI
    """
    if options is None:
        options = {}
    
    print("Loading:", src_path)
    
    # Handle DEH-only case (no WAD, just DEH/BEX files)
    if os.path.isfile(src_path) and src_path.lower().endswith(('.deh', '.bex')):
        all_deh_files = [(os.path.basename(src_path), open(src_path, 'rb').read())]
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

    # --- PC Speaker sound conversion (if requested) ---
    if options.get('use_pcspeaker', False):
        print("Converting PC Speaker (DP) sounds to DMX format...")
        converted = replace_ds_with_dp(out_wad, options.get('pcspeaker_sample_rate', 11025))
        print(f"Converted {converted} PC speaker sounds to DMX format")
    
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

    # --- patch pegging flags (ensure DOOM-like midtexture behavior in SRB2) ---
    if options.get('normalize_pegging', True):
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

    # Create player sprites from PLAY lumps
    if options.get('player_sprites', True):
        print("Creating player sprites from PLAY lumps...")
        sprites_created = create_player_sprites_from_play_lumps(src_wad, out_wad, "johndoom")

    if options.get('stcfn_uppercase_to_lowercase', True):
        print("Copying STCFN uppercase graphics to lowercase letter codes...")
        append_stcfn_uppercase_to_lowercase(out_wad)

    # MIDI to OGG conversion (optional)
    if options.get('midi_to_ogg', False):
        print("Converting MIDI to OGG...")
        try:
            process_midi_conversion(out_wad, out_wad)
        except Exception as e:
            print(f"MIDI to OGG conversion failed: {e}")

    if out_path.lower().endswith('.pk3'):
        # Output as PK3
        wad_to_pk3(out_wad, out_path)
    else:
        # Output as WAD
        out_wad.to_file(out_path)
        print(f"Wrote PWAD to {out_path}")

    print("Done.")

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description='Prepare WADs for use in SRB2 Doom port'
    )
    
    parser.add_argument('source', help='Source WAD/PK3 path or directory')
    parser.add_argument('output', help='Output WAD/PK3 path')
    parser.add_argument('deh_files', nargs='*', help='Additional DEH/BEX files')
    
    # Sound options
    parser.add_argument('--use-dp', '--use-pcspeaker', 
                       action='store_true',
                       help='Replace DS sounds with DP (PC speaker) conversions')
    parser.add_argument('--pcspeaker-sample-rate',
                       type=int, default=11025,
                       choices=[11025, 22050],
                       help='Sample rate for PC speaker conversions (default: 11025)')
    
    # Other options
    parser.add_argument('--no-normalize-pegging',
                       action='store_false', dest='normalize_pegging',
                       help='Disable normalization of pegging flags')
    parser.add_argument('--no-player-sprites',
                       action='store_false', dest='player_sprites',
                       help='Disable creation of player sprites from PLAY lumps')
    parser.add_argument('--midi-to-ogg',
                       action='store_true',
                       help='Convert MIDI music to OGG format')
    
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()
    
    # Convert args to options dictionary
    options = {
        'use_pcspeaker': args.use_dp,
        'pcspeaker_sample_rate': args.pcspeaker_sample_rate,
        'normalize_pegging': args.normalize_pegging,
        'player_sprites': args.player_sprites,
        'midi_to_ogg': args.midi_to_ogg,
    }
    
    # Load DEH/BEX files if provided
    deh_files = []
    for deh_file in args.deh_files:
        try:
            with open(deh_file, 'rb') as f:
                deh_files.append((os.path.basename(deh_file), f.read()))
        except Exception as e:
            print(f"Error reading DEH/BEX file {deh_file}: {e}")
    
    main(args.source, args.output, deh_files, options)