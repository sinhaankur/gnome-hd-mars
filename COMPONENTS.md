# Mars HAWC — Component List (what it needs to be good)

Grounded in the real current state (saw Level 1 in-game): strong *tech* underneath
(real HiRISE terrain data, a measured Perseverance-calibrated Mars shader, 64 scripts,
72 models, full GDD + campaign) — but the **presentation reads as an early prototype**:
flat pale ground, a blank white pilot, flat lighting. These are the components to fix.

Split: **You** = station + ship design (Blender). **Me** = Mars/surface + code/presentation.

## A. MARS SURFACE (my focus — "improve Mars and its surface")
- [ ] **FIX: terrain looks flat & pale in-game** — the HiRISE displacement + measured
      shader exist but aren't reading in Level 1. Verify the real heightmap loads,
      height_scale is meaningful, and the good `_mars_material` is actually applied.
- [ ] **Lighting + atmosphere** — flat now. Add a low warm Mars sun (long shadows),
      dusty tan fog, AgX tonemap, subtle bloom, SSAO. The Martian warm look (PALETTE).
- [ ] **Sky** — pale flat now → proper dusty pink-ochre gradient + faint sun disc.
- [ ] **Ground texture up close** — the scanned regolith (ground_albedo) should show
      grit near the mech; confirm it's blending in.
- [ ] **Rock scatter + relief variety** — more HiRISE relief (benches, ripples, a
      distant mesa/canyon wall), not a flat plain.

## B. THE PILOT / ON-FOOT (presentation)
- [ ] **FIX: pilot is a blank white mannequin** — replace with a real suited astronaut
      (white/orange Martian suit). We have `astronaut_fallen.glb`; need a walking one.

## C. THE MECH (player)
- [ ] Bring in the **Heavy Walker** (our Sci-Fi Pack original — armoured, gatling,
      rocket) as the player HAWC; it's far better than placeholders.
- [ ] Mech walk animation + weapon fire juice.

## D. VEHICLES / FACTIONS (per GDD — already scripted, needs art + feel)
- [ ] 4 classes (HAWC / tank / hover / multiped) distinct feel.
- [ ] 4 factions (Union/Darken/Bendian/Shalten) silhouettes + colours.
- [ ] The **HAWK/GASHR hijack loop** (eject → disable → commandeer) — the core pillar.

## E. STATION + SHIP (YOUR focus, Blender)
- [ ] Ground station / base (The Martian Hab + LUNA-7 modular ref).
- [ ] Dropship (tilt-rotor, ramp — drops the HAWC). We have `dropship.glb` to improve.
- [ ] Orbital station (Hermes-style rotating ring).

## F. GAME FEEL / POLISH
- [ ] Camera, HUD readability, hit feedback, sound (we have the real G-NOME soundtrack).
- [ ] Mission intro + objectives (campaign scripted already).

## PRIORITY ORDER (my half)
1. Fix the flat terrain + lighting/atmosphere (biggest visual win) ← START HERE
2. Replace the blank pilot with a suited astronaut
3. Wire the Heavy Walker as player
4. Sky + rock variety polish
