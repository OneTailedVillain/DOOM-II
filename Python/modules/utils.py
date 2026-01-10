"""
Utility functions and constants for WAD processing.
"""

import re
import struct
import math
import os
import shutil
from pathlib import Path
from subprocess import Popen, PIPE

# Constants
DESIRED_COLORMAP_SIZE = 256 * 32  # 8192 bytes (256*32)

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

def safe_add_lump_to_data(dst_wad, name, lump_obj):
    """Safely add a lump to WAD data, avoiding name conflicts."""
    name = name.upper()
    data = dst_wad.data
    if name not in data:
        data[name] = lump_obj
        return name
    i = 1
    while True:
        new_name = f"{name}_{i}"
        if new_name not in data:
            data[new_name] = lump_obj.copy()
            return new_name
        i += 1

def exmx_to_mapnum(episode: int, mapnum: int):
    """Convert ExMx to sequential MAP numbers starting from 01"""
    return (episode - 1) * 9 + mapnum  # 9 maps per episode (including secret levels)

def next_free_mapname(wad_obj, start=41, upper=99):
    """Find next available MAP name in WAD."""
    for n in range(start, upper + 1):
        name = f"MAP{n:02d}"
        if name not in wad_obj.maps:
            return name, n
    return None, None

def find_fluidsynth():
    """Find fluidsynth executable on Windows and other systems"""
    if shutil.which("fluidsynth"):
        return "fluidsynth"
    
    # Common Windows installation paths
    windows_paths = [
        "C:\\Program Files\\FluidSynth\\fluidsynth.exe",
        "C:\\Program Files (x86)\\FluidSynth\\fluidsynth.exe",
        os.path.expanduser("~\\AppData\\Local\\Programs\\FluidSynth\\fluidsynth.exe"),
    ]
    
    for path in windows_paths:
        if os.path.exists(path):
            return path
    
    # Try to find via registry or common locations
    try:
        import winreg
        try:
            key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\FluidSynth")
            install_path, _ = winreg.QueryValueEx(key, "InstallPath")
            exe_path = os.path.join(install_path, "fluidsynth.exe")
            if os.path.exists(exe_path):
                return exe_path
        except:
            pass
    except ImportError:
        pass  # Not on Windows
    
    return None

def find_ffmpeg():
    """Find ffmpeg executable"""
    if shutil.which("ffmpeg"):
        return "ffmpeg"
    
    # Common Windows paths
    windows_paths = [
        "C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe",
        "C:\\Program Files (x86)\\ffmpeg\\bin\\ffmpeg.exe",
    ]
    
    for path in windows_paths:
        if os.path.exists(path):
            return path
    
    return None

def find_soundfont():
    """Search for soundfont files"""
    possible_paths = [
        "midisoundfont.sf2",
        "C:\\ProgramData\\soundfonts\\default.sf2"
    ]
    
    for path in possible_paths:
        if os.path.exists(path):
            print(f"Found soundfont: {path}")
            return path
    
    # Try to find via fluidsynth config
    try:
        fluidsynth_path = find_fluidsynth()
        if fluidsynth_path:
            result = Popen([fluidsynth_path, "-a", "file"], stdout=PIPE, stderr=PIPE)
            output, _ = result.communicate()
            for line in output.decode('utf-8', errors='ignore').split('\n'):
                if '.sf2' in line:
                    path = line.strip()
                    if os.path.exists(path):
                        print(f"Found soundfont: {path}")
                        return path
    except:
        pass
    
    print("Warning: No soundfont found. MIDI to OGG conversion will not work.")
    return None