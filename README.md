# DOOM Engine Port for Sonic Robo Blast 2

A full port of the original DOOM engine back into Sonic Robo Blast 2, featuring support for classic DOOM WADs, Chex Quest, and compatibility with SRB2 versions like XMas and Halloween.

## Quick Start

### Loading in SRB2

1. **Load the engine first**, then your WAD/PWAD
   - The engine file must be loaded before your DOOM content
2. **Press ALT twice** to open the SRB2 add-ons menu

You can also use pywadadvance_gui.py for a quick set-up.

### Important Setup

When converting or building WAD files for use with this engine, use the included conversion tools to ensure proper compatibility.

## Features

- Full DOOM engine implementation in SRB2
- Support for classic DOOM and DOOM II WADs
- Chex Quest compatibility
- DEH/BEX patch support
- Customizable MIDI and sprite handling

## Building the DOOM Engine

### Prerequisites

- Python 3.6+
- Git (for version tagging)

### Build Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/OneTailedVillain/DOOM-II.git
   cd DOOM-II
   ```

2. **Run the build script:**
   ```bash
   python build.py
   ```

   The build script will:
   - Process the base WAD file (converting it to PK3 format)
   - Compile Lua scripts and resources
   - Package everything into `build/SL_DOOMII-v{version}.pk3`

3. **Build Options:**
   ```bash
   python build.py --output-dir build        # Specify output directory
   python build.py --force                   # Force rebuild (skip incremental checks)
   python build.py --clean                   # Clean build directory before building
   python build.py --version 1.0.0           # Set specific version
   ```

### Build Output

After building, you'll find:
- `build/SL_DOOMII-v{version}.pk3` - Main engine package
- `build/freedoom2.pk3` - Processed base WAD (if included)

## Converting WAD Files

The repository includes a conversion tool (`pywadadvance`) for converting DOOM WADs and DEH/BEX patches to something readable by the engine.

### Usage

#### Convert a WAD file:
```bash
python Python/pywadadvance_core.py doom.wad doom-converted.wad [optional-deh-or-bex-patch.deh] [another-patch.bex]
```

#### Convert only DEH/BEX files:
```bash
python Python/pywadadvance_core.py deh-patch.deh bex-patch.bex output.wad
```

### Conversion Guidelines

- **WAD conversion:** WAD file comes first, output file comes second
- **DEH/BEX only:** DEH/BEX files come first, output WAD comes last
- Multiple DEH/BEX patches can be chained together
- The conversion tool automatically handles:
  - Sprite and graphics conversion
  - Patch and colormap processing
  - Optional conversion to use PC Speaker sound effects

## License

Please refer to the individual component licenses. DOOM is a trademark of id Software.
