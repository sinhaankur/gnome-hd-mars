# What It Actually Takes to Build a Game Like G-Nome

> Research summary (June 2026) on the skills, roles, scope, and reality of building a 3D mech
> combat game — solo and as a team. Written for this project after the prototype made clear that
> "reimagining a game" is a *production* effort, not a design act. Sources at the bottom.

---

## The one-sentence truth
**The hard part isn't mastering any single skill — it's that a game needs ALL of them at once,
and each is its own years-long craft.** A studio splits these across specialists; a solo dev has
to be every one of them. That's why our prototype felt hollow next to the finished 1997 game: we
did a little of everything and none of it deeply.

---

## The full skill stack (what a game like this requires)

| # | Discipline | What it covers | How hard / how long to get good |
|---|-----------|----------------|---------------------------------|
| 1 | **Programming / Game Dev** | Core loop, mech controls, physics, weapons, AI, optimization. C#/C++/GDScript + an engine. | High. The biggest time sink. Months to be functional, years to be good. |
| 2 | **Game Feel / Systems Design** | Movement weight, camera, control tuning, balance — *invisible until you play it.* The "is it fun" skill. | High and underrated. This is the part that made ours feel "shit." |
| 3 | **3D Modeling (hard-surface)** | Mechs, weapons, props, environments. Blender. Topology, polycount, UVs. | High. Mech games are art-heavy — usually needs >1 artist or a strong generalist. |
| 4 | **Texturing / Materials** | Making models look real, not grey. Substance Painter / Blender shading, PBR. | Medium-high. Its own discipline separate from modeling. |
| 5 | **Rigging / Animation** | Walk cycles, weapon recoil, locomotion. Makes models move convincingly. | High. A mech that moves badly reads as broken. |
| 6 | **Level / Combat Design** | Arenas, encounters, mission flow, difficulty curve. | Medium-high. Distinct from systems design. |
| 7 | **Sound Design / Music** | Weapon SFX, weighty mech sounds, explosions, atmosphere, score. | Medium. *(For G-Nome we already extracted the original audio — a head start.)* |
| 8 | **Networking / Server** | Only if multiplayer PvP is core (it often is for mech games). | Very high. A specialist skill on its own. |
| 9 | **Writing / Narrative** | Lore, campaign, dialogue. Optional but defines tone. | Medium. *(We already have the GDD + campaign outline.)* |
| 10 | **Producer / Scope Management** | Milestones, cutting scope, actually finishing. | The skill that decides whether anything ships at all. |
| 11 | **Marketing / Community** | Devlogs, trailers, audience. *In 2025+ a game without this is invisible.* | High and usually a technical person's weakest area. Budget 25–40% of effort here. |
| 12 | **QA / Testing** | Finding and fixing what breaks. | Ongoing; tedious but essential. |

If you're picking where to start, the top 3 for a mech game are
**programming + 3D art/animation + game design**, with sound and networking added only if needed.

---

## The reality checks (the parts beginners underestimate)

- **Scope kills more projects than skill does.** The #1 lesson across every source. Buckshot
  Roulette (one mechanic, made in Godot) sold 8M copies and beat games with 10× the feature list.
  The solo devs who fail almost always fail on *scope*, not talent.
- **Successful solo games share a formula:** ONE core mechanic that's immediately fun, wrapped in
  just enough content. No complex narrative, no realistic graphics, no huge systems.
- **Timelines are long.** A first shipped game is typically 3–18 months; most solo successes are
  1–2 years *part-time alongside a day job*. Stardew Valley was 4.5 years at 10 hrs/day (the
  exception, not the rule).
- **The money is sobering.** ~55% of indie devs work solo; ~70% never profit. The *median* indie
  game on Steam earned ~$249 in 2025. (Outliers exist, but they're outliers.)
- **Engine choice barely matters.** Unity vs Godot vs Unreal won't make or break you — scope and
  marketing will. (Godot 4 is free and we already have a project in it.)
- **Buy/license to fill gaps.** Use asset packs (Kenney.nl is free CC0), engine templates, and
  paid models so you can spend your time on the *core mechanic and polish*, not building every
  asset from zero. (This is what your Sketchfab GLBs were gesturing at — legit strategy, just mind
  licenses for release.)
- **Version control from day one.** Git is non-negotiable; solo devs lose work constantly.

---

## What this means for THIS project (honest scoping)

Three realistic paths, smallest to largest:

1. **Learn one skill on a tiny scope.** Not "remake G-Nome" — *"make one mech feel good to drive
   on an empty plane."* Achievable in an afternoon-to-a-weekend. Builds the #1 skill (game feel).
   Best starting point.
2. **Assemble, don't build.** Use bought/free assets + an engine template to make ONE small,
   polished arena with ONE mechanic that's fun. Sidesteps the art/animation skill gap.
3. **Full reimagining.** Requires a team (or years solo) across the whole stack above. Not a
   solo-afternoon thing — this is the scale the original studio operated at.

**What we already have that's reusable** (so it's not starting from zero):
- Original soundtrack + cinematics (skill #7, largely covered)
- Complete game bible / GDD / campaign outline (skills #6, #9, design, covered on paper)
- A working Godot project + engine pipeline (skill #1 scaffolding)

The missing, hard-to-fake skills are **#2 game feel, #3–5 art/animation** — the production crafts.

---

## Recommended starting path (if you want to build the skill, not just read about it)
1. **Pick Godot 4** (free, installed, project exists). Engine choice isn't the bottleneck.
2. **Do one structured course** in order (Godot docs → a GDQuest / Brackeys-style series) rather
   than ad-hoc help — fundamentals taught in sequence beat random tutorials.
3. **First milestone = game feel, not content:** one controllable thing that feels *good*.
4. **Use Git from day one. Keep scope brutally small. Finish small things.**

> Bottom line: making a game is a stack of ~12 separate deep skills. A designer can do the *vision*
> solo; *building* it is a team-scale production. The viable solo path is the opposite of what we
> tried here — extreme depth on one tiny thing, not breadth across a whole game.

---

### Sources
- Indie team roles / mech-game disciplines — NYFA, Cominted Labs, Beamable, FutureLearn, Techneeds
- Solo dev skills, scope, timelines, finances (2025) — Ziva, Hacker News, Medium (Rego; Mouillard),
  The Game Marketer, ScreenRant
