# G-NOME: REBORN — Game Design Document & Technical Roadmap

> Working title for a modern spiritual successor to *G-NOME* (7th Level, 1997).
> **Directive: Modernize, but do not dilute.** Preserve the original's tactical flavor —
> combined-arms vehicle warfare with the eject-and-hijack loop — while rebuilding UX,
> graphics, AI, and scale for modern hardware.
>
> This GDD is grounded in data recovered from the original disc (`reference/GAME_BIBLE.md`,
> extracted from `LABTEXT.DAT`): the real faction roster, vehicle classes, stats, and weapon
> systems. Where the brief renames the hijack weapon "HAWK," note the original disc calls it
> the **GASHR** (Gas-Assault Shock Rifle); we adopt HAWK as the successor's name and keep
> GASHR as in-fiction lineage.

---

## 0. PRODUCT VISION (one paragraph)

You are a single pilot in a four-way war on the dying frontier world of Ruhelen. Your power
does not come from one unbreakable war machine — it comes from your willingness to *abandon* it.
Every enemy vehicle on the field is a weapon you can take. The fantasy is the tactical gamble:
crippling a 23-ton enemy HAWC, ejecting into the open as a fragile human, sprinting across a
killing field, and climbing into the still-warm cockpit of your enemy's machine. Combat is
**asset theft**, not just attrition.

---

## 1. CORE PILLARS (Do Not Change)

### Pillar 1 — The Hijack Loop (the HAWK / GASHR weapon)
The defining mechanic. Combat resolves not only by destroying enemies but by *capturing* them.
- The player can **eject** from any vehicle at any time, becoming a vulnerable foot soldier.
- The **HAWK** rifle (lineage: GASHR) fires an EM/shock spike that **disables an enemy vehicle
  and force-ejects its pilot** without destroying the chassis.
- The player then sprints to the abandoned vehicle and **commandeers** it.
- Risk/reward is the whole game: on foot you are soft, slow, and exposed, but a successful
  hijack swings the entire engagement.

### Pillar 2 — Combined-Arms Vehicle Variety (4 classes, radically different feel)
Each class has distinct handling, weight physics, and tactical role. (Original class names in
parentheses, from the disc roster.)
1. **HAWCs — Bipedal Anti-Personnel / Tactical Defense.** Heavily armored bipedal mechs;
   the backbone. 6–9 m, 17–26 t. Deliberate, heavy, dominant at mid-range. *(Prowler, Talon,
   Ogre, Jinx, Stalker, Rampage, Predator, Minotaur.)*
2. **Tracked / Tank — Armored Support Vehicle.** Low-profile, fast, heavy-hitting ground armor.
   3–4 m, 6–12 t. Best frontal armor, weak flanks, can't climb. *(Titan, Boulder, Stinger,
   Legionnaire.)*
3. **Hovercraft — Airborne Insurgence Platform.** Extremely agile, drifting, low-friction
   scouts. 95–104 kph, 3–4 t, thin armor. Momentum-based handling. *(Rapier, Vulture, Wasp,
   Razor.)*
4. **Multipedal Walkers — Heavy Assault / Cruiser.** Stable, all-terrain artillery platforms.
   8–15 m, 22–57 t. Slow, devastating, climb anything. *(Lion 14.7 m/57 t, Scorpion, WidowMaker,
   Venom.)*

### Pillar 3 — Asymmetrical Factions (4)
Distinct silhouettes, armor language, weapon profiles, and doctrine. From the disc:
| Faction | Identity | Visual language | Doctrine tell |
|---------|----------|-----------------|---------------|
| **Union** (player side) | Professional military | Balanced, olive/tan, modular weapon bays, **auto-eject** | Versatile, safety systems |
| **Darken** | Republic regulars | Heavier plating, missile-forward (CHUM/AIM9), darker greys | Rocket saturation |
| **Bendian Mercs** | Mercenary opportunists | Blue, unpredictable mixed loadouts, **NO auto-eject** | High speed, no safety net |
| **Scorp** | Alien Imperial empire | Organic/chitinous, ion & plasma (CETI/LRIP/zWASP), pitch-only turrets | Alien weapon physics |

