# Mars HAWC — How everything should look (research + ideas)

Written because "the landing ship looks shit," the 3rd-person camera is wrong, and the bar is
**"Star Wars and space games already have better design."** This grounds each element in real
references so we build to a target, not by guess. Sources at the bottom.

---

## 1. The descent / landing ship  ← the loudest problem

**Why the current one fails:** it's a plain cylinder with engine nozzles and spindly legs. No
heat shield read, no cargo bay read, no silhouette. A barrel.

**How real Mars landers actually look** (sources below):
- A **broad rounded heat shield** on the windward face — the single most iconic read.
- An **aeroshell / backshell** wrapping the lander; legs + cargo folded *inside* during entry.
- Final touchdown on **retro-rockets + deployed landing legs** (4 or 6), slow and planted.
- SpaceX Starship reimagines it as a **tall sleek stainless vessel** with **aero flaps** and a
  **dark hexagonal tile heat-shield** on the windward side — a much stronger silhouette than a tube.

**The "better design" bar (Star Wars / sci-fi game language):** great sci-fi ships read because
of **asymmetry, greeble density, a clear front/back, panel-line breakup, and a hero feature**
(a cockpit, a big engine, a cargo maw). Think the *UT-60D dropship*, the *AT-OT / landing barges*,
Halo *Pelican*, Titanfall drop-pods. Not a smooth cylinder.

**IDEAS for our descent ship (pick a direction):**
- **A) Dropship, not a capsule.** A chunky angular troop/mech dropship: flat wide heat-shield
  belly (hex tiles), an open rear cargo maw the HAWC walks out of, 4 splayed landing legs, twin
  engine clusters, stub wings with flaps, a lit cockpit at the nose. Silhouette reads from any angle.
- **B) Starship-lander hybrid.** Tall, leaning, stainless, hex-tile windward face, flaps, Raptor-style
  engine cluster at the base, lands on legs. More "epic," less "troop transport."
- **C) Aeroshell-that-opens.** Starts as a classic heat-shield capsule (great entry-burn read),
  then the shell splits/petals open on the surface to reveal the mech — a reveal moment.

Recommendation: **A (angular dropship)** — it best serves "the HAWC walks out," gives a strong
silhouette, and matches the gritty-military tone of the G-NOME pillars.

---

## 2. The 3rd-person mech camera  ← the "doesn't have correct 3rd person view" problem

**Why it looks wrong now** (`godot/scripts/follow_camera.gd`): the rig is well-built (spring arm,
modes, shake) but the **defaults are tuned flat**: `distance 12`, `height 6`, `look_height 4.5` on a
~7 m mech put the camera level with the mech's middle, far back and dead-centre → the mech reads
small and low over lots of ground, and (centred) its bulk covers the reticle.

**What great mech games do** (Armored Core, MechWarrior, Titanfall; camera research below):
- **Anchor to a target node at shoulder/cockpit height, not the feet.**
- **Camera slightly *above* the anchor, looking slightly *down*** over the mech.
- **Offset to one shoulder** so the mech's bulk never covers the reticle (the exact MechWarrior-5
  centred-cam failure).
- **Two blended framings:** a wider *traversal/follow* and a closer, narrower-FOV *aim* (distance
  pulls in hard, ~3.0 → ~1.2 in boom units).
- **Damp only the arm length**, keep rotation responsive, lock the reticle to the true aim vector.
- Tune order: **distance → lateral offset → facing.**

**Concrete fix (numbers to try):** on a ~7 m HAWC — `height ≈ 8–9` (just above the shoulders),
`distance ≈ 9–10`, `look_height ≈ 7` (look slightly down), add a **shoulder offset ≈ 1.5–2.0 m**
to one side, and an **aim state** that drops to `distance ≈ 6`, `fov −12`, offset tighter.

---

## 3. The HAWC mech

**Decision (from the user): the in-game HAWC is the one they like — use it everywhere.** So:
the game keeps `hero_striker.glb`; the web cinematic should deploy the *same* mech for consistency
(the HAWC you watch land is the HAWC you pilot). Drop the separate custom cinematic mech.
Quality direction for whichever we keep: panel-line breakup, worn metal edges, faction-colour
paint with grime — baked to texture so it ships in the asset (Star-Wars-ship level of surface story).

---

## 4. The Mars surface (already researched, for reference)

Butterscotch/tan regolith (red is a mm-thin dust veneer over dark basalt), megaripples, dust
devils, RSL slope streaks, rock scatter. Judge against `reference/real_mars/`. Keep going toward
the discovery-based "ecosystem" (see project-mars-surface-ecosystem).

---

## Sources
- Mars landers / EDL / Starship: NASA "How do you land on Mars," InSight/Mars-2020 EDL hardware,
  Aerospace America on SpaceX Starship (hex tiles, flaps, stainless, propulsive landing on legs).
- 3rd-person mech camera: Unity Cinemachine Third-Person Follow, Unreal spring-arm guides,
  MechWarrior 5 camera mods (centred-cam covers reticle → use shoulder offset), Armored Core.
