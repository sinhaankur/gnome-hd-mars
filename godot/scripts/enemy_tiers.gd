extends RefCounted
class_name EnemyTiers
## ENEMY TIERS — maps the campaign's escalation tiers onto REAL roster vehicles from
## HawcSpecs (the LABTEXT.DAT data). hp/move/scale come from the real specs; only
## combat pacing (fire rate, detection) stays hand-tuned here. Waves reference a tier
## by key; EnemyEngine reads the tier to set everything.
##
## Usage:  var t := EnemyTiers.get_tier("heavy")   # -> Dictionary of stats

# preload (not the global class name) so CLI runs never depend on the class cache
const Specs := preload("res://scripts/hawc_specs.gd")

const TIERS := {
	# tier -> which roster vehicle fields it + pacing. AREX fields captured/franchised
	# hulls from every faction, so the tint follows the vehicle's original faction.
	"scout":   {"vehicle": "Talon",    "fire_cd": 1.8, "detect": 90.0},
	"soldier": {"vehicle": "Stalker",  "fire_cd": 1.4, "detect": 80.0},
	"heavy":   {"vehicle": "Minotaur", "fire_cd": 1.1, "detect": 85.0},
	"boss":    {"vehicle": "Scorpion", "fire_cd": 0.8, "detect": 110.0},
}

# tier -> silhouette class, so any faction can field its own machine for a tier
const TIER_ARCH := {"scout": "sentry", "soldier": "tactical", "heavy": "heavy", "boss": "heavy"}

static func get_tier(key: String, faction: String = "") -> Dictionary:
	var t: Dictionary = TIERS.get(key, TIERS["soldier"])
	var v: String = t["vehicle"]
	# territory campaigns field THAT faction's machines: pick its vehicle of the
	# tier's archetype (Darken scout = Talon, Merc scout = Ogre, Scorp = Jinx…)
	if faction != "":
		var arch: String = TIER_ARCH.get(key, "sentry")
		var pool: Array = []
		for n in Specs.by_faction(faction):
			if Specs.get_spec(n)["arch"] == arch:
				pool.append(n)
		if not pool.is_empty():
			v = pool[0] if key != "boss" else pool[-1]
	var spec: Dictionary = Specs.get_spec(v)
	return {
		"hp": Specs.hp(v),
		"scale": Specs.scale(v),
		"move": Specs.move(v),
		"fire_cd": t["fire_cd"],
		"detect": t["detect"],
		"tint": spec["faction"],
		"name": v,
	}

static func has(key: String) -> bool:
	return TIERS.has(key)
