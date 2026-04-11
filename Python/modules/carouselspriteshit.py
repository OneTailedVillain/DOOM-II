"""
Module for monochromizing sprite graphics in Doom WADs.
Converts sprites to red-scale (0.0 = #000000, 1.0 = #FF0000) using the palette.
Also creates carousel graphics with colored outlines.
"""

import struct
from typing import List, Optional, Tuple, Dict
import sys
import os
from io import BytesIO

# Add parent directory to path to import patch_t
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from classes.patch_t import patch_t, toPatchClass

# Try to import PIL for image manipulation
try:
	from PIL import Image
	PIL_AVAILABLE = True
except ImportError:
	PIL_AVAILABLE = False
	print("Warning: PIL/Pillow not installed. Outline functionality will be disabled.")

# Fallback palette
FALLBACK_PALETTE = bytes([
0x00, 0x00, 0x00, 0x1F, 0x17, 0x0B, 0x17, 0x0F, 0x07, 0x4B, 0x4B, 0x4B, 0xFF, 0xFF, 0xFF, 0x1B, 0x1B, 0x1B, 0x13, 0x13, 0x13, 0x0B, 0x0B, 0x0B, 0x07, 0x07, 0x07, 0x2F, 0x37, 0x1F, 0x23, 0x2B, 0x0F, 0x17, 0x1F, 0x07, 0x0F, 0x17, 0x00, 0x4F, 0x3B, 0x2B, 0x47, 0x33, 0x23, 0x3F, 0x2B, 0x1B, 0xFF, 0xB7, 0xB7, 0xF7, 0xAB, 0xAB, 0xF3, 0xA3, 0xA3, 0xEB, 0x97, 0x97, 0xE7, 0x8F, 0x8F, 0xDF, 0x87, 0x87, 0xDB, 0x7B, 0x7B, 0xD3, 0x73, 0x73, 0xCB, 0x6B, 0x6B, 0xC7, 0x63, 0x63, 0xBF, 0x5B, 0x5B, 0xBB, 0x57, 0x57, 0xB3, 0x4F, 0x4F, 0xAF, 0x47, 0x47, 0xA7, 0x3F, 0x3F, 0xA3, 0x3B, 0x3B, 0x9B, 0x33, 0x33, 0x97, 0x2F, 0x2F, 0x8F, 0x2B, 0x2B, 0x8B, 0x23, 0x23, 0x83, 0x1F, 0x1F, 0x7F, 0x1B, 0x1B, 0x77, 0x17, 0x17, 0x73, 0x13, 0x13, 0x6B, 0x0F, 0x0F, 0x67, 0x0B, 0x0B, 0x5F, 0x07, 0x07, 0x5B, 0x07, 0x07, 0x53, 0x07, 0x07, 0x4F, 0x00, 0x00, 0x47, 0x00, 0x00, 0x43, 0x00, 0x00, 0xFF, 0xEB, 0xDF, 0xFF, 0xE3, 0xD3, 0xFF, 0xDB, 0xC7, 0xFF, 0xD3, 0xBB, 0xFF, 0xCF, 0xB3, 0xFF, 0xC7, 0xA7, 0xFF, 0xBF, 0x9B, 0xFF, 0xBB, 0x93, 0xFF, 0xB3, 0x83, 0xF7, 0xAB, 0x7B, 0xEF, 0xA3, 0x73, 0xE7, 0x9B, 0x6B, 0xDF, 0x93, 0x63, 0xD7, 0x8B, 0x5B, 0xCF, 0x83, 0x53, 0xCB, 0x7F, 0x4F, 0xBF, 0x7B, 0x4B, 0xB3, 0x73, 0x47, 0xAB, 0x6F, 0x43, 0xA3, 0x6B, 0x3F, 0x9B, 0x63, 0x3B, 0x8F, 0x5F, 0x37, 0x87, 0x57, 0x33, 0x7F, 0x53, 0x2F, 0x77, 0x4F, 0x2B, 0x6B, 0x47, 0x27, 0x5F, 0x43, 0x23, 0x53, 0x3F, 0x1F, 0x4B, 0x37, 0x1B, 0x3F, 0x2F, 0x17, 0x33, 0x2B, 0x13, 0x2B, 0x23, 0x0F, 0xEF, 0xEF, 0xEF, 0xE7, 0xE7, 0xE7, 0xDF, 0xDF, 0xDF, 0xDB, 0xDB, 0xDB, 0xD3, 0xD3, 0xD3, 0xCB, 0xCB, 0xCB, 0xC7, 0xC7, 0xC7, 0xBF, 0xBF, 0xBF, 0xB7, 0xB7, 0xB7, 0xB3, 0xB3, 0xB3, 0xAB, 0xAB, 0xAB, 0xA7, 0xA7, 0xA7, 0x9F, 0x9F, 0x9F, 0x97, 0x97, 0x97, 0x93, 0x93, 0x93, 0x8B, 0x8B, 0x8B, 0x83, 0x83, 0x83, 0x7F, 0x7F, 0x7F, 0x77, 0x77, 0x77, 0x6F, 0x6F, 0x6F, 0x6B, 0x6B, 0x6B, 0x63, 0x63, 0x63, 0x5B, 0x5B, 0x5B, 0x57, 0x57, 0x57, 0x4F, 0x4F, 0x4F, 0x47, 0x47, 0x47, 0x43, 0x43, 0x43, 0x3B, 0x3B, 0x3B, 0x37, 0x37, 0x37, 0x2F, 0x2F, 0x2F, 0x27, 0x27, 0x27, 0x23, 0x23, 0x23, 0x77, 0xFF, 0x6F, 0x6F, 0xEF, 0x67, 0x67, 0xDF, 0x5F, 0x5F, 0xCF, 0x57, 0x5B, 0xBF, 0x4F, 0x53, 0xAF, 0x47, 0x4B, 0x9F, 0x3F, 0x43, 0x93, 0x37, 0x3F, 0x83, 0x2F, 0x37, 0x73, 0x2B, 0x2F, 0x63, 0x23, 0x27, 0x53, 0x1B, 0x1F, 0x43, 0x17, 0x17, 0x33, 0x0F, 0x13, 0x23, 0x0B, 0x0B, 0x17, 0x07, 0xBF, 0xA7, 0x8F, 0xB7, 0x9F, 0x87, 0xAF, 0x97, 0x7F, 0xA7, 0x8F, 0x77, 0x9F, 0x87, 0x6F, 0x9B, 0x7F, 0x6B, 0x93, 0x7B, 0x63, 0x8B, 0x73, 0x5B, 0x83, 0x6B, 0x57, 0x7B, 0x63, 0x4F, 0x77, 0x5F, 0x4B, 0x6F, 0x57, 0x43, 0x67, 0x53, 0x3F, 0x5F, 0x4B, 0x37, 0x57, 0x43, 0x33, 0x53, 0x3F, 0x2F, 0x9F, 0x83, 0x63, 0x8F, 0x77, 0x53, 0x83, 0x6B, 0x4B, 0x77, 0x5F, 0x3F, 0x67, 0x53, 0x33, 0x5B, 0x47, 0x2B, 0x4F, 0x3B, 0x23, 0x43, 0x33, 0x1B, 0x7B, 0x7F, 0x63, 0x6F, 0x73, 0x57, 0x67, 0x6B, 0x4F, 0x5B, 0x63, 0x47, 0x53, 0x57, 0x3B, 0x47, 0x4F, 0x33, 0x3F, 0x47, 0x2B, 0x37, 0x3F, 0x27, 0xFF, 0xFF, 0x73, 0xEB, 0xDB, 0x57, 0xD7, 0xBB, 0x43, 0xC3, 0x9B, 0x2F, 0xAF, 0x7B, 0x1F, 0x9B, 0x5B, 0x13, 0x87, 0x43, 0x07, 0x73, 0x2B, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xDB, 0xDB, 0xFF, 0xBB, 0xBB, 0xFF, 0x9B, 0x9B, 0xFF, 0x7B, 0x7B, 0xFF, 0x5F, 0x5F, 0xFF, 0x3F, 0x3F, 0xFF, 0x1F, 0x1F, 0xFF, 0x00, 0x00, 0xEF, 0x00, 0x00, 0xE3, 0x00, 0x00, 0xD7, 0x00, 0x00, 0xCB, 0x00, 0x00, 0xBF, 0x00, 0x00, 0xB3, 0x00, 0x00, 0xA7, 0x00, 0x00, 0x9B, 0x00, 0x00, 0x8B, 0x00, 0x00, 0x7F, 0x00, 0x00, 0x73, 0x00, 0x00, 0x67, 0x00, 0x00, 0x5B, 0x00, 0x00, 0x4F, 0x00, 0x00, 0x43, 0x00, 0x00, 0xE7, 0xE7, 0xFF, 0xC7, 0xC7, 0xFF, 0xAB, 0xAB, 0xFF, 0x8F, 0x8F, 0xFF, 0x73, 0x73, 0xFF, 0x53, 0x53, 0xFF, 0x37, 0x37, 0xFF, 0x1B, 0x1B, 0xFF, 0x00, 0x00, 0xFF, 0x00, 0x00, 0xE3, 0x00, 0x00, 0xCB, 0x00, 0x00, 0xB3, 0x00, 0x00, 0x9B, 0x00, 0x00, 0x83, 0x00, 0x00, 0x6B, 0x00, 0x00, 0x53, 0xFF, 0xFF, 0xFF, 0xFF, 0xEB, 0xDB, 0xFF, 0xD7, 0xBB, 0xFF, 0xC7, 0x9B, 0xFF, 0xB3, 0x7B, 0xFF, 0xA3, 0x5B, 0xFF, 0x8F, 0x3B, 0xFF, 0x7F, 0x1B, 0xF3, 0x73, 0x17, 0xEB, 0x6F, 0x0F, 0xDF, 0x67, 0x0F, 0xD7, 0x5F, 0x0B, 0xCB, 0x57, 0x07, 0xC3, 0x4F, 0x00, 0xB7, 0x47, 0x00, 0xAF, 0x43, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xD7, 0xFF, 0xFF, 0xB3, 0xFF, 0xFF, 0x8F, 0xFF, 0xFF, 0x6B, 0xFF, 0xFF, 0x47, 0xFF, 0xFF, 0x23, 0xFF, 0xFF, 0x00, 0xA7, 0x3F, 0x00, 0x9F, 0x37, 0x00, 0x93, 0x2F, 0x00, 0x87, 0x23, 0x00, 0x4F, 0x3B, 0x27, 0x43, 0x2F, 0x1B, 0x37, 0x23, 0x13, 0x2F, 0x1B, 0x0B, 0x00, 0x00, 0x53, 0x00, 0x00, 0x47, 0x00, 0x00, 0x3B, 0x00, 0x00, 0x2F, 0x00, 0x00, 0x23, 0x00, 0x00, 0x17, 0x00, 0x00, 0x0B, 0x00, 0x00, 0x00, 0xFF, 0x9F, 0x43, 0xFF, 0xE7, 0x4B, 0xFF, 0x7B, 0xFF, 0xFF, 0x00, 0xFF, 0xCF, 0x00, 0xCF, 0x9F, 0x00, 0x9B, 0x6F, 0x00, 0x6B, 0xA7, 0x6B, 0x6B
])

