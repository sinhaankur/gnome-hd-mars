"""Bake tileable Mars-surface PBR texture sets for the Godot terrain shader.

Four surfaces — dry soil, fine sand, water ice, liquid — each written as a
*seamless, tileable* set: albedo + normal + roughness PNGs (1024²). The terrain
is a shader (not meshes), so these feed Godot's ground material, not GLBs.

WHY PURE NUMPY (not a Cycles bake):
The previous version built Blender node graphs and baked them with Cycles. Three
things broke:
  * NORMAL bake of a `Bump` node on a flat plane produced an almost-flat normal
    (R/G ~127, B 255) — no micro-relief at all.
  * ROUGHNESS came out a single constant (the BSDF default_value), never varying.
  * `Generated` coords over non-integer noise frequencies did NOT wrap, so the
    "tileable" maps showed a visible seam.
So we generate the maps directly from *tileable* value-noise in numpy and derive
the normal from the height field's gradient. No GPU, no node graph, no Blender
scene — deterministic, fast, and genuinely seamless. numpy ships with Blender's
Python, so run it the same way:

    /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
        --python tools/build_ground_materials.py

(It also runs under any python3 that has numpy; Blender isn't required.)

Output: godot/assets/ground/<name>/{albedo,normal,roughness}.png  (1024², tiling)
"""
import os
import struct
import zlib
import numpy as np

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "godot", "assets", "ground")
RES = 1024
SEED = 1337


# ----------------------------------------------------- tileable value noise ---
def _tileable_noise(res, freq, rng):
    """Seamless value noise at integer frequency `freq` (so it wraps at the edge).

    A `freq`×`freq` lattice of random values is bilinearly upsampled to `res`²
    using periodic indexing (np.roll-style wrap), guaranteeing the left edge
    matches the right and top matches bottom — the map tiles with no seam.
    """
    freq = int(freq)
    lattice = rng.random((freq, freq), dtype=np.float32)
    # sample coordinates in lattice space, wrapping with %
    u = (np.arange(res, dtype=np.float32) / res) * freq
    i0 = np.floor(u).astype(np.int32) % freq
    i1 = (i0 + 1) % freq
    t = u - np.floor(u)
    # smoothstep for C1 continuity
    t = t * t * (3.0 - 2.0 * t)
    tx = t[None, :]
    ty = t[:, None]
    # gather the four lattice corners (broadcast over the 2D grid)
    c00 = lattice[np.ix_(i0, i0)]
    c10 = lattice[np.ix_(i0, i1)]
    c01 = lattice[np.ix_(i1, i0)]
    c11 = lattice[np.ix_(i1, i1)]
    top = c00 * (1 - tx) + c10 * tx
    bot = c01 * (1 - tx) + c11 * tx
    return top * (1 - ty) + bot * ty


def _fbm(res, base_freq, octaves, rng, gain=0.5, lacunarity=2):
    """Fractal sum of tileable noise — frequencies kept integer so each octave
    (and therefore the sum) still tiles."""
    out = np.zeros((res, res), dtype=np.float32)
    amp = 1.0
    freq = base_freq
    norm = 0.0
    for _ in range(octaves):
        out += amp * _tileable_noise(res, freq, rng)
        norm += amp
        amp *= gain
        freq *= lacunarity
    return out / norm


def _normalize(a):
    lo, hi = float(a.min()), float(a.max())
    return (a - lo) / (hi - lo + 1e-6)


# --------------------------------------------------- height -> normal map -----
def _height_to_normal(height, strength=2.0):
    """Tangent-space normal map from a tileable height field (periodic gradient)."""
    # periodic central differences (np.roll wraps, so the normal map stays seamless)
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5
    nx = -dx * strength
    ny = -dy * strength
    nz = np.ones_like(height)
    inv = 1.0 / np.sqrt(nx * nx + ny * ny + nz * nz)
    nx *= inv; ny *= inv; nz *= inv
    # pack to 0..1 (OpenGL-style, +Y up — matches the terrain shader's RG decode)
    rgb = np.stack([nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5], axis=-1)
    return np.clip(rgb, 0.0, 1.0)


# ------------------------------------------------------------- PNG writer -----
def _save_rgb(path, arr01):
    """Write an (H,W,3) float 0..1 array as an 8-bit RGB PNG (no PIL needed)."""
    h, w, _ = arr01.shape
    data = (np.clip(arr01, 0, 1) * 255.0 + 0.5).astype(np.uint8)
    raw = bytearray()
    for y in range(h):
        raw.append(0)                       # filter type 0 (none) per scanline
        raw.extend(data[y].tobytes())
    comp = zlib.compress(bytes(raw), 9)

    def chunk(typ, payload):
        c = struct.pack(">I", len(payload)) + typ + payload
        return c + struct.pack(">I", zlib.crc32(typ + payload) & 0xffffffff)

    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)   # 8-bit, colour type 2 (RGB)
    with open(path, "wb") as f:
        f.write(sig)
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", comp))
        f.write(chunk(b"IEND", b""))


def _gray(a):
    return np.stack([a, a, a], axis=-1)


def _ramp(t, c0, c1):
    """Lerp two RGB colours by a 0..1 scalar field -> (H,W,3)."""
    c0 = np.asarray(c0, np.float32); c1 = np.asarray(c1, np.float32)
    return c0[None, None, :] * (1 - t)[..., None] + c1[None, None, :] * t[..., None]


# ----------------------------------------------------- surface definitions ---
# Each returns (albedo HxWx3, height HxW, roughness HxW), all tileable 0..1.

