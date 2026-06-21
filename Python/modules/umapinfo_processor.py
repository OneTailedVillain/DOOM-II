"""
MAPINFO Processor Module

This module provides functionality to parse, validate, and process both
UMAPINFO and classic ZDoom MAPINFO lumps from Doom engine games.
"""

import re
import json
from typing import Dict, List, Optional, Union, Any, Tuple
from dataclasses import dataclass, field, asdict
from enum import Enum


class MAPINFOError(Exception):
    """Custom exception for MAPINFO parsing errors."""
    pass


@dataclass
class BossAction:
    """Represents a boss action definition."""
    thingtype: str
    linespecial: int
    tag: int

    def __post_init__(self):
        self.tag = int(self.tag) if self.tag != 0 else 0


@dataclass
class EpisodeEntry:
    """Represents an episode menu entry."""
    patch: str
    name: str
    key: str


@dataclass
class MapDefinition:
    """
    Represents a single map definition, capable of holding both UMAPINFO
    and classic MAPINFO properties.
    """
    mapname: str
    # UMAPINFO / common fields
    levelname: Optional[str] = None
    author: Optional[str] = None
    label: Optional[Union[str, str]] = None          # "clear" special value
    levelpic: Optional[str] = None
    next: Optional[str] = None
    nextsecret: Optional[str] = None
    skytexture: Optional[str] = None
    music: Optional[str] = None
    exitpic: Optional[str] = None
    enterpic: Optional[str] = None
    partime: Optional[int] = None
    endgame: Optional[bool] = None
    endpic: Optional[str] = None
    endbunny: Optional[bool] = None
    endcast: Optional[bool] = None
    nointermission: Optional[bool] = None
    intertext: Optional[Union[str, List[str], str]] = None  # "clear" special
    intertextsecret: Optional[Union[str, List[str], str]] = None
    interbackdrop: Optional[str] = None
    intermusic: Optional[str] = None
    episode: Optional[Union[str, List[EpisodeEntry]]] = None  # "clear" or list
    bossactions: List[BossAction] = field(default_factory=list)

    # Additional fields common in classic MAPINFO
    levelnum: Optional[int] = None
    cluster: Optional[int] = None
    sky1: Optional[str] = None
    sky1scroll: Optional[float] = None
    sky2: Optional[str] = None
    sky2scroll: Optional[float] = None
    doublesky: Optional[bool] = None
    fade: Optional[str] = None
    outsidefog: Optional[str] = None
    titlepatch: Optional[str] = None
    cdtrack: Optional[int] = None
    cdid: Optional[int] = None
    bordertexture: Optional[str] = None
    nosoundclipping: Optional[bool] = None
    allowmonstertelefrags: Optional[bool] = None
    map07special: Optional[bool] = None
    baronspecial: Optional[bool] = None
    cyberdemonspecial: Optional[bool] = None
    spidermastermindspecial: Optional[bool] = None
    # ... many more possible; we store the rest in 'extra'

    # Catch‑all for any property not explicitly defined
    extra: Dict[str, Any] = field(default_factory=dict)

    def __post_init__(self):
        # Convert string special values to consistent format
        if self.label == "clear":
            self.label = "clear"
        if isinstance(self.intertext, str) and self.intertext.lower() == "clear":
            self.intertext = "clear"
        if isinstance(self.intertextsecret, str) and self.intertextsecret.lower() == "clear":
            self.intertextsecret = "clear"
        if self.episode == "clear":
            self.episode = "clear"
        elif isinstance(self.episode, str) and self.episode.lower() == "clear":
            self.episode = "clear"


