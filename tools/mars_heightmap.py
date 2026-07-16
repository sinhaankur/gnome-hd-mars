#!/usr/bin/env python3
"""Convert a real MOLA MEGDR elevation tile into a Godot-ready heightmap.

Reads the 16-bit big-endian signed integer .img (meters of topography), finds an
interesting high-relief sub-region, and writes:
  - mars_height.png   : 16-bit grayscale heightmap (for terrain displacement)
  - mars_height.exr?  : (skipped; PNG16 is enough for Godot)
Prints the real-world elevation range and scale so the game can size terrain correctly.
"""
import numpy as np
from PIL import Image
import os, sys

SRC = "/Users/sinhaankur/Downloads/G-Nome_ISO/mars_data/megt44n270hb.img"
OUT_DIR = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"
LINES, SAMPLES = 5632, 11520
PX_PER_DEG = 128.0
M_PER_DEG = 59274.0          # ~ metres per degree on Mars (2*pi*3396km/360)
M_PER_PX = M_PER_DEG / PX_PER_DEG   # ~463 m/pixel

CROP = 512                   # output heightmap size (px) -> ~237 km of Mars

def main():
    data = np.fromfile(SRC, dtype=">i2").astype(np.int32)   # big-endian int16
    data = data.reshape(LINES, SAMPLES)
    print("full tile:", data.shape, "elev range m:", int(data.min()), int(data.max()))

    # slide a CROP window and pick the sub-region with the highest relief (std dev)
    best = None
    # Pick a GENTLE, WALKABLE region (like a rover landing site / crater floor):
    # rolling terrain with modest relief and — crucially — NO steep cliffs a mech
    # can't climb. Score = reward mild variation, heavily penalize steep local slopes.
    step = 256
    for r in range(0, LINES - CROP, step):
        for c in range(0, SAMPLES - CROP, step):
            sub = data[r:r+CROP, c:c+CROP].astype(np.float32)
            relief = float(sub.max() - sub.min())
            if relief > 900:            # skip anything with big canyons/mountains
                continue
            # local steepness: max abs gradient between neighbouring pixels (~463m apart)
            gx = np.abs(np.diff(sub, axis=1)); gy = np.abs(np.diff(sub, axis=0))
            steep = max(float(gx.max()), float(gy.max()))   # m rise per 463m pixel
            if steep > 60:              # reject cliffs (>~13% grade over a pixel)
                continue
            variation = float(sub.std())
            # want SOME interest (not a dead-flat plain) but gentle: peak around 60-120m std
            interest = -abs(variation - 90.0)
            score = interest - steep * 0.3
            if best is None or score > best[0]:
                best = (score, r, c)
    if best is None:                    # fallback: flattest available
        for r in range(0, LINES - CROP, step):
            for c in range(0, SAMPLES - CROP, step):
                sub = data[r:r+CROP, c:c+CROP].astype(np.float32)
                s = -float(sub.std())
                if best is None or s > best[0]:
                    best = (s, r, c)
    _, r, c = best
    sub = data[r:r+CROP, c:c+CROP].astype(np.float32)
    lo, hi = float(sub.min()), float(sub.max())
    relief = hi - lo
    # region center in Mars coords (tile spans lat 0-44N, lon 270-360E)
    lat = 44.0 - (r + CROP/2) / PX_PER_DEG
    lon = 270.0 + (c + CROP/2) / PX_PER_DEG
    print(f"picked region: row={r} col={c}  center lat={lat:.2f}N lon={lon:.2f}E")
    print(f"elevation: {lo:.0f} .. {hi:.0f} m  (relief {relief:.0f} m over ~{CROP*M_PER_PX/1000:.0f} km)")

    # normalize to full 16-bit range for a crisp heightmap
    norm = (sub - lo) / max(relief, 1.0)
    img16 = (norm * 65535).astype(np.uint16)
    Image.fromarray(img16, mode="I;16").save(os.path.join(OUT_DIR, "mars_height.png"))

    # also an 8-bit preview so it's easy to eyeball
    Image.fromarray((norm*255).astype(np.uint8)).save(os.path.join(OUT_DIR, "mars_height_preview.png"))

    # write scale metadata for the game
    with open(os.path.join(OUT_DIR, "mars_height.txt"), "w") as f:
        f.write(f"source=MOLA MEGDR megt44n270hb (128 px/deg)\n")
        f.write(f"crop_px={CROP}\n")
        f.write(f"m_per_px={M_PER_PX:.2f}\n")
        f.write(f"world_span_m={CROP*M_PER_PX:.1f}\n")
        f.write(f"elev_min_m={lo:.1f}\n")
        f.write(f"elev_max_m={hi:.1f}\n")
        f.write(f"relief_m={relief:.1f}\n")
        f.write(f"center_lat={lat:.4f}\n")
        f.write(f"center_lon={lon:.4f}\n")
    print("wrote mars_height.png (16-bit), preview, and mars_height.txt")

if __name__ == "__main__":
    main()
