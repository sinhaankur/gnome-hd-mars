# Mars HAWC — The Build Cycle (the team + the loop)

This defines the **team of agents** that build Mars HAWC and the **repeating cycle** they
run. Each agent is a person on the team, living in `.claude/agents/`. Invoke one by name
(e.g. "have the art-director review the terrain") or let the **producer** route work.

## The team

| Agent | Role | Owns | Key skills |
|---|---|---|---|
| `producer` | Producer | The loop: picks next work, routes it, tracks to done | tasks, git |
| `creative-director` | Creative Director | Vision, G-NOME pillars, story, premise, "is this the RIGHT thing?" | GDD, design docs |
| `art-director` | Art Director | Visual quality bar, judges every frame vs real photos | `godot-art-pass` |
| `asset-artist` | 3D Asset Artist | Mechs, ships, props, terrain meshes → GLBs | `blender-asset`, `mars-hawc-asset-sourcing`, blender suite |
| `godot-engineer` | Gameplay Engineer | `godot/` — 3 engines, hijack loop, physics, combat, HUD | Godot/GDScript |
| `technical-artist` | Technical Artist | Shaders, materials, lighting, Mars surface/ecosystem render | `blender-shader-nodes`, Godot shaders |
| `level-designer` | Level/Mission Designer | Level layout, mission flow, encounters, pacing | design docs |
| `web-dev` | Web/Showcase Dev | The browser "window" — devlog, cinematic, Pages | Three.js, `anatomy` |
| `qa` | QA/Build Engineer | Verifies it runs, deploy health, repo cleanliness | bash, CI |

## The cycle (one iteration = one shippable improvement)

```
        ┌──────────────────────────────────────────────────────┐
        │                                                        │
   1. PLAN            2. DEFINE           3. BUILD               │
   producer  ──►  creative-director  ──►  asset-artist          │
   picks the      + level-designer        godot-engineer        │
   next highest-  decide WHAT and         technical-artist      │
   value piece    why (intent, spec)      web-dev               │
        ▲                                     │                  │
        │                                     ▼                  │
   6. SHIP          5. JUDGE            4. VERIFY                │
   producer   ◄──  art-director    ◄──  qa                      │
   commits,        judges vs REAL        proves it RUNS         │
   updates mem,    photos; sends         error-free, assets     │
   picks next      back slop in          valid, deploy green    │
        │          payoff order              │                  │
        └──────────────────────────────────────────────────────┘
                 (repeat — one thing finished to quality at a time)
```

### Step detail
1. **PLAN** — `producer` reads MEMORY, GDD, git log, open tasks; picks the single most
   valuable next piece (what a player most notices). Creates a task.
2. **DEFINE** — `creative-director` confirms it serves a pillar + the fantasy;
   `level-designer` specs the gameplay/mission shape if relevant. Output: a clear intent.
3. **BUILD** — the right maker does the work: `asset-artist` (models), `godot-engineer`
   (gameplay), `technical-artist` (shaders/lighting), `web-dev` (the browser window).
4. **VERIFY** — `qa` proves it runs error-free, assets are valid, deploy is green.
   Fails here → back to BUILD, never forward.
5. **JUDGE** — `art-director` captures a shot, compares to the real reference, writes an
   ordered fix-list. Fails here → back to BUILD. Passes → it's genuinely good.
6. **SHIP** — `producer` commits with a clear message, updates memory if direction moved,
   picks the next piece. **One thing finished to quality before the next.**

## The rules every agent defends (the house constitution)
- **Real, not sloppy** — judge visuals only against real photos (art-director is the gate).
- **Library-first** — "how do we do this without endless coding?" before any code.
- **Repo-first assets** — check the user's own repos/assets before building new.
- **Finish one thing to quality before starting the next** — the discipline that ships games.
- **Godot stays the game**; the web build is a progress window.
- **Clean up** — no temp/dead files; review `git status` before committing.
- **Every screen/frame must be good and well-designed** — 4K, composed, real.

## How to run it
- **Hand off to the producer** to pick and route the next piece, or
- **Call a specialist by name** for a focused task ("asset-artist: rebuild the hero mech";
  "art-director: judge the arrival cinematic"; "qa: verify the build and deploy").
- The producer keeps the task list; each agent updates its own task to done only when its
  gate truly passes.

## Current open threads (as of this file's creation)
- Hero mech (`hero.glb`) still the old asset — `asset-artist` to rebuild (rigged, 41 anims).
- Real SpaceEngine sky to replace the fake starfield — needs the user to capture it, then `web-dev` wires it.
- Mars surface "ecosystem" (scatter + weather + RSL) — `technical-artist`, per `project-mars-surface-ecosystem`.
- Gameplay depth — `level-designer` + `godot-engineer` (mission variety, player kit).