class MAPINFOProcessor:
    """
    Main class for parsing and processing both UMAPINFO and classic ZDoom MAPINFO.
    """

    # Known valid keys for UMAPINFO validation
    UMAPINFO_KEYS = {
        'levelname', 'author', 'label', 'levelpic', 'next', 'nextsecret',
        'skytexture', 'music', 'exitpic', 'enterpic', 'partime', 'endgame',
        'endpic', 'endbunny', 'endcast', 'nointermission', 'intertext',
        'intertextsecret', 'interbackdrop', 'intermusic', 'episode',
        'bossaction', 'exitanim', 'enteranim', 'kex_finishedtaskid',
        'kex_intertextlocid', 'kex_episodefinishedactivityid'
    }

    # Valid thing types for boss actions
    VALID_THINGTYPES = {
        'BaronOfHell', 'Cyberdemon', 'SpiderMastermind', 'Fatso', 'Arachnotron',
        'HellKnight', 'Mancubus', 'Revenant', 'Cacodemon', 'PainElemental',
        'Archvile', 'Spectre', 'Demon', 'LostSoul', 'Zombieman', 'ShotgunGuy',
        'ChaingunGuy', 'Imp', 'WolfensteinSS', 'CommanderKeen', 'IconOfSin'
    }

    def __init__(self, text: str = None, format: str = 'auto'):
        """
        Initialize the processor with optional MAPINFO text.

        Args:
            text: Raw MAPINFO text to parse.
            format: 'umapinfo', 'mapinfo' (classic), or 'auto' (detect).
        """
        self.text = text
        self.maps: Dict[str, MapDefinition] = {}
        self.episode_order: List[str] = []
        self.current_map: Optional[str] = None
        self.current_definition: Optional[MapDefinition] = None
        self.format = format.lower()
        self._defaults = {}          # for defaultmap/adddefaultmap
        self._gamedefaults = {}      # for gamedefaults

        if text:
            self.parse()

    # ----------------------------------------------------------------------
    #  Public interface
    # ----------------------------------------------------------------------

    def parse(self) -> Dict[str, MapDefinition]:
        """Parse the text according to the detected or specified format."""
        if not self.text:
            return {}

        # Auto-detect format
        if self.format == 'auto':
            self.format = self._detect_format(self.text)

        if self.format == 'umapinfo':
            self._parse_umapinfo()
        elif self.format == 'mapinfo':
            self._parse_old_mapinfo()
        else:
            raise MAPINFOError(f"Unknown format: {self.format}")

        return self.maps

    def get_map(self, mapname: str) -> Optional[MapDefinition]:
        """Get a specific map definition by name."""
        return self.maps.get(mapname)

    def get_maps(self) -> Dict[str, MapDefinition]:
        """Get all map definitions."""
        return self.maps

    def validate(self) -> List[str]:
        """
        Validate the parsed data.
        Returns a list of warnings/errors.
        """
        warnings = []

        for mapname, mapdef in self.maps.items():
            # Check map name format
            if not re.match(r'^(E\dM\d+|MAP\d+)$', mapname):
                warnings.append(f"Map name '{mapname}' may be invalid for standard IWADs")

            # Check that next/nextsecret references exist
            if mapdef.next and mapdef.next not in self.maps:
                warnings.append(f"Map '{mapname}' references nonexistent next map: '{mapdef.next}'")
            if mapdef.nextsecret and mapdef.nextsecret not in self.maps:
                warnings.append(f"Map '{mapname}' references nonexistent secret map: '{mapdef.nextsecret}'")

            # Boss action validation
            for action in mapdef.bossactions:
                if action.thingtype not in self.VALID_THINGTYPES:
                    warnings.append(f"Map '{mapname}' uses unknown thingtype: '{action.thingtype}'")

            # Episode validation
            if isinstance(mapdef.episode, list):
                if len(mapdef.episode) > 8:
                    warnings.append(f"Map '{mapdef.mapname}' defines more than 8 episodes (max supported)")
                for ep in mapdef.episode:
                    if not ep.patch or not ep.name or not ep.key:
                        warnings.append(f"Map '{mapdef.mapname}' has incomplete episode definition: {ep}")

        return warnings

    def to_json(self) -> str:
        """Convert parsed data to JSON."""
        def serialize(obj):
            if hasattr(obj, '__dict__'):
                d = asdict(obj)
                # Convert special values
                for key in ['label', 'intertext', 'intertextsecret', 'episode']:
                    if key in d and d[key] == 'clear':
                        d[key] = '__clear__'
                return d
            if isinstance(obj, Enum):
                return obj.value
            return str(obj)

        data = {
            'maps': self.maps,
            'episode_order': self.episode_order
        }
        return json.dumps(data, default=serialize, indent=2)

    @classmethod
    def from_json(cls, json_str: str) -> 'MAPINFOProcessor':
        """Create a MAPINFOProcessor from JSON data."""
        data = json.loads(json_str)
        processor = cls()

        for mapname, mapdata in data['maps'].items():
            # Handle special values
            for key in ['label', 'intertext', 'intertextsecret', 'episode']:
                if key in mapdata and mapdata[key] == '__clear__':
                    mapdata[key] = 'clear'

            # Reconstruct bossactions
            if 'bossactions' in mapdata:
                bossactions = []
                for action in mapdata['bossactions']:
                    if isinstance(action, dict):
                        bossactions.append(
                            BossAction(
                                thingtype=action['thingtype'],
                                linespecial=action['linespecial'],
                                tag=action['tag']
                            )
                        )
                    else:
                        bossactions.append(action)
                mapdata['bossactions'] = bossactions

            # Reconstruct episodes
            if 'episode' in mapdata and isinstance(mapdata['episode'], list):
                episodes = []
                for ep in mapdata['episode']:
                    if isinstance(ep, dict):
                        episodes.append(
                            EpisodeEntry(
                                patch=ep['patch'],
                                name=ep['name'],
                                key=ep['key']
                            )
                        )
                    else:
                        episodes.append(ep)
                mapdata['episode'] = episodes

            processor.maps[mapname] = MapDefinition(**mapdata)

        processor.episode_order = data.get('episode_order', [])
        return processor

    def validate_map_names(self, iwad_type: str) -> List[str]:
        """Validate map names against an IWAD format."""
        warnings = []
        pattern = None
        if iwad_type.lower() == 'doom1':
            pattern = r'^E\d+M\d+$'
        elif iwad_type.lower() in ['doom2', 'chex']:
            pattern = r'^MAP\d+$'
        else:
            warnings.append(f"Unknown IWAD type: {iwad_type}")
            return warnings

        for mapname in self.maps.keys():
            if not re.match(pattern, mapname):
                warnings.append(
                    f"Map '{mapname}' doesn't match expected format for {iwad_type}"
                )
        return warnings

    # ----------------------------------------------------------------------
    #  Format detection
    # ----------------------------------------------------------------------

    def _detect_format(self, text: str) -> str:
        """Detect whether the text is UMAPINFO or classic MAPINFO."""
        # Normalize line endings
        lines = text.replace('\r\n', '\n').split('\n')
        for line in lines:
            line = line.strip()
            if not line or line.startswith('//'):
                continue
            # UMAPINFO starts with 'MAP' followed by name, then a '{' later
            if re.match(r'^MAP\s+[A-Za-z0-9_]+\s*$', line, re.IGNORECASE):
                # Check for an opening brace in the next non‑comment lines
                idx = lines.index(line) + 1
                while idx < len(lines):
                    nextline = lines[idx].strip()
                    if nextline and not nextline.startswith('//'):
                        if nextline == '{':
                            return 'umapinfo'
                        else:
                            # No brace -> old format
                            return 'mapinfo'
                    idx += 1
                # If we run out, assume UMAPINFO? But old format also could have no braces.
                # Heuristic: if the line after the map name contains a '=' or a quoted string, it's old.
                # For safety, we'll see if we find a '{' eventually.
                # If we don't find any '{' before the next map directive, it's old.
                # This is not perfect but works for most cases.
                return 'umapinfo'  # fallback
        # If no MAP directive found, default to UMAPINFO
        return 'umapinfo'

    # ----------------------------------------------------------------------
    #  UMAPINFO parser (unchanged, with minor adjustments)
    # ----------------------------------------------------------------------

    def _strip_comments(self, line: str) -> str:
        """Strip inline comments (//) from a line, respecting quotes."""
        in_quotes = False
        quote_char = None
        i = 0
        while i < len(line):
            char = line[i]
            if char in ['"', "'"] and (i == 0 or line[i-1] != '\\'):
                if not in_quotes:
                    in_quotes = True
                    quote_char = char
                elif char == quote_char:
                    in_quotes = False
                    quote_char = None
            if not in_quotes and char == '/' and i+1 < len(line) and line[i+1] == '/':
                return line[:i].strip()
            i += 1
        return line.strip()

    def _parse_umapinfo(self):
        """Parse UMAPINFO format (with braces)."""
        lines = self.text.replace('\r\n', '\n').split('\n')
        i = 0
        while i < len(lines):
            line = self._strip_comments(lines[i])
            if not line:
                i += 1
                continue

            map_match = re.match(r'^MAP\s+([A-Za-z0-9_]+)\s*$', line, re.IGNORECASE)
            if map_match:
                mapname = map_match.group(1)
                self.current_map = mapname
                self.current_definition = MapDefinition(mapname=mapname)
                self.maps[mapname] = self.current_definition
                i += 1
                if i < len(lines):
                    next_line = self._strip_comments(lines[i])
                    if next_line == '{':
                        i += 1
                        i = self._parse_umapinfo_contents(i, lines)
                    else:
                        raise MAPINFOError(f"Expected '{{' after MAP {mapname}, got: {next_line}")
                continue
            i += 1

    def _parse_umapinfo_contents(self, start_index: int, lines: List[str]) -> int:
        """Parse the inside of a UMAPINFO map block."""
        i = start_index
        brace_count = 1
        while i < len(lines) and brace_count > 0:
            line = self._strip_comments(lines[i])
            if not line:
                i += 1
                continue
            if line == '}':
                brace_count -= 1
                if brace_count == 0:
                    return i + 1
                i += 1
                continue
            if line == '{':
                brace_count += 1
                i += 1
                continue

            # Multiline intertext/intertextsecret
            if re.match(r'^(intertext|intertextsecret)\s*=', line, re.IGNORECASE):
                key = line.split("=", 1)[0].strip().lower()
                value_part = line.split("=", 1)[1].strip()
                text_lines = []
                if value_part:
                    m = re.match(r'"(.*)"\s*,?$', value_part)
                    if m:
                        text_lines.append(m.group(1))
                i += 1
                while i < len(lines):
                    nextline = self._strip_comments(lines[i])
                    if not nextline:
                        i += 1
                        continue
                    m = re.match(r'^"(.*)"\s*,?$', nextline)
                    if not m:
                        break
                    text_lines.append(m.group(1))
                    i += 1
                self._set_value(key, "\n".join(text_lines))
                continue

            self._parse_umapinfo_keyvalue(line, i)
            i += 1

        if brace_count > 0:
            raise MAPINFOError("Unclosed brace in map definition")
        return i

    def _parse_umapinfo_keyvalue(self, line: str, line_number: int):
        """Parse a key=value line in UMAPINFO."""
        if '=' not in line:
            raise MAPINFOError(f"Expected '=' in key-value pair at line {line_number}: {line}")
        key_part, value_part = line.split('=', 1)
        key = key_part.strip().lower()
        if key not in self.UMAPINFO_KEYS:
            # Just warn, don't crash
            print(f"Unknown key '{key}' at line {line_number}")
        value = self._parse_value(value_part.strip())
        self._set_value(key, value)

    def _parse_value(self, value_str: str) -> Any:
        """Parse a single value (string, number, identifier, special)."""
        value_str = value_str.strip()
        if value_str.startswith('"') and value_str.endswith('"'):
            return value_str[1:-1]
        special = {'clear': 'clear', 'true': True, 'false': False}
        if value_str.lower() in special:
            return special[value_str.lower()]
        try:
            return int(value_str)
        except ValueError:
            pass
        if ',' in value_str:
            parts = [p.strip().strip('"') for p in value_str.split(',') if p.strip()]
            return parts
        if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', value_str):
            return value_str
        raise MAPINFOError(f"Invalid value: {value_str}")

    def _set_value(self, key: str, value: Any):
        """Set a value in the current map definition."""
        if not self.current_definition:
            raise MAPINFOError("No current map definition")
        if key == 'bossaction':
            self._parse_bossaction(value)
            return
        if key == 'episode':
            self._parse_episode(value)
            return
        if key == 'label' and value == 'clear':
            setattr(self.current_definition, key, 'clear')
            return
        if key in ['intertext', 'intertextsecret']:
            setattr(self.current_definition, key, value)
            return
        setattr(self.current_definition, key, value)

    def _parse_bossaction(self, value: Any):
        """Parse bossaction from UMAPINFO."""
        if value == 'clear':
            self.current_definition.bossactions = []
            return
        if isinstance(value, str):
            parts = [p.strip() for p in value.split(',')]
        elif isinstance(value, list):
            parts = value
        else:
            raise MAPINFOError(f"Invalid bossaction value: {value}")
        if len(parts) != 3:
            raise MAPINFOError(f"bossaction requires exactly 3 values: {parts}")
        thingtype = parts[0].strip()
        if thingtype not in self.VALID_THINGTYPES:
            pass  # warn only
        try:
            linespecial = int(parts[1].strip())
            tag = int(parts[2].strip())
        except ValueError:
            raise MAPINFOError(f"bossaction numeric values must be integers: {parts[1]}, {parts[2]}")
        if tag == 0:
            raise MAPINFOError("bossaction tag 0 is not allowed except for level exits")
        self.current_definition.bossactions.append(
            BossAction(thingtype=thingtype, linespecial=linespecial, tag=tag)
        )

    def _parse_episode(self, value: Any):
        """Parse episode from UMAPINFO."""
        if value == 'clear':
            self.current_definition.episode = 'clear'
            return
        if isinstance(value, str):
            parts = [p.strip().strip('"') for p in value.split(',')]
        elif isinstance(value, list):
            parts = [p.strip().strip('"') for p in value if p.strip()]
        else:
            raise MAPINFOError(f"Invalid episode value: {value}")
        if len(parts) != 3:
            raise MAPINFOError(f"Episode requires exactly 3 values: {parts}")
        ep = EpisodeEntry(patch=parts[0], name=parts[1], key=parts[2])
        if self.current_definition.episode is None or isinstance(self.current_definition.episode, list):
            if self.current_definition.episode is None:
                self.current_definition.episode = [ep]
            else:
                self.current_definition.episode.append(ep)
        else:
            self.current_definition.episode = [ep]

    # ----------------------------------------------------------------------
    #  Classic ZDoom MAPINFO parser
    # ----------------------------------------------------------------------

    def _parse_old_mapinfo(self):
        """
        Parse the classic ZDoom MAPINFO format.
        Supports both brace‑delimited and line‑based map definitions.
        Handles defaultmap, adddefaultmap, and gamedefaults (partially).
        """
        lines = self.text.replace('\r\n', '\n').split('\n')
        # Remove full‑line comments and empty lines for easier processing
        cleaned_lines = []
        for line in lines:
            stripped = self._strip_comments(line)
            if stripped:
                cleaned_lines.append(stripped)

        i = 0
        self._defaults = {}
        self._gamedefaults = {}

        while i < len(cleaned_lines):
            line = cleaned_lines[i]

            # Check for directives
            lower = line.lower()
            if lower.startswith('map '):
                # map <maplump> <nice name> [optional brace]
                i = self._parse_old_map_definition(i, cleaned_lines, self._defaults)
            elif lower.startswith('defaultmap'):
                # defaultmap – reset defaults, then parse properties until next directive
                self._defaults = {}
                i = self._parse_old_defaults(i, cleaned_lines, self._defaults, reset=True)
            elif lower.startswith('adddefaultmap'):
                # adddefaultmap – add to existing defaults
                i = self._parse_old_defaults(i, cleaned_lines, self._defaults, reset=False)
            elif lower.startswith('gamedefaults'):
                # gamedefaults – global defaults (not applied per map)
                self._gamedefaults = {}
                i = self._parse_old_defaults(i, cleaned_lines, self._gamedefaults, reset=True)
            else:
                # Might be a property without a preceding map? skip
                i += 1

    def _parse_old_map_definition(self, start_idx: int, lines: List[str], defaults: Dict) -> int:
        """
        Parse a map definition starting at 'map <maplump> <nice name>'.
        Returns the next index to process.
        """
        line = lines[start_idx]
        # Extract maplump and nice name
        # Format: map <maplump> <nice name> (with optional quoted nice name)
        parts = line.split(None, 2)  # split into at most 3 parts
        if len(parts) < 3:
            raise MAPINFOError(f"Invalid map line: {line}")
        maplump = parts[1]
        nice_name = parts[2].strip()
        # Remove trailing '{' if present (some people use braces)
        if nice_name.endswith('{'):
            nice_name = nice_name[:-1].strip()
        # Remove quotes
        if nice_name.startswith('"') and nice_name.endswith('"'):
            nice_name = nice_name[1:-1]

        # Create map definition
        mapdef = MapDefinition(mapname=maplump, levelname=nice_name)
        # Apply defaults
        for k, v in defaults.items():
            setattr(mapdef, k, v) if hasattr(mapdef, k) else mapdef.extra.update({k: v})

        self.maps[maplump] = mapdef
        self.current_definition = mapdef
        self.current_map = maplump

        # Now parse properties until we hit another directive or end
        i = start_idx + 1
        while i < len(lines):
            line = lines[i].strip()
            lower = line.lower()
            # Directives that end the map definition
            if lower.startswith('map ') or lower.startswith('defaultmap') or \
               lower.startswith('adddefaultmap') or lower.startswith('gamedefaults'):
                break

            # Parse property
            self._parse_old_property(line, mapdef)
            i += 1

        return i

    def _parse_old_defaults(self, start_idx: int, lines: List[str], defaults: Dict, reset: bool) -> int:
        """
        Parse a defaultmap/adddefaultmap/gamedefaults block.
        Properties are read until a directive is encountered.
        If reset is True, the defaults dict is cleared first.
        """
        if reset:
            defaults.clear()
        i = start_idx + 1
        while i < len(lines):
            line = lines[i].strip()
            lower = line.lower()
            if lower.startswith('map ') or lower.startswith('defaultmap') or \
               lower.startswith('adddefaultmap') or lower.startswith('gamedefaults'):
                break
            # Parse property and store in defaults
            # We use a temporary MapDefinition to hold values, then copy to defaults
            temp = MapDefinition(mapname='')
            self._parse_old_property(line, temp)
            # Copy all set attributes from temp to defaults
            for k, v in temp.__dict__.items():
                if v is not None and k != 'mapname' and k != 'extra':
                    defaults[k] = v
            # Also copy extra
            for k, v in temp.extra.items():
                defaults[k] = v
            i += 1
        return i

    def _parse_old_property(self, line: str, mapdef: MapDefinition):
        """
        Parse a single property line in classic MAPINFO format.
        Supports both 'key = value' and 'key value' styles.
        """
        # Remove trailing semicolon if present
        line = line.rstrip(';').strip()
        if '=' in line:
            key, value_str = line.split('=', 1)
            key = key.strip().lower()
            value_str = value_str.strip()
        else:
            # No '=' – split on first space
            parts = line.split(None, 1)
            if len(parts) < 2:
                return  # malformed
            key = parts[0].lower()
            value_str = parts[1].strip()

        # Try to parse value
        # Many properties are simple: strings, numbers, booleans, or special keywords
        # Some have multiple arguments (sky1, specialaction, etc.)
        # We'll handle known cases and fallback to generic parsing.

        # Special handling for keys with multiple args
        if key in ('sky1', 'sky2'):
            # sky1 <texture> <scrollspeed>
            # We'll store texture and scroll separately
            parts = self._split_value(value_str)
            if len(parts) >= 1:
                texture = parts[0].strip('"')
                if key == 'sky1':
                    mapdef.sky1 = texture
                    if len(parts) >= 2:
                        try:
                            mapdef.sky1scroll = float(parts[1])
                        except ValueError:
                            pass
                else:  # sky2
                    mapdef.sky2 = texture
                    if len(parts) >= 2:
                        try:
                            mapdef.sky2scroll = float(parts[1])
                        except ValueError:
                            pass
            return

        if key == 'doublesky':
            # boolean flag, set True
            mapdef.doublesky = True
            return

        if key == 'specialaction':
            # specialaction <monstertype>, <action special>, <arg1>, ...
            # We'll store as a dict in extra
            parts = self._split_value(value_str)
            if parts:
                mapdef.extra['specialaction'] = parts
            return

        if key == 'next' or key == 'secretnext':
            # Can be a lump name or an endgame directive/block
            # We'll attempt to parse the value; if it's a simple lump, store in next/nextsecret
            # If it's an endgame directive like EndPic, we set endgame flags.
            val = self._parse_old_endgame_value(value_str)
            if key == 'next':
                if isinstance(val, str):
                    mapdef.next = val
                elif isinstance(val, dict):
                    # It's an endgame structure
                    mapdef.endgame = True
                    if 'pic' in val:
                        mapdef.endpic = val['pic']
                    if 'cast' in val:
                        mapdef.endcast = True
                    if 'music' in val:
                        mapdef.music = val['music']
                    # Store any remaining
                    mapdef.extra['next_endgame'] = val
            else:  # secretnext
                if isinstance(val, str):
                    mapdef.nextsecret = val
                else:
                    mapdef.extra['secretnext_endgame'] = val
            return

        # For boolean flags that are just present (no value)
        boolean_flags = {
            'nointermission', 'nosoundclipping', 'allowmonstertelefrags',
            'map07special', 'baronspecial', 'cyberdemonspecial', 'spidermastermindspecial',
            'lightning', 'evenlighting', 'smoothlighting', 'clipmidtextures',
            'forcenoskystretch', 'skystretch', 'noautosequences', 'autosequences',
            'strictmonsteractivation', 'laxmonsteractivation',
            'missileshootersactivateimpactlines', 'missilesactivateimpactlines',
            'fallingdamage', 'monsterfallingdamage', 'oldfallingdamage',
            'strifefallingdamage', 'forcefallingdamage', 'nofallingdamage',
            'filterstarts', 'allowrespawn', 'teamplayon', 'teamplayoff',
            'noinventorybar', 'keepfullinventory', 'infiniteflightpowerup',
            'nojump', 'allowjump', 'nocrouch', 'allowcrouch',
            'noinfighting', 'normalinfighting', 'totalinfighting',
            'checkswitchrange', 'nocheckswitchrange',
            'unfreezesingleplayerconversations'
        }
        if key in boolean_flags:
            # If value is present, parse it; otherwise set True
            if value_str.lower() in ('true', 'false'):
                setattr(mapdef, key, value_str.lower() == 'true')
            else:
                setattr(mapdef, key, True)
            return

        # Other known keys with simple values
        simple_keys = {
            'levelnum': int, 'cluster': int, 'partime': int, 'cdtrack': int, 'cdid': int,
            'gravity': float, 'aircontrol': float, 'airsupply': int,
            'teamdamage': float, 'vertwallshade': int, 'horizwallshade': int,
        }
        if key in simple_keys:
            try:
                val = simple_keys[key](value_str)
                setattr(mapdef, key, val)
            except ValueError:
                # store as string
                mapdef.extra[key] = value_str
            return

        # String properties
        string_keys = {
            'music', 'exitpic', 'enterpic', 'intermusic', 'bordertexture',
            'fade', 'outsidefog', 'titlepatch', 'translator', 'f1'
        }
        if key in string_keys:
            # Remove quotes
            val = value_str.strip('"')
            setattr(mapdef, key, val)
            return

        # If we don't know the key, store it in extra
        mapdef.extra[key] = value_str

    def _split_value(self, value_str: str) -> List[str]:
        """Split a value string by commas, respecting quotes."""
        # We need to handle commas inside quotes correctly.
        result = []
        current = []
        in_quotes = False
        for ch in value_str:
            if ch == '"':
                in_quotes = not in_quotes
                current.append(ch)
            elif ch == ',' and not in_quotes:
                result.append(''.join(current).strip())
                current = []
            else:
                current.append(ch)
        if current:
            result.append(''.join(current).strip())
        return result

    def _parse_old_endgame_value(self, value_str: str) -> Union[str, Dict]:
        """
        Parse a 'next' or 'secretnext' value that might be an endgame directive.
        Returns either a string (lump name) or a dict with endgame details.
        """
        val = value_str.strip()
        # Check for endgame directives
        endgame_map = {
            'endgame1': 'EndGame1',
            'endgame2': 'EndGame2',
            'endgamew': 'EndGameW',
            'endgame4': 'EndGame4',
            'endgamec': 'EndGameC',
            'endgame3': 'EndGame3',
            'enddemon': 'EndDemon',
            'endgames': 'EndGameS',
        }
        if val.lower() in endgame_map:
            return {'type': endgame_map[val.lower()]}

        # Check for EndPic <lump>
        m = re.match(r'EndPic\s+(.+)', val, re.IGNORECASE)
        if m:
            return {'pic': m.group(1).strip()}

        # Check for endgame block with braces: { ... }
        # This is more complex; we'll skip for simplicity or handle with a simple regex.
        # For now, treat as a lump name.
        return val


