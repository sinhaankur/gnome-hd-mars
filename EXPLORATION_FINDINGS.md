# Exploration findings (code + design audit)

The game is MUCH more complete than the flat-terrain screenshot suggested. The gap is
presentation + which scene you boot, NOT missing mechanics.

## What's actually BUILT (verified in code)
- **Pillar 1 — the hijack loop works** (mission1.gd): dismount beside mech → camera to
  pilot on foot → GASHR (gashr.gd) arcs + hits enemy → enemy_ai.eject_pilot() → vacant
  hull joins "hijackable" → walk within BOARD_REACH → E → _steal() commandeers it.
  Possession = group membership (single source of truth). This is the signature mechanic.
- **Player HAWC** (hawc.gd, 323 lines): movement, torso-face-travel, jump/thrusters,
  weapon + cooldown, rockets, GASHR, muzzle flash, landing impact.
- **Enemies** (enemy_ai.gd): HP, real damage states (scorch + smoke past half), eject,
  wave counting, hunt-player.
- **Design is deep**: GDD (3 pillars), CAMPAIGN.md (20 missions / 4 campaigns, story:
  Gant + Kylie + the G-NOME weapon), GAME_BIBLE (20 vehicles w/ exact disc stats,
  structures, weapons).
- **Enemy models**: per-archetype CC-BY + our AI olive HAWC (sentry).
- **Terrain**: real HiRISE (mars_terrain.gd) + Perseverance-calibrated shader.

## The real gaps (presentation + polish)
1. TWO level scenes: `mission1.tscn` (full hijack loop) vs `level1.tscn` (simpler
   prototype — the flat one I screenshotted). Decide the canonical playable level.
2. Surface/lighting — FIXED in level1 (HiRISE + butterscotch). mission1 may need the same.
3. Player mech is a placeholder — Vanguard (pack) should be the hero.
4. Base is procedural placeholder (installation.gd) — colony kit should replace it.
5. The pilot-on-foot model is a plain capsule — needs a suited astronaut.

## Priority (my half, non-GPU)
- Make mission1 the canonical level + give it the fixed Mars surface/lighting.
- Wire pack assets (player=Vanguard, base=colony, terrain) when exported.
- Suited-astronaut pilot.

## AI image→3D quality finding (tested)
- Green HAWC (clean single-view photo) → GREAT mesh (sharp, recognizable).
- saviour-mech (busy multi-VIEW concept SHEET) → mushier (AI can't resolve callouts).
RULE: feed the AI CLEAN SINGLE-SUBJECT, SINGLE-VIEW images. Concept sheets degrade it.
→ Use hand-built rigged pack (Vanguard) for HERO assets; AI for quick enemy/gap-fill
  variety from clean renders.
