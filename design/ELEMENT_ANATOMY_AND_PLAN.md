# Mars HAWC — Element Anatomy, Task Plan, Design Ideas & Skill Map

> One document answering four questions:
> 1. **Anatomy** — every element/resource in the game, what it *is*, and how it connects.
> 2. **Tasks** — that anatomy turned into a prioritised, do-able task list.
> 3. **Design ideas** — concrete ideas to make it play *good*, not just run.
> 4. **Skill research** — which design/engine skills we actually have on hand to build each thing.
>
> Grounded in the real codebase (audited 2026-11-02): the game **loads clean, no script errors**.
> "Not working great" = depth/feel/polish, not a crash. That shapes everything below.

Status legend: 🟢 solid · 🟡 exists, needs work · 🔵 to build · 🔴 broken/weak

---

## 0 · The 30-second map

The game is built on **three engines + thin levels** (a deliberate architecture — see memory
`project-gnome-three-engines`):

```
  main_menu ──▶ planet (globe, pick territory) ──▶ mission1 (the level)
                                                       │
         ┌─────────────────────────────────────────────┼─────────────────────────────┐
         ▼                        ▼                      ▼                             ▼
  EnvironmentEngine         HAWC (player)          EnemyEngine                 Exploration
  (world: terrain, sun,     hawc.gd / pilot.gd     (wave director +            (POIs scattered
   scatter, installation,   + follow_camera        enemy_ai per archetype)      on the surface)
   atmosphere, dust)        + mech_animator
         │                        │                      │
         └──────────────── mission1.gd wires them together, owns win/lose ──────────┘
                                   │
                        GameHUD + pause + end_screen + Audio/Sfx/Campaign (autoloads)
```

`mission1.gd` is a **thin coordinator**: it reads a level dict from `Campaign`, builds the three
engines, and connects their signals. It does *not* raycast or own world geometry — it asks the
Environment where the ground is. This is good structure; keep it.

---

## 1 · ANATOMY — every element & resource

### 1A · Autoloads (global singletons, always alive)

| Resource | File | What it is | State |
|----------|------|-----------|-------|
| **Settings** | `settings.gd` | user prefs (volume, quality) | 🟢 |
| **DevShot** | `dev_shot.gd` | screenshot capture for the art-pass loop | 🟢 |
| **Sfx** | `sfx.gd` | procedural one-shot sounds (ui, alarm, hit) | 🟢 |
| **Campaign** | `campaign.gd` | the level list + current index + unlock/advance | 🟢 |
| **Audio** | `audio_manager.gd` | ambient wind + music beds (calm/tense) | 🟢 |

### 1B · Screens & flow (2D / UI)

| Element | File(s) | Role | State |
|---------|---------|------|-------|
| Main menu | `main_menu.tscn/.gd` | entry; routes to planet/mission | 🟢 |
| Planet / globe | `planet.tscn`, `planet_view.gd` | strategic map, pick a territory | 🟡 polish |
| Mission intro | `mission_intro.gd` | dropship delivery cinematic + briefing card | 🟡 |
| Story screen | `story_screen.gd` | narrative beats | 🟡 |
| Game HUD | `game_hud.gd` + `hud_*` | crosshair, armor bars, radar, hit markers | 🟡 |
| Pause menu | `pause_menu.gd` | ESC: resume/restart/settings/quit | 🟢 |
| End screen | `end_screen.gd` | win/lose, stats, next level | 🟢 |
| Settings screen | `settings_screen.gd` | in-game options | 🟢 |
| Dead prototype | `level1.*`, `tune.*` | **unreachable** from menu | 🔴 retire |

### 1C · The three engines

