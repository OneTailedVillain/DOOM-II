#!/usr/bin/env python3
"""
doomrender.py - render a view of a Doom level from a WAD, in software.

Command line:
    python doomrender.py mymap.wad -header MAP01 -iwad doom2.wad
    python doomrender.py doom.wad  -header E1M1 -o e1m1.png -scale 4
    python doomrender.py mymap.wad -header MAP01 -preset p     # 160x100 level select
    python doomrender.py mymap.wad -header MAP01 -preset w     # 564x100 wide level select

As a module:

    from modules import doomrender

    iwad  = doomrender.Wad('doom2.wad')
    pwad  = doomrender.Wad('mymap.wad')            # or doomrender.Wad(raw_bytes)
    res   = doomrender.Resources([iwad, pwad])     # later WADs override earlier ones
    level = doomrender.load_level(pwad, 'MAP01')

    # arbitrary size / focal length -> list of palette indices (width * height)
    fb = doomrender.render_level(res, level, 'MAP01', width=320, height=200)

    # SRB2 level select pictures: {'MAP01P': <patch bytes>, 'MAP01W': <patch bytes>}
    pics = doomrender.render_level_select_images(res, pwad, ['MAP01'])

All failures that are the fault of the input data raise `RenderError`.
"""
import argparse
import math
import os
import struct
import sys
import zlib
from collections import namedtuple

__all__ = [
    'RenderError', 'Wad', 'Resources', 'Level', 'Renderer', 'build_wad_bytes',
    'load_level', 'render_level', 'render_level_select',
    'render_level_select_images', 'level_select_lump_names',
    'doom1_sky_name', 'fb_to_patch', 'fb_to_rgb', 'write_png', 'find_iwad', 'resolve_iwad',
    'LEVEL_SELECT_SPECS',
]

# Default view (command line default). Everything size-related is per-Renderer.
DEFAULT_W, DEFAULT_H = 160 * 8, 100 * 8
DEFAULT_FOCAL_DIV = 2.0          # FOCAL = height / DEFAULT_FOCAL_DIV

# SRB2 level select pictures: (lump suffix, width, height, focal divisor)
#   MAPxxP : 160x100, FOCAL = H / 2.0
#   MAPxxW : 564x100, FOCAL = H / 1.0
LEVEL_SELECT_SPECS = (
    ('P', 160, 100, 2.0),
    ('W', 564, 100, 1.0),
)

NEAR = 1.0
VIEW_HEIGHT = 41.0
NONE = 0xFFFF
SKY = 'F_SKY1'
STRIFE_SKY = 'F_SKY001'
LIGHT_PROJ = 160.0
SIL_BOTTOM, SIL_TOP = 1, 2     # drawseg silhouettes (as in r_defs.h)
BIG = 1 << 30


class DrawSeg(object):
    """One rendered wall range (Doom's drawseg_t): used to clip sprites and masked textures."""
    __slots__ = ('x1', 'x2', 'scale1', 'scale2', 'seg', 'sil', 'bsil', 'tsil',
                 'topclip', 'botclip', 'mtex', 'mcol', 'sx1', 'span', 'invd1',
                 'invd2', 'ud1', 'ud2', 'anchor', 'yoff', 'sl')


class VisSprite(object):
    __slots__ = ('scale', 'gx', 'gy', 'gz', 'gzt', 'xs', 'xe', 'x1f', 'ytop',
                 'r0', 'r1', 'cols', 'pw', 'ph', 'flip', 'lr', 'fuzz')


class RenderError(Exception):
    """Raised when a level or its resources cannot be rendered."""


Sector = namedtuple('Sector', 'floor ceil floor_pic ceil_pic light')
Side = namedtuple('Side', 'xoff yoff upper lower mid sector')
Line = namedtuple('Line', 'v1 v2 flags special tag right left')
Seg = namedtuple('Seg', 'v1 v2 angle line dir offset')
Node = namedtuple('Node', 'x y dx dy bbox child')
Thing = namedtuple('Thing', 'x y angle type flags')

# ----------------------------------------------------------------------------
# Thing type -> sprite prefix (first frame 'A' unless listed in THING_FRAMES)
# ----------------------------------------------------------------------------
THING_SPRITES = {
    3004: 'POSS', 9: 'SPOS', 3001: 'TROO', 3002: 'SARG', 58: 'SARG', 3006: 'SKUL',
    3005: 'HEAD', 69: 'BOS2', 3003: 'BOSS', 16: 'CYBR', 7: 'SPID', 64: 'VILE',
    65: 'CPOS', 66: 'SKEL', 67: 'FATT', 68: 'BSPI', 71: 'PAIN', 72: 'KEEN',
    84: 'SSWV', 88: 'BBRN',
    2001: 'SHOT', 82: 'SGN2', 2002: 'MGUN', 2003: 'LAUN', 2004: 'PLAS',
    2006: 'BFUG', 2005: 'CSAW',
    2007: 'CLIP', 2008: 'SHEL', 2010: 'ROCK', 2047: 'CELL', 2048: 'AMMO',
    2049: 'SBOX', 2046: 'BROK', 17: 'CELP', 8: 'BPAK',
    2011: 'STIM', 2012: 'MEDI', 2013: 'SOUL', 2014: 'BON1', 2015: 'BON2',
    2018: 'ARM1', 2019: 'ARM2', 83: 'MEGA', 2022: 'PINV', 2023: 'PSTR',
    2024: 'PINS', 2025: 'SUIT', 2026: 'PMAP', 2045: 'PVIS',
    5: 'BKEY', 13: 'RKEY', 6: 'YKEY', 38: 'RSKU', 39: 'YSKU', 40: 'BSKU',
    2028: 'COLU', 2035: 'BAR1', 48: 'ELEC', 30: 'COL1', 31: 'COL2', 32: 'COL3',
    33: 'COL4', 36: 'COL5', 37: 'COL6', 41: 'CEYE', 42: 'FSKU', 43: 'TRE1',
    44: 'TBLU', 45: 'TGRN', 46: 'TRED', 47: 'SMIT', 54: 'TRE2', 55: 'SMBT',
    56: 'SMGT', 57: 'SMRT', 35: 'CBRA', 34: 'CAND',
    25: 'POL1', 26: 'POL6', 27: 'POL4', 28: 'POL2', 29: 'POL3', 24: 'POL5',
    49: 'GOR1', 50: 'GOR2', 51: 'GOR3', 52: 'GOR4', 53: 'GOR5',
    59: 'GOR2', 60: 'GOR4', 61: 'GOR3', 62: 'GOR5', 63: 'GOR1',
    73: 'HDB1', 74: 'HDB2', 75: 'HDB3', 76: 'HDB4', 77: 'HDB5', 78: 'HDB6',
    79: 'POB1', 80: 'POB2', 81: 'BRS1', 85: 'TLMP', 86: 'TLP2', 70: 'FCAN',
}
THING_FRAMES = {10: ('PLAY', 'W'), 12: ('PLAY', 'W'), 15: ('PLAY', 'N'),
                18: ('POSS', 'L'), 19: ('SPOS', 'L'), 20: ('TROO', 'M'),
                21: ('SARG', 'N'), 22: ('HEAD', 'L'), 23: ('SKUL', 'K')}
