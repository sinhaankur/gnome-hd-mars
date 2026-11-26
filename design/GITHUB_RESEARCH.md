# GitHub Research + Make Mars HAWC Optimal & Fast

> Goal (user, 2026-11-02): *"design the game with this so it's optimal and works faster"* — and a
> hunch that **"we are missing something important [for a] fast game."**
>
> This doc answers that in three parts:
> 1. **What's on GitHub we can USE** — engines, plugins, assets, so we build faster (library-first).
> 2. **What's making OUR game heavy** — measured facts about this repo + runtime.
> 3. **The optimize plan** — prioritised, with the one thing we're actually missing at the top.
>
> Method: real web/GitHub search (Nov 2026) + a direct audit of this repo. Sources at the bottom.

---

## PART 1 · What's on GitHub we can use (build faster, library-first)

Library-first is a project rule (`feedback-lean-library-first-coding`): *before any code, ask "how
without endless coding?"* These are the real, license-safe building blocks.

### 1A · Terrain / open-world engines (don't hand-roll what these do)

| Project | What it gives us | License | Fit for us |
|---------|------------------|---------|-----------|
| **TokisanGames/Terrain3D** | C++ GDExtension clipmap terrain (Witcher-3 tech): 16k×16k, 10 LODs, 32 texture sets, GDScript/C# API | MIT | **Strong.** Could replace `mars_terrain.gd` if we outgrow HiRISE meshes. Built-in LOD = the FPS win on big maps. |
| **mohsenph69/Godot-MTerrain-plugin** | GDExtension terrain *built for open worlds*: HLOD, procedural grass/trees, multi-frame asset streaming (no stutter) | MIT | **Strong.** The "distribute loading across frames" feature is exactly the anti-stutter we need. |
| **TopScales/terrainer** | GPU terrain: whole terrain = **one MultiMesh**, CDLOD vertex-morph (no LOD popping), biome painting | MIT | Good reference for the single-MultiMesh + GPU-morph pattern. |

> **Decision:** our terrain already works (real HiRISE). Don't swap engines mid-flight. BUT adopt
> their *techniques* (clipmap LOD, frame-distributed streaming) and keep Terrain3D as the escape
> hatch if we ever want a truly huge continuous Mars.

### 1B · Reference games (learn architecture, not fork wholesale)

| Project | Why look at it | License |
|---------|----------------|---------|
| **lampe-games/godot-open-rts** | Clean Godot 4 RTS: unit management, selection, pathing at scale — relevant if enemy counts grow | open |
| **gdquest-demos/godot-open-rpg** | Turn-based combat structure, clean state handling | open |
| **davelawson/mech** | A BattleTech-style mech game (management, not action) — mech *data modeling* reference only | open |
| **godotengine/tps-demo** (memory ref) | The animation state-machine reference for our mech locomotion | MIT |

> No existing open-source **mech-piloting action game on Mars** to fork (confirmed again). We're
> building something that doesn't exist — so we take *patterns* (RTS unit scale, TPS anim SM) not
> whole games.

### 1C · CC0 assets to build faster (zero attribution, becomes ours)

CC0 = public domain, commercial OK, no credit. This is the fastest path to breadth (memory:
`project-gnome-asset-sourcing-pipeline` = find CC0>CC-BY now, custom-build later).

| Source | What | Use for |
|--------|------|---------|
| **Quaternius — Animated Mech Pack** (CC0) | rigged mechs, animated | enemy roster variety; player-mech alternates |
| **Quaternius — Sci-Fi Essentials Kit** (CC0, 60+) | robots, guns, screens, crates | props, weapons, enemy infantry |
| **Quaternius — Modular Sci-Fi MegaKit** (CC0, 270+) | grid-modular base pieces, color-mask shaders, **Godot-ready** | the Mars base / installation / city (replaces borrowed `installation.glb`) |
| **Quaternius — Sci-Fi Modular Gun Pack** (CC0, ~80 parts) | mix-match weapon parts | the 3-weapon player kit (T-07 in the plan) |
| **Kenney — Space Kit / Sci-Fi UI / Sci-Fi Sounds** (CC0) | ships, HUD icons, 70 laser/scan/mech SFX | ships, HUD, audio punch |
| **Poly Haven** (CC0) | PBR ground textures + HDRIs, photoreal | Mars regolith detail, sky/ambient |