TRANSPARENT_INDEX = 112


def get_palette_from_wad(wad, palettename: str = "PLAYPAL") -> bytes:
	"""
	Extract palette from WAD lump.
	
	Args:
		wad: WAD object with data attribute
		palettename: Name of the palette lump (default: PLAYPAL)
	
	Returns:
		bytes: 768 bytes of RGB data (256 colors * 3 bytes)
	"""
	if palettename in wad.data:
		palette_data = wad.data[palettename].data
		if len(palette_data) >= 768:
			return palette_data[:768]
		else:
			print(f"Warning: {palettename} is too small ({len(palette_data)} bytes), using fallback")
	else:
		print(f"Warning: {palettename} not found, using fallback palette")
	
	return FALLBACK_PALETTE


def rgb_to_grayscale(r: int, g: int, b: int) -> float:
	"""
	Convert RGB to grayscale using luminance formula.
	Returns value between 0.0 and 1.0.
	"""
	# Standard luminance formula for sRGB
	return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0


def grayscale_to_redscale(grayscale: float) -> Tuple[int, int, int]:
	"""
	Convert grayscale value (0.0-1.0) to red-scale RGB.
	0.0 = #000000, 1.0 = #FF0000
	"""
	red = int(grayscale * 255)
	return (red, 0, 0)


