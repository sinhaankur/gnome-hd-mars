# Game Requirements — the master manifest (find → use → rebuild)

> **Everything the game requires**, in one list. This is the tracker for our two-stage pipeline:
>
> **Stage 1 — FIND**: pull a good CC0/CC-BY asset (Sketchfab first, then other CC libraries) to
> get the game looking and playing right *now*.
> **Stage 2 — REBUILD**: eventually rebuild each one in Blender so the whole game is **custom-built
> and 100% ours** (© Ankur Sinha, MIT). Pulled assets are placeholders/reference until then.
>
> **License rule:** prefer **CC0** (no strings, becomes fully ours); allow **CC-BY** when nothing
> good is CC0 (must stay credited in `CREDITS.md` until rebuilt). **Block** NC / ND / paid.
>
> Pipeline: `tools/sketchfab_search.py` → `sketchfab_download.py` → `normalize_*.py` → GLB into
> `godot/assets/` → verify vs NASA photos via `godot-art-pass`. Blender add-on also installed (5.1).
>
> Status per row: **FIND** = need to source · **HAVE(placeholder)** = pulled, works, not ours ·
> **REBUILD** = being custom-built in Blender · **DONE(ours)** = original, shippable.

Legend: 🟢 DONE(ours) · 🟡 HAVE(placeholder) · 🔵 FIND · 🟠 REBUILD-in-progress

---

## 1 · Player / Hero

| Item | Purpose | State | Find plan (CC0>CC-BY) | Rebuild target |
|------|---------|-------|-----------------------|----------------|
| **Hero HAWC** (Union Sentry — Prowler) | the mech you pilot; most-seen asset | 🟢 hero_striker.glb (SHIPPED Aug27 — MSGDI Striker, rigged, 41 anims, 10.8k tris, union-tinted) | — | Blender hard-surface, 4K PBR, auto-eject hatch (long-term) |
| **Pilot (Union)** | persistent entity; eject/on-foot/hijack | 🟡 pilot_trooper.glb (SHIPPED Aug27 — ART_LOLL trooper, upright, 512px textures) | rigged version for walk anims | Blender character + rig |
| **PRIF44 rifle** | on-foot weapon | 🔵 FIND | "sci-fi rifle" (brief: design/HAWK_rifle_brief.md) | Blender hard-surface |
| **GASHR launcher** | eject/steal tool (5 canisters) | 🔵 FIND | "grenade launcher sci-fi" | Blender |

---

## 2 · HAWC / vehicle roster (20 units — 5 classes × 4 factions)

Build **one great base per class silhouette**, faction = tint (Union tan / Darken grey / Merc blue /
Scorp green). See `design/HAWC_VARIETY_SPEC.md`. Specs from `reference/GAME_BIBLE.md`.

| Class silhouette | Roster (faction) | State | Find plan | Rebuild |
|------------------|------------------|-------|-----------|---------|
| **A · Sentry** compact biped | Prowler(U) Talon(D) Ogre(M) Jinx(S) | 🟡 enemy_sentry.glb | "bipedal mech" | Blender base + tints |
| **B · Tactical** taller biped | Rampage(U) Stalker(D) Minotaur(M) Predator(S) | 🟡 enemy_tactical.glb | "assault mech" | Blender base + tints |
| **C · Heavy** 4–6-leg multipedal | Lion(U,4-leg) WidowMaker(M) Venom(M) Scorpion(S,6-leg) | 🟡 enemy_heavy.glb (Arachnid-Z4 spider tank — REBUILT Aug27) | — | Blender base + tints |
| **D · Support** tracked hull+turret | Titan(U) Boulder(D) Legionnaire(M) Stinger(S) | 🟡 enemy_support.glb | "sci-fi tank", "MBT" | Blender base + tints |
| **E · Hover** arrowhead on skirt | Rapier(U) Vulture(D) Razor(M) Wasp(S) | 🟡 enemy_hover.glb (Stormbringer hover tank — REBUILT Aug27, was broken sliver) | — | Blender base + tints |
| **Infantry** (4 faction tints) | Union/Darken/Merc/Scorp soldiers | 🟡 pilot_trooper.glb (shipped, static) | "sci-fi soldier" rigged | Blender base + tints |

---

## 3 · Ships & orbital / delivery

| Item | Purpose | State | Find plan | Rebuild |
|------|---------|-------|-----------|---------|
| **Mothership** (interplanetary carrier) | orbital arrival cinematic | 🟡 built via tools/build_ships.py | "spaceship capital", "carrier" | Blender |
| **Sub-ship / drop-ship** (detaches, descends) | carries HAWC down | 🟡 subship.glb | "dropship", "landing craft" | Blender |
| **HAWC drop pod / capsule** | the descent capsule | 🟡 hawc_pod.glb | "drop pod sci-fi" | Blender |
| **Ground dropship** | lands at mission (bay doors TODO) | 🟢 dropship.glb | — | add bay-door anim |
| **Vehicle Delivery System** | enemy reinforcement spawner (bible structure) | 🔵 FIND | "sci-fi hangar", "vehicle bay" | Blender |

---

## 4 · Stations / structures / bases (destructible)

Modular kit first (walls/pillars/doors/panels), then assemble named buildings. From bible §Structures.

