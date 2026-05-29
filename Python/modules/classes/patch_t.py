import struct
from typing import Iterable, List, Optional, Sequence

__all__ = ["post_t", "patch_t", "toPatchClass"]


class post_t:
    """
    Doom patch post:
        topdelta: uint8
        length:   uint8
        unused:   uint8   (always 0)
        data:     uint8[length]
        unused:   uint8   (always 0)
    """

    __slots__ = ("topdelta", "length", "data")

    def __init__(self, topdelta: int, data: bytes):
        if not (0 <= topdelta <= 255):
            raise ValueError("topdelta must be 0..255")
        if len(data) > 255:
            raise ValueError("post length must be <= 255")
        self.topdelta = topdelta
        self.length = len(data)
        self.data = bytes(data)

    def toBytes(self) -> bytes:
        return struct.pack(
            f"<BBB{self.length}sB",
            self.topdelta,
            self.length,
            0,
            self.data,
            0,
        )

    @staticmethod
    def fromBytes(data: bytes, offset: int):
        """
        Returns (post_or_none, next_offset).
        If the column terminator 0xFF is found, returns (None, offset + 1).
        """
        topdelta = data[offset]
        if topdelta == 0xFF:
            return None, offset + 1

        length = data[offset + 1]
        pixel_data = data[offset + 3 : offset + 3 + length]
        next_offset = offset + 3 + length + 1
        return post_t(topdelta, pixel_data), next_offset


class patch_t:
    """
    In-memory Doom patch.

    columns[x] is a list of post_t objects for that column.
    """

    __slots__ = ("width", "height", "leftoffset", "topoffset", "columns")

    def __init__(
        self,
        width: int,
        height: int,
        leftoffset: int = 0,
        topoffset: int = 0,
    ):
        if width < 0 or height < 0:
            raise ValueError("width/height must be non-negative")
        self.width = int(width)
        self.height = int(height)
        self.leftoffset = int(leftoffset)
        self.topoffset = int(topoffset)
        self.columns: List[List[post_t]] = [[] for _ in range(self.width)]

    def addPost(self, column: int, topdelta: int, data: bytes):
        """
        Add one post to a column.

        This is the low-level form. The caller is responsible for not
        producing overlapping posts if they do not want them.
        """
        if not (0 <= column < self.width):
            raise IndexError("column out of range")
        self.columns[column].append(post_t(topdelta, data))

    def setColumn(self, column: int, pixels: Sequence[Optional[int]]):
        """
        Replace a whole column from a vertical list of pixel indices.

        Transparent pixels are skipped when forming posts.
        """
        if not (0 <= column < self.width):
            raise IndexError("column out of range")

        posts: List[post_t] = []
        run_start: Optional[int] = None
        run_data: List[int] = []

        for y, px in enumerate(pixels):
            if px is None:
                if run_start is not None:
                    posts.append(post_t(run_start, bytes(run_data)))
                    run_start = None
                    run_data = []
                continue

            if not (0 <= px <= 255):
                raise ValueError("pixel must be 0..255 or None")

            if run_start is None:
                run_start = y
            run_data.append(px)

        if run_start is not None:
            posts.append(post_t(run_start, bytes(run_data)))

        self.columns[column] = posts

    def fromPixelGrid(
        self,
        grid: Sequence[Sequence[int]],
        transparent: Optional[int] = None,
    ):
        """
        Fill the patch from a 2D pixel grid: grid[y][x].

        This is the easiest path for a texture script:
        render the texture into a flat image first, then call this.
        
        Args:
            grid: 2D list of pixel indices (0-255)
            transparent: If provided, treat this palette index as transparent.
                         If None, all pixels are considered opaque.
        """
        if not grid:
            self.width = 0
            self.height = 0
            self.columns = []
            return self

        h = len(grid)
        w = len(grid[0])
        if any(len(row) != w for row in grid):
            raise ValueError("all rows in grid must have the same length")

        self.width = w
        self.height = h
        self.columns = [[] for _ in range(w)]

        for x in range(w):
            # Convert column to list with None for transparent pixels
            col = []
            for y in range(h):
                px = grid[y][x]
                if transparent is not None and px == transparent:
                    col.append(None)
                else:
                    col.append(px)
            self.setColumn(x, col)  # setColumn now handles None values properly

        return self

    def _build_columns_blob(self):
        columnofs: List[int] = []
        blob = bytearray()

        for col in self.columns:
            columnofs.append(len(blob))
            for post in col:
                blob.extend(post.toBytes())
            blob.append(0xFF)  # end of column

        return columnofs, bytes(blob)

    def toBytes(self) -> bytes:
        """
        Serialize to Doom patch format.
        columnofs are absolute offsets from the start of the patch.
        """
        columnofs, column_blob = self._build_columns_blob()

        header = struct.pack(
            f"<HHhh{self.width}I",
            self.width,
            self.height,
            self.leftoffset,
            self.topoffset,
            *[ofs + 8 + (4 * self.width) for ofs in columnofs],
        )
        return header + column_blob

    def copy(self):
        other = patch_t(self.width, self.height, self.leftoffset, self.topoffset)
        other.columns = [[post_t(p.topdelta, p.data) for p in col] for col in self.columns]
        return other


def toPatchClass(data: bytes) -> patch_t:
    """
    Parse a raw Doom patch lump into a patch_t.
    """
    width, height, leftoffset, topoffset = struct.unpack_from("<HHhh", data, 0)
    columnofs = struct.unpack_from(f"<{width}I", data, 8)  # Use 'width', not 'self.width'

    patch = patch_t(width, height, leftoffset, topoffset)

    for col_idx, col_ofs in enumerate(columnofs):
        offset = col_ofs
        while True:
            topdelta = data[offset]
            if topdelta == 0xFF:
                break
            post, offset = post_t.fromBytes(data, offset)
            if post is not None:
                patch.columns[col_idx].append(post)

    return patch