def find_closest_palette_color(r: int, g: int, b: int, palette: bytes) -> int:
	"""
	Find the closest color in the palette using Euclidean distance.
	
	Args:
		r, g, b: RGB values (0-255)
		palette: 768 bytes of RGB data
	
	Returns:
		int: Palette index (0-255)
	"""
	best_index = 0
	best_distance = float('inf')

	indices = [176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 164]

	for i in indices:
		pr = palette[i * 3]
		pg = palette[i * 3 + 1]
		pb = palette[i * 3 + 2]
		
		# Euclidean distance in RGB space
		dr = r - pr
		dg = g - pg
		db = b - pb
		distance = dr*dr + dg*dg + db*db
		
		if distance < best_distance:
			best_distance = distance
			best_index = i
			if distance == 0:  # Perfect match
				break
	
	return best_index


def find_closest_palette_color_all(r: int, g: int, b: int, palette: bytes) -> int:
	"""
	Find the closest color in the palette using Euclidean distance.
	
	Args:
		r, g, b: RGB values (0-255)
		palette: 768 bytes of RGB data
	
	Returns:
		int: Palette index (0-255)
	"""
	best_index = 0
	best_distance = float('inf')

	indices = range(0, 256)

	for i in indices:
		pr = palette[i * 3]
		pg = palette[i * 3 + 1]
		pb = palette[i * 3 + 2]
		
		# Euclidean distance in RGB space
		dr = r - pr
		dg = g - pg
		db = b - pb
		distance = dr*dr + dg*dg + db*db
		
		if distance < best_distance:
			best_distance = distance
			best_index = i
			if distance == 0:  # Perfect match
				break
	
	return best_index


