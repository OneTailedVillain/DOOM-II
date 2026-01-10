"""
PK3/ZIP processing functions.
"""

import os
import re
import zipfile
import tempfile
from pathlib import Path
from modules.wad_processor import (
    make_fw_sequence, convert_exmx_maps, create_cutscene_graphics,
    patch_linedefs_add, process_udmf_map_linedefs,
    convert_flat_to_graphic, is_doom1_wad
)
from modules.lua_generator import generate_lua_for_pk3
from modules.utils import CUTSCENE_GRAPHICS
from omg import WAD

def search_pk3_files(pk3_path, search_patterns=None):
    """
    Search through PK3 files (renamed ZIPs) for key data points using ZDoom folder structure.
    """
    if search_patterns is None:
        search_patterns = [
            r'.*\.wad$',
            r'.*\.pk3$',
            r'maps/.*\.wad$',
            r'textures/.*\.(png|jpg|jpeg|pcx)$',
            r'sprites/.*\.(png|jpg|jpeg|pcx)$',
            r'sounds/.*\.(wav|ogg|mp3|flac)$',
            r'music/.*\.(mid|mus|ogg|mp3|flac)$',
            r'graphics/.*\.(png|jpg|jpeg|pcx)$',
            r'actors/.*\.(txt|decorate)$',
            r'zscript/.*\.(txt|zs)$',
            r'acs/.*\.(src|o)$',
            r'voices/.*\.(wav|ogg|mp3)$',
            r'patches/.*\.(png|jpg|jpeg|pcx)$',
            r'flats/.*\.(png|jpg|jpeg|pcx)$',
            r'hires/.*\.(png|jpg|jpeg|pcx)$',
            r'models/.*\.(md2|md3|obj)$',
            r'shaders/.*\.(glsl|shader)$',
            r'.*\.deh$',
            r'.*\.bex$',
        ]
    
    results = {
        'pk3_files': [],
        'search_patterns': search_patterns,
        'matches': {},
        'file_types': {},
        'total_files': 0,
        'largest_files': []
    }
    
    compiled_patterns = []
    for pattern in search_patterns:
        try:
            compiled_patterns.append(re.compile(pattern, re.IGNORECASE))
        except re.error as e:
            print(f"Warning: Invalid regex pattern '{pattern}': {e}")
            continue
    
    def search_single_pk3(pk3_file):
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
                    for i, pattern in enumerate(compiled_patterns):
                        if pattern.search(file_path):
                            match_type = search_patterns[i]
                            pk3_results['matches'].append({
                                'path': file_path,
                                'type': match_type,
                                'size': None
                            })
                            
                            file_ext = Path(file_path).suffix.lower()
                            results['file_types'][file_ext] = results['file_types'].get(file_ext, 0) + 1
                            
                            try:
                                zip_info = pk3_zip.getinfo(file_path)
                                results['largest_files'].append({
                                    'path': file_path,
                                    'pk3': str(pk3_file),
                                    'size': zip_info.file_size,
                                    'compressed_size': zip_info.compress_size
                                })
                            except KeyError:
                                pass
                            break
                
                results['largest_files'].sort(key=lambda x: x['size'], reverse=True)
                results['largest_files'] = results['largest_files'][:20]
                
        except zipfile.BadZipFile:
            print(f"Warning: {pk3_file} is not a valid ZIP/PK3 file")
            return None
        except Exception as e:
            print(f"Error reading {pk3_file}: {e}")
            return None
            
        return pk3_results
    
    if os.path.isfile(pk3_path) and pk3_path.lower().endswith('.pk3'):
        pk3_result = search_single_pk3(pk3_path)
        if pk3_result:
            results['pk3_files'].append(pk3_result)
            results['matches'][pk3_path] = pk3_result['matches']
    
    elif os.path.isdir(pk3_path):
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
        
        matches_by_type = {}
        for match in pk3_info['matches']:
            match_type = match['type']
            if match_type not in matches_by_type:
                matches_by_type[match_type] = []
            matches_by_type[match_type].append(match['path'])
        
        for match_type, paths in matches_by_type.items():
            print(f"    {match_type}: {len(paths)} files")
            for path in paths[:5]:
                print(f"      - {path}")
            if len(paths) > 5:
                print(f"      ... and {len(paths) - 5} more")
    
    if results['file_types']:
        print(f"\nFILE TYPE SUMMARY:")
        for file_type, count in sorted(results['file_types'].items(), key=lambda x: x[1], reverse=True):
            if file_type:
                print(f"  {file_type or 'no ext'}: {count} files")
    
    if results['largest_files']:
        print(f"\nLARGEST FILES (top {min(10, len(results['largest_files']))}):")
        for file_info in results['largest_files'][:10]:
            print(f"  {file_info['path']} ({file_info['size']:,} bytes)")

