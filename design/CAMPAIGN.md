# G-NOME: REBORN — Campaign Outline (20 missions / 4 campaigns)

> Mission-by-mission outline for the single-player campaign of the modern successor.
> Grounded in the original's structure (4 campaigns across faction territories), its premise
> (the G-NOME genetic-cloning program), and the real structures/units from the disc
> (`reference/GAME_BIBLE.md`). The hijack loop (`GDD.md`, Pillar 1) is the spine of the design:
> nearly every mission is winnable — or made dramatically easier — by *capturing* enemy assets
> rather than out-trading them.
>
> Premise recap: You are **Gant**, a Union pilot. Your partner **Kylie** is deep undercover in
> Darken territory. The four campaigns trace the hunt for the G-NOME — a stolen genetic weapon —
> across four hostile regions, each introducing a faction, a vehicle class, and a hijack twist.

---

## Design rules for the campaign
- **One new idea per mission.** Each mission teaches or stress-tests exactly one mechanic
  (a vehicle class, a structure type, an objective verb, an AI behavior).
- **Hijacking is always an option, never the only one.** The "intended" solution and the "steal
  your way through it" solution should both be viable; the second is faster and riskier.
- **Difficulty curve = density + asymmetry.** Early missions: few enemies, your class advantaged.
  Late missions: combined-arms enemy formations, alien (Scorp) physics, defended objectives.
- **At least 3 missions force you out of the cockpit** (on-foot infiltration), per the original.

---

## CAMPAIGN 1 — DARKEN REPUBLIC  *(teaches: core loop, HAWCs, the hijack)*
Tone: cold industrial republic; greys and rust; rocket-heavy Darken regulars. Find Kylie.

| # | Title | Primary objective | Teaches / twist |
|---|-------|-------------------|-----------------|
| 1 | **Cold Start** | Reach the rendezvous beacon across a Darken patrol zone in your Union **Prowler** HAWC | Movement, torso-twist aim, weapon heat, first kills. Pure HAWC tutorial. |
| 2 | **First Blood** | Destroy a Darken **Talon** picket and survive a CHUM rocket ambush | Component damage (your leg gets hit); shields by facing. |
| 3 | **The HAWK** | Your HAWC is crippled by design — **eject, recover the HAWK rifle**, and hijack a Darken Talon to escape | THE hijack tutorial: eject → on-foot → HAWK force-eject → commandeer. Pillar 1 onboarding. |
| 4 | **Bridge Control** | Capture the **Bridge Control Building** to lower a span; hold it vs a counterattack | Structures + objective defense; on-foot capture interior. |
| 5 | **Extraction** | Fight through a Darken motor pool to reach Kylie; **steal a fresh HAWC** from the Chassis Assembly Plant | Set-piece; rewards hijacking over attrition. Campaign 1 boss: a Darken **Stalker**. |

---

## CAMPAIGN 2 — BENDIAN MERC TERRITORY  *(teaches: speed, hovercraft, no safety net)*
Tone: lawless blue-marked mercs, fast and unpredictable, **no auto-eject** (they fight harder —
they can't bail safely). Gant + Kylie push deeper.

| # | Title | Primary objective | Teaches / twist |
|---|-------|-------------------|-----------------|
| 6 | **Run the Gauntlet** | Outrun a Merc **Razor** hovercraft pack to a safe zone | Hovercraft class introduced (hijack a **Rapier** mid-mission); momentum drift handling. |
| 7 | **Hit and Fade** | Raid a Merc supply depot and escape before reinforcements box you in | Speed-based objective; weapon-depot resupply structure. |
| 8 | **Dead Air** | Destroy a **LATLON Communications Array** to blind the Mercs (on foot — array interior) | On-foot infiltration #2; stealth-ish, light cover combat. |
| 9 | **Ogre Hunt** | Duel a Merc **Ogre** HAWC in a tight canyon | Asymmetry: Mercs have no auto-eject → hijacking them is high-value but they don't quit. |
| 10 | **Minotaur's Maze** | Survive a Merc **Minotaur** + escorts defending a shield generator; drop the **Shield Generator** to win | Campaign 2 boss; shielded-structure puzzle (can't be entered until shield drops). |

