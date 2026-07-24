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
- **Enemy mech** (`godot/assets/warrior.glb`) & **player hero mech**
  (`godot/assets/hawc_hero.glb`) — "Bot Mecha Warrior" by **Oscar Creativo** —
  CC-BY 4.0 (via Sketchfab). Credit required in game credits.
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