def patch_to_pil_image(patch: patch_t, palette: bytes) -> Optional[Image.Image]:
	"""
	Convert patch_t -> RGBA PIL image.
	Transparent pixels become alpha=0.
	"""
	if not PIL_AVAILABLE:
		return None

	rgba_data = bytearray()

	for y in range(patch.height):
		for x in range(patch.width):
			px = None

			for post in patch.columns[x]:
				if post.topdelta <= y < post.topdelta + post.length:
					px = post.data[y - post.topdelta]
					break

			if px is None:
				rgba_data.extend([0, 0, 0, 0])
			else:
				if 0 <= px < 256:
					rgba_data.extend(palette[px * 3:px * 3 + 3])
					rgba_data.append(255)
				else:
					rgba_data.extend([0, 0, 0, 0])

	return Image.frombytes("RGBA", (patch.width, patch.height), bytes(rgba_data))


def pil_image_to_patch(
	image: Image.Image,
	palette: bytes,
	leftoffset: int = 0,
	topoffset: int = 0,
	transparent_index: Optional[int] = None,
) -> patch_t:
	"""
	Convert a PIL image back to patch_t.

	If transparent_index is provided, fully transparent pixels are written
	as that index first, then fed through patch_t.fromPixelGrid(...).
	Otherwise they are written as None directly.
	"""
	if image.mode != "RGBA":
		image = image.convert("RGBA")

	width, height = image.size
	patch = patch_t(width, height, leftoffset, topoffset)
	rgba = image.tobytes()

	if transparent_index is None:
		# Direct None-based path, matches patch_t's native behavior.
		for x in range(width):
			column: List[Optional[int]] = []
			for y in range(height):
				i = (y * width + x) * 4
				r, g, b, a = rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]
				if a == 0:
					column.append(None)
				else:
					column.append(find_closest_palette_color(r, g, b, palette))
			patch.setColumn(x, column)
		return patch

	# Indexed transparent sentinel path.
	grid: List[List[int]] = []
	for y in range(height):
		row: List[int] = []
		for x in range(width):
			i = (y * width + x) * 4
			r, g, b, a = rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]
			if a == 0:
				row.append(transparent_index)
			else:
				row.append(find_closest_palette_color(r, g, b, palette))
		grid.append(row)

	return patch.fromPixelGrid(grid, transparent=transparent_index)