> **Why this matters for "faster":** the Quaternius MegaKit is **grid-modular and already works in
> Godot**. Assembling a base from it is hours, not the weeks a bespoke Blender build takes. It
> directly unblocks the structures/city rows that are all 🔵 FIND in `GAME_REQUIREMENTS.md`.

---

## PART 2 · What's making OUR game heavy (measured 2026-11-02)

### 2A · Repo weight — **4.9 GB working tree, 1.1 GB `.git`**

| File | Size | Tracked in git? | Verdict |
|------|------|-----------------|---------|
| `G-NOME.bin` | 571 MB | **No** (gitignored) | original disc — local only, fine |
| `extracted/gnome01.iso` | 206 MB | No | disc extract — local only, fine |
| `mars_data/hirise/candor_chasma_dtm.IMG` | 262 MB | No | re-derivable NASA data, fine |
| `design/bot_mecha_warrior_3d_…glb` | 243 MB | No (gitignored) | **unused** — delete from disk |
| `w9231_combat_mech_rigged-2.glb` ×2 | 132 MB ×2 | No (gitignored) | **unused** — delete from disk |
| `godot/.godot/imported/warrior_*.ctex` | **529 MB** (57 files) | No (gitignored) | **orphan cache** from retired warrior.glb — delete |
| `godot/assets/warrior_*.jpg` | **22 MB** (25 files) | likely tracked | **orphan textures** from retired warrior.glb — delete |

**Good news:** the giant files are already gitignored, so the *pushed* repo isn't carrying them.
**Bad news:** 1.1 GB `.git` = history bloat from before the purge; ~1.2 GB of local disk is pure dead
weight (the two unused mechs + the warrior ctex cache + orphan jpgs).

### 2B · Runtime — what the engine is doing per frame

| Setting (project.godot) | Current | Note |
|-------------------------|---------|------|
| Directional shadow size | **4096** | high; soft-shadow filter quality **3** (max) |
| MSAA 3D | 2 (2×) | + `screen_space_aa` 1 + `use_taa true` — **AA stacked** |
| SSAO quality | 3 (max) | expensive full-screen effect |
| SSIL quality | 2 | screen-space indirect light — expensive, rarely noticed |
| Glow upscale | 1 | fine |

**Rock scatter already uses MultiMesh** (`environment_engine.gd:563` — 2800 instances, one draw call
per variant). ✅ That's the big open-world win *already done*. So our FPS cost is **NOT** draw calls
from scatter — it's **full-screen effects** (SSAO+SSIL+TAA+4096 soft shadows all maxed) and
**oversized textures**.

### 2C · The thing we're "missing" for a fast game

Per the optimization guides, the single most-common miss — and the one that matches "it doesn't feel
fast" — is **physics interpolation + tick rate**, together with **no profiling/monitor loop**:

- **Physics interpolation is almost certainly OFF.** At 60 Hz physics with no interpolation, a mech
  moving fast looks *stuttery* even at high FPS. Turning on `physics/common/physics_interpolation`
  (and optionally dropping physics to 30 Hz) is the classic "suddenly feels smooth" switch.
- **No in-game Monitors/profiler habit.** We've been guessing at perf. The guides are unanimous:
  measure CPU-vs-GPU-bound *first* (Debugger → Monitors: FPS, draw calls, objects drawn, physics ms).
- **Mesh LOD / visibility ranges unused on props.** Rocks are MultiMeshed, but POIs, wrecks, the
  rover, mechs have no `visibility_range_end` — they render at full detail to the horizon.

---

## PART 3 · The optimize plan (prioritised)

`[S]`<1h · `[M]` half-day · `[L]` multi-session. **P-01 is the "missing thing."**

