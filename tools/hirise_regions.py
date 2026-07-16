#!/usr/bin/env python3
"""Carve the game's per-level heightmaps from a REAL HiRISE DTM at ~1 m/px.

Replaces the old MOLA-derived region maps (463 m/px, so the whole play area was
~2 source pixels and everything underfoot was procedural). The HiRISE DTM is
458x finer, so the actual ground a 10 m mech walks on is genuine Mars topography.

Source: Candor Chasma (Valles Marineris), HiRISE DTEEC_001918_1735 — a 6.4 x 10.9 km
canyon-wall tile, 1.0116 m/px, 32-bit float elevations (metres), ~518 m real relief.

For each campaign region we slide a WINDOW over the DTM and pick the sub-area whose
character (relief + steepness) best matches that region's intended feel, then write a
16-bit grayscale PNG heightmap in exactly the format mars_terrain.gd already consumes.
One real hero DTM -> four real, genuinely-different region heightmaps.
"""
import numpy as np
from PIL import Image
import os

SRC   = "/Users/sinhaankur/Downloads/G-Nome_ISO/mars_data/hirise/candor_chasma_dtm.IMG"
OUT   = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"

# --- DTM geometry (from the attached PDS label) ---
LINES, SAMPLES = 10767, 6368
RECORD_BYTES   = 25472               # == LINE_SAMPLES*4, so rows are record-aligned
M_PER_PX       = 1.0116
VALID_LO, VALID_HI = 700.0, 1400.0   # VALID_MINIMUM 782 .. VALID_MAXIMUM 1300, padded

# The game world is 400 m across, sampled to a heightmap. At 1.0116 m/px that's ~395 px,
# but we grab a bit more and downsample to a clean power-of-two-ish map for crisp terrain.
WIN_PX = 396                         # ~400 m of real Mars per region window
OUT_PX = 512                         # heightmap resolution written to PNG

# Each region wants a different slice of the canyon. Relief/steepness are measured over
# the WINDOW in metres; these bands pick genuinely distinct terrain from the same tile.
REGIONS = {
    # gentle rolling bench near the canyon rim — walkable, mild relief
    "plains":  {"relief_lo": 8,   "relief_hi": 40,  "max_steep": 3.5, "want": 22},
    # cratered / pitted flat area — modest relief, some pockmarks
    "craters": {"relief_lo": 25,  "relief_hi": 70,  "max_steep": 6.0, "want": 45},
    # dramatic canyon wall — the hero Valles Marineris look: big relief AND rough,
    # layered, rocky texture (reward local roughness so it's not a bland smooth ramp).
    "canyon":  {"relief_lo": 180, "relief_hi": 520, "max_steep": 60.0, "want": 380, "rough": 30.0},
    # broken rugged slope — strong relief but not a sheer cliff
    "rugged":  {"relief_lo": 70,  "relief_hi": 150, "max_steep": 14.0, "want": 110},
}


def load_dtm() -> np.ndarray:
    """Read the float32 elevation grid, masking no-data to NaN."""
    total = os.path.getsize(SRC)
    header = total - LINES * RECORD_BYTES
    with open(SRC, "rb") as f:
        f.seek(header)
        arr = np.fromfile(f, dtype="<f4", count=LINES * SAMPLES).reshape(LINES, SAMPLES)
    arr = arr.astype(np.float32)
    arr[(arr < VALID_LO) | (arr > VALID_HI)] = np.nan     # no-data -> NaN
    return arr


def fill_nan(sub: np.ndarray) -> np.ndarray:
    """Inpaint no-data holes by nearest-valid diffusion so terrain has no spikes/pits."""
    out = sub.copy()
    mask = np.isnan(out)
    if not mask.any():
        return out
    # iterative neighbour-average fill (cheap, gap-free); seed holes with global mean
    fillv = np.nanmean(out)
    out[mask] = fillv
    for _ in range(24):
        if not mask.any():
            break
        # average of 4-neighbours
        up    = np.roll(out, 1, 0); down = np.roll(out, -1, 0)
        left  = np.roll(out, 1, 1); right = np.roll(out, -1, 1)
        avg = (up + down + left + right) * 0.25
        out[mask] = avg[mask]
    return out


def measure(sub: np.ndarray):
    relief = float(np.nanmax(sub) - np.nanmin(sub))
    gx = np.abs(np.diff(sub, axis=1)); gy = np.abs(np.diff(sub, axis=0))
    steep = max(float(np.nanmax(gx)), float(np.nanmax(gy)))   # m rise per ~1 m pixel
    return relief, steep


