---
name: godot-art-pass
description: Run the reference-vs-game visual loop for the G-NOME HD Mars game — capture in-game screenshots, compare them against real NASA Mars photos, and fix visual slop in payoff order. Use when the game "looks wrong/sloppy", after art changes, or before showing a build.
---

# Godot Art Pass — the de-slop loop

The game is judged against REAL photos, never against taste. Ground truth lives in
`reference/real_mars/` (Perseverance Mastcam-Z panoramas, public domain NASA/JPL).

## The loop

1. **Shoot the game** (self-terminating, ~35 s, saves 10 frames to `reference/shots/`):
   ```sh
   cd godot && DEV_SHOTS=1 godot --path . scenes/mission1.tscn
   ```
   The `DevShot` autoload (`scripts/dev_shot.gd`) only runs with `DEV_SHOTS=1`;
   normal play is never interrupted.
2. **Compare** shots side-by-side with `reference/real_mars/*.jpg`. Read both as images.
3. **Fix in payoff order** (cheapest, biggest visual win first):
   lighting/atmosphere → terrain material → scatter/props → hero mech → FX.
4. **Re-shoot and re-compare.** A change that can't be seen in the shots didn't happen.

## Real-Mars checklist (from the reference photos)

- Sky is **butterscotch-grey**, brighter peach-tan at the horizon. NEVER blue, never black in daytime.
- **No cumulus clouds.** The sky is bare; at most thin wisps.
- Light is **soft and diffuse** — dust scatters light into shadows, so shadow sides stay readable. High ambient, gentle SSAO.
- Terrain is **caramel/butterscotch, low saturation** — not maroon, not lava-red. Rocks are grey-brown basalt dusted tan.
- **Strong aerial perspective**: relief a few km out washes toward the sky color (dense tan fog).
- Ground is **littered with small rocks and pebbles** everywhere.
- Martian **twilight is blue-grey** around the sun — the reverse of Earth. No salmon sunsets.

## Where the knobs live

- `scripts/environment_engine.gd` — sky material, fog, glow, fill light, rock/pebble/mesa palettes, horizon ring. Owns the world; passive and authoritative.
- `scripts/mars_sun.gd` — day-cycle palette (SKY_/FOG_ constants), sun color/energy, ambient over the day.
- `scripts/mars_terrain.gd` — terrain shader colors (low/mid/high/slope uniforms) on real HiRISE geometry.

## Layered architecture (planet → ground)

Real data flows up through layers; each layer only talks to the one below:

1. **Reality layer** — HiRISE DTMs (`tools/hirise_regions.py` → `assets/mars_*.png`), NASA photo palette (`reference/real_mars/`), global Mars maps (MOLA in `assets/_mola_backup/`, NASA global color mosaics).
2. **Asset layer** — GLB models in `godot/assets/` (see the `blender-asset` skill).
3. **Engine layer** — EnvironmentEngine (world), HAWC (player), EnemyEngine (story/waves). Engines answer queries and emit signals; they don't know about each other's internals.
4. **Game layer** — thin mission scripts compose engines; Campaign autoload drives level data AND territory state.
5. **Planet layer** — the real Mars globe as the strategic map: factions hold territories on the actual planet; picking a contested region launches its HiRISE ground mission. This is what the war is *for*.

North star: **GTA-like** — a freely roamable open Mars with missions layered on top.
Keep levels thin; put behavior in engines, data in Campaign.

## Detail bar

Every element gets its own detail pass judged against references — soil, clouds,
rocks, mech, installation, FX, HUD. "Good enough at a distance" is not done;
walk the mech up close during the shot run and check there too. Exploration
content must be physical and diegetic (landmarks you can see and walk to),
never floating emissive markers.