### Pillar 4 — Grim, Low-Fi Sci-Fi Aesthetic
Bleak, industrial, alien-wasteland. **Not** colorful hero-shooter. Gritty, high-fidelity
*mechanical* fidelity: weathered metal, dust, heat haze, sodium-lit interiors, oppressive skies.
The mood is "war machines in a hostile place that wants you dead," not spectacle.

---

## 2. MODERN ENHANCEMENT LAYER (The Upgrade)

- **Seamless on-foot transitions.** Vehicle→infantry is one continuous, interpolated motion (no
  hard scene cut). Ejecting at speed inherits momentum: bail from a 100-kph hovercraft and you
  ragdoll-roll and take fall damage. Exiting is a deliberate, high-stakes act.
- **Diegetic cockpit UI.** Replace the 1997 screen-hogging dashboard with in-world cockpit
  instrumentation: shield-vector ring, per-component armor integrity, and weapon-heat gauges
  rendered as physical cockpit elements and AR overlays — readable, never cluttering.
- **Hijack-aware AI.** Ejected enemy pilots fight back: they shoot the player on foot or sprint
  to reclaim an empty vehicle (theirs or a nearby one). AI defends teammates being hijacked.
- **Scale & environment.** Vast atmospheric battlefields; dynamic weather; artillery terrain
  deformation; destructible industrial bases (power plants, meson towers, bridges, the Citadel —
  all real structures from the disc).

---

## 3. GAMEPLAY LOOP ANALYSIS (second-by-second)

**Scenario:** Player pilots a Union *Prowler* HAWC, gets crippled, ejects, hijacks a hovercraft,
turns the fight. (~45 seconds.)

| t | State | Player action | System / feel |
|---|-------|---------------|---------------|
| 0:00 | **HAWC combat** | Strafe-fire twin FLECH guns at a Darken *Talon* across a ridge | Heavy, deliberate; torso twist lags the legs; weapon heat climbs |
| 0:06 | **Taking damage** | A Darken CHUM rocket volley shreds the Prowler's **left leg** (component damage) | Cockpit lists; movement speed drops 40%; "LEG ACTUATOR CRITICAL" on the diegetic panel |
| 0:11 | **Decision point** | Chassis is dying. Player commits to ejecting | Half-second canopy-blow telegraph; vulnerability window begins |
| 0:12 | **Eject** | Ejection inherits the HAWC's lean; player ragdoll-lands, rolls to prone | Camera punches to 3rd-person infantry; world feels suddenly *huge* and loud |
| 0:14 | **On foot, exposed** | Sprint between rocks, dodging Talon autocannon fire kicking up dust | Low HP, no shields; every hit is near-lethal; tunnel-vision audio |
| 0:22 | **HAWK opportunity** | A lightly-damaged Bendian *Rapier* hovercraft sits 30 m away, pilot distracted | Player raises the HAWK; capacitor whine spins up; charge meter fills |
| 0:27 | **HAWK fire** | Discharge an EM spike into the Rapier | Vehicle systems flatline; enemy pilot force-ejected, stumbles out |
| 0:29 | **Foot race** | Sprint to the Rapier while the ejected merc draws a sidearm | Twin threat: reach the cockpit OR lose the race; AI pilot may beat you to it |
| 0:33 | **Commandeer** | Mount the Rapier; boot sequence (0.8 s) as systems spin up | Brief defenseless beat during boot — tension spike |
| 0:35 | **Turn the tide** | Now in a 100-kph drifting scout, flank the Talon that killed your HAWC | Completely different physics: low friction, momentum drift, thin armor |
| 0:42 | **Payoff** | Strafe the Talon's exposed rear with the Rapier's ARCM cannon | Role reversal complete; the gamble paid off |

**The loop's emotional arc:** dominance → catastrophe → desperation → gamble → reversal. Every
engagement should be able to swing on a hijack. That swing *is* G-Nome.

