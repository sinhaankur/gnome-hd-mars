# G-NOME Asset Catalog

Extraction of the 1997 game **G-NOME** (7th Level, Inc.) from `G-NOME.bin`/`G-NOME.cue`,
prepared as reference + reusable material for an HD reimagining in Blender.

> Engine: **RenderWare 2.0** (Criterion). Original art: 640×480, 256-color, low-poly.
> "HD" means **rebuilding** models/textures in Blender using these originals as reference.
> Audio is reused as-is.

## Folder layout (this directory)

| Folder | Contents | Status |
|--------|----------|--------|
| `extracted/gnome01.iso` | The mountable ISO9660 data track (206 MB) | ✅ done |
| `assets/G-NOME/` | All 130 raw game files extracted from the ISO | ✅ done |
| `audio/soundtrack/` | 19 CD-audio tracks → WAV (44.1kHz stereo) — **the soundtrack** | ✅ done |
| `audio/sfx/` | In-game `.WAV` sound effects | ✅ done |
| `cinematics/` | 5 Smacker `.SMK` videos → MP4 (H.264) | ✅ done |
| `tools/` | Analysis scripts | working |
| `design/` | GDD, campaign outline, HAWK rifle asset brief (successor docs) | ✅ done |
| `godot/` | Playable Godot 4 prototype (Level 1) | working |
| `blender_assets/` | Blender HD asset set (placeholder mechs — being replaced by real extraction) | working |

## Design documents (`design/`)

| File | Contents |
|------|----------|
| `design/GDD.md` | Full Game Design Document + technical roadmap for a modern G-Nome successor (pillars, gameplay loop, UE5/Godot architecture, control schema) |
| `design/CAMPAIGN.md` | Mission-by-mission outline of the 20-mission, 4-campaign single-player arc |
| `design/HAWK_rifle_brief.md` | Hard-surface 3D asset brief for the HAWK (hijack) rifle — visual language, mechanics, LODs, texturing |
| `reference/GAME_BIBLE.md` | The extracted source-of-truth: 20 vehicles, all weapons, all structures (from `LABTEXT.DAT`) |

## Audio (reusable as-is — keep unchanged)

- **Soundtrack**: `audio/soundtrack/track02.wav` … `track20.wav` (19 tracks, ~334 MB total).
  These are the Red Book CD-audio music tracks played during the game.
- **SFX**: `SQEEL.WAV`, `TRK_01B.WAV` (loose), plus **20 packed audio banks** inside the
  archives (`G-NOME.000`, `.040`–`.061`) holding voice/dialogue/effects at 22050 & 44100 Hz,
  stereo, 16-bit. (Bank extraction not yet unpacked — format is a 7th Level custom container.)

## Cinematics (converted)

| File | MP4 | Notes |
|------|-----|-------|
| `G-NOME.SMK`  | `cinematics/G-NOME.mp4`  | Intro, 320×200, 64s |
| `DREAM.SMK`   | `cinematics/DREAM.mp4`   | |
| `NEWS.SMK`    | `cinematics/NEWS.mp4`    | |
| `WILKINS.SMK` | `cinematics/WILKINS.mp4` | |
| `CREDITS.SMK` | `cinematics/CREDITS.mp4` | Largest (41 MB SMK) |

Upscaled 2× (nearest-neighbor) to 640×400 for clean playback; AI upscaling possible later.

## 3D models — the `MODL` format

The game's 3D content is **647 `MODL` model blocks** across **42 archive files**.

| Archive group | Count | Role |
|---------------|-------|------|
| Direct MODL packs (`.005`–`.008`, `.035`–`.038`) | 8 files | Standalone object/model sets |
| Embedded-MODL containers (`.001`, `.010`–`.029`, `.088`–`.099`) | 33 files | Level/scene packs (e.g. `.001` holds **149** models) |

**MODL structure (decoded so far):**
- Magic `MODL`, then `u32` fields: `pad, 26, 6, <n1>, <n2>, <n3>, 1.0f, …`
- Per-node: a `1.0`-diagonal **transform matrix** (3×4 floats) + a vertex/geometry block.
- Geometry is **interleaved** float data (verts/normals) with node hierarchy — NOT a flat
  vertex array. Full mesh reconstruction (faces, UVs, material/texture binding) requires
  more reversing. ⚠️ partially decoded.

## Textures / other archives

| Group | Files | Likely content |
|-------|-------|----------------|
| `30050000` uniform | `.071`–`.082` (12) | Textures / HUD / palette atlases (~80–130 KB each) |
| Misc | `.002`–`.004`, `.039`, `.043`, `.044`, `.060` | Level scripts / palettes / textures (unclassified) |
| `BM`-bearing | `.007`, `.028`, `.096`, `.099` | Contain embedded Windows BMP bitmaps (textures) |

