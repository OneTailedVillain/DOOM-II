#!/usr/bin/env python3
"""
Extract doomednum values from all Lua object definition files.
Useful for validating that all expected doomednums exist in the codebase.
"""

import os
import re
from pathlib import Path
from typing import Dict, List, Set


class DoomedNumExtractor:
    """Extract doomednum values from Lua files."""
    
    def __init__(self, objects_path: str):
        """
        Initialize the extractor.
        
        Args:
            objects_path: Path to the Lua/Definitions/Objects/ directory
        """
        self.objects_path = Path(objects_path)
        self.doomednums: Dict[int, str] = {}  # doomednum -> file path
        self.errors: List[str] = []
        self.pattern = re.compile(r'doomednum\s*=\s*(\d+)')
    
    def extract_all(self) -> Dict[int, str]:
        """
        Recursively extract all doomednums from Lua files.
        
        Returns:
            Dictionary mapping doomednum to file path
        """
        if not self.objects_path.exists():
            raise FileNotFoundError(f"Objects path not found: {self.objects_path}")
        
        for lua_file in self.objects_path.rglob("*.lua"):
            self._extract_from_file(lua_file)
        
        return self.doomednums
    
    def _extract_from_file(self, file_path: Path) -> None:
        """
        Extract all doomednums from a single Lua file.
        
        Args:
            file_path: Path to the Lua file
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                matches = self.pattern.findall(content)
                if matches:
                    for match in matches:
                        doomednum = int(match)
                        
                        # Check for duplicates
                        if doomednum in self.doomednums:
                            self.errors.append(
                                f"Duplicate doomednum {doomednum} found in {file_path}. "
                                f"Already defined in {self.doomednums[doomednum]}"
                            )
                        
                        self.doomednums[doomednum] = str(file_path.relative_to(self.objects_path.parent))
        except Exception as e:
            self.errors.append(f"Error reading {file_path}: {str(e)}")
    
    def check_against_expected(self, expected_doomednums: Set[int]) -> Dict[str, List[int]]:
        """
        Check extracted doomednums against a set of expected values.
        
        Args:
            expected_doomednums: Set of doomednums that should exist
            
        Returns:
            Dictionary with keys 'missing' and 'unexpected'
        """
        actual_doomednums = set(self.doomednums.keys())
        
        return {
            'missing': sorted(expected_doomednums - actual_doomednums),
            'unexpected': sorted(actual_doomednums - expected_doomednums),
        }
    
    def print_summary(self) -> None:
        """Print a summary of extracted doomednums."""
        print(f"\nFound {len(self.doomednums)} doomednums:")
        for doomednum in sorted(self.doomednums.keys()):
            print(f"  {doomednum:4d} -> {self.doomednums[doomednum]}")
        
        if self.errors:
            print(f"\n{len(self.errors)} error(s) encountered:")
            for error in self.errors:
                print(f"  - {error}")


def main():
    """Main function to demonstrate usage."""
    # Path to the Objects directory
    script_dir = Path(__file__).parent
    workspace_root = script_dir.parent
    objects_path = workspace_root / "Lua" / "Definitions" / "Objects"
    
    # Extract doomednums
    extractor = DoomedNumExtractor(str(objects_path))
    doomednums = extractor.extract_all()
    
    # Print results
    extractor.print_summary()
    
    # Example: Check against expected doomednums
    # You can modify this with your expected values
    expected = {
    5, 6, 7, 8, 9, 13, 16, 17, 18, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
    60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2010, 2011,
    2012, 2013, 2014, 2015, 2018, 2019, 2022, 2023, 2024, 2025, 2026, 2028,
    2035, 2045, 2046, 2047, 2048, 2049, 3001, 3002, 3003, 3004, 3005, 3006 }
    results = extractor.check_against_expected(expected)
    
    if results['missing']:
        print(f"\nMissing doomednums: {results['missing']}")
    if results['unexpected']:
        print(f"\nUnexpected doomednums: {results['unexpected']}")
    
    if not results['missing'] and not results['unexpected']:
        print(f"\n✓ All doomednums match expected values!")


if __name__ == "__main__":
    main()