**Environment** (`environment_engine.gd`, 833 lines — the biggest system)
| Sub-element | Where | What | State |
|-------------|-------|------|-------|
| Walkable terrain | `mars_terrain.gd` | real HiRISE ~1m/px mesh | 🟢 |
| Regolith skin | terrain shader | scanned ground textures, palette-tinted | 🟢 |
| Sun / day cycle | `mars_sun.gd` | drives ALL lighting + shadows | 🟢 |
| Sky / atmosphere | env engine | butterscotch sky, fog, haze | 🟡 |
| Dust / wind | env engine particles | blowing ground dust, follows camera | 🟡 |
| Scatter | env engine | rocks, pebbles, POI props | 🟡 |
| Installation | `installation.glb` | the thing you defend | 🟡 |
| Biome / faction theme | `biome.gd`, `faction.gd` | per-territory palette + tint | 🟡 |

**HAWC / player** (`hawc.gd` 323 · `pilot.gd` 164 · `follow_camera.gd` 150 · `mech_animator.gd` 142)
| Sub-element | What | State |
|-------------|------|-------|
| Player mech | `hero_striker.glb` — rigged, 41 anims, union-tinted | 🟢 |
| On-foot pilot | `pilot_trooper.glb` — eject/board/hijack | 🟡 static anims |
| Camera | 3rd-person follow, speed-widen FOV | 🟡 feel |
| Animator | walk/idle state machine, foot dust | 🟡 |
| GASHR | `gashr.gd` — eject enemy pilots (steal tool) | 🟡 |
| Weapons/FX | `laser.gd`, `rocket.gd`, muzzle/impact | 🟡 feel |
| Specs/materials | `hawc_specs.gd`, `hawc_material.gd`, `hero_material_fix.gd` | 🟢 |

**Enemy / story** (`enemy_engine.gd` 213 · `enemy_ai.gd` 319 · `enemy_tiers.gd` · `enemy.gd`)
| Sub-element | What | State |
|-------------|------|-------|
| Wave director | spawns per-level wave script | 🟢 |
| Enemy AI | role-driven: rush/snipe/anchor/flank + strafe/retreat | 🟡 |
| Archetype models | sentry / tactical / heavy / hover / support `.glb` | 🟡 placeholders |
| Faction routing | per-territory machines + tint | 🟡 |
| Beacon | `beacon.gd` — "reach" objective landmark | 🟢 |

### 1D · Asset library (`godot/assets/`)

| Group | Count / files | State | Note |
|-------|---------------|-------|------|
| Player hero mech | `hero_striker.glb` (9.3 MB) | 🟢 | best asset; most-seen |
| Pilot | `pilot_trooper.glb` (8 MB) | 🟡 | static; needs walk rig |
| Enemy mechs | sentry/tactical/heavy/hover/support | 🟡 | borrowed CC-BY placeholders |
| Ships | dropship, subship, hawc_pod | 🟡 | bay-door anim TODO |
| Structures | `installation.glb` + `basekit/` (5 modules) | 🟡/🟢 | kit is ours; HQ borrowed |
| Props | `props/` (5), crate, monolith (9 MB — oversized) | 🟡 | monolith needs slimming |
| Rocks | `mars_rock_1..4` + `rockfield/` (16 variants) | 🟢 | real scans, baked AO |
| POIs | nasa_rover, shuttle_wreck, astronaut_fallen | 🟢 | real/credited |
| Terrain data | HiRISE maps, regolith textures, mars globe | 🟢 | real ~1m/px |
| Dead weight | `env/grass/ice/molten_hd`, `gnome_assets`, `wr_hawk` | 🔴 | pre-Mars leftovers → delete |

### 1E · The big liability

`design/bot_mecha_warrior_3d_by_oscar_creativo.glb` = **254 MB** and `w9231_combat_mech_rigged-2.glb`
= **139 MB** sit in the repo but **are not loaded by the game**. They bloat the repo massively.
→ Confirm unused, then remove from working tree (keep off LFS or delete). See task T-21.

---

## 2 · TASKS — prioritised

Ordered by **payoff for "make it feel good"** first, then breadth, then cleanup.
`[S]` small (<1h) · `[M]` medium (half-day) · `[L]` large (multi-session).