def process_pk3_file(src_pk3_path, out_pk3_path):
    """Process a PK3 file with WAD-like operations and Lua generation."""
    print(f"Processing PK3: {src_pk3_path}")
    
    with tempfile.TemporaryDirectory() as temp_dir:
        with zipfile.ZipFile(src_pk3_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
        
        wad_files_processed = 0
        lua_content_lines = []
        
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = os.path.join(root, file)
                
                if file.lower().endswith('.wad'):
                    try:
                        print(f"  Processing WAD: {file}")
                        wad = WAD()
                        wad.from_file(file_path)
                        
                        created = make_fw_sequence(wad, wad)
                        if created > 0:
                            print(f"    Created {created} FWATER textures")
                        
                        converted = convert_exmx_maps(wad, wad, file_path)
                        if converted > 0:
                            print(f"    Converted {converted} ExMx maps")
                        
                        graphics_created = create_cutscene_graphics(wad)
                        if graphics_created > 0:
                            print(f"    Created {graphics_created} cutscene graphics")
                        
                        patch_linedefs_add(wad, 941)
                        print("    Patched linedef specials (+941)")
                        
                        for map_name in wad.maps:
                            wad.maps[map_name] = process_udmf_map_linedefs(wad.maps[map_name], 941)
                        
                        wad_lua = generate_lua_for_pk3(wad)
                        if wad_lua.strip():
                            lua_content_lines.append(f"-- From {file}")
                            lua_content_lines.append(wad_lua)
                            lua_content_lines.append("")
                        
                        wad.to_file(file_path)
                        wad_files_processed += 1
                        
                    except Exception as e:
                        print(f"    Error processing WAD {file}: {e}")
        
        lua_dir = os.path.join(temp_dir, 'Lua')
        if lua_content_lines and not os.path.exists(lua_dir):
            os.makedirs(lua_dir)
        
        if lua_content_lines:
            mapdata_content = '\n'.join(lua_content_lines)
            mapdata_path = os.path.join(temp_dir, 'MapData.lua')
            with open(mapdata_path, 'w') as f:
                f.write(mapdata_content)
            print(f"  Created MapData.lua with {len(lua_content_lines)} lines")
        
        if lua_content_lines:
            lua_file_path = os.path.join(lua_dir, 'AutoGeneratedMaps.lua')
            with open(lua_file_path, 'w') as f:
                f.write(mapdata_content)
            print(f"  Created Lua/AutoGeneratedMaps.lua")
        
        graphics_dir = os.path.join(temp_dir, 'Graphics')
        if not os.path.exists(graphics_dir):
            os.makedirs(graphics_dir)
        
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = os.path.join(root, file)
                if file.lower().endswith('.wad'):
                    continue
                    
                for flat_name, graphic_name in CUTSCENE_GRAPHICS:
                    if file.upper() == flat_name:
                        try:
                            with open(file_path, 'rb') as f:
                                flat_data = f.read()
                            
                            if len(flat_data) >= 4096:
                                from modules.wad_processor import convert_flat_to_graphic
                                graphic_lump = convert_flat_to_graphic(flat_data, graphic_name)
                                graphic_path = os.path.join(graphics_dir, graphic_name)
                                with open(graphic_path, 'wb') as f:
                                    f.write(graphic_lump.data)
                                print(f"  Created Graphics/{graphic_name} from loose flat {file}")
                        except Exception as e:
                            print(f"  Error converting loose flat {file}: {e}")
        
        with zipfile.ZipFile(out_pk3_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(temp_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, temp_dir)
                    zipf.write(file_path, arcname)
        
        print(f"  Processed {wad_files_processed} WAD files")
        print(f"  Created PK3: {out_pk3_path}")

def wad_to_pk3(wad, pk3_path):
    """
    Convert a WAD to PK3 format with proper directory structure.
    """
    print(f"Converting WAD to PK3: {pk3_path}")
    
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
    
    alt_lua_names = {
        'DOOM': 'DoomMarker',
        'ENDM': 'Endoom',
        'DEH': 'DehLanguageBex',
    }

    alt_soc_names = {
        'MAPS': 'SOC_DOOMMAP',
    }
    
    with tempfile.TemporaryDirectory() as temp_dir:
        with zipfile.ZipFile(pk3_path, 'w', zipfile.ZIP_DEFLATED) as pk3:
            for map_name, map_data in wad.maps.items():
                temp_wad = WAD()
                temp_wad.maps[map_name] = map_data
                temp_wad_path = os.path.join(temp_dir, f"{map_name}.wad")
                temp_wad.to_file(temp_wad_path)
                pk3.write(temp_wad_path, f"Maps/{map_name}.wad")
                print(f"  Added map: Maps/{map_name}.wad")
            
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
            
            lua_lumps = {}
            soc_lumps = {}
            player_sprite_lumps = {}
            p_skin_lump = None
            player_sprite_states = ['STND', 'WALK', 'FIRE', 'FLSH', 'PAIN', 'DYIN', 'DEAD', 'GIBN', 'GIBD']
            
            for group_name, group in groups.items():
                for lump_name, lump in group.items():
                    if group_name == 'maps':
                        continue
                    
                    if lump_name.startswith('LUA_'):
                        lua_lumps[lump_name] = lump
                        continue
                    if lump_name.startswith('SOC_'):
                        soc_lumps[lump_name] = lump
                        continue
                    
                    if lump_name == 'P_SKIN':
                        p_skin_lump = lump
                        continue
                    
                    if group_name == 'Data':
                        is_player_sprite = False
                        for state in player_sprite_states:
                            if lump_name.startswith(state):
                                if len(lump_name) > len(state):
                                    next_char = lump_name[len(state)]
                                    if next_char in 'ABCDEFGHIJKLMNOPQRSTUVW':
                                        is_player_sprite = True
                                        break
                        
                        if is_player_sprite:
                            player_sprite_lumps[lump_name] = lump
                            continue
                    
                    path_prefix = pathlookup.get(group_name, '')
                    if path_prefix:
                        full_path = f"{path_prefix}{lump_name}"
                    else:
                        full_path = lump_name
                    
                    pk3.writestr(full_path, lump.data)
                    print(f"  Added {full_path}")
            
            for lua_name, lua_lump in lua_lumps.items():
                lua_filename = lua_name[4:] if lua_name.startswith('LUA_') else lua_name
                if lua_filename in alt_lua_names:
                    lua_filename = alt_lua_names[lua_filename]
                pk3.writestr(f"Lua/{lua_filename}.lua", lua_lump.data)
                print(f"  Added Lua/{lua_filename}.lua")
            
            for soc_name, soc_lump in soc_lumps.items():
                soc_filename = soc_name[4:] if soc_name.startswith('SOC_') else soc_name
                if soc_filename in alt_soc_names:
                    soc_filename = alt_soc_names[soc_filename]
                pk3.writestr(f"SOC/{soc_filename}", soc_lump.data)
                print(f"  Added SOC/{soc_filename}")
            
            if p_skin_lump or player_sprite_lumps:
                print("  Adding player sprites to Skins/ directory structure...")
                
                if p_skin_lump:
                    pk3.writestr("Skins/1 - P_SKIN/P_SKIN", p_skin_lump.data)
                    print(f"    Added Skins/1 - P_SKIN/P_SKIN")
                
                if player_sprite_lumps:
                    for sprite_name, sprite_lump in player_sprite_lumps.items():
                        pk3.writestr(f"Skins/2 - Sprites/{sprite_name}", sprite_lump.data)
                        print(f"    Added Skins/2 - Sprites/{sprite_name}")
    
    print(f"Created PK3: {pk3_path}")