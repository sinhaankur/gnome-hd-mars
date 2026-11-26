# Mars HAWC — browser edition

The three.js (0.160) browser build of Mars HAWC, successor to G-NOME (7th Level,
1997). The Godot edition lives in this same repo under `godot/`; this is the
web edition.

- **Entry:** `Mars HAWC.dc.html` — open in a browser (served, for module loads).
- **Engine:** `hawc/*.js` (~28 modules: anatomy, armor, atmos, audio, base,
  campaign, …).
- **Design system:** `_ds/`.
- **Design docs:** `design/*.dc.html` — Steam Production Plan, Asset & Skills
  Bible, Icon Library, Research, Section Audit.
- **Assets:** `assets/` (pilot + terrain + textures). The shared mech/enemy GLBs
  (hero_striker, enemy_*, dropship, mars_*) are NOT duplicated here — they live
  in `../godot/assets/` (identical geometry).

Added 2026-11-26 from the "Mars HAWC mech game" drop; the 323 MB of raw
source-texture scratch + duplicate GLBs from that drop were intentionally left
out to keep the repo clean.