### Tier 1 — Game feel (why it "doesn't feel great"; no new assets)
- **T-01 [M]** Run the `godot-art-pass` loop: capture current build, compare vs NASA refs, list the top 5 visual slop items. *Measure before fixing.*
- **T-02 [M]** Combat feel: hit-stop on impact, stronger muzzle flash, camera shake on fire/hit, tracer/impact punch. (`hawc.gd`, `laser.gd`, `follow_camera.gd`, `game_hud.gd`)
- **T-03 [S]** Camera feel: tune follow lag, collision with terrain, speed-widen FOV curve. (`follow_camera.gd`)
- **T-04 [M]** Enemy readability: health bars that face camera, hit markers, death FX, clearer aggro tells. (`enemy_ai.gd`, `game_hud.gd`)
- **T-05 [S]** Movement feel: accel/decel curve, foot-dust scaling with speed, landing thump on jetpack land. (`hawc.gd`, `mech_animator.gd`)
- **T-06 [S]** Audio punch: weapon fire, impacts, mech footsteps, low-armor warning. (`sfx.gd`, `audio_manager.gd`)

### Tier 2 — Gameplay depth (memory: "gameplay is just low")
- **T-07 [L]** Player kit: give the mech 2–3 real weapons (primary/secondary/special) with distinct feel + cooldowns, not one fire button. (`hawc.gd`, `hawc_specs.gd`)
- **T-08 [M]** Mission variety: make `defend` / `reach` / `hijack` feel distinct; add 1 new verb (escort or destroy-target). (`mission1.gd`, `campaign.gd`)
- **T-09 [M]** Possession core payoff: stolen mechs keep their weapon loadout (not just the model); make hijack worth it. (`mission1.gd` `_steal`, `hawc_specs.gd`)
- **T-10 [M]** Wave pacing: spawn telegraph, reinforcement dropships, a boss/elite in the final wave. (`enemy_engine.gd`)

### Tier 3 — Asset quality (breadth over polish — memory rule)
- **T-11 [M]** Replace borrowed enemy mechs OR re-tint cleanly into the 20-unit roster (5 classes × 4 factions) via Godot shader. (`faction.gd`, `mars-hawc-asset-sourcing`)
- **T-12 [M]** Pilot walk rig so on-foot phase reads right. (`blender-animation-rigging`)
- **T-13 [S]** Slim the 9 MB monolith; audit oversized assets. (`blender-expert`)
- **T-14 [M]** Installation/HQ: assemble from the owned `basekit/` modules instead of the borrowed GLB. (`blender-modeling-modifiers`, `blender-geometry-nodes`)

### Tier 4 — World / atmosphere (Phase 2, mostly shader/particle)
- **T-15 [M]** Atmosphere calibration: sky color, height-haze, horizon aerial perspective vs NASA. (env engine, `godot-art-pass`)
- **T-16 [S]** Dust polish: wind *direction* global var, density/opacity to NASA, mech plume scaling. (env engine)
- **T-17 [M]** Signature Mars FX: dust devils, weather states (clear/dusty/storm). (`blender-physics-simulation` refs + Godot particles)
- **T-18 [S]** Night pass: starfield + Phobos/Deimos moons + mech running lights. (`mars_sun.gd`, env engine)

### Tier 5 — Cleanup / hygiene (memory rule: always clean up)
- **T-19 [S]** Commit the untracked `basekit/`, `props/`, `rockfield/` `.import` + AO files (or gitignore intentionally). *Working tree is dirty right now.*
- **T-20 [S]** Retire dead scenes `level1.*` + `tune.*` and their only-referenced GLBs (`wr_hawk`, `gnome_assets`) ~3.7 MB.
- **T-21 [M]** Remove the 254 MB + 139 MB unused mech GLBs from `design/` and repo root — confirm no loader references first.
- **T-22 [S]** Delete pre-Mars biome sets (`env/grass/ice/molten_hd`) once confirmed unreferenced.

---

## 3 · DESIGN IDEAS — making it play *good*

These are opinionated bets, ordered by impact. The north star (memory): **GTA-like open Mars,
real not sloppy, the G-NOME possession loop as the signature mechanic.**

1. **Make the possession loop the whole point.** Right now it's a feature; make it the *fantasy*.
   Every enemy mech is a potential upgrade. Show a "STEAL VALUE" readout on enemies (class, armor,
   weapons) so the player *wants* to GASHR-and-board rather than just shoot. Your mech is
   disposable; the next one is the reward. This is what makes it G-NOME and not generic.