def pil_image_to_patch_all(
	image: Image.Image,
	palette: bytes,
	leftoffset: int = 0,
	topoffset: int = 0,
	transparent_index: Optional[int] = None,
) -> patch_t:
	"""
	Convert a PIL image back to patch_t.

	If transparent_index is provided, fully transparent pixels are written
	as that index first, then fed through patch_t.fromPixelGrid(...).
	Otherwise they are written as None directly.
	"""
	if image.mode != "RGBA":
		image = image.convert("RGBA")

	width, height = image.size
	patch = patch_t(width, height, leftoffset, topoffset)
	rgba = image.tobytes()

	if transparent_index is None:
		# Direct None-based path, matches patch_t's native behavior.
		for x in range(width):
			column: List[Optional[int]] = []
			for y in range(height):
				i = (y * width + x) * 4
				r, g, b, a = rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]
				if a == 0:
					column.append(None)
				else:
					column.append(find_closest_palette_color_all(r, g, b, palette))
			patch.setColumn(x, column)
		return patch

	# Indexed transparent sentinel path.
	grid: List[List[int]] = []
	for y in range(height):
		row: List[int] = []
		for x in range(width):
			i = (y * width + x) * 4
			r, g, b, a = rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]
			if a == 0:
				row.append(transparent_index)
			else:
				row.append(find_closest_palette_color_all(r, g, b, palette))
		grid.append(row)

	return patch.fromPixelGrid(grid, transparent=transparent_index)


def add_outline_to_patch(patch: patch_t, palette: bytes, 
						 outline_color: Tuple[int, int, int]) -> patch_t:
	"""
	Add a 1px outline to a patch using the specified RGB color.
	Extends the canvas by 1 pixel on all sides to prevent outline cutoff.
	
	Args:
		patch: Original patch_t object
		palette: 768 bytes of RGB palette data
		outline_color: RGB tuple (r, g, b) for the outline
	
	Returns:
		patch_t: New patch with outline added and canvas extended
	"""
	if not PIL_AVAILABLE:
		print("Warning: PIL not available, cannot add outline")
		return patch.copy()

	image = patch_to_pil_image(patch, palette)
	if image is None:
		return patch.copy()

	width, height = image.size
	pixels = image.load()

	# Solid mask from alpha
	solid = [[False] * width for _ in range(height)]
	for y in range(height):
		for x in range(width):
			solid[y][x] = (pixels[x, y][3] != 0)

	# Find palette-matched outline color
	outline_index = find_closest_palette_color(
		outline_color[0], outline_color[1], outline_color[2], palette
	)
	outline_rgb = tuple(palette[outline_index * 3:outline_index * 3 + 3])

	# Build a new expanded RGBA image
	new_w, new_h = width + 2, height + 2
	out = Image.new("RGBA", (new_w, new_h), (0, 0, 0, 0))
	out_px = out.load()

	# Copy original solid pixels into the center
	for y in range(height):
		for x in range(width):
			if solid[y][x]:
				out_px[x + 1, y + 1] = pixels[x, y]

	# Now iterate over the entire expanded canvas to apply outline
	for y in range(new_h):
		for x in range(new_w):
			# Skip pixels that are already solid
			if out_px[x, y][3] != 0:
				continue

			should_outline = False
			# Check neighbors in the original image bounds
			for dy in (-1, 0, 1):
				for dx in (-1, 0, 1):
					if dx == 0 and dy == 0:
						continue
					nx, ny = x + dx - 1, y + dy - 1  # offset back to solid mask coords
					if 0 <= nx < width and 0 <= ny < height and solid[ny][nx]:
						should_outline = True
						break
				if should_outline:
					break

			if should_outline:
				out_px[x, y] = outline_rgb + (255,)

	# Important: transparent pixels stay transparent here;
	# pil_image_to_patch turns them into None or 112->None for patch_t.
	return pil_image_to_patch(
		out,
		palette,
		leftoffset=new_w // 2,
		topoffset=new_h // 2,
		transparent_index=TRANSPARENT_INDEX,
	)


