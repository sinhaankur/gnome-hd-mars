# World Elements — Phase 2 breakdown ("rocks, air, wind, climate")

> Break the Mars world into art-directed **elements** and build each one properly, verified
> against real NASA Mars photos (`godot-art-pass`). This is the Phase-2 checklist. Grounded in
> what `godot/scripts/environment_engine.gd` + `mars_terrain.gd` + `mars_sun.gd` already do.
>
> Guiding bar: **real, not sloppy** — every element judged only vs NASA rover/orbiter imagery.
> Method per element: reference photo → current state → concrete build step → verify in-engine.

Status: 🟢 good · 🟡 exists, needs work · 🔵 to build · 🟠 in progress

---

## A · Ground / terrain

| Element | Current | State | Phase-2 build step |
|---------|---------|-------|--------------------|
| **Walkable terrain mesh** | real HiRISE ~1m/px, MarsTerrain.make | 🟢 | keep; add more regions for mission variety |
| **Regolith skin** | scanned ground textures (Pers Scans) tinted to palette | 🟢 | per-region palette variants (Gale/Jezero/Candor tones) |
| **Terrain shader** | low/mid/high/slope palette blend | 🟡 | add micro-normal detail + subtle specular for wet-look rocks after dawn |
| **Craters / relief** | from the HiRISE DTM | 🟡 | scatter a few sharp bowl craters as set-pieces (Blender geo-nodes) |
| **Dunes / ripples** | flat-ish regions | 🔵 | build aeolian ripple fields (real Mars has km of them) — displacement or geo-nodes |
| **Slopes / talus** | terrain only | 🔵 | scatter rock talus on steep slopes (use slope_at) |

## B · Rocks & debris (scatter)

| Element | Current | State | Phase-2 build step |
|---------|---------|-------|--------------------|
| **Landmark boulders** | mars_rock_1..4 (real scans), _scatter_rocks | 🟢 | more size variety; a hero outcrop per region |
| **Pebble field** | _scatter_detail | 🟡 | denser near-camera pebbles via geo-nodes instancing (perf-safe) |
| **Half-buried wreckage** | imported/wreck, debris | 🟡 | a few story-flavored wrecks (crashed lander, old HAWC) as POIs |
| **Vein / stratified rock** | — | 🔵 | Blender-sculpted layered outcrops (Candor Chasma look) |

## C · Air / dust / wind (the "air, winds" you flagged)

| Element | Current | State | Phase-2 build step |
|---------|---------|-------|--------------------|
| **Blowing ground dust** | _build_wind_dust, follows camera | 🟡 | tune density/opacity to NASA (thin, tan, low); wind DIRECTION from a global var |
| **Dust devils** | — | 🔵 | signature Mars feature: a moving column particle system + faint shadow; rare spawn |
| **Wind gusts** | none (dust is constant) | 🔵 | a global wind vector that varies over time; drives dust + banner/flag sway |
| **Saltation (sand skipping)** | — | 🔵 | low near-ground particle burst behind the mech's feet (already have foot dust) |
| **Dust kicked by mechs** | mech_animator foot dust | 🟢 | scale with mass/speed; heavier mechs = bigger plumes |
| **Suspended haze** | fog | 🟡 | height-based haze; thicker at horizon (aerial perspective) — key to "vast" feel |

## D · Sky / atmosphere / climate

| Element | Current | State | Phase-2 build step |
|---------|---------|-------|--------------------|
| **Sky color** | _build_sky_and_sun | 🟡 | butterscotch daytime, blue-tinted near sun (real Mars is the inverse of Earth) — verify vs NASA |
| **Sun disk + light** | MarsSun day cycle drives all lighting | 🟢 | smaller, dimmer sun disk (Mars is 1.5 AU); slightly blue sunset glow |
| **Day/night cycle** | mars_sun.gd | 🟢 | keep; expose time-of-day to missions (dawn raids, night defense) |
| **Clouds** | thin ice cirrus, drift | 🟢 | keep faint; never Earth cumulus (noted in code) |
| **Horizon / atmosphere depth** | fog | 🟡 | calibrated aerial perspective so distant terrain fades tan — sells scale |
| **Weather states (climate)** | none | 🔵 | 3 presets: clear / dusty / dust-storm (lowers visibility + reddens light). Data-driven per mission. |
| **Global dust storm** | — | 🔵 | dramatic mission modifier: heavy haze, orange-out, reduced sun — a real Mars event |

## E · Light / time-of-day FX

| Element | Current | State | Phase-2 build step |
|---------|---------|-------|--------------------|
| **Shadows** | directional from sun | 🟢 | keep 4096 soft shadows (protected in project.godot) |
| **Ambient / GI** | sky ambient | 🟡 | warmer bounce off the regolith (Mars ground reflects orange up onto mechs) |
| **Dawn/dusk grade** | sun color ramp | 🟡 | stronger long-shadow golden hour; blue twilight |
| **Night** | dim | 🟡 | starfield + 2 moons (Phobos/Deimos) for authenticity; mech running lights |

## F · Hazards / interactive world

| Element | Current | State | Phase-2 build step |
|---------|---------|-------|--------------------|
| **Steep-slope / fall** | terrain collision | 🟡 | damage/slowdown on extreme slopes |
| **Dust-storm visibility** | — | 🔵 | tie to weather state (D) |
| **Craters as cover** | — | 🔵 | gameplay: use crater rims as cover in encounter design |
| **Destructible props** | — | 🔵 | rocks/wrecks that shatter under fire (later; ties to structures phase) |

---

## Build order (payoff-first, Phase 2)

1. **Atmosphere calibration** (D: sky color, haze, horizon) — biggest "feels like Mars" win, no new assets.
2. **Dust polish** (C: wind direction, density, mech plumes scale) — cheap, high immersion.
3. **Dust devils + weather states** (C/D) — signature Mars features; particle + global-var work.
4. **Rock/dune density** (A/B: ripples, talus, denser pebbles via geo-nodes) — fills the empty plains.
5. **Night/moons + golden hour** (E) — variety and beauty.
6. **Hazards** (F) — gameplay depth; comes with encounter design.

> Most of Phase 2 is **shader + particle + global-variable** work (env engine), not new GLBs —
> which is exactly what Godot + Blender geo-nodes are good at. New meshes only for craters,
> dunes, veined outcrops, and story wrecks. Verify every step with `godot-art-pass` vs NASA photos.
