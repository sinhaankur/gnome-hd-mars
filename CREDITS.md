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
- **Enemy HAWC archetypes** (`godot/assets/enemy_*.glb`) — five distinct class
  silhouettes, each a real CC-BY model sourced from Sketchfab and normalized for the
  game (`tools/sketchfab_download.py` + `tools/normalize_enemy_mechs.py`).
  Attribution required — CC-BY 4.0:
  - Sentry — "Bipedal Mech" by **Nabo** — https://sketchfab.com/3d-models/bipedal-mech-9271b28473454a53bf037963a2878338
  - Tactical — "Magnetar / Assault Combat Mech" by **Treva** — https://sketchfab.com/3d-models/magnetar-assault-combat-mech-c3a05b54da27477089aeff3cff226c9e
  - Heavy — "Arachnid-Z4 / Heavy Infiltrator Spider Tank" by **Treva** — https://sketchfab.com/3d-models/ebd5ef1895e2455998cb6e9eb827b0dd
  - Support — "MBT-70" by **_Muzaev** — https://sketchfab.com/3d-models/mbt-70-6aebe7926d954a21b1abd0ca8fbfd5d5
  - Hover — "Stormbringer-H4 / Armored Hover Tank" by **Treva** — https://sketchfab.com/3d-models/ae42b017d4084503824746c770220a6d
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
- **On-foot pilot** (`pilot_trooper.glb`) — "Sci-Fi Soldier / Futuristic Combat Trooper"
  by **ART_LOLL** — CC-BY 4.0 (Sketchfab). Normalized upright to 1.85 m as the Union
  pilot for the eject/hijack loop. https://sketchfab.com/3d-models/de876bfdce1c47a4aa67670faee7208e
- **Player hero HAWC** (`hero_striker.glb`) — "Medium Mech Striker" by **MSGDI**
  — CC-BY 4.0 (Sketchfab). Normalized to 7 m + Union-tinted as the player mech.
  https://sketchfab.com/3d-models/27ba717c173a40b7841d2f2c6a89d823
- **Crashed insertion shuttle** (`shuttle_wreck.glb`) — "Sci-fi Dropship" by
  **Pascal T. Monette** — CC-BY 4.0 (Sketchfab). Normalized to 14 m as the prologue
  crash-site wreck. https://sketchfab.com/3d-models/709a1916c0cc4cbebe197e7ef26964cb
- **Fallen astronaut POI** (`astronaut_fallen.glb`) — "Dark Astronaut" by
  **Charles Cloutier** — CC-BY 4.0 (Sketchfab). Normalized to 1.9 m, laid to rest as
  a memorial site. https://sketchfab.com/3d-models/1b2d325edc814d068e920add2ecc8a32

### Mech reference library (`blender_assets/sketchfab_src/mech_library/`, not shipped in-game)
Sourced as candidates/reference for the hero + roster; each CC-BY 4.0 (Sketchfab). Only
those promoted into `godot/assets/` ship; the rest are study/kitbash reference. If any is
shipped, keep its attribution here:
- "Medium Mech Striker" by **MSGDI** — CC-BY 4.0 (in use as hero, above)
- "Catfish Mech low-poly (animated)" by **Jungle Jim** — CC-BY 4.0
- "PHANTOM / Titanfall fan concept" by **sanekcloff** — CC-BY 4.0
- "Biped robot" by **Willy Decarpentrie** — CC-BY 4.0
- "Mech Walker Drone" by **MauriceBaxter** — CC-BY 4.0
- "Robot Warrior" by **Andrei Milin** — CC-BY 4.0
- "Battle Mech" by **Felipe Maciel** — CC-BY 4.0
- "Industrial Sci Fi Loader Droid - F.A.L.D" by **Mike Farrant** — CC-BY 4.0
- "Star Wars AT-ST [Rigged]" by **smithson17** — CC-BY 4.0 (fan model; do NOT ship — IP)

## Not distributed (kept out of this repo)
These are excluded via `.gitignore` and are **not** part of the public release:
- **Reference mechs** (`Glb/` — w9231, wr_hawk, combat_robot) — user-supplied,
  license unverified.
- **Original 1997 game** (`game/`, `G-NOME.bin/.cue`, `extracted/`,
  `cinematics/`) — © 1997 7th Level, Inc. Used only as private study reference;
  never redistributed. Mars HAWC is an independent game and is not affiliated
  with, or endorsed by, the rights holders of G-NOME.

## Procedurally generated (our own — no third-party license)
Built headless in Blender via `tools/build_*.py`, so 100% original geometry:
- **Modular base kit** (`godot/assets/basekit/`) — wall/pillar/panel/door/floor.
- **POI props** (`godot/assets/props/`) — crate/barrel/antenna/pallet/debris.
- **Rock-field variants** (`godot/assets/rockfield/`) — derived by transforming our
  already-shipped scanned `mars_rock_1..4` (source attribution unchanged, above).

## Tools & skills
- **Godot Engine 4** — MIT license (godotengine.org).
- **Sketchfab Blender add-on** v1.7.1 — Apache 2.0, © Sketchfab.
- **Blender Claude skills** (`.claude/skills/blender-*`) — adapted from
  [ra100/blender-claude-plugin](https://github.com/ra100/blender-claude-plugin) — MIT, © 2026 ra100.