def monochromize_patch(patch: patch_t, palette: bytes) -> patch_t:
	"""
	Convert a patch to monochrome (red-scale) using the given palette.
	
	Args:
		patch: Original patch_t object
		palette: 768 bytes of RGB palette data
	
	Returns:
		patch_t: New monochromized patch
	"""
	# Create a new patch with same dimensions
	monochrome_patch = patch_t(patch.width, patch.height, patch.leftoffset, patch.topoffset)
	
	# Process each column
	for x in range(patch.width):
		# Build the column pixels (with transparency as None)
		column_pixels: List[Optional[int]] = [None] * patch.height
		
		# Fill from posts
		for post in patch.columns[x]:
			for y_offset, pixel_index in enumerate(post.data):
				y = post.topdelta + y_offset
				if y < patch.height:
					column_pixels[y] = pixel_index
		
		# Convert each pixel to monochrome
		monochrome_column = []
		for y in range(patch.height):
			pixel_index = column_pixels[y]
			
			if pixel_index is None:
				# Transparent pixel
				monochrome_column.append(None)
			else:
				# Get RGB from palette
				if pixel_index * 3 + 2 < len(palette):
					r = palette[pixel_index * 3]
					g = palette[pixel_index * 3 + 1]
					b = palette[pixel_index * 3 + 2]
					
					# Convert to grayscale then to red-scale
					gray = rgb_to_grayscale(r, g, b)
					red_r, red_g, red_b = grayscale_to_redscale(gray)
					
					# Find closest palette color
					new_index = find_closest_palette_color(red_r, red_g, red_b, palette)
					monochrome_column.append(new_index)
				else:
					# Fallback if palette index is out of range
					monochrome_column.append(0)
		
		# Set the column in the new patch
		monochrome_patch.setColumn(x, monochrome_column)
	
	return monochrome_patch


def monochromize_sprites(wad, sprite_prefix: str, palettename: str = "PLAYPAL") -> int:
	"""
	Monochromize all sprites with the given prefix.
	
	Args:
		wad: WAD object (must have data attribute with lumps)
		sprite_prefix: Sprite name prefix (e.g., "PLAY", "POSS", "PISG")
		palettename: Name of the palette lump (default: PLAYPAL)
	
	Returns:
		int: Number of sprites monochromized
	"""
	# Get palette
	palette = get_palette_from_wad(wad, palettename)
	
	# Find all matching sprite lumps
	matching_lumps = []
	for lump_name in wad.sprites.keys():
		if lump_name.startswith(sprite_prefix):
			# Check if it's a sprite (not PLAYPAL or other special lumps)
			if lump_name != "PLAYPAL" and len(lump_name) >= 5:
				matching_lumps.append(lump_name)
	
	if not matching_lumps:
		print(f"No sprites found with prefix '{sprite_prefix}'")
		return 0
	
	print(f"Found {len(matching_lumps)} sprites with prefix '{sprite_prefix}'")
	
	# Process each sprite
	converted_count = 0
	for lump_name in matching_lumps:
		try:
			# Parse the patch
			lump_data = wad.sprites[lump_name].data
			original_patch = toPatchClass(lump_data)
			
			# Create monochrome version
			monochrome_patch = monochromize_patch(original_patch, palette)
			
			# Convert back to bytes
			monochrome_data = monochrome_patch.toBytes()
			
			# Replace in WAD
			wad.graphics[lump_name].data = monochrome_data
			
			converted_count += 1
			print(f"  Monochromized: {lump_name}")
			
		except Exception as e:
			print(f"  Failed to monochromize {lump_name}: {e}")
	
	print(f"Successfully monochromized {converted_count}/{len(matching_lumps)} sprites")
	return converted_count

def downscale_patch_3_4(patch: patch_t, palette: bytes) -> patch_t:
    """
    Downscale a patch to 75% size using PIL, preserving transparency.
    Offsets are scaled by the same factor.
    """
    if not PIL_AVAILABLE:
        return patch.copy()

    image = patch_to_pil_image(patch, palette)
    if image is None:
        return patch.copy()

    # Pillow compatibility across versions
    try:
        resample = Image.Resampling.LANCZOS
    except AttributeError:
        resample = Image.LANCZOS

    new_w = max(1, int(round(image.width * 3 / 4)))
    new_h = max(1, int(round(image.height * 3 / 4)))
    
    # Resize the image
    scaled = image.resize((new_w, new_h), resample=resample)
    
    # CRITICAL FIX: Convert semi-transparent pixels to fully transparent
    # Alpha values below this threshold become fully transparent
    alpha_threshold = 128
    rgba_data = bytearray(scaled.tobytes())
    
    # Process alpha channel (every 4th byte)
    for i in range(3, len(rgba_data), 4):
        if rgba_data[i] < alpha_threshold:
            rgba_data[i] = 0  # Make fully transparent
    
    # Create new image with corrected alpha
    corrected_scaled = Image.frombytes("RGBA", (new_w, new_h), bytes(rgba_data))
    
    return pil_image_to_patch_all(
        corrected_scaled,
        palette,
        leftoffset=int(round(patch.leftoffset * 3 / 4)),
        topoffset=int(round(patch.topoffset * 3 / 4)),
        transparent_index=TRANSPARENT_INDEX,
    )