## Other game files (reference)

- `G-NOME.EXE` (27 KB launcher) + `RTLIB32.DLL`, `RWL20.DLL`, `RWDL8?20.DLL` (RenderWare runtime)
- `*.R32` = RenderWare driver PE modules (`RENDER.R32`, `NETGN.R32`, `SMACKER.R32`)
- `README.TXT`, `LABTEXT.DAT`, `TRIVIA.DAT/IDX` = text content
- `/DOMINION`, `/KRONDOR` = demos of other 7th Level games (bonus)

## MODL geometry — reversal status (researched)

- The `MODL`/`OB3D` format is **7th Level's own proprietary container**, NOT RenderWare DFF
  (RenderWare 2.08 did rendering only). **No public spec or tool exists** for it.
- The only 7th Level RE tool (`stascorp/7thLevelFile`) handles ADPCM audio + MIDI from their
  *older 2D engine* — not MODL/OB3D, not G-Nome.
- Geometry is interleaved with the node hierarchy + normals (not a flat vertex/face array),
  so clean mesh export requires bespoke reverse-engineering (estimated days, uncertain topology/UV
  fidelity). **Not completed.**
- Textures are NOT stored as standard BMPs on the disc (carving for `BM` headers yielded 0 valid
  files); pixel data is packed/custom with palettes referenced by name. The `.071`–`.082`
  (`30050000`) files are packed/compressed (high-entropy), not directly decodable bitmaps.

## What we DID recover as reference → `reference/`

- **`reference/texture_names.txt`** — **923 unique texture names** the models reference.
- **`reference/texture_paths.txt`** — full original source paths
  (`\7thlevel\gnome\src\data\bitmaps\*.BMP`), revealing the original art directory layout.
- The naming scheme is a full **asset taxonomy**, e.g.:
  - `DBL2CABA / CABS / CABW` = a vehicle CAB in **A**rmor / **S**hadow / **W**ireframe variants
  - `DCHAS*` = chassis parts, `CRAT*` = crates, `MTL1/HTL1/STL1` = material/turret sets,
    `DRT/DRY/DTRE/DSRTRIVR` = desert terrain (dirt/dry/tree/river).

This name map tells you **exactly what art the game contains** — the shopping list for the
Blender rebuild — even though the original low-res pixels aren't directly extractable.

## Blender HD assets (BUILT) → `blender_assets/`

First HD asset set, modeled in Blender from the original game's taxonomy:

| File | Contents |
|------|----------|
| `blender_assets/gnome_assets.blend` | Native Blender file — the whole `G-Nome` collection |
| `blender_assets/gnome_assets.glb`   | glTF 2.0 (universal; modifiers applied) |
| `blender_assets/gnome_assets.obj` + `.mtl` | Wavefront OBJ |
| `reference/preview_hawc.png`  | Render of the HAWC mech |
| `reference/preview_scene.png` | Render of the full desert scene |

Assets built:
- **HAWC mech** (`HAWC_mech` root + 22 parts): armored torso, cockpit canopy, twin reverse-jointed
  legs w/ knee joints + foot pads, hip block, shoulder pauldrons, GASHR cannon w/ glowing muzzle,
  missile pod, sensor visor, antenna. HD bevels + PBR materials (desert tan armor, dark plating,
  metal joints, cockpit glass, emissive glow).
- **Supply crates** ×3 (`crate_AMMO/HEALTH/WEAPON`): beveled olive-drab body, corner rails,
  glowing colored icon panel each (CRATAMMO/CRATHLTH/CRATEONE).
- **Desert terrain** (`desert_terrain`): 120×120 grid, dune + ripple displacement, procedural
  two-tone sand material with grain bump (DRT/DRY/DSRTRIVR desert).

Built live in the user's running Blender into a dedicated `G-Nome` collection, alongside their
unrelated unsaved `smallsat` work (left untouched; user saves their own file).

## Next steps

1. **More assets** — expand the set (more HAWC variants, buildings/`DBL2`/`DBRDG` bridge, enemy
   Scorp units) using `reference/texture_names.txt` as the shopping list.
2. **Textures/UVs** — author HD textures (the originals aren't directly extractable) and UV-map.
3. (Optional, deep) Resume bespoke MODL→OBJ reversing for original low-poly geometry as a base.
4. (Optional) Unpack the 20 audio banks (`.000`, `.040`–`.061`) for individual voice/sfx clips.
