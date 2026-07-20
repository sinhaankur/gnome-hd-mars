#!/usr/bin/env python3
"""Turn a REAL Perseverance Navcam XYZ point-cloud RDR into a terrain mesh (OBJ).

Honest provenance: the geometry is genuine stereo-derived Mars surface from
NASA/PDS Mars 2020 (public domain). We only reproject + triangulate it — no
sculpting, no fakery. The chosen wedge (Sol 180, product ...039XYZ...) covers a
~30 x 24 m patch of open ground in front of the rover.

Input : a Mars 2020 Navcam XYZ .IMG (3-band IEEE754 MSB float, band-sequential)
        + its PDS4 .xml label (for Band/Line/Sample dims).
Output: an OBJ mesh in the ROVER-NAV frame reoriented to +Z up, ground near z=0,
        centered on the footprint, ready for Blender import.

Rover-nav frame is X=forward, Y=right, Z=DOWN. We map to a Z-up world:
    world_x = Y   (right)
    world_y = X   (forward)
    world_z = -Z  (up)
"""
import sys, os
import numpy as np
import xml.etree.ElementTree as ET


def label_dims(xml_path):
    t = ET.parse(xml_path)
    for e in t.iter():
        e.tag = e.tag.split('}')[-1]
    ax = {a.find('axis_name').text: int(a.find('elements').text)
          for a in t.iter('Axis_Array')}
    return ax.get('Band', 3), ax['Line'], ax['Sample']


def load_xyz(img_path, xml_path):
    B, L, S = label_dims(xml_path)
    cube = np.fromfile(img_path, dtype='>f4', count=B * L * S).reshape(B, L, S)
    X, Y, Z = cube[0], cube[1], cube[2]
    valid = ~((X == 0) & (Y == 0) & (Z == 0))
    valid &= np.isfinite(X) & np.isfinite(Y) & np.isfinite(Z)
    valid &= (np.abs(X) < 60) & (np.abs(Y) < 60) & (np.abs(Z) < 60)
    return X, Y, Z, valid, L, S


def build_mesh(img_path, xml_path, out_obj, stride=2, max_edge=0.35, max_range=16.0):
    X, Y, Z, valid, L, S = load_xyz(img_path, xml_path)

    # CLIP to the near-to-mid ground: beyond ~16 m a single stereo viewpoint smears
    # distant terrain into long "fan" spikes (unreliable + ugly). Keep only the dense,
    # accurate near ground — that's the real walkable patch.
    horiz = np.sqrt(X * X + Y * Y)   # distance from the rover on the ground plane
    valid &= (horiz < max_range)

    # rover-nav (X fwd, Y right, Z down) -> Z-up world
    WX = Y
    WY = X
    WZ = -Z

    # center the footprint on origin, drop ground to ~z=0
    gx, gy, gz = WX[valid], WY[valid], WZ[valid]
    cx, cy = gx.mean(), gy.mean()
    z0 = np.percentile(gz, 2)   # ground floor

    # per-pixel vertex index map (subsampled by stride for a game-weight mesh)
    idx = -np.ones((L, S), dtype=np.int64)
    verts = []
    for r in range(0, L, stride):
        for c in range(0, S, stride):
            if not valid[r, c]:
                continue
            idx[r, c] = len(verts)
            verts.append((WX[r, c] - cx, WY[r, c] - cy, WZ[r, c] - z0))
    verts = np.array(verts, dtype=np.float32)

    # triangulate each 2x2 (strided) quad where all corners exist AND the quad isn't
    # a stereo "stretch" spanning a depth discontinuity (skip long edges)
    faces = []
    def ok(a, b):
        return np.linalg.norm(verts[a] - verts[b]) < max_edge * stride
    rows = list(range(0, L - stride, stride))
    cols = list(range(0, S - stride, stride))
    for r in rows:
        for c in cols:
            a = idx[r, c]; b = idx[r, c + stride]
            d = idx[r + stride, c]; e = idx[r + stride, c + stride]
            if a < 0 or b < 0 or d < 0 or e < 0:
                continue
            if ok(a, b) and ok(a, d) and ok(b, e) and ok(d, e) and ok(a, e):
                faces.append((a, d, e))   # CCW, Z-up
                faces.append((a, e, b))

    with open(out_obj, 'w') as f:
        f.write("# Real Perseverance Sol 180 Navcam terrain (NASA/PDS, public domain)\n")
        for v in verts:
            f.write("v %.4f %.4f %.4f\n" % (v[0], v[1], v[2]))
        for tri in faces:
            f.write("f %d %d %d\n" % (tri[0] + 1, tri[1] + 1, tri[2] + 1))

    ext_x = verts[:, 0].max() - verts[:, 0].min()
    ext_y = verts[:, 1].max() - verts[:, 1].min()
    print("verts=%d faces=%d  footprint=%.1f x %.1f m  -> %s"
          % (len(verts), len(faces), ext_x, ext_y, out_obj))


if __name__ == "__main__":
    img = sys.argv[1]
    xml = img[:-4] + '.xml'
    out = sys.argv[2] if len(sys.argv) > 2 else img[:-4] + '.obj'
    build_mesh(img, xml, out)
