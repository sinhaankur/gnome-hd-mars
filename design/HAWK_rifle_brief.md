# ASSET DESIGN BRIEF — "HAWK" Heavy Asset Weapon Capture Rifle

> **Role in game:** The hijack tool. A two-handed, infantry-carried EM spike weapon that disables
> enemy vehicles and force-ejects their pilots without destroying the chassis (see `GDD.md`,
> Pillar 1). In-fiction lineage: the original G-Nome **GASHR** (Gas-Assault Shock Rifle).
> **Design north star:** grounded, heavy, functionally plausible. A high-voltage industrial tool
> that happens to be a weapon — NOT a sleek cyberpunk toy. If it looks like it weighs 18 kg and
> could give you a lethal arc burn, we're on target.

---

## 1. DESIGN INTENT (read first)

- **Form follows function.** Every shape exists for a reason: to channel a massive capacitor
  discharge through induction coils. It reads as a cross between a **tactical anti-materiel rifle**
  and a **high-voltage railway/overhead-line maintenance tool**.
- **Honest engineering, not fantasy.** Visible fasteners, heat-sink fins, warning placards,
  grounding straps, exposed (but shielded) high-current paths. The threat is electrical and
  thermal, and the design should telegraph that danger.
- **Weight is the feeling.** Thick walls, a low/forward center of mass (the coil rail), a stock
  dominated by a battery brick. It should look braced, not nimble.

---

## 2. VISUAL LANGUAGE & SILHOUETTE

| Element | Description |
|---------|-------------|
| **Overall silhouette** | Long, front-heavy. The open coil-rail dominates the forward 60%; a blocky receiver and battery-laden stock balance the rear. Boxy and industrial, broken by the cylindrical coils. |
| **The coil rail (signature)** | In place of a barrel: an **open, heavy-duty rail cage** housing thick **raw copper induction coils** in series. The rail is exposed (caged, not enclosed) so the coils are visible and can visibly arc when charging. Ceramic standoff insulators separate coils from the frame. |
| **Receiver** | Cast, blocky, the structural heart. Houses the capacitor bank (implied mass), the fire-control group, and the readout screen. |
| **Stock / battery** | Dominated by a **ruggedized quick-release lithium-ion battery brick** with a physical locking lever and a thick rubber recoil pad. |
| **Grips** | Forward vertical grip (well clear of the live rail) + pistol grip. Both heavily textured, rubber-overmolded, sweat-worn. |
| **Cabling** | Thick **yellow insulated high-current wiring** runs externally along a cable channel from battery → receiver → coil rail, secured with metal P-clamps. The yellow is the one allowed color accent against an otherwise grim palette. |

**Proportions (feel target):** ~1.3 m long, heavy two-handed carry. Coil rail diameter noticeably
thicker than a normal barrel. The thing should not shoulder comfortably — it's braced and fired
deliberately, matching the high-stakes hijack beat.

---

## 3. MECHANICAL DETAILS (for modeling + animation)

### 3.1 Power source
- Quick-release **battery brick** seats into the stock; a **physical locking lever** (real hinge
  pivot, detent) clamps it. Model the lever in both locked/unlocked poses for the reload anim.
- Battery face: charge-state LED bar (low-res, chunky segments), a coolant port, carry handle.

### 3.2 Interface — the readout
- A small **low-resolution monochrome green CRT/LCD** set into the receiver at a slight upward
  cant toward the user's eye. Shows **"CHARGE %"** and a **"CAPACITOR OVERHEAT"** warning, plus a
  crude bar graph. Scanline/phosphor flicker, NOT a crisp modern HUD. Deliberately retro-industrial.
- A few hard physical controls beside it: a charge-mode rotary, an arming toggle with a wire guard,
  a recessed reset button.

### 3.3 Firing sequence (animation beats)
On discharge, in order (~0.6 s):
1. **Coils energize** — visible electric arcs leap between copper coils; heat haze distorts air
   above the rail; emissive ramps from cold copper to white-hot at the muzzle gap.
2. **Discharge** — the EM spike releases; brief blinding bloom at the rail mouth.
3. **Recoil absorb** — the **copper coils physically shift backward** along the rail (a short slide,
   ~3–4 cm) to absorb recoil, then return on damped springs.
4. **Pneumatic venting** — pressurized gas vents from **side ports** with audible hiss + vapor jets.
5. **Thermal rod eject** — a **spent thermal cooling rod** pops out of an ejection port like an
   oversized shotgun shell (glowing, tumbling, clatters on the ground). This is the "spent casing"
   read that grounds the weapon.
6. **Cooldown lockout** — if overheated, the screen flashes "CAPACITOR OVERHEAT," coils glow
   residually, and the weapon is locked until vented (a mandatory cadence, not spammable).

> These beats double as **player feedback**: the coil slide + vent + rod eject tell the player the
> shot landed and the weapon is now in cooldown — readable at a glance during a tense hijack.

---

## 4. REFERENCE IMAGERY DIRECTIONS

Gather/board references in these buckets:
- **Anti-materiel rifles** — for the two-handed scale, bipod/brace logic, stock + receiver mass.
- **Overhead-line / railway high-voltage maintenance tools & insulators** — for the caged rail,
  ceramic standoffs, grounding hardware, hazard language.