# Things that hang from the ceiling -> object height
HANGING = {49: 68, 50: 84, 51: 84, 52: 68, 53: 52, 59: 84, 60: 68, 61: 84,
           62: 52, 63: 68, 73: 88, 74: 88, 75: 64, 76: 64, 77: 64, 78: 64, 72: 72}
FUZZ_TYPES = {58}
# Sprites whose first frame is full-bright in the game
FULLBRIGHT = {'SKUL', 'SOUL', 'MEGA', 'PINV', 'PSTR', 'PINS', 'PMAP', 'PVIS',
              'CAND', 'CBRA', 'COLU', 'TBLU', 'TGRN', 'TRED', 'SMBT', 'SMGT',
              'SMRT', 'TLMP', 'TLP2', 'FCAN', 'CEYE'}

LEVEL_LUMPS = {'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS', 'SSECTORS',
               'NODES', 'SECTORS', 'REJECT', 'BLOCKMAP', 'BEHAVIOR', 'SCRIPTS'}
FLAT_START = {'F_START', 'FF_START', 'F1_START', 'F2_START', 'F3_START'}
FLAT_END = {'F_END', 'FF_END', 'F1_END', 'F2_END', 'F3_END'}
SPRITE_START = {'S_START', 'SS_START'}
SPRITE_END = {'S_END', 'SS_END'}


# ----------------------------------------------------------------------------
# WAD handling
# ----------------------------------------------------------------------------
def build_wad_bytes(lumps, wad_type=b'PWAD'):
    """Serialize [(name, bytes), ...] into a WAD (handy for in-memory resources)."""
    body = bytearray()
    directory = bytearray()
    pos = 12
    for name, data in lumps:
        data = bytes(data)
        raw = name.upper().encode('latin-1', 'replace')[:8].ljust(8, b'\0')
        directory += struct.pack('<ii8s', pos, len(data), raw)
        body += data
        pos += len(data)
    return (struct.pack('<4sii', wad_type, len(lumps), 12 + len(body)) +
            bytes(body) + bytes(directory))


class Wad:
    """Read-only WAD. `source` is a file path or the raw bytes of a WAD."""

    def __init__(self, source, name=None):
        if isinstance(source, (bytes, bytearray, memoryview)):
            self.data = bytes(source)
            self.path = name or '<memory>'
        else:
            with open(source, 'rb') as f:
                self.data = f.read()
            self.path = name or str(source)
        if len(self.data) < 12:
            raise RenderError('%s is not a WAD file' % self.path)
        ident, n, off = struct.unpack_from('<4sii', self.data, 0)
        if ident not in (b'IWAD', b'PWAD'):
            raise RenderError('%s is not a WAD file' % self.path)
        if n < 0 or off < 12 or off + 16 * n > len(self.data):
            raise RenderError('%s has a corrupt directory' % self.path)
        self.is_iwad = ident == b'IWAD'
        self.lumps = []
        self.index = {}
        for i in range(n):
            pos, size, raw = struct.unpack_from('<ii8s', self.data, off + 16 * i)
            name_ = raw.split(b'\0', 1)[0].decode('latin-1').upper()
            self.lumps.append((name_, pos, size))
            self.index[name_] = i

    def get(self, i):
        _, pos, size = self.lumps[i]
        return self.data[pos:pos + size]

    def find_level(self, header):
        for i, (name, _, _) in enumerate(self.lumps):
            if name == header and i + 1 < len(self.lumps) and self.lumps[i + 1][0] == 'THINGS':
                return i
        return None

    def level_headers(self):
        """Names of every lump that is immediately followed by THINGS."""
        return [name for i, (name, _, _) in enumerate(self.lumps)
                if i + 1 < len(self.lumps) and self.lumps[i + 1][0] == 'THINGS']

    def has_palette(self):
        return 'PLAYPAL' in self.index and 'COLORMAP' in self.index


def decode_patch(data):
    """Doom picture format -> (columns, w, h, left, top); -1 = transparent."""
    if len(data) < 8 or data[:4] == b'\x89PNG':
        return None
    w, h, lo, to = struct.unpack_from('<hhhh', data, 0)
    if w <= 0 or h <= 0 or w > 4096 or h > 4096 or len(data) < 8 + 4 * w:
        return None
    cols = []
    n = len(data)
    for x in range(w):
        off = struct.unpack_from('<I', data, 8 + 4 * x)[0]
        col = [-1] * h
        while off < n and data[off] != 255:
            top = data[off]
            cnt = data[off + 1] if off + 1 < n else 0
            for i in range(cnt):
                y = top + i
                if y < h and off + 3 + i < n:
                    col[y] = data[off + 3 + i]
            off += cnt + 4
        cols.append(col)
    return cols, w, h, lo, to


