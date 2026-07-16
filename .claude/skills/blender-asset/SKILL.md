---
name: blender-asset
description: Source, kitbash, and export game-ready 3D assets for G-NOME HD using Blender and the Sketchfab add-on. Use when the game needs a new model (mech, prop, installation piece) or an existing asset needs rework.
---

# Blender Asset Pipeline — real assets, not invented placeholders

Hand-modeled guesses were rejected before ("invented placeholders"). The order of
preference is: **real extracted asset > sourced CC model > kitbash of CC parts >
build from scratch** (last resort, hero assets only).

## Sourcing (do this before modeling anything)

- **Sketchfab add-on v1.7.1** is installed and enabled in Blender 5.1
  (`~/Library/Application Support/Blender/5.1/scripts/addons/sketchfab/`).
  In the 3D Viewport: N-sidebar → Sketchfab tab → log in → search with the
  *Downloadable* filter. Prefer **CC0**, then **CC-BY** (the add-on writes an
  `sf_attributions` text block — copy it into the game credits).
- Existing local libraries: `Glb/` (reference mechs), `cc0_assets/`, Kenney packs.
- Reference images first: collect real photos into `reference/` before judging any
  model. For Mars environment matching, use `reference/real_mars/`.

## Blender working rules (hard-learned)

- **Blender is unstable here — build and export in ONE session/call.** The MCP
  connection drops and scenes reset. Never leave work unsaved in the GUI scene.
- **Never clobber the open scene** — the user keeps unrelated work (satellite
  project) in the main file. Work inside the `G-Nome` collection or a fresh file.
- Don't fuss per-asset ("breadth over polish") — EXCEPT the player mech, which gets
  full detail (4K PBR textures-first).

## Export conventions (Godot side)

- Export **GLB** into `godot/assets/`, lowercase snake_case names.
- Mechs: rigged, ~2.5 units tall at identity; the level applies `MECH_SCALE`
  (see `scripts/mission1.gd`). Include a walk/idle animation if available
  (`mech_animator.gd` drives it).
- Materials: Principled BSDF only — complex node graphs won't survive export.
  Environment-wide looks (Mars tint, faction colors) are applied in Godot shaders,
  not baked into the GLB.
- After export, verify in-game with the `godot-art-pass` skill loop, not in Blender.