# ----------------------------------------------------------------------
#  Convenience functions
# ----------------------------------------------------------------------

def load_mapinfo_file(filename: str) -> MAPINFOProcessor:
    """Load MAPINFO from a file, auto‑detect format."""
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    return MAPINFOProcessor(content)


def main():
    """Example usage showing both UMAPINFO and classic MAPINFO parsing."""

    # Example classic MAPINFO text (ZDoom style)
    classic_text = """
    map MAP01 "Entryway"
    {
        levelnum = 1
        next = MAP02
        sky1 = SKY1 0.0
        music = D_RUNNIN
        nointermission
    }

    map MAP02 "Underhalls"
        levelnum = 2
        next = MAP03
        sky1 = SKY1 0.0
        music = D_STALKS
        partime = 30
    """

    print("=== Parsing classic MAPINFO ===")
    processor_old = MAPINFOProcessor(classic_text)
    for name, mapdef in processor_old.get_maps().items():
        print(f"Map: {name} -> {mapdef.levelname}")
        print(f"  next: {mapdef.next}, sky1: {mapdef.sky1}")
        print(f"  extra: {mapdef.extra}")

    # Example UMAPINFO text (unchanged)
    umapinfo_text = """
    MAP E1M7
    {
        levelname = "The Hidden Cave"
        skytexture = "sky2"
        intertext = "You have beaten the shit",
            "out of those big barons",
            "and now must continue the fight."
        bossaction = BaronOfHell, 23, 666
    }
    MAP MAP30
    {
        levelname = "Icon of Sin"
        endgame = true
        nointermission = true
    }
    """

    print("\n=== Parsing UMAPINFO ===")
    processor_umap = MAPINFOProcessor(umapinfo_text)
    for name, mapdef in processor_umap.get_maps().items():
        print(f"Map: {name} -> {mapdef.levelname}")
        print(f"  skytexture: {mapdef.skytexture}")
        print(f"  bossactions: {len(mapdef.bossactions)}")

    # Validate
    warnings = processor_umap.validate()
    if warnings:
        print("\nWarnings:", warnings)

    # JSON round‑trip
    json_data = processor_umap.to_json()
    print("\nJSON representation (first map):")
    print(json_data[:500] + "...")

    processor2 = MAPINFOProcessor.from_json(json_data)
    print(f"\nReloaded from JSON: {len(processor2.get_maps())} maps")


if __name__ == "__main__":
    main()