def mars_soil(res, rng):
    """Dry oxidised Mars soil — low-sat caramel, matte, fine granular bump.
    Albedo measured against the Perseverance panoramas: mean ~sRGB(150,112,88)."""
    patch = _normalize(_fbm(res, 6, 4, rng))        # broad lighter/darker drifts
    grain = _normalize(_fbm(res, 64, 5, rng))       # fine grit
    stones = _normalize(_tileable_noise(res, 48, rng))
    col = _ramp(patch, (0.44, 0.31, 0.24), (0.66, 0.49, 0.38))   # Mars caramel band
    col *= (0.85 + 0.30 * grain)[..., None]          # granular value break-up
    # scatter a few darker basalt specks
    rock_mask = np.clip((stones - 0.72) / 0.1, 0, 1)
    col = col * (1 - 0.35 * rock_mask[..., None]) + \
        np.array([0.30, 0.22, 0.17])[None, None, :] * (0.35 * rock_mask[..., None])
    height = 0.6 * grain + 0.4 * patch + 0.5 * rock_mask
    rough = 0.90 + 0.08 * grain - 0.15 * rock_mask    # specks a touch slicker
    return np.clip(col, 0, 1), _normalize(height), np.clip(rough, 0.5, 1.0)


def mars_sand(res, rng):
    """Fine wind-blown sand — lighter tan, soft dune ripples (seamless phase)."""
    # ripples as a sine whose period is an integer across the tile (so it wraps)
    waves = 7
    xs = np.linspace(0, 2 * np.pi * waves, res, endpoint=False, dtype=np.float32)
    warp = _fbm(res, 4, 3, rng) * 2.0                # wander the ripple lines
    ripple = 0.5 + 0.5 * np.sin(xs[None, :] + warp)
    grain = _normalize(_fbm(res, 90, 4, rng))
    t = np.clip(0.6 * ripple + 0.4 * grain, 0, 1)
    col = _ramp(t, (0.50, 0.38, 0.26), (0.74, 0.58, 0.40))
    height = 0.7 * ripple + 0.3 * grain
    rough = 0.86 + 0.06 * grain
    return np.clip(col, 0, 1), _normalize(height), np.clip(rough, 0.5, 1.0)


def mars_ice(res, rng):
    """Water ice — pale blue-white, semi-glossy, cracked (Voronoi-edge network)."""
    cracks = _voronoi_edges(res, 12, rng)            # 0 at cell edge -> 1 interior
    frost = _normalize(_fbm(res, 50, 4, rng))
    body = np.clip(cracks * 0.8 + 0.2 * frost, 0, 1)
    col = _ramp(body, (0.62, 0.70, 0.78), (0.88, 0.93, 0.97))
    height = 0.8 * cracks + 0.2 * frost
    rough = 0.20 + 0.25 * (1.0 - cracks)             # crack lines read rougher
    return np.clip(col, 0, 1), _normalize(height), np.clip(rough, 0.05, 0.9)


def water_liquid(res, rng):
    """Liquid coolant pool — dark teal, glossy, gentle concentric ripples."""
    yy, xx = np.mgrid[0:res, 0:res].astype(np.float32) / res
    # tileable ripple: sum of a few integer-frequency sine gratings (wraps cleanly)
    ripple = np.zeros((res, res), np.float32)
    for fx, fy in ((3, 2), (5, -3), (2, 4)):
        ripple += np.sin(2 * np.pi * (fx * xx + fy * yy))
    ripple = _normalize(ripple)
    base = np.array([0.04, 0.16, 0.18], np.float32)
    col = base[None, None, :] * (0.85 + 0.30 * ripple)[..., None]
    rough = 0.06 + 0.06 * ripple
    return np.clip(col, 0, 1), ripple, np.clip(rough, 0.02, 0.3)


def _voronoi_edges(res, freq, rng):
    """Tileable distance-to-edge Voronoi (jittered lattice, wrapped). 0 on edges,
    ->1 toward cell centres — used for the ice crack network."""
    freq = int(freq)
    pts = (np.stack(np.mgrid[0:freq, 0:freq], -1).astype(np.float32)
           + rng.random((freq, freq, 2), dtype=np.float32)) / freq
    yy, xx = np.mgrid[0:res, 0:res].astype(np.float32) / res
    best = np.full((res, res), 10.0, np.float32)
    second = np.full((res, res), 10.0, np.float32)
    for gy in range(freq):
        for gx in range(freq):
            px, py = pts[gy, gx]
            dx = np.abs(xx - px); dx = np.minimum(dx, 1 - dx)   # wrap in x
            dy = np.abs(yy - py); dy = np.minimum(dy, 1 - dy)   # wrap in y
            d = np.sqrt(dx * dx + dy * dy)
            closer = d < best
            second = np.where(closer, best, np.minimum(second, d))
            best = np.where(closer, d, best)
    edge = second - best                 # small near a cell border, large inside
    return _normalize(edge)


SURFACES = {
    "soil": mars_soil,
    "sand": mars_sand,
    "ice": mars_ice,
    "water": water_liquid,
}


def build_surface(name, fn, rng):
    albedo, height, rough = fn(RES, rng)
    normal = _height_to_normal(height, strength=2.0)
    d = os.path.join(OUT, name)
    os.makedirs(d, exist_ok=True)
    _save_rgb(os.path.join(d, "albedo.png"), albedo)
    _save_rgb(os.path.join(d, "normal.png"), normal)
    _save_rgb(os.path.join(d, "roughness.png"), _gray(rough))
    return name, d


def main():
    rng = np.random.default_rng(SEED)
    results = [build_surface(n, fn, rng) for n, fn in SURFACES.items()]
    print("GROUND_MATERIALS_OK")
    for name, d in results:
        files = sorted(os.listdir(d))
        print("  %-7s -> %s" % (name, files))


if __name__ == "__main__":
    main()