2. **Three weapons, three feels.** A rapid light weapon (hitscan, suppressive), a heavy slow one
   (projectile, big punch, splash), and a special (missile lock / ion burst with cooldown). The
   *difference* between mechs becomes which three you get — ties directly into possession (#1).

3. **Encounters, not waves.** Pure "N enemies spawn" is flat. Use the terrain: snipers on ridges,
   a heavy anchoring a chokepoint, flankers using crater rims as cover. The env already has
   `slope_at` / `is_walkable` — let the AI *use* the real HiRISE geography.

4. **Feel first, content second.** A game with 3 weapons that feel *great* (hit-stop, shake,
   screen-space punch, audio crunch) beats 20 mechs that feel like cardboard. Tier-1 tasks are the
   actual fix for "doesn't feel great."

5. **One signature set-piece per mission.** A dust storm that rolls in and drops visibility, a
   collapsing canyon, a reinforcement dropship you can shoot down before it unloads. Cheap to build
   (one scripted event), huge for memorability.

6. **Diegetic everything.** Memory shows a lean toward diegetic UI (cockpit readouts, physical
   beacons, real crash sites). Lean all the way in: the HUD *is* the cockpit, the objective *is* a
   thing in the world. It's the cheapest way to look premium.

7. **Scope discipline.** Memory (`reference-gnome-production-doc-index`) says: **one great mech →
   one great hijack vertical-slice mission → then scale.** Resist building all 20 mechs before one
   mission is genuinely fun. Tier 1+2 make one mission fun; Tier 3 scales.

---

## 4 · SKILL RESEARCH — what we have to build each thing

These are the **actual skills available in this environment** (not aspirational). Each row maps a
build area to the right tool so we never "endlessly code" what a skill/engine does for us
(memory: `feedback-lean-library-first-coding`).

### 4A · In-environment skills (callable now)

| Skill | What it's for | Use it for (tasks) |
|-------|---------------|--------------------|
| **godot-art-pass** | reference-vs-game visual loop; capture + compare vs NASA, fix slop in payoff order | T-01, T-15, T-16 — the judge of "real not sloppy" |
| **mars-hawc-asset-sourcing** | find→rebuild CC0/CC-BY assets; axis/scale/layout contract (Y-up, −Z fwd, base Y=0, real metres) | T-11 roster, any new GLB |
| **blender-asset** | source/kitbash/export game-ready GLBs for this game via Sketchfab add-on | T-11, T-14, new props |
| **blender-expert** | Blender→glTF export, optimization, batch bpy scripting, texture baking | T-13 slim assets, all exports |
| **blender-animation-rigging** | armatures, IK/FK, keyframes, NLA, shape keys | T-12 pilot walk, mech anim fixes |
| **blender-modeling-modifiers** | SubSurf/Boolean/Array/Mirror/Bevel, bmesh, hard-surface | T-14 structures, hero mech detail |
| **blender-geometry-nodes** | procedural scatter, modular layout, instancing | T-14 base layout, dune/rock fields |
| **blender-shader-nodes** | PBR materials, procedural textures, world/HDRI | mech materials, regolith detail |
| **blender-scene-rendering** | Cycles/EEVEE, import/export, color mgmt (AgX), view layers | render checks, cinematics |
| **blender-physics-simulation** | rigid body, cloth, fluid/smoke/fire (Mantaflow), particles | T-17 dust devils/storm refs, destructibles |
| **blender-compositing-nodes** | post, color grade, glare, DoF, render passes | cinematic polish, promo shots |
| **blender-python-scripting** | bpy operators, batch, add-ons, handlers | automation (we already have `tools/build_*.py`) |
| **anatomy** | crafted interactive isometric SVG explainers | docs/pitch diagrams (this file's visuals) |
| **framer-motion** | React/Next animation (house eases, scroll, gestures) | a web landing page for the game, if wanted |

### 4B · In-game "engines/managers" (our own code — the library-first layer)

The project already follows an Atomic-Design / engine-manager model (memory
`feedback-lean-library-first-coding`). Reuse these instead of writing new one-offs:

| Layer | Files | Reuse for |
|-------|-------|-----------|
| **Atoms** | `atoms.gd` | mesh helpers, foot-align, dust material — call before hand-rolling |
| **Engines** | `environment_engine.gd`, `enemy_engine.gd`, HAWC stack | all world/enemy/player behavior routes here |
| **Managers (autoload)** | Audio, Sfx, Campaign, Settings, DevShot | global state; never re-implement |
| **Policy** | `scripts/POLICY.md` | the coding rules for this project — read before adding code |
| **Data** | `campaign.gd` level dicts, `hawc_specs.gd`, `enemy_tiers.gd` | tune gameplay as *data*, not new code |

### 4C · Tooling we already built (`tools/`)
`build_enemy_mechs.py`, `build_hero_mech.py`, `build_props.py`, `build_base_kit.py`,
`build_rock_field.py`, `build_ships.py`, `normalize_*.py`, `sketchfab_search/download*.py`,
`hirise_regions.py`, `mars_heightmap.py`. **Headless-Blender pipelines already exist** — extend
these rather than starting new ones.

---

## 4.5 · Living world / fauna & hazards (idea bank — "sand worm etc")

> Captured as **ideas to build later**, not yet scheduled. A living world is a huge "GTA-feel" win
> but must stay *real-not-sloppy* — Mars has no macro-fauna, so these read as **sci-fi additions**
> (terraforming experiments, alien/engineered life, geological hazards) rather than Earth animals.
> They slot cleanly into the three-engine model: a **creature/hazard = an Environment-owned entity**
> with its own tiny AI, surfaced to the level via signals like enemies are.

| Idea | What it is | Engine home | Build sketch |
|------|-----------|-------------|--------------|
| **Sand worm** | burrowing colossus under the dunes; surfaces to attack mechs, dives again | Environment (hazard entity) | path under terrain via `ground_height`; breach VFX (displaced regolith particles); a damage AoE + grab; rare spawn in dune regions. Blender: segmented tube rig (`blender-animation-rigging`), geo-node sand burst. |
| **Dust-devil (living)** | the planned Phase-2 dust devil, but it *tracks* and buffets the player | Environment | moving column particle + force push on the mech; ties to weather state. Pure Godot particles + a global wind vector. |
| **Regolith crawlers** | small swarming engineered scavengers; skitter, flee light, chew props | Environment / Enemy | MultiMesh-instanced for a swarm (cheap); simple flock AI; a minor nuisance, not a boss. |
| **Rock-mimic / ambush node** | a "boulder" that's actually a dormant turret-creature; wakes when you're close | Environment | reuse a rock mesh + reveal anim; perfect for encounter design (crater-rim ambush). |
| **Geysers / vents** | CO₂/steam jets that erupt on a timer; knock-back + obscure vision | Environment hazard | scripted timed particle + area force; a traversal puzzle/hazard, no new mesh. |
| **The G-NOME itself** | the original game's titular bio-weapon — an engineered monster as a campaign boss | Enemy (story) | the lore payoff; a hero build much later (`blender-asset`, physics sim for motion). |

**Why the sandworm is a great first creature:** it's a *set-piece*, not a crowd — one of them, rare,
scripted. That's cheap (one entity + breach VFX) but unforgettable, which is exactly the
"signature set-piece per mission" design bet (§3.5). Scheduled only after Tier-1 feel + Tier-A perf.

---

## 5 · Recommended first move

If the goal is "make it feel great," do **T-01 → T-02 → T-07** in order:
1. **T-01** measures the actual gap with the art-pass loop (no guessing).
2. **T-02** fixes combat feel (hit-stop, shake, FX) — the single biggest "feels cheap" fix.
3. **T-07** gives the player a real kit — the biggest "gameplay is low" fix.

Everything else (breadth of mechs, world FX, cleanup) scales *after* one mission is genuinely fun —
exactly the scope guidance the production doc already validated.
