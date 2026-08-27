---
name: mars-hawc-asset-sourcing
description: Find/scrape CC0/CC-BY 3D assets (Sketchfab + other libraries) for Mars HAWC, then normalize orientation/axis/layout/scale into game-ready GLBs and log attribution. Use when sourcing any new model (mech, ship, pilot, structure, city, rock, prop) or fixing a pulled asset's axis/scale/facing. The eventual goal is to REBUILD each in Blender so the game is 100% custom.
---

# Mars HAWC — Asset Sourcing & Normalization

The plan is two-stage: **(1) FIND** a good CC0/CC-BY asset to make the game look/play right now,
then **(2) REBUILD** it in Blender later so everything is custom-built and 100% ours. Pulled assets
are placeholders/reference until rebuilt. Track every item in `design/GAME_REQUIREMENTS.md`.

> This skill is the *find + normalize* half. For hero modeling / kitbash from scratch, use the
> `blender-asset` skill. This doc is meant to be improved as we learn — edit it freely.

## License policy (hard rule)

- **Prefer CC0** (public domain — becomes fully ours, no attribution, safe to relabel/rebuild).
- **Allow CC-BY** only when nothing good is CC0 — **must** stay credited in `CREDITS.md` with
  author + link + license, until an original replaces it.
- **Block** NonCommercial (NC), NoDerivatives (ND), and paid/standard-license assets.
- When an original Blender rebuild replaces a pull, **remove** that `CREDITS.md` entry.

## Where to find (in order)

1. **Kenney.nl** — CC0, huge sci-fi/modular-kit/prop/UI packs. First stop for structures, props,
   base kits, UI. No attribution needed.
2. **Sketchfab** — best for mechs/ships/characters. Two ways:
   - CLI: `tools/sketchfab_search.py` → `sketchfab_download.py` (token at
     `~/.config/gnome_hd/sketchfab_token`). Filter downloadable + CC0/CC-BY.
   - In Blender: add-on v1.7.1 (Blender 5.1), N-sidebar → Sketchfab tab → log in →
     *Downloadable* filter. It writes an `sf_attributions` text block — copy to CREDITS.
3. **Poly Haven** (CC0 HDRIs/textures/models), **Quaternius / Poly Pizza** (CC0 low-poly),
   **NASA 3D Resources** (public-domain spacecraft/rovers), **ambientCG** (CC0 PBR textures).
4. User's own GitHub repos (check first — `star-cleaver-assets` has planets/asteroids/Voyager).

## Orientation / axis / layout — the normalization contract

Every GLB dropped into `godot/assets/` MUST follow this so it drops into a scene correctly.
(Codified in `tools/normalize_env_assets.py`; this skill ships `scripts/normalize_asset.py`.)

- **Axis:** export with `export_yup=True` → glTF is **Y-up** (Godot's convention). Blender is
  Z-up internally; the exporter converts. Never hand-rotate to fake it.
- **Facing:** the model's **forward = -Z** in Godot. If a mech/ship faces the wrong way after
  import, fix it with a rotation BEFORE apply (the `rot_deg` arg), not in the game.
- **Layout / origin:** center **X/Z** on origin, drop the **base to Y=0** (feet/wheels/hull-bottom
  on the ground), set origin to geometry bounds. So `spawn.position = ground_point` just works.
- **Scale:** real-world **metres**. 1 Blender unit = 1 m. Normalize to the real height/length:
  HAWC ~6–15 m (see roster in `reference/GAME_BIBLE.md`), pilot ~1.8 m, rover ~3 m, crate ~1.2 m.
- **Apply transforms:** location, rotation, AND scale applied before export (no baked-in transforms).
- **Cleanup:** drop stray armatures/empties/cameras/lights; **join** multi-part meshes into one
  object (unless a rig must be kept — hero mechs keep their rig+anim, see normalize_hero_mech.py).
- **Budget:** hero ≤40k tris / 4K PBR; enemy ≤25k / 2K; props ≤5k / 1K; structures modular+instanced.
  **Never** a 243 MB single mesh (the warrior.glb mistake).

## Per-asset flow

```
reference photo/spec  →  find (CC0>CC-BY)  →  download to blender_assets/sketchfab_src/
   →  normalize (scripts/normalize_asset.py: clean → orient → scale → base → apply → GLB)
   →  godot/assets/<name>.glb  →  log in CREDITS.md  →  verify in Godot
   →  (later) REBUILD in Blender → replace → drop CREDITS entry
```

## Verify in-engine (every drop)

- Headless import check: `Godot --headless --path godot --quit` (must be error-free).
- Visual check via the `godot-art-pass` skill: capture a frame, compare to NASA Mars photos,
  fix in payoff order. Judge quality only against real photos.

## Special: City / base environment creation

"City creation" = a Mars settlement/base bigger than the single installation. Approach:
1. **Modular kit first** (Kenney CC0 sci-fi structures, or a few CC-BY building blocks).
2. **Scatter/layout** with Blender geometry-nodes or a Godot layout scene (roads, domes,
   habitat modules, towers, landing pads) — instanced, not one giant mesh.
3. Match the bible's structures (HQ, Meson Tower, Shield Generator, Power Plant, Citadel).
4. Keep it modular so missions can compose different bases; rebuild key hero buildings custom.

## Companion files & pipeline scripts

- `scripts/normalize_asset.py` — generic import→clean→orient→scale→base→GLB (run via Blender MCP
  or `blender --background --python`). Parameterized: name, target size, facing, keep-rig.
- Existing: `tools/sketchfab_search.py`, `sketchfab_download.py`, `normalize_env_assets.py`,
  `normalize_enemy_mechs.py`, `normalize_hero_mech.py` (rig-preserving).
- Requirements tracker: `design/GAME_REQUIREMENTS.md`. Roster/specs: `reference/GAME_BIBLE.md`.

## Keep improving

When a pull's axis/scale/facing needed a fix not covered above, add the rule here. When a source
library proves great (or bad), note it. This skill should get sharper every time we source an asset.
