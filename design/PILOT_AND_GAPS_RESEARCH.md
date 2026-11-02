# Pilot / Suit Research + "What's Missing" Gap List

> User (2026-11-02): *"the human and suit are bad"* → *"research this first"* → *"there are a lot
> of things missing."* So: (1) research proper rigged pilot/suit options, (2) lay out the gaps.

---

## Part 1 · Why the pilot/suit is bad (root cause, verified)

Both human models in the repo are **dead ends for an animated pilot**:

| Model | skins | anims | materials | Verdict |
|-------|-------|-------|-----------|---------|
| `pilot_trooper.glb` | **0** | **0** | 6 | static prop — can NEVER walk; rendered as a flat-white T-pose |
| `astronaut_fallen.glb` | **0** | **0** | 2 | a corpse POI (meant to lie on the ground) — not a playable body |

The current in-game pilot is the **procedural primitive soldier** (capsule body + sphere head +
box visor) I swapped in to kill the white mannequin. It's *legible* but **crude** — the user is
right that it reads as "bad." We need a real rigged humanoid with a walk/run/idle cycle.

---

## Part 2 · The fix — recommended pilot asset (CC0, rigged, animated)

Research (web, Nov 2026) converges on **one clear answer**:

### ★ Recommended: Quaternius — Universal Base Characters + Universal Animation Library
- **Universal Animation Library** (CC0, Mar 2025): **120+ animations** on a universal humanoid rig —
  8-direction locomotion, jog, sprint, crouch, gun/combat, death. **Tested in Godot** (ships a
  Godot-exported version + the source .blend). This is exactly the walk/idle/run set the pilot needs.
- **Universal Base Characters / Modular Character Outfits** (CC0): the body + outfit pieces to dress
  it as a Union trooper (helmet, chestplate, pack).
- **License: CC0** — no attribution, becomes fully ours. Fits the find→rebuild pipeline.
- **Why it wins:** one rig → all our humans (pilot + 4 faction infantry) retarget from the same
  animation set. Solves the pilot AND the infantry roster in one source.

### Alternatives (if we want an astronaut look specifically)
- **Grab3D** (CC0, no login): a ready-made **sci-fi soldier in white armor w/ cyan visor**, 24 rigged
  characters, plus a browser **auto-rig** tool (rig our own humanoid in seconds → GLB). Great backup.
- **Quaternius Ultimate Space Kit** (CC0, ~90 models): includes **animated astronauts** — on-theme
  for Mars, if we want a spacesuit silhouette over a soldier.
- **Gobkit Free Character Pack** (CC0): 8 rigged chars, named Idle/Walk/Run/Death/Hit/Attack clips,
  single atlas — lightest-weight option, lower fidelity.
- **itch.io "Rigged Low Poly Astronaut"** (CC0): humanoid skeleton + skin weights.

### The build step (next session, via `mars-hawc-asset-sourcing` skill)
1. Pull Quaternius Soldier/Base Character + Universal Animation Library (CC0).
2. Normalize to our contract: Y-up, −Z forward, feet at Y=0, ~1.85 m real height.
3. Wire in `pilot.gd` via an AnimationPlayer: idle when still, walk/run by speed (the
   `MechAnimator` pattern already does this for mechs — reuse it).
4. Tint per faction (Union tan) with the existing `Faction` shader.
5. AABB-verify in Godot (re-exports lose normalization — a known lesson).

> Until then the procedural soldier stays (it's not broken, just plain). The swap is a sourcing
> task, not a code fix.

---

## Part 3 · "A lot of things missing" — the gap list

From `design/GAME_REQUIREMENTS.md` (🔵 = not yet sourced). Grouped by impact:

### People & on-foot kit (the gap the user is feeling right now)
- 🔵 **Rigged pilot** (Part 2 above) — the human, done right
- 🔵 **Faction infantry** ×4 (same Quaternius rig, re-tinted)
- 🔵 **PRIF44 rifle** (on-foot weapon; brief exists: `design/HAWK_rifle_brief.md`)
- 🔵 **GASHR launcher** (the eject/steal tool — core to the possession loop)

### Structures / base / city (big "world feels empty" gap)
- 🔵 **Modular base kit** — **Quaternius Modular Sci-Fi MegaKit (CC0, 270+, Godot-ready)** solves
  most of these at once (walls/doors/panels/towers)
- 🔵 Meson Tower · Shield Generator · Power Plant · Rocket Towers · Turrets · Comms Array · Bridge ·
  Silo · **The Citadel** (finale) · **Mars city/settlement**

### World / atmosphere
- 🔵 **Dust devils / wind** (shader+particle) · **craters / dunes / relief props**

### Weapons & FX
- 🔵 **HAWC weapon families** (lasers/cannons/missiles/ion/plasma — mount points exist) —
  **Quaternius Sci-Fi Modular Gun Pack (CC0, ~80 parts)**

### Props & UI
- 🔵 Antennas / pipes / barrels / containers — **Kenney Sci-Fi props (CC0)**
- 🔵 Faction crests / markers / icons — **Kenney UI packs (CC0)**

---

## Priority recommendation

The thing the user is *looking at* and calling bad is the **human on foot**, so do that first:

1. **Pilot** — pull the Quaternius rig + animation library → real walking Union trooper. (biggest felt win)
2. **Infantry ×4** — same rig, faction tints. (fills the world with people)
3. **Base/city kit** — Quaternius MegaKit → the installation + a Mars settlement. (fills the empty world)
4. **On-foot weapons** (rifle + GASHR) — completes the possession-loop fantasy.

All CC0, all from 2–3 sources, all sourced the same way — fast, library-first, licensing-safe.

---

## Sources
- [Quaternius — Universal Animation Library (CC0)](https://quaternius.com/packs/universalanimationlibrary.html)
- [Quaternius (CC0 packs: Base Characters, Space Kit, MegaKit, Gun Pack)](https://quaternius.com/)
- [Grab3D — CC0 rigged sci-fi soldier + auto-rig tool](https://grab3d.com/)
- [Gobkit Free Character Pack (CC0, named walk clips)](https://gobkit.itch.io/gobkit-free-character-pack-vol-1)
- [OpenGameArt — CC0 3D Humans/Players](https://opengameart.org/content/cc0-3d-humans-players)
- [Kenney (CC0 props/UI/audio)](https://kenney.nl/)