### Tier A — the missing-fast-game fixes (cheap, high feel)
- **P-01 [S]** Turn ON **physics interpolation**; try **30 Hz** physics tick. *The "suddenly smooth" switch.* (`project.godot`)
- **P-02 [S]** Add a dev **Monitors overlay** (FPS, draw calls, objects drawn, physics ms) toggled by a key, so we stop guessing. (new tiny `scripts/perf_hud.gd`)
- **P-03 [S]** Dial back stacked full-screen FX to a budget: **SSIL off** (barely visible, costly), **SSAO 3→1**, keep TAA, pull **shadow max distance** in tight. Re-measure with P-02. (`project.godot` + env)

### Tier B — repo/disk slimming (smaller/faster repo)
- **P-04 [S]** Delete orphan **warrior ctex cache** (529 MB) and **warrior_*.jpg** (22 MB) — retired asset leftovers, re-derivable/dead. (also do T-19/T-20 from the plan)
- **P-05 [S]** Delete the two **unused mech GLBs** on disk (243 MB + 132 MB×2 = ~507 MB) — confirmed no loader references. Keep one archived outside the repo if wanted.
- **P-06 [M]** `git gc --aggressive` / consider history filter for the 1.1 GB `.git` (only if clone speed matters; risky — back up first).

### Tier C — runtime scaling (FPS as content grows)
- **P-07 [M]** Add **visibility ranges** to props/POIs/wrecks/rover (30–120 m by size); let distant clutter cull. (env scatter + POI spawn)
- **P-08 [M]** Confirm **auto mesh LOD** survived GLB import on mechs; tune `mesh_lod_threshold`. (import settings)
- **P-09 [S]** Keep collision shapes **primitive** (capsule/box) — audit for any trimesh colliders on terrain/props; let distant enemies **sleep**.
- **P-10 [M]** Texture budget pass: no mech/texture over 2K; props 1K (several enemy textures are 1.8 MB+ 2K+ now). (`blender-expert` batch)

### Tier D — build-faster (library-first, from Part 1)
- **P-11 [M]** Pull **Quaternius Modular Sci-Fi MegaKit** (CC0) → assemble the installation/base/city. Unblocks all the 🔵 structure rows at once.
- **P-12 [S]** Pull **Kenney Sci-Fi Sounds** (CC0) → weapon/impact/mech audio punch (feeds feel task T-06).
- **P-13 [M]** Evaluate **MTerrain** or **Terrain3D** as the escape hatch *only if* we want one continuous huge Mars later — not now.

---

## Recommended sequence

1. **P-01 + P-02 + P-03** (one session) — flip physics interpolation, add the perf overlay, cut the
   stacked full-screen FX. This is the "make it feel fast" core, and P-02 lets us *prove* each change.
2. **P-04 + P-05** — reclaim ~1 GB of dead disk in minutes.
3. Then scale with Tier C as content grows, and pull CC0 kits (Tier D) to build breadth fast.

> Everything here honors the project rules: library-first (Part 1), measure-don't-guess (P-02),
> real-not-sloppy (verify via `godot-art-pass` after FX cuts), always clean up (Tier B).

---

## Sources

- [TokisanGames/Terrain3D](https://github.com/TokisanGames/Terrain3D) — MIT clipmap terrain
- [mohsenph69/Godot-MTerrain-plugin](https://github.com/mohsenph69/Godot-MTerrain-plugin) — open-world terrain + HLOD
- [TopScales/terrainer](https://github.com/TopScales/terrainer) — single-MultiMesh GPU terrain
- [lampe-games/godot-open-rts](https://github.com/lampe-games/godot-open-rts) — Godot 4 RTS
- [gdquest-demos/godot-open-rpg](https://github.com/gdquest-demos/godot-open-rpg) — turn-based combat
- [davelawson/mech](https://github.com/davelawson/mech) — mech data-model reference
- [Godot 3D Optimization Guide (2026)](https://www.strayspark.studio/blog/godot-3d-optimization-guide-2026)
- [Godot 4.4 Performance: 60 FPS tips](https://godotawesome.com/godot-44-performance-optimization-60fps/)
- [Quaternius (CC0 3D)](https://quaternius.com/) · [Modular Sci-Fi MegaKit](https://quaternius.itch.io/modular-sci-fi-megakit)
- [Kenney (CC0 assets/audio)](https://kenney.nl/)
- [Poly Haven (CC0 PBR + HDRI)](https://polyhaven.com/)
