# Blender Asset Build List — the master checklist

> **Purpose.** Most of the 3D assets currently in the game are bad (placeholder, bloated,
> wrong scale, or borrowed CC-BY models that don't fit). This is the single source of truth for
> **every asset the game needs**, its current state, and the order we rebuild them in Blender —
> properly, one at a time.
>
> **Grounding.** Roster/silhouettes from `design/HAWC_VARIETY_SPEC.md`; structures from
> `reference/GAME_BIBLE.md`; env/props from what `godot/scripts/*` + `scenes/*` actually load
> (audited 2026-08-27). Sizes are the on-disk `.glb` today.
>
> **Rules (from project memory).**
> - All models are **our own**, licensing-safe. Borrowed CC-BY assets are placeholders to *replace*.
> - `silhouette differs by CLASS; color/detail differs by FACTION` — one good base per archetype + tints.
> - Real vs sloppy: judge only against NASA Mars photos via the `godot-art-pass` loop.
> - Build + export in ONE Blender call (connection is unstable); reapply materials via Godot shader.
> - Keep polys/texture sizes sane — see the budget note at the bottom.

Legend: 🔴 bad/replace · 🟡 placeholder-borrowed (works, not ours) · 🟢 acceptable · ⬜ not built yet

---

## 0. The headline problem — RESOLVED (2026-08-27)

| Asset | Size | Status |
|-------|------|--------|
| `warrior.glb` | **243 MB** | ✅ RETIRED (c4f104b). Player now uses `hero_striker.glb` (10.8k tris, rigged, 41 anims). |
| `combat_robot.glb` | 25 MB | ✅ DELETED (057edba) — orphan. |
| `mech.glb` | 16 MB | ✅ DELETED (057edba) — orphan. |

`godot/assets/` went ~467 MB → 178 MB (-62%). The mech layer is now real, distinct models.
Remaining focus shifts to per-vehicle detail, structures/city, and the hijack vertical slice.

---

## 1. HAWCs / mechs — the roster (5 archetypes × 4 factions)

Base silhouette per archetype, then faction tint (Union tan / Darken grey / Merc blue / Scorp green).
Build **one excellent base per archetype**, then recolor. Target ~15–40k tris each, 2K PBR.

| # | Archetype | Silhouette | Current asset | State | Notes |
|---|-----------|-----------|---------------|-------|-------|
| 1 | **Player hero** (Union Sentry) | compact biped, auto-eject hatch | `warrior.glb` (243 MB) | 🔴 | Hero deserves the most detail (memory: "8K/every pixel" → 4K PBR). Build FIRST. |
| 2 | **A — Sentry** | compact biped, shoulder pods | `enemy_sentry.glb` (5.2 MB) | 🟡 | borrowed CC-BY; → Prowler/Talon/Ogre/Jinx by tint |
| 3 | **B — Tactical** | taller/bulkier biped | `enemy_tactical.glb` (6.5 MB) | 🟡 | the spec's known gap; → Stalker/Rampage/Minotaur/Predator |
| 4 | **C — Heavy** | 4–6-leg multipedal, big cannons | `enemy_heavy.glb` (13 MB) | 🟡 | → Lion(4-leg)/WidowMaker/Venom/Scorpion(6-leg) |
| 5 | **D — Support** | low wide tracked hull + turret | `enemy_support.glb` (8.2 MB) | 🟡 | → Titan/Boulder/Legionnaire/Stinger |
| 6 | **E — Hover** | arrowhead on glowing skirt, no legs | `enemy_hover.glb` (3.2 MB) | 🟡 | → Rapier/Vulture/Razor/Wasp |

Orphan mech files: DELETED 2026-08-27 (commit 057edba) — `combat_robot`, `mech`,
`prowler_hawc/mk2/mk3`, `hawc_heavy/hover/support/tactical` (~68 MB, all 0-ref). Still
present + referenced: `wr_hawk.glb` (refs=2), `gnome_assets.glb` (refs=1) — retire later.

**Faction tints** (from one base each) yield the full 19 + player. Do tints as a Godot shader
first (fast), bake to texture later.

---

## 2. On-foot / possession loop

| # | Asset | Current | State | Notes |
|---|-------|---------|-------|-------|
| 7 | **Pilot / infantry** (humanoid, 4 faction tints) | — | ⬜ | needed for eject-and-hijack; carries rifle + GASHR |
| 8 | **PRIF44 rifle** (hijack weapon) | — | ⬜ | brief exists: `design/HAWK_rifle_brief.md` |
| 9 | **GASHR launcher** (eject/steal tool) | — | ⬜ | |

---

## 3. Structures (from GAME_BIBLE — destructible bases)

Modular kit first (walls/pillars/panels/doors), then assemble named buildings.

| # | Asset | Current | State |
|---|-------|---------|-------|
| 10 | **Installation / HQ** (the thing you defend) | `installation.glb` | 🟡 borrowed/placeholder |
| 11 | Modular base kit (wall/pillar/door/panel) | — | ⬜ |
| 12 | Meson Tower | — | ⬜ |
| 13 | Shield Generator | — | ⬜ |
| 14 | Electro-chemical Power Plant | — | ⬜ |
| 15 | Rocket Towers (CHUM/UNKPA) | — | ⬜ |
| 16 | Sweep / Pop-Up Turret | — | ⬜ |
| 17 | Comms Array (LATLON) | — | ⬜ |
| 18 | Bridge + Bridge Control | — | ⬜ |
| 19 | The Citadel (campaign finale) | — | ⬜ |

---

## 4. Vehicles / ships (orbital + ground)

| # | Asset | Current | State | Notes |
|---|-------|---------|-------|-------|
| 20 | **Dropship** (ground landing) | `dropship.glb` | 🟢 DONE (memory) | bay doors still TODO |
| 21 | **Mothership** (orbital carrier) | `subship.glb`? built via `tools/build_ships.py` | 🟡 | de-faked, real GLB |
| 22 | **Sub-ship** (detaches, descends) | `subship.glb` | 🟡 | used in orbital_arrival |
| 23 | **HAWC pod** (drop capsule) | `hawc_pod.glb` | 🟡 | |
| 24 | **NASA rover** (POI) | `nasa_rover.glb` (8.1 MB) | 🟢 real NASA model | credit in CREDITS.md |

---

## 5. Environment / terrain / props

| # | Asset | Current | State | Notes |
|---|-------|---------|-------|-------|
| 25 | **Walkable Mars terrain** | HiRISE + scanned regolith | 🟢 DONE | real ~1m/px, landing-patch fixed |
| 26 | **Mars globe** (campaign map) | `imported/mars.glb` | 🟢 | planet layer |
| 27 | **Rocks** ×4 | `mars_rock_1..4.glb` | 🟢 real scanned | keep |
| 28 | **Crate** (supply/POI) | `mars_crate.glb` (2 MB) | 🟡 | |
| 29 | **Monolith** (POI) | `mars_monolith.glb` (9.2 MB) | 🟡 oversized | 9 MB for a slab = rebuild lean |
| 30 | Old desert/biome HD sets | `env_desert_hd`, `grass_hd`, `ice_hd`, `molten_hd` | 🔴 | pre-Mars leftovers; likely delete |
| 31 | CC0 dust / cloud / flag | `dust_cc0`, `cloud_cc0`, `flag_cc0` | 🟡 | atmosphere/vfx dressing |
| 32 | `gnome_assets.glb` (old HAWC+crates+terrain) | 1.2 MB | 🔴 | original placeholder set; retire |

---

## 6. Weapons / FX meshes (mostly shader/particle, minimal geo)

| # | Asset | Current | State |
|---|-------|---------|-------|
| 33 | Laser / projectile | `laser.tscn` | 🟢 exists |
| 34 | Muzzle flash / impact / explosion | procedural | 🟢 (verify quality in art-pass) |

---

## Build order (payoff-first)

1. **Player hero mech** (§1 #1) — replaces the 243 MB bomb, most-seen asset, gets top fidelity.
2. **5 enemy archetype bases** (§1 #2–6) — our own models replacing borrowed CC-BY; unlocks all 19 via tint.
3. **Faction tints** (Godot shader) — instant variety once bases exist.
4. **Installation + modular base kit** (§3 #10–11) — the defend objective + reusable structure pieces.
5. **Pilot + rifle + GASHR** (§2) — completes the possession loop visually.
6. **Structure set** (§3 #12–19) — mission variety / destructibles.
7. **Cleanup** — delete retired placeholders (§1 orphans, §5 #30/#32), shrink oversized (#29).

---

## Budget / conventions (so nothing balloons again)

- **Tris:** hero mech ≤ ~40k; enemy mechs ≤ ~25k; props ≤ ~5k; structures modular & instanced.
- **Textures:** hero 4K PBR; enemies/structures 2K; props 1K. No 243 MB single meshes — ever.
- **Export:** one Blender call → `.glb` into `godot/assets/`; +Y up, real-world metres, origin at feet/base.
- **Materials:** rough PBR in Blender, final tint/emissive via Godot shader (Blender is unstable).
- **Judge quality** only against NASA photos via `godot-art-pass`; don't fuss edges before breadth.

## Dead prototype scenes (found 2026-08-27 — user's call to remove)

`scenes/level1.tscn` + `scripts/level1.gd` and `scenes/tune.tscn` + `scripts/tune.gd` are
NOT reachable from the game (menu only routes to mission1 + planet). They're the only things
referencing `wr_hawk.glb` (2.5 MB) and `gnome_assets.glb` (1.2 MB). Safe to retire the scenes +
scripts + those two GLBs together (~3.7 MB) if you don't want them as prototype reference.
Left in place pending your decision — they're harmless dead code.