- **Industrial capacitor banks / spot welders / rail launchers** — for thick copper bus-bars,
  coil windings, heat-sink fins, the "this stores lethal energy" read.
- **Heavy power-tool ergonomics** (demolition hammers, core drills) — for overmolded grips,
  quick-release battery packs, the chunky utilitarian shape language.
- **Weathered field equipment** — sun-bleached placards, chipped anodizing, rust bloom at fasteners,
  cable abrasion. Real wear patterns, not uniform "grunge."
- **CRT/LCD industrial readouts** — green monochrome, low-res, scanlines, for the screen.

Anti-references (avoid): glowing neon trim, clean white plastics, holographic sights, symmetrical
"cool" sci-fi curves, anything that looks light or toy-like.

---

## 5. TOPOLOGY & POLY BUDGET

Target: modern game engine (UE5/Godot 4), first-person + third-person, so it's seen close.

| LOD | Tri budget | Notes |
|-----|-----------|-------|
| **LOD0 (hero/FP)** | ~40–70k tris | Coils, fasteners, vent ports, screen bezel, cable clamps modeled. Seen inches from camera. |
| **LOD1 (TP/mid)** | ~15–20k | Simplify coil count, merge small greebles to normal map. |
| **LOD2 (distance)** | ~4–6k | Silhouette only; details baked. |
| **LOD3** | ~1–1.5k | Far/background occupants. |

**Topology priorities**
- **Animated/moving parts as separate, clean sub-meshes**, pivots authored at real hinge axes:
  *coil-slide assembly, battery brick, locking lever, ejection-port door, thermal rod, vent flaps,
  charge rotary, arming toggle.* Rigging depends on these being discrete.
- **Hard-surface bevels everywhere** — no zero-radius edges; support loops to hold shape under
  normal-mapped baking; chamfer all primary edges so they catch light (the gritty look lives in
  edge highlights).
- **Even quad density on grip/overmold** for clean deformation-free skinning and crisp roughness.
- Keep the **coils as real geometry on LOD0** (they arc + slide — fakeable only at distance).
- UDIM or 2–3 texture sets: (1) receiver/rail body, (2) coils/copper/cabling, (3) battery+grips.

---

## 6. TEXTURING & WEATHERING GUIDELINES

**Material palette (grim, low-fi — one yellow accent):**
| Surface | Material treatment |
|---------|-------------------|
| Body / receiver | **Scratched matte-black anodized aluminum** — low spec, micro-scratches revealing raw alloy at wear points |
| Frame / rail cage | **Weathered cast iron** — rougher, pitted, cooler tone, rust bloom at fasteners/welds |
| Coils / bus-bars | **Raw copper** — oxidized patina in recesses, polished/bright on contact faces, heat-discoloration (blue/straw temper) near the muzzle gap |
| Venting ports / muzzle | **Heat-treated distressed steel** — temper colors, soot, the most thermally abused zone |
| Cabling | **Thick yellow insulated wire** — chalky sun-faded yellow, abrasion-worn to black core at flex points |
| Grips | Black rubber overmold — sheen from hand-oil at contact, matte elsewhere |
| Battery brick | Industrial casing — scuffed corners, chipped warning placards, grime in seams |

**Weathering logic (make it tell a story, not random noise):**
- **Wear follows use:** edges/corners chipped; grip + lever + trigger guard hand-polished; recessed
  areas hold dust and oxidation.
- **Heat zones:** strongest discoloration, soot, and temper colors concentrate at the muzzle/vent
  end and along the coils — visually anchors *where the energy comes out*.
- **Grounding/electrical tells:** scorch marks near coil standoffs, faint arc-etch patterns on the
  rail cage, oxidized contact points.
- **Field grime:** dust accumulation by gravity (top surfaces lighter, undersides + crevices
  caked); mud splatter low; sun-bleach on upward faces.
- **Roughness is the hero map:** sell metal vs. rubber vs. ceramic insulators vs. faded plastic
  through roughness/spec contrast more than through hue. Keep albedo restrained and grim.

**Emissive / FX hooks (mask these for the engine):**
- Coil arc-glow emissive mask (animated, charge-driven cold→white-hot gradient).
- Screen emissive (green CRT, separate animated texture for CHARGE% / OVERHEAT states).
- Heat-haze placement at muzzle gap + vents (engine post/particle, but author the UV anchor).
- Thermal-rod emissive (glowing-to-cooling gradient over the eject's lifetime).

---

## 7. DELIVERABLES CHECKLIST

- [ ] Blockout (silhouette + proportion lock, scale-referenced to the infantry character)
- [ ] Hero high-poly (all greebles, coils, fasteners)
- [ ] Game-res LOD0–LOD3 with clean animation sub-meshes + authored pivots
- [ ] Baked maps (normal, AO, curvature, thickness) per texture set
- [ ] PBR texture sets (albedo/roughness/metallic/normal) + emissive masks (coils, screen, rod)
- [ ] Material variants per faction tint (Union olive / Darken grey / Merc blue / Scorp organic)
- [ ] Animation-ready FBX: moving parts separated, pivots correct, naming convention documented

> Keep the GDD's tone law in mind throughout: **grim, industrial, functionally plausible.** The
> HAWK is the player's most desperate, most empowering tool — it should look like dangerous,
> hard-won field equipment, scarred by every hijack it's ever pulled off.
