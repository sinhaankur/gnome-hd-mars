#!/usr/bin/env python3
"""Extract several DISTINCT Mars regions from the MOLA tile as separate heightmaps,
so each campaign level has its own genuinely different landscape.

Scans the tile for windows matching each region 'character' (by relief + steepness)
and writes mars_<name>.png (16-bit) for each. Falls back to fixed offsets if no match.
"""
import numpy as np
from PIL import Image
import os

SRC = "/Users/sinhaankur/Downloads/G-Nome_ISO/mars_data/megt44n270hb.img"
OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"
LINES, SAMPLES = 5632, 11520
CROP = 512

# each region wants a different terrain character (target relief in metres over the crop)
REGIONS = {
	"plains":  {"relief_lo": 200,  "relief_hi": 700,  "max_steep": 45},   # gentle rolling
	"rugged":  {"relief_lo": 700,  "relief_hi": 1600, "max_steep": 90},   # broken hills
	"canyon":  {"relief_lo": 1600, "relief_hi": 6000, "max_steep": 400},  # dramatic chasms
	"craters": {"relief_lo": 400,  "relief_hi": 1100, "max_steep": 70},   # cratered flats
}

def score_window(sub, spec):
	relief = float(sub.max() - sub.min())
	if relief < spec["relief_lo"] or relief > spec["relief_hi"]:
		return -1e9
	gx = np.abs(np.diff(sub, axis=1)); gy = np.abs(np.diff(sub, axis=0))
	steep = max(float(gx.max()), float(gy.max()))
	if steep > spec["max_steep"]:
		return -1e9
	# prefer the middle of the relief band, mild steepness
	mid = (spec["relief_lo"] + spec["relief_hi"]) * 0.5
	return -abs(relief - mid) - steep * 0.2

def main():
	data = np.fromfile(SRC, dtype=">i2").astype(np.float32).reshape(LINES, SAMPLES)
	step = 384
	used = []
	for name, spec in REGIONS.items():
		best = None
		for r in range(0, LINES - CROP, step):
			for c in range(0, SAMPLES - CROP, step):
				# avoid reusing the same spot for two regions
				if any(abs(r-ur) < 300 and abs(c-uc) < 300 for ur, uc in used):
					continue
				sub = data[r:r+CROP, c:c+CROP]
				s = score_window(sub, spec)
				if best is None or s > best[0]:
					best = (s, r, c)
		if best is None or best[0] < -1e8:
			# fallback: just take a fixed offset
			r, c = (len(used)*400) % (LINES-CROP), (len(used)*700) % (SAMPLES-CROP)
		else:
			_, r, c = best
		used.append((r, c))
		sub = data[r:r+CROP, c:c+CROP]
		lo, hi = float(sub.min()), float(sub.max())
		norm = (sub - lo) / max(hi - lo, 1.0)
		img = (norm * 65535).astype(np.uint16)
		Image.fromarray(img).save(os.path.join(OUT, f"mars_{name}.png"))
		print(f"{name}: row={r} col={c} relief={hi-lo:.0f}m -> mars_{name}.png")

if __name__ == "__main__":
	main()
