# Sci-Fi Pack → Mars HAWC integration plan

Your own pack (rigged, 4K, game-ready — beats AI gap-fillers). Only HeavyWalker +
MarsRover were exported so far. Export the rest from the pack .py builds, drop in
~/Downloads, and I wire per this map.

## Exports needed (GLB) → game asset + role
| Pack asset | Export as | Game file | Wire into |
|---|---|---|---|
| **Vanguard** (MDL-02, 50k, 37-joint) | vanguard.glb | godot/assets/vanguard.glb | PLAYER HAWC (hawc.gd / hawc_specs) — jointed hands = hero |
| **Mars Terrain** (MDL-03, 240m, 4K, flat build zone) | mars_terrain_hd.glb | godot/assets/mars_terrain_hd.glb | level1 ground (option: use instead of/with HiRISE) |
| **HabDome** | hab_dome.glb | godot/assets/base/hab_dome.glb | base cluster |
| **HubDome** (5 airlocks) | hub_dome.glb | " | base centre |
| **Greenhouse** | greenhouse.glb | " | base (green domes) |
| **PodLarge/Small** | pod_lg.glb/pod_sm.glb | " | base |
| **PodTunnel / Tunnel** | tunnel.glb | " | base connectors |
| **SolarArray** | solar_array.glb | " | base power |
| **LandingPad** | landing_pad.glb | " | dropship LZ |
| **CommsTower** | comms_tower.glb | " | base |
| **TankFarm / Container** | tank.glb / container.glb | " | base props |

## Wiring targets (where in code)
- Player HAWC model: `godot/scripts/hawc.gd` / `hawc_specs.gd` (swap model path → vanguard.glb)
- Base/colony: build a `base_cluster` in `level1.gd` or `installation.gd` using the kit
  pieces (hub centre + spokes → domes, per MDL-04B star layout), placed on the flattened
  build zone of the terrain.
- Terrain: `level1.gd` `_build_environment` (MarsTerrain already wired; pack terrain is an
  alternative — the pack's "flattened build zone" is ideal for seating the colony).
- Normalize mechs to class height (Vanguard 8.39m) like the enemy pipeline.
- Credit: add pack rows to CREDITS.md (own originals).

## Note
These supersede the AI batch for anything they cover. AI stays for gap-fills only.
