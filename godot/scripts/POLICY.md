# G-NOME HD — Code Policy & Architecture

The governing conventions for this project. Read before adding code. The guiding rule:
**before writing any line, ask "how can this be done without endless coding?"** — reuse a
library, extend an engine, or change a data config first. Process over vibe-coding.

## Layers (Atomic Design mapping)
- **Atoms** — `atoms.gd` (`Atoms.*`): smallest reusable helpers (mesh search, ground raycast,
  flash/spark effects). Duplicated helpers go here ONCE. Add an atom only when none exists.
- **Libraries (molecules)** — small composed units: `mech_animator.gd`, `laser.gd`,
  `hud_*.gd`, `game_hud.gd`, `mars_terrain.gd`, `faction.gd`, `exploration.gd`.
- **Engines (organisms)** — the big interacting systems:
  - `environment_engine.gd` — the Mars world (terrain, sun/day-cycle, atmosphere, scatter,
    installation). PASSIVE + authoritative: answers queries (`ground_height`, `is_walkable`,
    `random_edge_spawn`, `time_of_day`), emits events. Depends on nothing above it.
  - HAWC engine — `hawc.gd` (controller) + `follow_camera.gd` + `mech_animator.gd`.
  - `enemy_engine.gd` — wave director + `enemy_ai.gd`. May read HAWC + Environment.
- **Templates** — `mission1.gd`: the thin level composer. Wires engines + managers together.
  Should stay THIN — move logic into engines/managers.
- **Pages (data)** — `campaign.gd` LEVELS array: each level is DATA, not code.

## Managers (autoloads)
- `Settings` — prefs + input map (`_ensure_input_map` binds keys in code — don't rely on
  project.godot for gameplay keys).
- `Sfx` — procedural sound library.
- `Campaign` — level list + progression.
(Future: AudioManager for music, a LevelManager if mission1 logic grows.)

## Dependency direction
Environment → nobody. HAWC → Environment. Enemy → HAWC + Environment. Templates → all.
Never create a cycle; if tempted, use a signal/event instead.

## Conventions
- Every file: header comment (what it is, how to use) + meaningful inline comments.
- Prefer DATA/config over new code. Prefer extending a library over a new script.
- GDScript strict typing: annotate vars that infer from Variant (`lerp`→`lerpf`, `Color.lerp`
  needs `: Color`) or the "warnings as errors" build fails.
- Delete dead code as you go. Keep functions small/composable.

## Asset / Blender rules (hard-won)
- Blender connection is unstable: BUILD + EXPORT in ONE call; never rely on it persisting.
- Never clobber the user's Blender scene — build in an own collection.
- Export GLB, Y-up. VERIFY-BY-RENDER (isolation screenshot) before wiring a model in.
- Mech facing: body faces movement via `atan2(hv.x, hv.z)` (+Z forward); model flip is set
  by `MECH_FACE_FLIP` in mission1 — verify visually, it has bitten us repeatedly.
- Ship licensing-clean assets (CC0 / our own); the reference GLBs are references.

## Known dead files (safe to remove once confirmed — currently kept, no git):
`level1.gd/.tscn`, `tune.gd/.tscn`, `terrain.gd`, `biome.gd`, `hawc_material.gd`, `enemy.gd`
— old prototype cluster, not referenced by the current main scene (main_menu→mission1).
