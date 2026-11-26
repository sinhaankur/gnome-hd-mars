# Mars HAWC — studio rules (browser edition)

This project is the browser edition of Mars HAWC, a third-person mech game on the real Martian surface and a successor to G-NOME (7th Level, 1997). The Godot game lives in the GitHub repo sinhaankur/gnome-hd-mars. Copyright sinhaankur.
Entry point: `Mars HAWC.dc.html`. Engine code: `hawc/*.js` (three.js 0.160). Assets: `assets/`.

## Core fantasy (never dilute)
"Your power doesn't come from one unbreakable machine. It comes from your willingness to abandon it."
The whole game is the hijack loop: eject, HAWK an enemy HAWC, force its pilot out, steal the intact hull. It is asset theft, not attrition. There are 4 vehicle classes (bipedal HAWC, tank, hovercraft, walker) and the factions are asymmetric. The tone is grim, grounded hard sci-fi. Never cute, clean, candy or primitive.

## Loop: PLAN → DEFINE → BUILD → VERIFY → JUDGE → SHIP
Finish ONE thing to quality before starting the next. Each piece goes through these roles:
- **Producer.** Pick the highest-value next piece and track it to done.
- **Creative director.** Is this the right thing, and does it serve the core fantasy and the story? Ground the fiction in real references.
- **Storyboard.** Sketch sequences before building them, using real shot grammar (EST/FULL/OS/LOW/HIGH/CU/POV).
- **Asset artist / technical artist.** Use real metres, feet at y=0, facing +Z after `getTemplate` normalisation. Calibrate lighting rather than eyeballing it, and check normals before blaming the light.
- **Engineer.** Keep these apart: the pilot as a persistent entity, component damage, capture-not-kill.
- **Level designer.** The arc runs dominance → catastrophe → gamble → reversal. Get Level 1 right before scaling up.
- **Art director + critic.** Screenshot every changed frame and judge it against real Mars photos (Perseverance and Curiosity colour, butterscotch sky). Give the verdict first. "Looks fine" is not a pass.
- **QA.** No console errors, the mission boots, test files are deleted (`hawc/_s`, `_shots`, `_test.js`), and ready_for_verification passes.

## Rules
- Score every build. Each report opens with a scorecard: 1-10 for silhouette/form, materials and Mars light, motion, gameplay readability and UI, plus an overall score and the one thing that would raise it most. Be strict: 7 means it holds up as a still, 9 means shippable.
- Real-not-sloppy. Every screen and every frame has to hold up as a still image.
- Repo-first: check what already exists (here and in the GitHub repo) before building something new. Library-first: reach for a proven library before writing a lot of custom code.
- Clean up after every piece of work.
- Mars logic stays consistent:
  - Everything runs on methalox fuel cells. Ice + CO2 go through the Sabatier process and electrolysis to make methane and oxygen.
  - Stations make cells according to their ice: shallow glaciers toward the poles, deep ice near the equator.
  - Bases have a Kilopower-class reactor, solar blankets, a propellant plant, an ice pit, a cell dock and a Starship-class tanker.
  - Real agencies hold their real landing sites, and the heritage probes stand there at true scale.
  - All people are fictional. No real individuals (Starfall's leader is "The Founder").
- Real data only, credited: MOLA heights (`hawc/mola.json`, from the upload's DEM), HiRISE-style terrain, Viking colour.

## Asset manifest targets (from the repo)
- hero_striker (rigged, 41 clips, ~7 m)
- pilot_human (1.9 m, rigged)
- five distinct enemy silhouettes: sentry, tactical, heavy spider tank, hover, support (≤30k tris each)
- subship: a vertical Starship-style lander with a ring-banded stainless hull, flaps, hex heat shield and 6 legs
- mg01_orbital_station
- mars_rock_1..4
- nasa_rover
- shuttle_wreck and astronaut_fallen
- mars_monolith
- terrain: HiRISE heightmaps, MOLA, photoreal albedo and normals, plus a higher-resolution globe than 2048×1024
