"""
UMAPINFO processing functions.
"""

import re

def process_umapinfo_lump(umapinfo_bytes, wad):
    """
    Process UMAPINFO lump and store parsed data in WAD object.
    This is a placeholder - actual implementation would depend on the UmapInfoParser.
    """
    try:
        # This is a simplified version - actual implementation would use UmapInfoParser
        umapinfo_text = umapinfo_bytes.decode('latin-1', errors='replace')
        
        if not hasattr(wad, 'umapinfo_data'):
            wad.umapinfo_data = {}
        
        # Simple parsing - just extract map names and properties
        lines = umapinfo_text.split('\n')
        current_map = None
        current_data = {}
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('//'):
                continue
            
            if line.startswith('[') and line.endswith(']'):
                if current_map:
                    wad.umapinfo_data[current_map] = current_data
                current_map = line[1:-1]
                current_data = {'mapname': current_map}
            elif '=' in line and current_map:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip().strip('"')
                current_data[key] = value
        
        if current_map:
            wad.umapinfo_data[current_map] = current_data
        
        print(f"Parsed UMAPINFO: {len(wad.umapinfo_data)} maps")
        
    except Exception as e:
        print(f"Error processing UMAPINFO: {e}")