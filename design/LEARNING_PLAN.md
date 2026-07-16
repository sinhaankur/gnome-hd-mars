# Learning Plan — Game Feel & Programming in Godot 4

> Focused, scope-controlled plan to build ONE real skill: **game feel** (movement, camera,
> controls — the "is it fun" part) in Godot 4. Grounded in the research (`SKILLS_REQUIRED.md`):
> extreme depth on one tiny thing, not breadth. Assumes ~4–6 hrs/week, part-time.
>
> **The single goal of this whole plan:** *Make one mech feel genuinely good to drive on an empty
> plane.* Not a game. Not a level. Not art. Just: driving feels heavy, responsive, and satisfying.
> That is the foundation everything else sits on.

---

## Ground rules (read once, follow always)
- **Scope is the enemy.** If you catch yourself adding "and also...", stop. One mech, empty plane.
- **Git from day one.** Commit after every session. Never lose work.
- **Finish each week's milestone before moving on.** A rough-but-done thing beats a perfect plan.
- **Judge by feel, not by code.** After each change, *play it* and ask "does this feel better?"
- **Use the existing project** (`godot/`) or a fresh one — either is fine. Fresh is cleaner to learn on.
- **You already have:** Godot 4.7 installed, a working project, and a mech model (`wr_hawk.glb`).

---

## Phase 0 — Setup (½ session, ~1 hr)
**Goal: tools ready, version control on.**
- [ ] Confirm Godot 4 opens and runs (`godot` in terminal, or the app).
- [ ] Create a new project folder (e.g. `learn_gamefeel/`) OR reuse `godot/`.
- [ ] `git init`, make a `.gitignore` (ignore `.godot/`), first commit.
- [ ] Bookmark the two reference sources you'll actually use (see "Resources" below).
- **Milestone:** empty Godot project opens, runs, and is under Git. Commit: "project setup".

---

## Week 1 — The absolute basics (Godot fundamentals)
**Goal: understand nodes, scenes, scripts, and the game loop. Don't touch mechs yet.**
- Follow **Godot's official "Your first 2D game" (Dodge the Creeps)** tutorial start to finish.
  *(Yes, 2D first — it teaches the engine faster with less friction. ~3–4 hrs.)*
- Learn what these are by using them: `Node`, `Scene`, `_ready()`, `_process(delta)`,
  `_physics_process(delta)`, `Input`, signals, exported variables.
- **Milestone:** you finished Dodge the Creeps and understand *why* each line exists.
  Commit. Write yourself 3 sentences: "a scene is…, `_physics_process` is for…, a signal is…".

---

## Week 2 — Move a box in 3D
**Goal: your first 3D controllable thing. A CUBE, not a mech.**
- New 3D scene: a `CharacterBody3D` with a cube mesh + collision, a floor (`StaticBody3D` plane),
  a camera, a light.
- Write movement: WASD moves the cube. Start with the *simplest* version (instant velocity).
- Then add ONE feel improvement: **acceleration** (ease velocity toward target with `move_toward`).
  Play it before and after. *Feel the difference.* That difference is the whole skill.
- **Milestone:** a cube you can drive around a plane, with acceleration. Commit "moving cube".
- **Concept to internalize:** *game feel = the gap between input and result, deliberately tuned.*

---

## Week 3 — Camera that feels good
**Goal: a third-person camera that follows without making you sick.**
- Add a follow camera behind the cube. Start naive (snap to position) — notice it feels bad.
- Improve step by step, playing after each: (a) smooth the *position* with `lerp`;
  (b) keep the *aim* stable (don't re-snap every frame); (c) add slight look-ahead.
- Try a **SpringArm3D** node (Godot's built-in for chase cams that avoid clipping through walls).
- **Milestone:** driving the cube feels smooth and readable, not jittery. Commit "follow camera".
- *This is exactly the thing our prototype got wrong — you'll now understand why.*

---

## Week 4 — Mouse-look steering + weight
**Goal: modern, responsive control with a heavy feel.**
- Add mouse-look: capture the mouse (`Input.MOUSE_MODE_CAPTURED`), steer with mouse X, ESC to release.
- Tune the "heavy machine" feel with numbers (this IS the craft):
  - acceleration / deceleration rates (weight)
  - top speed
  - turn rate / mouse sensitivity
  - a tiny bit of camera lag on fast turns
- Change ONE number at a time, play, keep or revert. Keep a note of what each does.
- **Milestone:** the cube now feels like a heavy vehicle, not a floating box. Commit "weighty control".

---

## Week 5 — Swap the cube for the mech
**Goal: the mech model, driving well. NOW it looks like something.**
- Import `wr_hawk.glb` (or the box HAWC) as the visual child of your `CharacterBody3D`.
  Orient it upright, scale it, no gameplay change — just a new skin on your good controller.
- Re-tune numbers for the mech's size (bigger = feels heavier/slower).
- Add ONE piece of juice: screen-shake on movement start, or a footstep sound, or camera bob.
  *One.* Play it. Does it add or distract?
- **Milestone:** a mech that feels genuinely good to drive on an empty plane. **This is the goal.**
  Commit "mech feels good". Record a 20-second clip — you'll want the before/after proof.

---

## Week 6 — Reflect, polish, decide
**Goal: consolidate the skill; decide the next tiny scope.**
- Play your Week-5 result next to a game whose movement you admire. Note 3 differences.
- Do a "feel polish pass": fix the single worst-feeling thing. Just one.
- Write a short devlog note: what you learned about game feel, what still feels off.
- **Decide the NEXT tiny milestone** (still scope-controlled), e.g.:
  - "make it fire a weapon that feels punchy," or
  - "make it feel good to turn at speed," or
  - "add one enemy that reacts."
- **Do NOT** decide "now build the game." Depth on the next small thing.

---

## Resources (use these, don't drown in tutorials)
- **Godot official docs — "Getting Started" + "Your first game"** (the canonical path; free).
  <https://docs.godotengine.org/>
- **One video series only** — pick a single well-regarded Godot 4 beginner series (e.g. a
  Brackeys "Godot" intro or GDQuest's free Godot path) and *finish it* rather than sampling many.
- **Godot's "3D" and "SpringArm3D" docs** — for Weeks 2–3 specifically.
- Avoid: 20 open tabs of half-watched tutorials. One course, in order, finished.

## How to know it's working
You'll know the skill is landing when: you can *feel* that a change made movement better or worse,
and you can name *which number* to turn to fix it. That instinct — not memorizing code — is game
feel. That's the skill. Everything else in game dev is a different plan, for later.

---

### Why this plan and not a bigger one
Per the research (`SKILLS_REQUIRED.md`): scope kills projects, not lack of skill. This plan
deliberately learns ONE skill on the SMALLEST possible scope (one mech, one plane, one feel),
finishing something small each week. It's the opposite of what we did before (breadth, nothing
polished). Master this, and you have the single most important skill for making a game fun — and a
real, honest basis to decide whether to go further.