---

## 4. TECHNICAL ARCHITECTURE

### 4.1 Engine recommendation
**Primary: Unreal Engine 5.** Rationale: Nanite/Lumen deliver the "vast atmospheric battlefield +
gritty hard-surface mechs" target cheaply; Chaos physics handles vehicle dynamics and destructible
bases; mature replication for the (hard) hijack netcode; strong vehicle/character templates.

**Alternative: Godot 4.** Lighter, open-source, fully scriptable; viable for a smaller team or a
vertical slice. We already have a Godot 4 prototype (`godot/`) proving the asset pipeline. Trade-off:
you build more of the physics/destruction/replication yourself.

> Recommendation: **prototype mechanics in Godot 4** (fast iteration, we have it running), then
> port the proven vertical slice to **UE5** for the production scale/fidelity target.

### 4.2 Vehicle ↔ Infantry state switching
Model the **pilot** as the persistent entity; vehicles are *possessable controllers*.

```
Pawn: PilotCharacter (always exists — the "soul")
   ├─ state: ON_FOOT      → drives CharacterMovement (infantry)
   └─ state: PILOTING     → possesses a VehiclePawn, input routed to it

VehiclePawn (HAWC / Tank / Hover / Walker)
   ├─ MovementComponent   (class-specific physics profile)
   ├─ DamageModel         (component-based, see 4.3)
   ├─ WeaponHardpoints[]
   └─ occupant: PilotCharacter | null
```

- **Enter:** trace for an empty/disabled vehicle in range → detach PilotCharacter (hide mesh,
  disable infantry collision) → possess VehiclePawn → run a `BootSequence` timeline (0.5–1.0 s)
  during which the vehicle is inert (the deliberate vulnerability beat).
- **Eject:** spawn PilotCharacter at the cockpit hatch → inherit `vehicle.velocity` (momentum
  transfer) → apply launch impulse + fall/impact damage scaled by speed → vehicle goes to
  `UNOCCUPIED` (AI may reclaim).
- Keep it a **state machine on the pilot**, not two separate game modes — this is what makes the
  transition feel seamless rather than a loading cut.

### 4.3 Component-based damage model
Each vehicle is a tree of damageable components, not a single HP pool.

