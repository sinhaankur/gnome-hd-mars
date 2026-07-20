# Real Mars surface — provenance

The `mars_patch_sol180.glb` terrain in `godot/assets/imported/` is a genuine
recreation of the Martian surface, not procedural or AI-generated geometry.

## Source
- **Mission:** NASA Mars 2020 / Perseverance rover
- **Instrument:** Left Navigation Camera (Navcam), stereo pair
- **Product:** `NLF_0180_0682926799_039XYZ_N0070000NCAM03180_0A0195J04.IMG`
  — a Navcam **XYZ RDR** (per-pixel Cartesian point cloud from stereo processing),
  Sol 180, 3-band IEEE754 MSB float, 960×1280.
- **Archive:** PDS Imaging Node, Mars 2020 Navcam ops-stereo bundle
  `https://pds-imaging.jpl.nasa.gov/data/mars2020/mars2020_navcam_ops_stereo/data/sol/00180/`
- **Rights:** NASA/JPL-Caltech — **public domain** (U.S. government work).

## Pipeline (honest, reproducible)
1. Download the `.IMG` + `.xml` XYZ product from the PDS bundle above.
2. `tools/rover_xyz_to_mesh.py` reads the 3-band point cloud, reprojects the
   rover-nav frame (X fwd / Y right / Z down) to Z-up, clips to the dense
   near-field ground (<16 m, beyond which a single stereo viewpoint smears), and
   triangulates the grid (skipping stretched depth-discontinuity edges) → OBJ.
3. Blender: import OBJ, decimate to ~70k tris, recalc normals, apply a Mars-tone
   basalt material → export GLB (`godot/assets/imported/mars_patch_sol180.glb`).

The raw `.IMG`/`.obj` are gitignored (large, re-fetchable); the small `.xml`
labels are kept here as provenance. The final GLB is a ~22×16 m patch of the
actual ground Perseverance imaged on Sol 180.

## Albedo (done — geometry-driven)
The DFF/color products in this ops-stereo bundle are processed derived products, not a
clean reflectance photo (the true ECM camera image lives in a separate raw bundle). So
the albedo is derived HONESTLY from the real surface shape instead: baked ambient
occlusion + slope drive a dust-tan (exposed up-faces) vs dark-basalt (crevices/steep)
mix, baked to `mars_patch_albedo.png` and embedded in the GLB. Darker areas correspond
to real cavities/shadowed rock faces in the Perseverance geometry.

## Still TODO (polish)
- Crop the fan-shaped Navcam FOV to a clean rectangular tile.
- Tighter edge filtering to remove residual stereo spikes on rock rims.
- Optional: project the true ECM Navcam photo (separate raw bundle) for photographic color.
- Blend the patch seam into the surrounding HiRISE-heightmap terrain in-game.
