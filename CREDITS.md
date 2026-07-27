# Credits & Third-Party Attributions — Mars HAWC

Original game code, design, story, and tools: **© 2026 Ankur Sinha**, released
under the MIT License (see LICENSE). Third-party assets below keep their own
licenses — retain these attributions in any distribution.

## Real-world data (public domain, attribution appreciated)
- **Mars terrain heightmaps** — carved from HiRISE DTM `DTEEC_001918_1735`
  (Candor Chasma) — NASA/JPL/University of Arizona. Legacy global relief: MOLA,
  NASA/GSFC. Processed via `tools/hirise_regions.py`.
- **Mars surface reference photos** (`reference/real_mars/`) — Perseverance
  Mastcam-Z panoramas, NASA/JPL-Caltech/ASU/MSSS. Public domain.

## Third-party assets (keep these attributions in any distribution)
- **Mars globe texture** (`godot/assets/mars_globe.jpg`) — Solar System Scope,
  based on NASA Viking imagery — CC-BY 4.0. https://www.solarsystemscope.com/textures/
- **Player hero mech** (`godot/assets/hawc_hero.glb`) — "Bot Mecha Warrior" by
  **Oscar Creativo** — CC-BY 4.0 (via Sketchfab). Credit required in game credits.
- **Enemy HAWC archetypes** (`godot/assets/enemy_*.glb`) — five distinct class
  silhouettes, each a real CC-BY model sourced from Sketchfab and normalized for the
  game (`tools/sketchfab_download.py` + `tools/normalize_enemy_mechs.py`).
  Attribution required — CC-BY 4.0:
  - Sentry — "Bipedal Mech" by **Nabo** — https://sketchfab.com/3d-models/bipedal-mech-9271b28473454a53bf037963a2878338
  - Tactical — "Magnetar / Assault Combat Mech" by **Treva** — https://sketchfab.com/3d-models/magnetar-assault-combat-mech-c3a05b54da27477089aeff3cff226c9e
  - Heavy — "Quadruped Mech walker" by **Jungle Jim** — https://sketchfab.com/3d-models/quadruped-mech-walker-5a8a1d83d1674c3982340c38bf52f069
  - Support — "MBT-70" by **_Muzaev** — https://sketchfab.com/3d-models/mbt-70-6aebe7926d954a21b1abd0ca8fbfd5d5
  - Hover — "Duster 46 - Sci-Fi Hovercraft" by **mgfxer** — https://sketchfab.com/3d-models/duster-46-sci-fi-hovercraft-25376ae6a4674c21b164ebc7b84fd80f
- **Mars surface rocks** (`godot/assets/mars_rock_*.glb`) — from "Free Pack - Rocks
  Stylized" by **PolyOne Studio** — CC-BY 4.0 (Sketchfab). Scattered as landmark boulders.
- **Derelict rover POI** (`godot/assets/nasa_rover.glb`) — "NASA Curiosity (Clean)" by
  **Thomas Flynn** — CC-BY 4.0 (Sketchfab).
- **Supply cache POI** (`godot/assets/mars_crate.glb`) — "High-Poly Tactical Supply Box"
  by **TahmidTauz** — CC-BY 4.0 (Sketchfab).
- **Anomaly monolith POI** (`godot/assets/mars_monolith.glb`) — "monolith" by
  **barbodoji** — CC-BY 4.0 (Sketchfab).
- **Scanned regolith ground textures** (`godot/assets/mars_ground_*.png`) — extracted from
  "Gravel Ground Module Scan" by **Pers Scans** — CC-BY 4.0 (Sketchfab).
- **Kenney assets** (`dust_cc0.glb`, `flag_cc0.glb`, `cloud_cc0.glb`) —
  Kenney.nl — CC0.

## Not distributed (kept out of this repo)
These are excluded via `.gitignore` and are **not** part of the public release:
- **Reference mechs** (`Glb/` — w9231, wr_hawk, combat_robot) — user-supplied,
  license unverified.
- **Original 1997 game** (`game/`, `G-NOME.bin/.cue`, `extracted/`,
  `cinematics/`) — © 1997 7th Level, Inc. Used only as private study reference;
  never redistributed. Mars HAWC is an independent game and is not affiliated
  with, or endorsed by, the rights holders of G-NOME.

## Tools & skills
- **Godot Engine 4** — MIT license (godotengine.org).
- **Sketchfab Blender add-on** v1.7.1 — Apache 2.0, © Sketchfab.
- **Blender Claude skills** (`.claude/skills/blender-*`) — adapted from
  [ra100/blender-claude-plugin](https://github.com/ra100/blender-claude-plugin) — MIT, © 2026 ra100.
