# Mars HAWC — Asset Audit (every object in the game)

The full inventory of what the game loads, categorized and graded against `ART_DIRECTION.md`
(grim, grounded, hard sci-fi; real, not cute). Total live GLBs after the Nov 26 cleanup: ~27,
~95 MB (was 131 MB — 5 orphans removed). Grade: ✅ good · 🔶 ok, needs a pass · ⚠️ weak/suspect.

## Player & pilot
| Asset | MB | Role | Grade | Note |
|---|---|---|---|---|
| hero_striker.glb | 9.3 | Player HAWC (rigged, 41 anims) | ✅ | User-approved ("i like this hawck"). Use everywhere. |
| pilot_human.glb | 7.6 | On-foot pilot (armored trooper) | ✅ | Real rigged Halo-style figure; upright, Walk clip works. |
| wr_hawk.glb | 2.4 | Enemy HAWC visual (level1 + tune) | ✅ | Confirmed in use — NOT an orphan. Lean enemy model. |
| hawc_green_ai.glb | 1.7 | AI-gen olive HAWC (sentry enemy base) | 🔶 | Lower-detail; fine as an enemy. |
| hawc_pod.glb | 0.06 | Cockpit pod | 🔶 | Tiny; used in arrival. |

## Enemy roster (5 archetypes, faction-tinted)
| Asset | MB | Role | Grade | Note |
|---|---|---|---|---|
| enemy_sentry.glb | 5.2 | Sentry archetype | ✅ | Distinct silhouette. |
| enemy_tactical.glb | 6.4 | Tactical defense | ✅ | |
| enemy_heavy.glb | 7.2 | Heavy (spider tank) | ✅ | Freshly rebuilt. |
| enemy_hover.glb | 7.1 | Hover tank | ✅ | Freshly rebuilt. |
| enemy_support.glb | 8.2 | Support | 🔶 | Heaviest enemy — check poly budget. |

## Ships & station (arrival / cinematic)
| Asset | MB | Role | Grade | Note |
|---|---|---|---|---|
| mg01_orbital_station.glb | 2.2 | In-game mothership/station | ✅ | MG-series, wired via orbital_ships.gd. |
| dropship.glb | 0.2 | Ground dropship | 🔶 | Reads ok; rejected the web barrel version. |
| subship.glb | 0.1 | Descent sub-ship (in-game) | 🔶 | Web cinematic uses the new Starship-style lander (docs/assets). |

## Mars world objects (props, POIs, terrain kit)
| Asset | MB | Role | Grade | Note |
|---|---|---|---|---|
| mars_rock_1..4.glb | 0.9×4 | Hero scatter rocks | ✅ | Real scanned; the new MarsScatter adds procedural rocks too. |
| mars_crate.glb | 1.9 | Supply crate prop | ✅ | |
| mars_monolith.glb | 9.1 | Monolith POI | ⚠️ | 9 MB for a monolith is heavy — decimate. |
| nasa_rover.glb | 8.1 | Curiosity-style rover POI | ✅ | Real NASA model; hero POI. |
| mg05_survey_rover — REMOVED | — | — | — | Orphan, deleted. |
| shuttle_wreck.glb | 5.2 | Crash-site POI (prologue) | ✅ | |
| astronaut_fallen.glb | 3.9 | Fallen-astronaut POI (prologue) | ✅ | Story beat. |
| installation (procedural) | — | The base you defend/take | ✅ | Built in scripts/installation.gd (old GLB removed). |
| env_desert_hd / grass_hd / ice_hd / molten_hd | 0.7×4 | Biome ground kits (Ruhelen themes) | 🔶 | Legacy biome themes; Mars is the focus now. |
| dust_cc0.glb | 0.03 | Dust billboard | ✅ | Plus the new MarsDustDevil system. |
| gnome_assets.glb | 1.2 | Misc kit atlas | 🔶 | Audit contents. |

## Terrain data (not GLB)
Real HiRISE heightmaps: mars_plains/rugged/canyon/craters.png + mars_height.png (Candor Chasma,
~1 m/px). Ground material set: mars_ground_albedo/normal/rough.png (calibrated to Perseverance).
Plus the 4 shipped ecosystem systems (rock scatter, megaripples, dust devils, RSL).

## Priority fix list (worst first, for the loop)
1. ⚠️ **mars_monolith.glb (9 MB)** — decimate; a monolith shouldn't cost more than the hero mech.
2. 🔶 **wr_hawk.glb** — confirm orphan vs hero_striker; remove if dead.
3. 🔶 **enemy_support.glb (8.2 MB)** — poly budget check.
4. 🔶 **Legacy Ruhelen biome kits** (grass/ice/molten_hd) — Mars-only now? Archive if unused.
5. In-game visual tuning of the 4 ecosystem systems + 3rd-person camera (needs a human to run Godot).

## Removed this audit (orphans, 36 MB)
hero_hawc.glb, mg04_ground_station.glb, pilot_trooper.glb, mg05_survey_rover.glb, installation.glb.
