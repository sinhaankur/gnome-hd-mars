# Mars HAWC — Art Direction (the parameters every agent builds to)

This is the single source of truth for **how the world looks**. All 9 agents build to it; the
art-director rejects anything that drifts from it. Set deliberately, from the GDD's Pillar 4,
the user's calls ("Star Wars / space games have better design", "not cute", "AI-designed"), and
real references.

## The one-line identity
**Grim, grounded, hard sci-fi.** Weathered military hardware on a real, hostile Mars.
A place that wants you dead — not a toy box.

## NOT this ↔ THIS (the cute-vs-grim axis, settled)
| ✗ Avoid (too cute / wrong) | ✓ Target |
|---|---|
| Bright primary colours, candy palette | Desaturated olive/tan/steel + Mars butterscotch; colour only for faction tells & hazard markings |
| Smooth rounded "friendly" blobs (Kerbal, cartoon) | Hard-surface, angular, panel-lined, functional |
| Clean / spotless | Weathered: dust, grime, scratches, worn edges, heat-stain |
| Oversized googly details, mascot shapes | Real proportions, real mechanisms (pistons, vents, greeble that *does* something) |
| Flat shading, no surface story | PBR metal, edge wear, image-based reflections |

## "AI-designed" = crisp, modern, intentional
The user's "AI-designed" bar means: **clean modern industrial design, confident silhouettes,
nothing accidental** — like concept art / a modern AAA sci-fi game, not a hobby model. Every
shape reads as engineered. Reference language: *Star Wars* hardware, *The Expanse*, *Helldivers*,
*Armored Core*, *Titanfall*, SpaceX Starship. Elegant + utilitarian, never whimsical.

## Measurable parameters (so "good" is objective)
- **Palette:** base surfaces desaturated (saturation < ~0.25). Mars ground = butterscotch/tan
  measured vs `reference/real_mars/` (red is a mm-thin veneer, not lava-orange). Faction accent
  colours + hazard yellow are the only saturated hits.
- **Silhouette:** every hero asset must read as the right object in one glance, from any angle —
  asymmetry + a clear hero feature (cockpit / engine / maw), never a featureless primitive.
- **Surface:** panel-line breakup + edge wear + grime on every large face. No bare flat faces.
  Beveled edges (catch light) are mandatory on hard-surface.
- **Lighting:** hard low Mars key (honest values), image-based reflections on metal, real cast
  shadows. Grim/oppressive skies, not bright-blue cheer.
- **Scale:** real metres. A 7 m HAWC must feel 7 m — heavy, deliberate.

## Per-element direction (current)
- **HAWC mech:** the in-game `hero_striker.glb` (user-approved). Weathered olive military, reverse-jointed legs, decoupled torso. Use everywhere (game + cinematic).
- **Ships:** Starship-style lander (tall, stainless, hex heat-tiles, flaps, engine cluster, legs). Grounded, not cute. No smooth barrels.
- **Station:** industrial ISS-lineage — trusses, modules, arrays, greeble.
- **Mars surface:** discovery-based ecosystem (rocks, megaripples, dust devils, RSL) — see #1.

## How the team uses this
Every build is checked against this doc by the art-director before "done". If a thing looks
cute, clean, candy-coloured, or like a primitive, it fails here. Judge against the real
reference, never "looks fine to me."