class Resources:
    """Palette, colormap, textures, flats and sprites from one or more WADs
    (later WADs override earlier ones)."""

    def __init__(self, wads):
        self.wads = list(wads)
        self.flats, self.sprites, self.texdefs = {}, {}, {}
        self.strife_texture_format = False
        self.sky_flat_name = SKY
        pnames = []
        for wad in self.wads:
            ns = None
            for i, (name, _, size) in enumerate(wad.lumps):
                if name in FLAT_START:
                    ns = 'F'
                elif name in SPRITE_START:
                    ns = 'S'
                elif name in FLAT_END or name in SPRITE_END:
                    ns = None
                elif ns == 'F' and size == 4096:
                    self.flats[name] = wad.get(i)
                elif ns == 'S' and size > 0:
                    self.sprites[name] = wad.get(i)
            if 'PNAMES' in wad.index:
                d = wad.get(wad.index['PNAMES'])
                n = struct.unpack_from('<i', d, 0)[0]
                pnames = [d[4 + 8 * k:12 + 8 * k].split(b'\0', 1)[0].decode('latin-1').upper()
                          for k in range(n)]
            for tname in ('TEXTURE1', 'TEXTURE2'):
                if tname in wad.index:
                    is_strife = self._is_strife_texture_lump(wad.get(wad.index[tname]))
                    self.strife_texture_format |= is_strife
                    self._parse_textures(wad.get(wad.index[tname]), pnames, is_strife)

        if self.strife_texture_format:
            self.sky_flat_name = STRIFE_SKY

        pal = self.lump('PLAYPAL')
        cmap = self.lump('COLORMAP')
        if pal is None or cmap is None:
            raise RenderError('PLAYPAL/COLORMAP not found. Pass the base game IWAD.')
        self.palette = [tuple(pal[i * 3:i * 3 + 3]) for i in range(256)]
        self.cm = [cmap[i * 256:(i + 1) * 256] for i in range(len(cmap) // 256)]
        mag = min(range(256), key=lambda i: (self.palette[i][0] - 255) ** 2 +
                  self.palette[i][1] ** 2 + (self.palette[i][2] - 255) ** 2)
        self.fallback_tex = ([[mag] * 64 for _ in range(64)], 64, 64)
        self.fallback_flat = bytes([mag]) * 4096
        self._tex_cache, self._patch_cache, self._spr_cache = {}, {}, {}

        self.sprite_frames = {}
        for name in self.sprites:
            if len(name) < 6:
                continue
            pairs = [(name[4], name[5], False)]
            if len(name) == 8:
                pairs.append((name[6], name[7], True))
            for frame, rot, flip in pairs:
                if not ('0' <= rot <= '8'):
                    continue
                fr = self.sprite_frames.setdefault(name[:4], {}).setdefault(frame, [None] * 8)
                if rot == '0':
                    for k in range(8):
                        fr[k] = (name, flip)
                else:
                    fr[int(rot) - 1] = (name, flip)

    @staticmethod
    def _texture_lump_valid(d, strife=False):
        """Check whether a TEXTURE1/2 lump uses the given record layout."""
        if len(d) < 4:
            return False
        n = struct.unpack_from('<i', d, 0)[0]
        if n < 0 or n > (len(d) - 4) // 4:
            return False
        header_size, patch_size = (18, 6) if strife else (22, 10)
        offsets = [struct.unpack_from('<i', d, 4 + 4 * k)[0] for k in range(n)]
        for k, off in enumerate(offsets):
            end = offsets[k + 1] if k + 1 < n else len(d)
            if off < 4 + 4 * n or off + header_size > end or end > len(d):
                return False
            if strife:
                _raw, _masked, w, h, pc = struct.unpack_from('<8siHHH', d, off)
            else:
                _raw, _masked, w, h, _cd, pc = struct.unpack_from('<8siHHiH', d, off)
            if w == 0 or h == 0 or pc > (end - off - header_size) // patch_size:
                return False
        return True

    @classmethod
    def _is_strife_texture_lump(cls, d):
        # Strife 1.1+ removes the unused column-directory and patch fields,
        # shortening texture headers from 22 to 18 bytes and patches from
        # 10 to 6 bytes. Prefer the classic layout if both validate.
        return (cls._texture_lump_valid(d, True) and
                not cls._texture_lump_valid(d, False))

    def _parse_textures(self, d, pnames, strife=False):
        n = struct.unpack_from('<i', d, 0)[0]
        header_size, patch_size = (18, 6) if strife else (22, 10)
        for k in range(n):
            off = struct.unpack_from('<i', d, 4 + 4 * k)[0]
            if strife:
                raw, _masked, w, h, pc = struct.unpack_from('<8siHHH', d, off)
            else:
                raw, _masked, w, h, _cd, pc = struct.unpack_from('<8siHHiH', d, off)
            name = raw.split(b'\0', 1)[0].decode('latin-1').upper()
            patches = []
            for p in range(pc):
                poff = off + header_size + patch_size * p
                if strife:
                    ox, oy, pi = struct.unpack_from('<hhh', d, poff)
                else:
                    ox, oy, pi, _s, _c = struct.unpack_from('<hhhhh', d, poff)
                if 0 <= pi < len(pnames):
                    patches.append((ox, oy, pnames[pi]))
            self.texdefs[name] = (w, h, patches)

    def lump(self, name):
        for wad in reversed(self.wads):
            i = wad.index.get(name)
            if i is not None:
                return wad.get(i)
        return None

    def patch(self, name):
        if name not in self._patch_cache:
            d = self.lump(name)
            self._patch_cache[name] = decode_patch(d) if d else None
        return self._patch_cache[name]

    def sprite_patch(self, name):
        if name not in self._spr_cache:
            self._spr_cache[name] = decode_patch(self.sprites[name])
        return self._spr_cache[name]

    def texture(self, name):
        """(cols, w, h); None for '-'; magenta placeholder if missing."""
        if not name or name == '-':
            return None
        t = self._tex_cache.get(name)
        if t is None:
            t = self._compose(name) or self.fallback_tex
            self._tex_cache[name] = t
        return t

    def _compose(self, name):
        d = self.texdefs.get(name)
        if not d:
            return None
        w, h, patches = d
        if w <= 0 or h <= 0:
            return None
        cols = [[-1] * h for _ in range(w)]
        for ox, oy, pn in patches:
            p = self.patch(pn)
            if p is None:
                continue
            pcols, pw, ph, _, _ = p
            for px in range(pw):
                tx = ox + px
                if 0 <= tx < w:
                    pc, dst = pcols[px], cols[tx]
                    for py in range(ph):
                        ty = oy + py
                        if 0 <= ty < h and pc[py] >= 0:
                            dst[ty] = pc[py]
        return cols, w, h

    def flat(self, name):
        return self.flats.get(name) or self.fallback_flat


# ----------------------------------------------------------------------------
# Level data
# ----------------------------------------------------------------------------
def _iter(fmt, data):
    sz = struct.calcsize(fmt)
    return struct.iter_unpack(fmt, data[:len(data) // sz * sz])


def _name(b):
    return b.split(b'\0', 1)[0].decode('latin-1').upper()


class Level:
    def __init__(self, wad, idx):
        lumps = {}
        i = idx + 1
        while i < len(wad.lumps) and wad.lumps[i][0] in LEVEL_LUMPS:
            lumps.setdefault(wad.lumps[i][0], wad.get(i))
            i += 1
        if 'BEHAVIOR' in lumps:
            raise RenderError('Hexen-format maps are not supported (Doom format only).')
        for need in ('THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS',
                     'SSECTORS', 'SECTORS', 'NODES'):
            if need not in lumps:
                raise RenderError('Level is missing the %s lump.' % need)
        if lumps['NODES'][:4] in (b'XNOD', b'ZNOD', b'XGLN', b'XGL2', b'ZGLN'):
            raise RenderError('Extended/compressed nodes are not supported.')
        if not lumps['SEGS']:
            raise RenderError('Level has no SEGS - BSP nodes were never built.')

        self.verts = [(x, y) for x, y in _iter('<hh', lumps['VERTEXES'])]
        self.sectors = [Sector(f, c, _name(fp), _name(cp), l)
                        for f, c, fp, cp, l, _s, _t in _iter('<hh8s8shhh', lumps['SECTORS'])]
        self.sides = [Side(xo, yo, _name(u), _name(lo), _name(m), s)
                      for xo, yo, u, lo, m, s in _iter('<hh8s8s8sh', lumps['SIDEDEFS'])]
        self.lines = [Line(*t) for t in _iter('<7H', lumps['LINEDEFS'])]
        self.segs = [Seg(*t) for t in _iter('<HHhHhh', lumps['SEGS'])]
        self.ssectors = list(_iter('<HH', lumps['SSECTORS']))   # (count, first)
        self.nodes = []
        for t in _iter('<12h2H', lumps['NODES']):
            self.nodes.append(Node(t[0], t[1], t[2], t[3], (t[4:8], t[8:12]), (t[12], t[13])))
        self.things = [Thing(*t) for t in _iter('<hhhhh', lumps['THINGS'])]
        self._ss_sector = {}
        self._ss_secidx = {}

    def subsector_at(self, x, y):
        if not self.nodes:
            return 0
        node = len(self.nodes) - 1
        while not node & 0x8000:
            n = self.nodes[node]
            side = 0 if (y - n.y) * n.dx < n.dy * (x - n.x) else 1
            node = n.child[side]
        return node & 0x7FFF

    def sector_index_of_subsector(self, ss):
        """Sector index of a subsector = sector of its first seg (as the game does)."""
        i = self._ss_secidx.get(ss)
        if i is None:
            _count, first = self.ssectors[ss]
            seg = self.segs[first]
            line = self.lines[seg.line]
            sd = line.right if seg.dir == 0 else line.left
            i = self.sides[sd].sector
            self._ss_secidx[ss] = i
        return i

    def sector_of_subsector(self, ss):
        return self.sectors[self.sector_index_of_subsector(ss)]

    def sector_index_at(self, x, y):
        return self.sector_index_of_subsector(self.subsector_at(x, y))

    def sector_at(self, x, y):
        return self.sector_of_subsector(self.subsector_at(x, y))


def load_level(wad, header):
    """Level named `header` from `wad`, or None if the WAD has no binary map by that name."""
    idx = wad.find_level(header.upper())
    return None if idx is None else Level(wad, idx)


# ----------------------------------------------------------------------------
# Renderer
# ----------------------------------------------------------------------------
class Renderer:
    """Renders one view. `width`/`height` are the framebuffer size in pixels and
    `focal` is the focal length in pixels (default height / 2)."""

    def __init__(self, res, level, header, skill=3,
                 width=DEFAULT_W, height=DEFAULT_H, focal=None, sky=None):
        self.res, self.lv, self.skill = res, level, skill
        self.W, self.H = int(width), int(height)
        if self.W < 1 or self.H < 1:
            raise ValueError('width and height must be positive')
        self.HW = self.W / 2.0
        self.HORIZON = self.H / 2.0
        self.FOCAL = float(focal) if focal else self.H / DEFAULT_FOCAL_DIV
        self.cm = res.cm
        self.fb = [0] * (self.W * self.H)
        # Clip arrays hold the first / last row still open in each column.
        self.ceilclip = [0] * self.W
        self.floorclip = [self.H - 1] * self.W
        self.solid = [False] * self.W       # columns closed by one-sided / closed-door lines
        self.nsolid = 0
        self.drawsegs = []                  # wall ranges, nearest first
        self.visited = set()                # sectors that had a subsector reached by the BSP walk
        self.neg_clip = [-1] * self.W
        self.scr_clip = [self.H] * self.W

        # Doom's light tables (scalelight for walls/sprites, zlight for flats)
        def startmap(i):
            return ((15 - i) * 2) * 32 // 16
        self.scalelight = [[max(0, min(31, startmap(i) - j // 2)) for j in range(48)]
                           for i in range(16)]
        self.zlight = [[max(0, min(31, startmap(i) - int(160 / (j + 1)) // 2)) for j in range(128)]
                       for i in range(16)]

        start = next((t for t in level.things if t.type == 1), None)
        if start is None:
            raise RenderError('No Player 1 start (thing type 1) in this level.')
        self.cx, self.cy = float(start.x), float(start.y)
        self.angle = math.radians(start.angle)
        self.ca, self.sa = math.cos(self.angle), math.sin(self.angle)
        self.start_sector = level.sector_at(start.x, start.y)
        self.cz = self.start_sector.floor + VIEW_HEIGHT

        self.sky = res.texture(sky or self.sky_name(header))

    @staticmethod
    def sky_name(header):
        """Default sky texture for a level header (Doom 1 ExMx / Doom 2 MAPxx rules)."""
        if len(header) == 4 and header[0] == 'E' and header[2] == 'M':
            return 'SKY' + header[1]
        if header.startswith('MAP') and header[3:].isdigit():
            n = int(header[3:])
            return 'SKY1' if n < 12 else 'SKY2' if n < 21 else 'SKY3'
        return 'SKY1'

    # ---- top level ---------------------------------------------------------
    def render(self):
        self.render_bsp()
        self.draw_masked_all()
        return self.fb

    # ---- BSP (iterative, so deep trees never hit the recursion limit) ------
    def render_bsp(self):
        lv = self.lv
        stack = [len(lv.nodes) - 1 if lv.nodes else 0x8000]
        while stack:
            if self.nsolid >= self.W:
                return
            node = stack.pop()
            if node & 0x8000:
                ss = node & 0x7FFF
                count, first = lv.ssectors[ss]
                self.visited.add(lv.sector_index_of_subsector(ss))
                for i in range(first, first + count):
                    self.draw_seg(lv.segs[i])
                continue
            n = lv.nodes[node]
            side = 0 if (self.cy - n.y) * n.dx < n.dy * (self.cx - n.x) else 1
            if self.bbox_visible(n.bbox[side ^ 1]):
                stack.append(n.child[side ^ 1])      # far child, visited second
            stack.append(n.child[side])              # near child, visited first

    def bbox_visible(self, bb):
        top, bottom, left, right = bb
        cx, cy, ca, sa = self.cx, self.cy, self.ca, self.sa
        if left <= cx <= right and bottom <= cy <= top:
            return True
        behind = off_r = off_l = True
        t = self.HW / self.FOCAL            # tan(half horizontal FOV)
        for x in (left, right):
            for y in (bottom, top):
                dx, dy = x - cx, y - cy
                d = dx * ca + dy * sa
                s = dx * sa - dy * ca
                if d > 0:
                    behind = False
                if s <= d * t:
                    off_r = False
                if s >= -d * t:
                    off_l = False
        return not (behind or off_r or off_l)

    # ---- wall segment (follows R_AddLine / R_StoreWallRange / R_RenderSegLoop) ---
    def draw_seg(self, seg):
        W, H, HW, HORIZON, FOCAL = self.W, self.H, self.HW, self.HORIZON, self.FOCAL
        lv, res = self.lv, self.res
        x1, y1 = lv.verts[seg.v1]
        x2, y2 = lv.verts[seg.v2]
        cx, cy, cz, ca, sa = self.cx, self.cy, self.cz, self.ca, self.sa
        if (x2 - x1) * (cy - y1) - (y2 - y1) * (cx - x1) >= 0:   # back-facing
            return
        line = lv.lines[seg.line]
        fi, bi = (line.right, line.left) if seg.dir == 0 else (line.left, line.right)
        if fi == NONE:
            return
        fside = lv.sides[fi]
        fs = lv.sectors[fside.sector]
        bs = lv.sectors[lv.sides[bi].sector] if bi != NONE else None
        fc, ff = fs.ceil, fs.floor

        # ---- R_AddLine classification -------------------------------------
        if bs is None or bs.ceil <= ff or bs.floor >= fc:
            solid_line = True                    # one-sided wall or closed door
        else:
            solid_line = False
            if (bs.ceil == fc and bs.floor == ff and bs.ceil_pic == fs.ceil_pic and
                    bs.floor_pic == fs.floor_pic and bs.light == fs.light and
                    res.texture(fside.mid) is None):
                return      # "empty" line (triggers, self-referencing sectors...): never drawn

        dx1, dy1, dx2, dy2 = x1 - cx, y1 - cy, x2 - cx, y2 - cy
        od1, os1 = dx1 * ca + dy1 * sa, dx1 * sa - dy1 * ca
        od2, os2 = dx2 * ca + dy2 * sa, dx2 * sa - dy2 * ca
        if od1 < NEAR and od2 < NEAR:
            return
        seglen = math.hypot(x2 - x1, y2 - y1)
        ua = seg.offset + fside.xoff
        ub = ua + seglen
        d1, s1, u1, d2, s2, u2 = od1, os1, ua, od2, os2, ub
        if od1 < NEAR:
            t = (NEAR - od1) / (od2 - od1)
            d1, s1, u1 = NEAR, os1 + (os2 - os1) * t, ua + (ub - ua) * t
        if od2 < NEAR:
            t = (NEAR - od1) / (od2 - od1)
            d2, s2, u2 = NEAR, os1 + (os2 - os1) * t, ua + (ub - ua) * t
        sx1 = HW + FOCAL * s1 / d1
        sx2 = HW + FOCAL * s2 / d2
        if sx2 <= sx1:
            return
        xs = max(0, math.ceil(sx1 - 0.5))
        xe = min(W - 1, math.ceil(sx2 - 0.5) - 1)
        if xs > xe:
            return
        invd1, invd2 = 1.0 / d1, 1.0 / d2
        ud1, ud2 = u1 * invd1, u2 * invd2
        span = sx2 - sx1

        # lighting (Doom's fake contrast on axis-aligned walls)
        ln = fs.light >> 4
        if y1 == y2:
            ln -= 1
        elif x1 == x2:
            ln += 1
        sl = self.scalelight[max(0, min(15, ln))]
        zl = self.zlight[max(0, min(15, fs.light >> 4))]

        flags = line.flags
        sky = res.sky_flat_name
        sky_f = fs.ceil_pic == sky
        ft = fc                    # front ceiling as used for the wall top (sky hack below)
        mid = upper = lower = masked_tex = None
        has_upper = has_lower = False
        bc = bf = 0
        anchor_m = anchor_u = anchor_l = anchor_mask = 0.0
        if bs is None:
            mid = res.texture(fside.mid)         # None for '-': nothing is drawn, columns still close
            markfloor = markceiling = True
            if mid is not None:
                anchor_m = (ff + mid[2]) if flags & 0x10 else fc
        else:
            bc, bf = bs.ceil, bs.floor
            if sky_f and bs.ceil_pic == sky:
                ft = bc                          # sky hack: no upper wall between two sky ceilings
            markfloor = (bf != ff or bs.floor_pic != fs.floor_pic or bs.light != fs.light)
            markceiling = (bc != ft or bs.ceil_pic != fs.ceil_pic or bs.light != fs.light)
            if bc <= ff or bf >= fc:             # closed door
                markfloor = markceiling = True
            has_upper = bc < ft
            has_lower = bf > ff
            if has_upper:
                upper = res.texture(fside.upper)
                if upper:
                    anchor_u = fc if flags & 0x08 else bc + upper[2]
            if has_lower:
                lower = res.texture(fside.lower)
                if lower:
                    anchor_l = fc if flags & 0x10 else bf
            masked_tex = res.texture(fside.mid)
            if masked_tex:
                anchor_mask = (max(ff, bf) + masked_tex[2]) if flags & 0x10 else min(fc, bc)
        # planes on the wrong side of the view plane are never marked
        if ff >= cz:
            markfloor = False
        if fc <= cz and not sky_f:
            markceiling = False
        ceil_flat = None if sky_f else res.flat(fs.ceil_pic)
        floor_flat = res.flat(fs.floor_pic)

        yoff = fside.yoff
        ceilclip, floorclip, solid = self.ceilclip, self.floorclip, self.solid
        mcol = [None] * W if masked_tex else None
        xmin, xmax = W, -1
        ceil, floor_ = math.ceil, math.floor

        for x in range(xs, xe + 1):
            if solid[x]:
                continue
            if x < xmin:
                xmin = x
            xmax = x
            cl, fl = ceilclip[x], floorclip[x]
            t = (x + 0.5 - sx1) / span
            invd = invd1 + (invd2 - invd1) * t
            d = 1.0 / invd
            u = (ud1 + (ud2 - ud1) * t) * d
            k = FOCAL * invd

            yl = ceil(HORIZON - (ft - cz) * k - 0.5)       # first row below the ceiling edge
            if yl < cl:
                yl = cl
            if markceiling:
                bottom = yl - 1
                if bottom > fl:
                    bottom = fl
                if cl <= bottom:
                    if sky_f:
                        self.col_sky(x, cl, bottom)
                    else:
                        self.col_plane(x, cl, bottom, fc, ceil_flat, zl)
            yh = ceil(HORIZON - (ff - cz) * k - 0.5) - 1   # last row above the floor edge
            if yh > fl:
                yh = fl
            if markfloor:
                top = yh + 1
                if top < cl:
                    top = cl
                if top <= fl:
                    self.col_plane(x, top, fl, ff, floor_flat, zl)

            if mcol is not None:
                mcol[x] = floor_(u)

            if mid is not None:                            # textured one-sided wall
                if yl <= yh:
                    self.col_wall(x, yl, yh, mid, u, anchor_m, yoff, d, sl)
                ceilclip[x], floorclip[x] = H, -1
                continue

            # two-sided line (or untextured one-sided line)
            if upper:
                m = ceil(HORIZON - (bc - cz) * k - 0.5) - 1
                if m > fl:
                    m = fl
                if m >= yl:
                    self.col_wall(x, yl, m, upper, u, anchor_u, yoff, d, sl)
                    ceilclip[x] = m + 1
                else:
                    ceilclip[x] = yl
            elif markceiling:
                ceilclip[x] = yl
            if lower:
                m = ceil(HORIZON - (bf - cz) * k - 0.5)
                if m < ceilclip[x]:
                    m = ceilclip[x]
                if m <= yh:
                    self.col_wall(x, m, yh, lower, u, anchor_l, yoff, d, sl)
                    floorclip[x] = m - 1
                else:
                    floorclip[x] = yh
            elif markfloor:
                floorclip[x] = yh

        if xmax < 0:
            return                                          # every column was already closed
        if solid_line:
            for x in range(xs, xe + 1):
                if not solid[x]:
                    solid[x] = True
                    self.nsolid += 1

        # ---- silhouette / sprite clip info (R_StoreWallRange) ---------------
        ds = DrawSeg()
        ds.x1, ds.x2, ds.seg = xmin, xmax, (x1, y1, x2, y2)
        ds.topclip = ds.botclip = None
        ds.bsil = ds.tsil = 0
        sil = 0
        if bs is None:
            sil = SIL_BOTTOM | SIL_TOP
            ds.botclip, ds.topclip = self.neg_clip, self.scr_clip
            ds.bsil, ds.tsil = BIG, -BIG
        else:
            if ff > bf:
                sil, ds.bsil = SIL_BOTTOM, ff
            elif bf > cz:
                sil, ds.bsil = SIL_BOTTOM, BIG
            if fc < bc:
                sil |= SIL_TOP
                ds.tsil = fc
            elif bc < cz:
                sil |= SIL_TOP
                ds.tsil = -BIG
            if bc <= ff:
                ds.botclip, ds.bsil = self.neg_clip, BIG
                sil |= SIL_BOTTOM
            if bf >= fc:
                ds.topclip, ds.tsil = self.scr_clip, -BIG
                sil |= SIL_TOP
        if (sil & SIL_TOP or masked_tex) and ds.topclip is None:
            ds.topclip = ceilclip[:]
        if (sil & SIL_BOTTOM or masked_tex) and ds.botclip is None:
            ds.botclip = floorclip[:]
        if masked_tex:
            if not sil & SIL_TOP:
                sil |= SIL_TOP
                ds.tsil = -BIG
            if not sil & SIL_BOTTOM:
                sil |= SIL_BOTTOM
                ds.bsil = BIG
        ds.sil = sil
        if sil == 0 and not masked_tex:
            return
        ds.scale1 = FOCAL * (invd1 + (invd2 - invd1) * ((xmin + 0.5 - sx1) / span))
        ds.scale2 = FOCAL * (invd1 + (invd2 - invd1) * ((xmax + 0.5 - sx1) / span))
        ds.mtex, ds.mcol = masked_tex, mcol
        ds.sx1, ds.span, ds.invd1, ds.invd2, ds.ud1, ds.ud2 = sx1, span, invd1, invd2, ud1, ud2
        ds.anchor, ds.yoff, ds.sl = anchor_mask, yoff, sl
        self.drawsegs.append(ds)

    # ---- column primitives -------------------------------------------------
    def col_wall(self, x, r0, r1, tex, u, anchor, rowoff, d, sl):
        W, HORIZON, FOCAL = self.W, self.HORIZON, self.FOCAL
        cols, tw, th = tex
        col = cols[math.floor(u) % tw]
        lr = self.cm[sl[min(47, int(LIGHT_PROJ * 16.0 / d))]]
        step = d / FOCAL
        v = anchor + rowoff - self.cz - (HORIZON - r0 - 0.5) * step
        fb = self.fb
        idx = r0 * W + x
        floor = math.floor
        for _ in range(r0, r1 + 1):
            p = col[floor(v) % th]
            fb[idx] = lr[p if p >= 0 else 0]
            v += step
            idx += W

    def col_plane(self, x, r0, r1, h, flat, zl):
        W, HW, HORIZON, FOCAL = self.W, self.HW, self.HORIZON, self.FOCAL
        cx, cy, cz, ca, sa = self.cx, self.cy, self.cz, self.ca, self.sa
        num = FOCAL * (h - cz)
        lat = (x + 0.5 - HW) / FOCAL
        fb, cm, floor = self.fb, self.cm, math.floor
        idx = r0 * W + x
        for r in range(r0, r1 + 1):
            den = HORIZON - (r + 0.5)
            if den != 0:
                D = num / den
                if D > 0:
                    l = lat * D
                    wx = cx + ca * D + sa * l
                    wy = cy + sa * D - ca * l
                    j = int(D * 0.0625)
                    if j > 127:
                        j = 127
                    fb[idx] = cm[zl[j]][flat[((floor(-wy) & 63) << 6) | (floor(wx) & 63)]]
            idx += W

    def col_sky(self, x, r0, r1):
        W, HW, HORIZON, FOCAL = self.W, self.HW, self.HORIZON, self.FOCAL
        cols, sw, sh = self.sky
        ang = self.angle - math.atan((x + 0.5 - HW) / FOCAL)
        col = cols[int(math.floor(ang / (2 * math.pi) * 1024)) % sw]
        lr = self.cm[0]
        fb = self.fb
        scale = 100.0 / FOCAL         # sky texels per pixel (== 200 / H when FOCAL == H / 2)
        for r in range(r0, r1 + 1):
            p = col[int(100 + (r + 0.5 - HORIZON) * scale) % sh]
            fb[r * W + x] = lr[p if p >= 0 else 0]

    # ---- masked mid textures and sprites (R_DrawMasked) ----------------------
    def render_masked_range(self, ds, r1, r2):
        """R_RenderMaskedSegRange: fences, grates... clipped by the saved clip arrays."""
        W, H, HORIZON, FOCAL = self.W, self.H, self.HORIZON, self.FOCAL
        cols, tw, th = ds.mtex
        cz = self.cz
        fb, floor = self.fb, math.floor
        mcol, topc, botc = ds.mcol, ds.topclip, ds.botclip
        for x in range(r1, r2 + 1):
            ux = mcol[x]
            if ux is None:
                continue
            mcol[x] = None
            t = (x + 0.5 - ds.sx1) / ds.span
            invd = ds.invd1 + (ds.invd2 - ds.invd1) * t
            d = 1.0 / invd
            a = topc[x] if topc[x] > 0 else 0
            b = botc[x] if botc[x] < H - 1 else H - 1
            if a > b:
                continue
            col = cols[ux % tw]
            lr = self.cm[ds.sl[min(47, int(LIGHT_PROJ * 16.0 / d))]]
            step = d / FOCAL
            v = ds.anchor + ds.yoff - cz - (HORIZON - a - 0.5) * step
            idx = a * W + x
            for _ in range(a, b + 1):
                iv = floor(v)
                if 0 <= iv < th:
                    p = col[iv]
                    if p >= 0:
                        fb[idx] = lr[p]
                v += step
                idx += W

    def draw_masked_all(self):
        sprites = self.project_things()
        sprites.sort(key=lambda sp: sp.scale)               # farthest first
        for spr in sprites:
            self.draw_sprite(spr)
        for ds in reversed(self.drawsegs):                  # remaining masked mid textures
            if ds.mcol is not None:
                self.render_masked_range(ds, ds.x1, ds.x2)

    # ---- things (sprites) --------------------------------------------------
    def thing_spawns(self, t):
        if t.flags & 0x10:                     # multiplayer-only
            return False
        bit = 1 if self.skill <= 2 else 2 if self.skill == 3 else 4
        return bool(t.flags & bit)

    def project_things(self):
        lv, res = self.lv, self.res
        W, H, HW, HORIZON, FOCAL = self.W, self.H, self.HW, self.HORIZON, self.FOCAL
        out = []
        for t in lv.things:
            if t.type in (1, 2, 3, 4, 11, 14) or not self.thing_spawns(t):
                continue
            if t.type in THING_FRAMES:
                prefix, frame = THING_FRAMES[t.type]
            elif t.type in THING_SPRITES:
                prefix, frame = THING_SPRITES[t.type], 'A'
            else:
                continue
            dx, dy = t.x - self.cx, t.y - self.cy
            tz = dx * self.ca + dy * self.sa
            if tz < 4:
                continue
            si = lv.sector_index_at(t.x, t.y)
            if si not in self.visited:         # sprites are only added for sectors the BSP walk reached
                continue
            frames = res.sprite_frames.get(prefix)
            if not frames:
                continue
            fr = frames.get(frame) or frames[sorted(frames)[0]]
            rot = int(((math.degrees(math.atan2(dy, dx)) - t.angle + 202.5) % 360) // 45) & 7
            ent = fr[rot] or next((e for e in fr if e), None)
            if ent is None:
                continue
            patch = res.sprite_patch(ent[0])
            if patch is None:
                continue
            cols, pw, ph, lo, to = patch
            flip = ent[1]
            side = dx * self.sa - dy * self.ca
            scale = FOCAL / tz
            xl = side - ((pw - lo) if flip else lo)
            x1f = HW + xl * scale
            x2f = x1f + pw * scale
            xs = max(0, math.ceil(x1f - 0.5))
            xe = min(W - 1, math.ceil(x2f - 0.5) - 1)
            if xs > xe:
                continue
            sec = lv.sectors[si]
            z = sec.ceil - HANGING[t.type] if t.type in HANGING else sec.floor
            ytop = HORIZON - (z + to - self.cz) * scale
            ybot = ytop + ph * scale
            r0 = max(0, math.ceil(ytop - 0.5))
            r1 = min(H - 1, math.ceil(ybot - 0.5) - 1)
            if r0 > r1:
                continue
            if prefix in FULLBRIGHT:
                lr = self.cm[0]
            else:
                ln = max(0, min(15, sec.light >> 4))
                lr = self.cm[self.scalelight[ln][min(47, int(LIGHT_PROJ * 16.0 / tz))]]
            v = VisSprite()
            v.scale, v.gx, v.gy, v.gz, v.gzt = scale, t.x, t.y, z, z + to
            v.xs, v.xe, v.x1f, v.ytop, v.r0, v.r1 = xs, xe, x1f, ytop, r0, r1
            v.cols, v.pw, v.ph, v.flip, v.lr = cols, pw, ph, flip, lr
            v.fuzz = t.type in FUZZ_TYPES
            out.append(v)
        return out

    def draw_sprite(self, spr):
        """R_DrawSprite: clip against the silhouettes of the wall ranges in front of it."""
        W, H = self.W, self.H
        x1, x2 = spr.xs, spr.xe
        clipbot = [None] * W
        cliptop = [None] * W
        for ds in reversed(self.drawsegs):
            if ds.x1 > x2 or ds.x2 < x1 or (ds.sil == 0 and ds.mcol is None):
                continue
            r1 = ds.x1 if ds.x1 > x1 else x1
            r2 = ds.x2 if ds.x2 < x2 else x2
            if ds.scale1 > ds.scale2:
                lowscale, scale = ds.scale2, ds.scale1
            else:
                lowscale, scale = ds.scale1, ds.scale2
            if scale < spr.scale:
                behind = True
            elif lowscale < spr.scale:
                ax, ay, bx, by = ds.seg           # sprite on the viewer's side of the seg
                behind = (bx - ax) * (spr.gy - ay) - (by - ay) * (spr.gx - ax) < 0
            else:
                behind = False
            if behind:
                if ds.mcol is not None:
                    self.render_masked_range(ds, r1, r2)
                continue
            sil = ds.sil
            if spr.gz >= ds.bsil:
                sil &= ~SIL_BOTTOM
            if spr.gzt <= ds.tsil:
                sil &= ~SIL_TOP
            if sil & SIL_BOTTOM:
                bc = ds.botclip
                for x in range(r1, r2 + 1):
                    if clipbot[x] is None:
                        clipbot[x] = bc[x]
            if sil & SIL_TOP:
                tc = ds.topclip
                for x in range(r1, r2 + 1):
                    if cliptop[x] is None:
                        cliptop[x] = tc[x]

        cols, pw, ph, flip = spr.cols, spr.pw, spr.ph, spr.flip
        scale, ytop, x1f = spr.scale, spr.ytop, spr.x1f
        r0, r1 = spr.r0, spr.r1
        lr, fuzzrow, fuzz = spr.lr, self.cm[6], spr.fuzz
        fb = self.fb
        for x in range(x1, x2 + 1):
            u = int((x + 0.5 - x1f) / scale)
            u = max(0, min(pw - 1, u))
            col = cols[pw - 1 - u if flip else u]
            a = r0
            ct = cliptop[x]
            if ct is not None and ct > a:
                a = ct
            b = r1
            cb = clipbot[x]
            if cb is not None and cb < b:
                b = cb
            idx = a * W + x
            for r in range(a, b + 1):
                v = int((r + 0.5 - ytop) / scale)
                if 0 <= v < ph:
                    p = col[v]
                    if p >= 0:
                        fb[idx] = fuzzrow[fb[idx]] if fuzz else lr[p]
                idx += W


# ----------------------------------------------------------------------------
# High level API
# ----------------------------------------------------------------------------
def doom1_sky_name(header):
    """Sky for a Doom 1 map after the ExMx -> MAPxx conversion,
    where MAP number = (episode - 1) * 9 + map. MAP01-09 -> SKY1, MAP10-18 -> SKY2, ..."""
    header = header.upper()
    if header.startswith('MAP') and header[3:].isdigit() and int(header[3:]) >= 1:
        return 'SKY%d' % min(4, (int(header[3:]) - 1) // 9 + 1)
    return None        # not a converted Doom 1 header: use the default rule


def render_level(res, level, header, width=DEFAULT_W, height=DEFAULT_H,
                 focal_div=DEFAULT_FOCAL_DIV, skill=3, sky=None):
    """Render `level` from the Player 1 start.

    Returns the framebuffer as a flat list of `width * height` palette indices.
    The focal length is `height / focal_div` pixels. `sky` overrides the sky texture name.
    """
    r = Renderer(res, level, header.upper(), skill, width, height,
                 height / float(focal_div), sky)
    return r.render()


def level_select_lump_names(header):
    """('MAP01P', 'MAP01W') for 'MAP01', or None if the names would exceed 8 chars."""
    header = header.upper()
    if not header or len(header) + 1 > 8:
        return None
    return tuple(header + spec[0] for spec in LEVEL_SELECT_SPECS)


def render_level_select(res, level, header, skill=3, sky=None):
    """Render both level select pictures. Returns {'P': patch_bytes, 'W': patch_bytes}."""
    pics = {}
    for suffix, w, h, focal_div in LEVEL_SELECT_SPECS:
        fb = render_level(res, level, header, w, h, focal_div, skill, sky)
        pics[suffix] = fb_to_patch(fb, w, h)
    return pics


def render_level_select_images(res, level_wad, headers=None, skill=3,
                               base_names=None, log=None, sky_for=None):
    """Render level select patches for several maps of `level_wad`.

    headers    - map header lumps to render (default: every map in level_wad)
    base_names - optional {header: lump name stem}; the stem gets 'P'/'W' appended
    log        - optional callable(str) for progress / skip messages
    sky_for    - optional callable(header) -> sky texture name or None (e.g. doom1_sky_name)

    Maps that cannot be rendered (UDMF, Hexen format, no BSP, no player start, ...)
    are skipped with a message. Returns {lump_name: patch_bytes}.
    """
    log = log or (lambda *_: None)
    base_names = base_names or {}
    if headers is None:
        headers = level_wad.level_headers()
    images = {}
    for header in headers:
        header = header.upper()
        base = base_names.get(header, header)
        if level_select_lump_names(base) is None:
            log('  %s: name too long for a level select lump, skipped' % base)
            continue
        try:
            level = load_level(level_wad, header)
            if level is None:
                log('  %s: no binary Doom-format map data (UDMF?), skipped' % base)
                continue
            pics = render_level_select(res, level, header, skill,
                                       sky_for(header) if sky_for else None)
        except RenderError as e:
            log('  %s: skipped (%s)' % (base, e))
            continue
        except Exception as e:
            log('  %s: render failed (%s: %s)' % (base, type(e).__name__, e))
            continue
        for suffix, data in pics.items():
            images[base + suffix] = data
        log('  Rendered level select images %sP / %sW' % (base, base))
    return images


# ----------------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------------
def fb_to_patch(fb, w, h):
    """Palette-index framebuffer -> opaque Doom picture (one post per column)."""
    if not (0 < h <= 255):
        raise ValueError('patch height must be 1..255')
    offsets_base = 8 + 4 * w
    body = bytearray()
    offsets = []
    for x in range(w):
        offsets.append(offsets_base + len(body))
        col = bytes(fb[y * w + x] for y in range(h))
        body += bytes((0, h, col[0])) + col + bytes((col[-1], 255))
    return (struct.pack('<hhhh', w, h, 0, 0) +
            struct.pack('<%dI' % w, *offsets) + bytes(body))


def fb_to_rgb(fb, w, h, palette, scale=1):
    """Palette-index framebuffer -> packed RGB bytes (optionally upscaled)."""
    s = max(1, int(scale))
    rows = []
    for y in range(h):
        row = b''.join(bytes(palette[fb[y * w + x]]) * s for x in range(w))
        rows.extend([row] * s)
    return b''.join(rows)


def write_png(path, w, h, rgb):
    raw = b''.join(b'\x00' + rgb[y * w * 3:(y + 1) * w * 3] for y in range(h))

    def chunk(tag, data):
        return (struct.pack('>I', len(data)) + tag + data +
                struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF))
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b'IDAT', zlib.compress(raw, 9)))
        f.write(chunk(b'IEND', b''))


def find_iwad(near):
    """Look for a known IWAD file name in the folder containing `near`."""
    folder = os.path.dirname(os.path.abspath(near))
    names = ['doom2.wad', 'doom.wad', 'doomu.wad', 'plutonia.wad', 'tnt.wad',
             'freedoom2.wad', 'freedoom1.wad', 'doom1.wad']
    have = {n.lower(): n for n in os.listdir(folder)}
    for n in names:
        if n in have:
            return os.path.join(folder, have[n])
    return None


def resolve_iwad(explicit=None, near=None, base=None, log=None):
    """Pick the base-game WAD to use for textures/flats/sprites/palette.

    Returns a `Wad` or None.  Order: the explicit path; otherwise, unless `base`
    (the WAD being rendered) is itself an IWAD, a known IWAD next to `near`.
    """
    log = log or (lambda *_: None)
    if explicit:
        try:
            wad = Wad(explicit)
            log('Using IWAD for level select renders: %s' % explicit)
            return wad
        except (OSError, RenderError) as e:
            log('Could not use IWAD %s (%s); trying auto-detection' % (explicit, e))
    if base is not None and base.is_iwad:
        return None
    if near:
        try:
            path = find_iwad(near)
            if path:
                log('Auto-detected IWAD for level select renders: %s' % path)
                return Wad(path)
        except (OSError, RenderError):
            pass
    return None


def main(argv=None):
    ap = argparse.ArgumentParser(allow_abbrev=False,
                                 description='Render a Doom level from the Player 1 start.')
    ap.add_argument('wad', help='WAD file containing the level')
    ap.add_argument('-header', required=True, help='level marker lump, e.g. E1M1 or MAP01')
    ap.add_argument('-iwad', help='base game WAD for textures/flats/sprites/palette '
                                  '(auto-detected next to the PWAD if omitted)')
    ap.add_argument('-o', '--output', help='output PNG (default <header>.png)')
    ap.add_argument('-scale', type=int, default=1, help='integer nearest-neighbour upscale')
    ap.add_argument('-skill', type=int, default=3, choices=range(1, 6),
                    help='skill level for thing filtering (default 3)')
    ap.add_argument('-width', type=int, default=DEFAULT_W, help='framebuffer width')
    ap.add_argument('-height', type=int, default=DEFAULT_H, help='framebuffer height')
    ap.add_argument('-focal-div', type=float, default=DEFAULT_FOCAL_DIV,
                    help='FOCAL = height / this value (default %.1f)' % DEFAULT_FOCAL_DIV)
    ap.add_argument('-preset', choices=[s[0].lower() for s in LEVEL_SELECT_SPECS],
                    help='SRB2 level select size: p = 160x100, w = 564x100 '
                         '(overrides -width/-height/-focal-div)')
    a = ap.parse_args(argv)
    header = a.header.upper()

    width, height, focal_div = a.width, a.height, a.focal_div
    if a.preset:
        for suffix, w, h, fd in LEVEL_SELECT_SPECS:
            if suffix.lower() == a.preset:
                width, height, focal_div = w, h, fd

    try:
        main_wad = Wad(a.wad)
        wads = [main_wad]
        iwad_path = a.iwad
        if iwad_path is None and not main_wad.is_iwad:
            iwad_path = find_iwad(a.wad)
            if iwad_path:
                print('Using IWAD:', iwad_path)
        if iwad_path:
            wads.insert(0, Wad(iwad_path))

        level = None
        for wad in reversed(wads):          # prefer the PWAD's version of the map
            level = load_level(wad, header)
            if level is not None:
                break
        if level is None:
            raise RenderError('Level %s not found.' % header)

        res = Resources(wads)
        r = Renderer(res, level, header, a.skill, width, height, height / focal_div)
        print('%s: player 1 at (%d, %d) facing %d deg, floor %d, eye z %.0f'
              % (header, r.cx, r.cy, round(math.degrees(r.angle)), r.start_sector.floor, r.cz))
        fb = r.render()
    except (RenderError, OSError) as e:
        print('doomrender: %s' % e, file=sys.stderr)
        return 1

    s = max(1, a.scale)
    out = a.output or header + '.png'
    write_png(out, width * s, height * s, fb_to_rgb(fb, width, height, res.palette, s))
    print('Wrote', out)
    return 0


if __name__ == '__main__':
    sys.exit(main())