def createCarouselGraphics(wad, spriteprefix: str, spriteframe: str,
						  outputprefix: str, custompalette: Optional[bytes] = None):
	"""
	Create carousel graphics from a specific sprite frame.
	Creates two versions with different colored outlines:
	- Version 0: Dark red outline (67, 0, 0)
	- Version 1: Gold/amber outline (175, 123, 31)

	Also writes the 3/4-downscaled sprite as outputprefix + "S".

	The canvas is extended by 1 pixel on all sides to prevent outline cutoff.
	Offsets are adjusted automatically to maintain proper sprite positioning.
	"""
	if not PIL_AVAILABLE:
		print("ERROR: PIL/Pillow is required for createCarouselGraphics")
		print("Please install it with: pip install Pillow")
		return 0, []

	if not hasattr(wad, "graphics"):
		raise AttributeError("wad.graphics does not exist")

	output_lumps = wad.graphics

	if custompalette:
		palette = custompalette
		if len(palette) < 768:
			print(f"Warning: Custom palette too small ({len(palette)} bytes), using fallback")
			palette = get_palette_from_wad(wad)
	else:
		palette = get_palette_from_wad(wad)

	sprite_pattern = f"{spriteprefix}{spriteframe}"

	matching_lumps = []
	for lump_name in wad.sprites.keys():
		if lump_name.startswith(sprite_pattern) and len(lump_name) >= len(sprite_pattern):
			matching_lumps.append(lump_name)

	if not matching_lumps:
		print(f"No sprites found with pattern '{sprite_pattern}*'")
		return 0, []

	print(f"Found {len(matching_lumps)} sprites with pattern '{sprite_pattern}*'")

	OUTLINE_COLOR_0 = (67, 0, 0)
	OUTLINE_COLOR_1 = (175, 123, 31)

	created_lumps = []
	created_count = 0

	for source_lump_name in matching_lumps:
		try:
			lump_data = wad.sprites[source_lump_name].data
			original_patch = toPatchClass(lump_data)

			# 1) Downscale first, and save that step as prefix + "S"
			scaled_patch = downscale_patch_3_4(original_patch, palette)

			output_name_s = f"{outputprefix}S"
			output_lumps[output_name_s] = type(wad.sprites[source_lump_name])(
				scaled_patch.toBytes()
			)
			created_lumps.append(output_name_s)
			created_count += 1
			print(f"  Created {output_name_s} (downscaled 3/4, {scaled_patch.width}x{scaled_patch.height})")

			# 2) Everything else uses the downscaled patch
			monochrome_patch = monochromize_patch(scaled_patch, palette)

			# Version 0
			print(f"  Adding outline to {source_lump_name} (dark red)...")
			outlined_patch_0 = add_outline_to_patch(monochrome_patch, palette, OUTLINE_COLOR_0)
			output_name_0 = f"{outputprefix}0"
			output_lumps[output_name_0] = type(wad.sprites[source_lump_name])(
				outlined_patch_0.toBytes()
			)
			created_lumps.append(output_name_0)
			created_count += 1
			print(f"  Created {output_name_0} (dark red outline, {outlined_patch_0.width}x{outlined_patch_0.height})")

			# Version 1
			print(f"  Adding outline to {source_lump_name} (gold)...")
			outlined_patch_1 = add_outline_to_patch(monochrome_patch, palette, OUTLINE_COLOR_1)
			output_name_1 = f"{outputprefix}1"
			output_lumps[output_name_1] = type(wad.sprites[source_lump_name])(
				outlined_patch_1.toBytes()
			)
			created_lumps.append(output_name_1)
			created_count += 1
			print(f"  Created {output_name_1} (gold outline, {outlined_patch_1.width}x{outlined_patch_1.height})")

		except Exception as e:
			print(f"  Failed to process {source_lump_name}: {e}")
			import traceback
			traceback.print_exc()

	print(f"\nSuccessfully created {created_count} carousel graphics")
	print(f"Output lumps: {', '.join(created_lumps)}")

	return created_count, created_lumps