def score(sub: np.ndarray, spec) -> float:
    # reject windows that are mostly no-data
    if np.isnan(sub).mean() > 0.30:
        return -1e9
    relief, steep = measure(sub)
    if relief < spec["relief_lo"] or relief > spec["relief_hi"]:
        return -1e9
    if steep > spec["max_steep"]:
        return -1e9
    # prefer the target relief ('want'), mild steepness, fewer holes
    holes = np.isnan(sub).mean()
    s = -abs(relief - spec["want"]) - steep * 0.3 - holes * 200.0
    # optionally reward local surface roughness (rocky/layered texture, not a smooth ramp):
    # detrend by subtracting a coarse blur, measure residual std over the window.
    if "rough" in spec:
        coarse = np.nanmean(sub)
        residual = np.nan_to_num(sub - coarse)
        # high-frequency energy = std of pixel-to-pixel differences
        hf = float(np.nanstd(np.diff(residual, axis=0)) + np.nanstd(np.diff(residual, axis=1)))
        s += hf * spec["rough"]
    return s


def main():
    print("loading HiRISE DTM …")
    data = load_dtm()
    print(f"  {SAMPLES}x{LINES} px, {SAMPLES*M_PER_PX/1000:.2f}x{LINES*M_PER_PX/1000:.2f} km, "
          f"{np.isnan(data).mean()*100:.0f}% no-data")

    step = 300                      # slide stride while searching (px)
    used = []                       # keep regions from overlapping
    for name, spec in REGIONS.items():
        best = None
        for r in range(0, LINES - WIN_PX, step):
            for c in range(0, SAMPLES - WIN_PX, step):
                if any(abs(r - ur) < WIN_PX and abs(c - uc) < WIN_PX for ur, uc in used):
                    continue
                sub = data[r:r+WIN_PX, c:c+WIN_PX]
                s = score(sub, spec)
                if best is None or s > best[0]:
                    best = (s, r, c)
        if best is None or best[0] < -1e8:
            # fallback: take a fixed offset and just use whatever's there
            r = (len(used) * 1200) % (LINES - WIN_PX)
            c = (len(used) * 900) % (SAMPLES - WIN_PX)
            print(f"  {name}: NO MATCH, fallback window row={r} col={c}")
        else:
            _, r, c = best
        used.append((r, c))

        sub = fill_nan(data[r:r+WIN_PX, c:c+WIN_PX])
        relief, steep = measure(sub)
        lo, hi = float(sub.min()), float(sub.max())

        # normalize to full 16-bit and resample to OUT_PX for a crisp square heightmap
        norm = (sub - lo) / max(hi - lo, 1e-3)
        img16 = Image.fromarray((norm * 65535).astype(np.uint16))
        img16 = img16.resize((OUT_PX, OUT_PX), Image.LANCZOS)
        img16.save(os.path.join(OUT, f"mars_{name}.png"))
        # 8-bit preview for eyeballing
        Image.fromarray((norm * 255).astype(np.uint8)).resize(
            (256, 256), Image.LANCZOS).save(os.path.join(OUT, f"mars_{name}_preview.png"))

        lat = -6.3778673872017 - (r + WIN_PX/2) / 58592.38106622  # rough (equirect)
        print(f"  {name:8s}: row={r:5d} col={c:5d}  relief={relief:6.1f}m  "
              f"max_step={steep:5.2f}m  elev {lo:.0f}-{hi:.0f}m  -> mars_{name}.png")

    # write provenance so the game/docs know these are REAL HiRISE now
    with open(os.path.join(OUT, "mars_terrain_source.txt"), "w") as f:
        f.write("source=HiRISE DTEEC_001918_1735_001984_1735_U01 (Candor Chasma, Valles Marineris)\n")
        f.write(f"m_per_px={M_PER_PX}\n")
        f.write(f"window_px={WIN_PX}  (~{WIN_PX*M_PER_PX:.0f} m of real Mars per region)\n")
        f.write(f"out_px={OUT_PX}\n")
        f.write("regions=plains,craters,canyon,rugged  (distinct sub-windows of the same DTM)\n")
    print("done -> real HiRISE region heightmaps written to godot/assets/")


if __name__ == "__main__":
    main()
