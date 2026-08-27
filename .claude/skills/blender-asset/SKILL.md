---
name: blender-asset
description: Source, kitbash, and export game-ready 3D assets for G-NOME HD using Blender and the Sketchfab add-on. Use when the game needs a new model (mech, prop, installation piece) or an existing asset needs rework.
---

# Blender Asset Pipeline — real assets, not invented placeholders

Hand-modeled guesses were rejected before ("invented placeholders"). The order of
preference is: **real extracted asset > sourced CC model > kitbash of CC parts >
build from scratch** (last resort, hero assets only).

## Honest capability limits — what MCP/bpy CAN and CANNOT do

> Set expectations correctly. Trying to *generate* high-definition hero art by scripting
> Blender blind (no visual feedback while modeling) does not work and wastes time. This is
> the #1 recurring mistake. Match the tool to the job:

**Blender-via-MCP is GOOD at (use it here):**
- **Processing/normalizing** downloaded models — fix axis/scale/origin, join, re-export GLB.
- **Procedural / parametric** geometry — geometry-nodes scatter (rocks, dust, debris),
  modular-kit assembly, arrays/mirrors/booleans/bevels, terrain from heightmaps, greebles.
- **Materials/shaders** — PBR node graphs, faction tints, emissive, weathering masks.
- **Kitbashing** — bolting downloaded CC parts together into a new asset.
- **Batch/repeatable** operations across many assets.

**Blender-via-MCP CANNOT realistically deliver:**
- **AAA hero art from scratch.** A beautiful sculpted, hand-textured mech is days of skilled
  human artist work with constant visual feedback. Scripting that quality blind is not feasible.
  Grey-box blockouts: yes. Shippable hero fidelity: no.

**Therefore the strategy for HD hero assets is SOURCE, don't GENERATE:**
1. **Find** the best-looking CC0/CC-BY asset (see `mars-hawc-asset-sourcing` skill).
2. **Process** it in Blender/MCP — normalize, tint, kitbash extra detail, add rig/anim if needed.
3. **Verify** in-engine vs NASA photos (`godot-art-pass`).
4. **Rebuild-from-scratch is a LONG-TERM, human-artist task** — not something to attempt via
   MCP in one go. Keep the sourced asset shipping in the meantime.

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
