# HAWC Variety Spec — the full roster, made visually distinct

> The original G-Nome's variety was a huge part of its appeal. This spec maps all 19 roster
> vehicles (from `reference/GAME_BIBLE.md`, extracted from the disc's `LABTEXT.DAT`) to a small
> set of **genuinely distinct silhouette archetypes** + faction identity, so the game reads as
> having real variety without needing 19 mediocre one-off models.
>
> Rule: **silhouette differs by CLASS; color/detail differs by FACTION.** A player should tell a
> Sentry from a Heavy at a glance by shape, and a Union unit from a Scorp by look.
> All models are our OWN (licensing-safe). We can't extract the 1997 meshes (MODL format uncracked),
> so these are faithful reinterpretations to the real specs, not copies.

---

## The 5 class archetypes (distinct silhouettes)

| Archetype | Silhouette | Height | Legs | Reads as | Roster members |
|-----------|-----------|--------|------|----------|----------------|
| **A. Sentry** | Compact bipedal, shoulder weapon pods, cockpit up top | ~6–7 m | 2 (digitigrade) | agile front-line mech | Prowler, Talon, Ogre, Jinx |
| **B. Tactical** | Taller, bulkier bipedal, heavier armor, more weapons | ~7.5–9.5 m | 2 | heavy trooper | Stalker, Rampage, Minotaur, Predator |
| **C. Heavy** | Massive **multipedal** (4–6 legs), dominant hull, big cannons | ~8–15 m | 4–6 | boss / artillery | Lion (4-leg, 14.7 m), WidowMaker, Venom, Scorpion (6-leg) |
| **D. Support** | Low, wide, **tracked** hull + turret | ~3–4 m | tracks | tank | Titan, Boulder, Legionnaire, Stinger |
| **E. Hovercraft** | Sleek arrowhead on a glowing skirt, no legs | ~3 m | hover | fast scout | Rapier, Vulture, Razor, Wasp |

> We already have working versions of A (HAWC/Prowler), C (Lion 4-leg, Scorpion 6-leg),
> D (Titan), E (Rapier) in the Blender `G-Nome` collection. **The main gap is B (Tactical)** —
> a taller, bulkier biped so Sentry vs Tactical are clearly different, plus faction tint variants.

---

## Faction identity (color + detail language)

| Faction | Base color | Accent / detail | Weapon glow | Tell |
|---------|-----------|-----------------|-------------|------|
| **Union** (player) | Olive / tan | clean panels, safety markings | warm orange | balanced, auto-eject hatch visible |
| **Darken** | Cold grey / gunmetal | rivets, missile racks prominent | red | rocket-heavy, blocky |
| **Bendian Merc** | Blue | mismatched/asymmetric parts, scavenged look | cyan | no auto-eject, irregular |
| **Scorp** (alien) | Dark green / chitin | organic ribs, uneven, bio-panels | toxic green | insectoid, pitch-only turrets |

Same archetype + different faction skin = a "new" unit at low cost. Example: the **Sentry**
archetype becomes **Prowler** (Union tan), **Talon** (Darken grey), **Ogre** (Merc blue),
**Jinx** (Scorp green) — four distinct-feeling mechs from one well-made silhouette.

---

## Full roster mapping (all 19)

| Vehicle | Faction | Archetype | Distinguishing detail to model |
|---------|---------|-----------|-------------------------------|
| **Prowler** | Union | A Sentry | 2 gun pods + 2 slim laser barrels, tan |
| **Talon** | Darken | A Sentry | 2 missile racks (boxy), grey |
| **Ogre** | Merc | A Sentry | asymmetric weapons, blue, scavenged |
| **Jinx** | Scorp | A Sentry | chitin plating, green, bio-glow eyes |
| **Stalker** | Darken | B Tactical | tall, 2 big lasers + 2 gatling, grey |
| **Rampage** | Union | B Tactical | anti-armor, rocket rack on back, tan |
| **Minotaur** | Merc | B Tactical | 9.5 m, twin missile racks, blue |
| **Predator** | Scorp | B Tactical | 8.9 m, spiny, green |
| **Lion** | Union | C Heavy (4-leg) | 14.7 m, twin top cannons, missile rack |
| **WidowMaker** | Merc | C Heavy | multipedal cruiser, gauss cannon, blue |
| **Venom** | Merc | C Heavy | multipedal, 4 weapons, blue |
| **Scorpion** | Scorp | C Heavy (6-leg) | tail stinger, 6 legs, green |
| **Titan** | Union | D Support | turret + main gun, tan tank |
| **Boulder** | Darken | D Support | missile rack tank, grey |
| **Legionnaire** | Merc | D Support | fast tank, blue |
| **Stinger** | Scorp | D Support | missile tank, green |
| **Rapier** | Union | E Hover | ARCM cannon, tan, fast |
| **Vulture** | Darken | E Hover | pulse weapon, grey |
| **Razor** | Merc | E Hover | 3 weapons, blue, fastest-looking |
| **Wasp** | Scorp | E Hover | ion gun, green |

**Infantry** (on-foot, for the hijack loop): Union Soldier / Darken / Bendian Merc / Scorp Warrior —
one humanoid model + faction tint, carrying PRIF44 rifle + GASHR launcher.

---

## Build order (when Blender reconnects) — smallest to biggest payoff

1. **Faction-tint the existing archetypes** (A, C, D, E already built) → instantly ~12 distinct
   units from recolors. Fast, huge variety gain.
2. **Build archetype B (Tactical biped)** — the missing silhouette; unlocks 4 more distinct units.
3. **Add the per-vehicle distinguishing detail** (missile racks, extra barrels, spines) so same-
   archetype units differ within a faction too.
4. **Export all** and wire an enemy-spawn table into the game so missions field varied HAWCs.
5. (Later) Infantry model for the hijack loop.

> This gets the game to "wow, lots of different HAWCs" with ~6 well-made base models + tints,
> instead of 19 rushed ones. Depth applied to variety — the disciplined way to "go crazy."