| Item | State | Find plan | Rebuild |
|------|-------|-----------|---------|
| **Installation / HQ** (what you defend) | 🟡 installation.glb | "sci-fi base", "outpost" | Blender modular |
| **Modular base kit** (wall/pillar/door/panel/antenna) | 🔵 FIND | "sci-fi modular kit" (Kenney CC0!) | Blender kit |
| Meson Tower | 🔵 FIND | "sci-fi tower" | Blender |
| Shield Generator | 🔵 FIND | "shield generator" | Blender |
| Electro-chemical Power Plant | 🔵 FIND | "power plant sci-fi" | Blender |
| Rocket Towers (CHUM/UNKPA) | 🔵 FIND | "missile turret" | Blender |
| Sweep / Pop-Up Turret | 🔵 FIND | "auto turret sci-fi" | Blender |
| Comms / LATLON Array | 🔵 FIND | "radar dish", "comms array" | Blender |
| Bridge + Bridge Control | 🔵 FIND | "sci-fi bridge" | Blender |
| Silo / Elevator / Mine Field Control | 🔵 FIND | "sci-fi silo" | Blender |
| **The Citadel** (campaign finale) | 🔵 FIND | (hero build — likely custom) | Blender |
| **Mars city / settlement** (bigger base env) | 🔵 FIND | modular kit (Kenney CC0) + geo-nodes layout: domes, habitats, roads, landing pads, towers | Blender modular + scatter |

---

## 5 · World / environment elements (Phase 2 — "rocks, air, wind, climate")

| Element | Purpose | State | Find plan | Rebuild |
|---------|---------|-------|-----------|---------|
| **Walkable terrain** (HiRISE) | the ground you drive on | 🟢 real ~1m/px | — | keep / extend regions |
| **Mars globe** | strategic map | 🟢 NASA Viking | — | keep |
| **Rocks / boulders** | scatter, cover, landmarks | 🟡 mars_rock_1..4 | "mars rocks", "boulders scan" (CC0 scans) | Blender sculpt set |
| **Regolith / ground textures** | terrain skin | 🟢 scanned (Pers Scans) | — | Blender/Substance later |
| **Dust & sand drifts** | ground dressing | 🟡 dust_cc0 | Kenney CC0 | Blender/geo-nodes scatter |
| **Wind / dust devils** | motion, atmosphere | 🔵 FIND (mostly shader/particle) | particle refs | Godot particles + Blender meshes |
| **Atmosphere / haze / climate** | sky color, fog, horizon | 🟢 calibrated to NASA | — | tune per-region |
| **Sky / sun / day-night** | lighting driver | 🟢 mars_sun.gd | — | keep |
| **Clouds** | rare high-altitude wisps | 🟡 cloud_cc0 | Kenney CC0 | Blender/vol |
| **Craters / dunes / relief props** | terrain variety | 🔵 FIND | "crater", "sand dune" | Blender / geo-nodes |

---

## 6 · POIs / props / set dressing

| Item | State | Find plan | Rebuild |
|------|-------|-----------|---------|
| NASA rover (derelict POI) | 🟢 real NASA model | — | keep (credited) |
| Supply crate / cache | 🟡 mars_crate | "supply crate" (many CC0) | Blender |
| Monolith / anomaly | 🟡 mars_monolith (9MB, oversized) | — | Blender lean rebuild |
| Flags / markers / beacons | 🟡 flag_cc0 | Kenney CC0 | Blender |
| Wreckage / debris | 🟡 imported/wreck, debris | "sci-fi wreck" | Blender |
| Antennas / pipes / barrels / containers | 🔵 FIND | Kenney "sci-fi props" CC0 | Blender kit |

---

## 7 · Weapons & FX (mostly shader/particle, minimal geo)

| Item | State | Notes |
|------|-------|-------|
| HAWC weapons (lasers/cannons/missiles/rockets/ion/plasma) | 🔵 FIND / procedural | mount points on mechs; FLECH/FIL30/CHUM/RAID/zWASP families from bible |
| Projectiles / laser bolt | 🟢 laser.tscn | verify look |
| Muzzle flash / impact / explosion / smoke | 🟢 procedural | verify in art-pass |
| Shield hit / eject blast / thruster glow | 🟡 partial | Godot shader/particles |

---

## 8 · UI / HUD / 2D (not Blender — noted for completeness)

| Item | State | Notes |
|------|-------|-------|
| Logo / brand | 🟢 logo.png (MARS HAWC) | done |
| HUD (health/shield/radar/ammo) | 🟢 in-game | diegetic cockpit is the upgrade target (GDD) |
| Menus / mission select / globe UI | 🟢 working | polish pass later |
| Icons / markers / faction crests | 🔵 FIND / make | Kenney UI packs CC0 |

---

## Find order (do this first — "first we will find assets")

1. **Hero HAWC** candidates (§1) — biggest impact.
2. **5 class-silhouette mechs** (§2) — better than current borrowed set if we can.
3. **Ships + pilot + infantry** (§1/§3) — completes the arrival + possession loop.
4. **Modular base kit + key structures** (§4) — Kenney CC0 is gold here.
5. **World elements** (§5) — rocks/dust/hazards for Phase 2.
6. **Props & POIs** (§6), then **weapons/FX** (§7).

> For each pull: log it in `CREDITS.md` immediately (author + link + license), drop the GLB in
> `godot/assets/`, verify in-engine. Rebuild-in-Blender happens per-item later; when an original
> replaces a pull, remove that CREDITS entry.