```
VehicleDamageModel
  components:
    - CHASSIS   (core; 0 = destroyed)
    - LEG_L / LEG_R (or TRACK_L/R, or SKIRT/FAN, or LEG_0..N)  → mobility
    - WEAPON_HARDPOINT_0..3                                     → offense
    - SENSOR/HEAD                                               → targeting/UI
    - SHIELD_EMITTER (directional: front/rear/left/right arcs)  → mitigation
```
- Each component: independent armor + HP + material state (intact / damaged / destroyed) driving
  a mesh/VFX swap. *(The original advertised "multiple levels of damage, right down to the last
  body part" — preserve this.)*
- Destroying a **leg** → mobility penalty/topple; a **weapon** → that hardpoint dies; the
  **shield emitter** for an arc → that facing becomes vulnerable. Encourages aimed, tactical fire.
- **HAWK interaction:** the HAWK does *near-zero* chassis damage but massively spikes a hidden
  `SYSTEMS_INTEGRITY` track; crossing the threshold triggers force-eject. This is what makes the
  weapon a *capture* tool, not a kill tool — keep them mechanically separate.

### 4.4 Networking the hijack (if multiplayer)
The hardest sync problem; design for it from day one.
- **Server-authoritative possession.** Enter/eject/hijack are server RPCs; clients predict
  locally and reconcile. Never let two clients believe they own the same vehicle.
- **Vehicle = replicated actor with an `OwningPilot` ref**, not owned by a player connection —
  ownership transfers cleanly on hijack.
- **Contested-hijack race:** authoritative trace on the server resolves who reaches the cockpit
  first; losers get a clear "CONTESTED" UI beat rather than a silent rubber-band.
- **Relevancy:** stream vehicle/pilot states by proximity for large battles; the HAWK's
  force-eject is a server event broadcast to nearby clients.

---

## 5. CONTROL SCHEMA (modern, but retains heavy deliberate feel)

Design goal: WASD+Mouse / Gamepad parity, while the **weight** of war machines is felt through
*input latency and momentum*, not clunky bindings.

### On Foot (Infantry)
| Action | KB/M | Gamepad |
|--------|------|---------|
| Move / Sprint | WASD / Shift | L-stick / L3 |
| Look | Mouse | R-stick |
| Fire HAWK / weapon | LMB | RT |
| Charge HAWK (hold) | RMB | LT |
| Enter / Hijack vehicle | F | Y |
| Jump / dodge-roll | Space / C | A / B |

### In Vehicle (shared base, class-modified)
| Action | KB/M | Gamepad |
|--------|------|---------|
| Throttle fwd/back | W / S | LT / RT (or L-stick Y) |
| Steer / turn chassis | A / D | L-stick X |
| Torso/turret aim | Mouse | R-stick |
| Fire weapon group 1 / 2 | LMB / RMB | RB / LB |
| Cycle weapon group | Q / scroll | D-pad ◀▶ |
| **Eject** | **Hold X** (deliberate, ~0.4 s) | **Hold Back/View** |
| Boost / ability (class) | Space | A |

**Per-class feel (the "heavy physics" retention):**
- **HAWC:** torso aim **decoupled** from leg facing (twist lag); turning has acceleration ramp;
  footfall screen-shake.
- **Tank:** fast straight-line, slow rotation; turret turns independent of hull; can't reverse-pivot.
- **Hovercraft:** **momentum drift** — release throttle and you keep sliding; counter-steer to
  correct; air-control feel.
- **Walker:** slowest turn, can climb/straddle terrain; weapon sway from the gait; stable firing
  platform when planted.

> The deliberate feel comes from **tuned acceleration curves, turn-rate caps, and aim lag** — the
> bindings are modern and clean; the *machines* are what feel heavy.

---

## 6. PRODUCTION ROADMAP (phased)

| Phase | Goal | Key deliverables |
|-------|------|------------------|
| **P0 — Vertical slice (Godot 4)** | Prove the hijack loop is fun | 1 HAWC + 1 hover, eject/hijack state machine, HAWK force-eject, component damage, 1 arena, basic enemy AI |
| **P1 — Combined arms** | All 4 vehicle classes feel distinct | Tank + walker classes, per-class physics profiles, weapon-group system |
| **P2 — Factions & AI** | The 4-way war reads clearly | Faction silhouettes/loadouts, hijack-aware AI, reclaim behavior |
| **P3 — UE5 port + scale** | Production fidelity & vast maps | Nanite mechs, Lumen lighting, destructible bases, weather, terrain deformation |
| **P4 — Campaign** | 20 missions / 4 campaigns | Mission scripting, objectives (incl. on-foot infiltration), the Darken→Bendian→Scorp→Shalten arc |
| **P5 — Multiplayer (optional)** | Hijacking online | Server-authoritative possession, contested-hijack resolution |

---

## 7. CONTENT REFERENCE (from the original disc — reuse, don't reinvent)

- **Full vehicle roster + stats:** `reference/GAME_BIBLE.md` (20 vehicles, all weapons, structures).
- **Weapon systems:** P2MEC, FLECH, TCREAP, CHUM, DASY, RUPP, CETI, LRIP, zWASP, GAUS30, **GASHR**
  (the HAWK's in-fiction ancestor), etc. — each has faction flavor.
- **Structures for destructible bases:** Meson Tower, Shield Generator, Power Plant, Rocket Towers,
  Bridge + Bridge Control, the Citadel, Research Labs (the G-NOME cloning program — the title drop).
- **Audio/cinematics:** original soundtrack (`audio/soundtrack/`) and cinematics (`cinematics/`)
  preserved for reference and licensing discussions.

> Guiding constraint: this is a *spiritual successor*, not an asset rip. The disc data is the
> design bible and tonal reference; production assets are built new to the verified aesthetic.
