# Component Audit — "see everything, even a lamp has to be good"

> The user: *"I find a lot of components not working good... even a lamp has to be good."*
> So we stopped theorizing and **shot the real game** (`godot-art-pass` loop, DEV_SHOTS) and judged
> **every visible component** against the NASA reference photos in `reference/real_mars/`.
>
> Captured 2026-11-02, 10 fresh frames in `reference/shots/shot_00..09.png`. The game runs clean
> (no errors) — every problem below is **visual/quality**, exactly the user's point.
>
> Grade: 🟢 good · 🟡 passable but off · 🔴 broken / reads as placeholder.
> Each row: **what I literally see** → **root cause** → **fix** (payoff order).

---

## The headline findings (what jumps out in the shots)

| # | Component | What I see in the shots | Grade | Root cause | Fix |
|---|-----------|-------------------------|-------|-----------|-----|
| 1 | **On-foot pilot** | a pure flat-**white T-pose mannequin**, arms out, no texture, no animation (shot_02, shot_05) | 🔴 | `pilot.gd` loads `pilot_trooper.glb` and returns; the GLB's textures aren't applying (renders white) and it has **no idle anim** (T-pose) | apply materials in Godot + play an idle/walk clip, OR use a working rigged CC0 soldier (Quaternius) |
| 2 | **"Trees" on Mars** | dark green/brown **lollipop bush shapes** dotted across the plain (shot_02) | 🔴 | leftover scatter primitive reading as vegetation — **Mars has no plants**; breaks realism instantly | find + remove the offending scatter in `environment_engine.gd`; replace with rock/pebble |
| 3 | **Scatter rocks** | flat, smooth, **dark disc/pebble blobs sitting ON the surface**, not embedded; too uniform (shot_05) | 🔴 | pebble `SphereMesh` + poor material; not half-buried, wrong shape | angular variation, grey-brown basalt material, sink into ground, size variety (ref: real rocks are sharp + half-buried) |
| 4 | **Enemy health bars** | red bars **floating in empty air** with no mech beneath (shot_02) | 🔴 | enemies spawned off-screen/under-terrain or invisible; bar billboard persists | clamp spawns to walkable ground; hide bar when owner not visible/alive |
| 5 | **Enemy / stolen mech** | reads as a **grey undetailed blob**, hard to parse as a mech (shot_08) | 🟡 | borrowed placeholder mech + flat lighting; small on screen | faction tint + better material; this is the roster-rebuild task |
| 6 | **Terrain color** | **too uniformly orange/saturated**; no grey-brown rock tone (all shots) | 🟡 | terrain shader palette too hot vs NASA caramel/butterscotch | desaturate, add grey-brown mid-tone, break up tiling |
| 7 | **Horizon / aerial perspective** | sky-to-ground transition is **clean/banded**; real Mars washes to tan haze a few km out | 🟡 | fog too thin / not tinted to sky color | thicken height-haze, tint to horizon color (big "vast" win) |
| 8 | **Installation / base** | flat angular **slabs, low detail**, reads placeholder (shot_08) | 🟡 | borrowed `installation.glb` | rebuild from Quaternius Modular Sci-Fi MegaKit (CC0) |
| 9 | **Sky** | butterscotch, roughly right, slightly too smooth-gradient | 🟢 | — | minor; add faint dust variation |
| 10 | **Sun disk** | present, reasonable | 🟢 | — | keep (could be slightly smaller/dimmer — Mars is 1.5 AU) |
| 11 | **HUD text** | readable amber telemetry, fine | 🟢 | — | keep |
| 12 | **Radar (top-right)** | works, readable | 🟢 | — | keep |

---

## Update after close inspection (2026-11-02, rendered each asset in isolation)

Investigating further changed the picture — some flagged "bad" components are actually **fine**,
and the real weakness is **staging**, not the assets:

| Component | First read | After close render | Verdict |
|-----------|-----------|--------------------|---------|
| **Enemy mechs** (#5) | "grey blob" | rendered each in isolation (`shots/enemy_*.png`) — **detailed, well-textured**: paneling, greebles, glowing cores, proper silhouettes | 🟢 the ASSET is good; it only reads as a speck **at distance** |
| **Terrain** (#6) | "too orange" | read `mars_terrain.gd` shader — **heavily calibrated** to measured NASA sRGB values, de-greened scan blend, ripples/cracks/pebbles | 🟡→🟢 near-ground is good; don't blind-edit a calibrated shader |
| **Faction tint** | suspected "darkens mechs" | `faction.gd` **blends** (keeps detail) + adds faint emission to read through haze | 🟢 well-designed |

**So the true remaining issue is STAGING, not broken assets:** enemies spawn at the 800 m map edges
and march in, so the opening frames show an empty plain with distant specks. The player starts at
z=160, base at z=-180 — the action is far away at mission start. That's a *composition/pacing*
problem (fixed by closer first-wave spawns or an opening framing on a nearby enemy), not an asset bug.

**Genuinely fixed this session:** #1 white T-pose pilot (was a static, unriggable GLB), #4 floating
far health bars (now distance-gated). Those WERE broken; they're now good.

---

## The "even a lamp has to be good" principle

The user's bar: **every element must survive a close look.** Right now the worst offenders fail at
*any* distance (the white mannequin, the Mars "trees", floating health bars). These read as
"placeholder/broken" and drag the whole game down regardless of how good the terrain or sky is.

So the fix order is **not** "polish the best thing more" — it's **"eliminate every component that
reads as broken,"** cheapest first:

1. **#2 Mars trees** — delete offending scatter (minutes). Instant realism win.
2. **#4 Floating health bars** — gate the bar on a live, visible, ground-clamped owner (small).
3. **#1 White mannequin pilot** — apply materials + idle anim, or swap to a working CC0 soldier (medium).
4. **#3 Rocks** — material + shape + half-bury pass (medium).
5. **#6/#7 Terrain + haze** — palette + fog calibration vs NASA (medium; the `godot-art-pass` core).
6. **#5/#8 Mechs + base** — asset rebuilds (the Quaternius CC0 route from GITHUB_RESEARCH.md).

> This IS the "skills to see everything" the user asked for: the `godot-art-pass` loop is the skill
> that *shows* us every component against truth, so nothing — not even a lamp — ships looking wrong.

---

## Method (repeatable — run this every time something "looks off")

```sh
cd godot && DEV_SHOTS=1 godot --path . scenes/mission1.tscn   # self-terminating, 10 frames
# then read shots/shot_*.png against reference/real_mars/*.jpg, grade each component, fix worst first
```