---

## CAMPAIGN 3 — SCORP TERRITORY  *(teaches: alien physics, walkers, the lab)*
Tone: organic chitinous alien empire; toxic greens; ion/plasma weapons with different feel;
Scorp Imperial Warriors defend tenaciously. Backed by clandestine Union orbital ion-strikes.

| # | Title | Primary objective | Teaches / twist |
|---|-------|-------------------|-----------------|
| 11 | **Hostile Ground** | Breach the Scorp perimeter past **Meson Towers** (GAUS30 ion cannons) | Scorp weapon physics (ion arcs, shield-killers); avoid/disable lethal static defenses. |
| 12 | **The Predator** | Ambush and hijack a Scorp **Predator** HAWC to pass an IFF checkpoint | Hijack-for-disguise: drive a captured Scorp unit past automated **Pop-Up Turrets** (IFF intercept). |
| 13 | **Walker Country** | Cross deformed high terrain only a **multipedal walker** can climb | Walker class introduced (hijack a Scorp unit or the slow **Scorpion**); terrain adaptability. |
| 14 | **Orbital Window** | Paint targets for a Union ion-strike while surviving a Scorp counterpush | Designation objective + survival; scripted spectacle (the orbital strikes). |
| 15 | **The Citadel** | Assault **the Citadel** atop Mesa Caracon — the Scorp/Union weapons & genetics vault | Campaign 3 boss arena; Scorp **Scorpion** heavy walker; multi-stage base destruction. |

---

## CAMPAIGN 4 — SHALTEN FRONTIER  *(teaches: mastery, combined arms, the truth)*
Tone: desolate war-torn frontier; everything at once. Pursue the G-NOME and its captors to the
research lab where the program was born.

| # | Title | Primary objective | Teaches / twist |
|---|-------|-------------------|-----------------|
| 16 | **Convoy** | Run down a mobile convoy carrying the G-NOME across open frontier | Combined-arms chase; swap vehicle classes on the fly via hijacking. |
| 17 | **Power Down** | Destroy the **Electro-chemical Power Plant** feeding the frontier's defenses | Cascade: killing power disables meson towers + barriers elsewhere on the map. |
| 18 | **Rocket Alley** | Push through a corridor of **Rocket Towers** (CHUM + UNKPA mixed) | Endurance gauntlet; component-targeting to silence towers fast. |
| 19 | **Infiltration** | Eject and enter the **Research Laboratory** on foot — the G-NOME cloning facility | On-foot infiltration #3; the narrative reveal (the G-NOME experiments). HAWK vs interior defenders. |
| 20 | **G-NOME** | Final confrontation: a Union **Lion** (or hijacked equivalent) vs the antagonist's heavy escort, then secure/destroy the G-NOME | Finale: every mechanic at once — combined arms, component damage, a desperate last hijack. |

---

## Recurring systems across the campaign
- **Capture economy.** Vehicles you hijack and survive with can be requisitioned in later missions
  via captured **Motor Pools / Vehicle Delivery Systems** — rewards bold theft over caution.
- **Structure verbs.** Capture (bridge/turret control), destroy (power/meson/shield), defend
  (held points), designate (orbital strikes), infiltrate (on foot). Each campaign adds one.
- **Faction escalation.** Darken (rockets) → Mercs (speed, no-eject) → Scorp (alien physics, IFF)
  → Shalten (all combined). The hijack twist deepens each campaign.
- **Optional objectives** every mission (destroy a side structure, capture a rare chassis, rescue
  a downed pilot) feed the capture economy and lore.

> This outline maps 1:1 onto the original's "20 missions / 4 campaigns / Darken→Bendian→Scorp→
> Shalten" structure while threading the hijack loop and the four vehicle classes through a clean
> teaching curve. Production order should follow `GDD.md` §6 (vertical slice = Mission 3, "The
> HAWK," since it exercises the entire core loop in one mission).
