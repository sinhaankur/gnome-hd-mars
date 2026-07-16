extends RefCounted
class_name EnemyTiers
## ENEMY TIERS — data library of enemy archetypes. Each tier is DATA (stats + look), so
## adding/tuning enemy types is a config change, not new code. Waves reference a tier by
## key; EnemyEngine reads the tier to set hp/speed/fire-rate/scale/tint.
##
## Usage:  var t := EnemyTiers.get_tier("heavy")   # -> Dictionary of stats

const TIERS := {
	# key        hp  scale  move  fire_cd  detect  tint       name
	"scout":   {"hp": 3, "scale": 0.85, "move": 9.0, "fire_cd": 1.8, "detect": 90.0, "tint": "merc",   "name": "Scout"},
	"soldier": {"hp": 6, "scale": 1.0,  "move": 6.0, "fire_cd": 1.4, "detect": 80.0, "tint": "darken", "name": "Soldier"},
	"heavy":   {"hp": 12,"scale": 1.35, "move": 4.0, "fire_cd": 1.1, "detect": 85.0, "tint": "darken", "name": "Heavy"},
	"boss":    {"hp": 26,"scale": 1.7,  "move": 3.5, "fire_cd": 0.8, "detect": 110.0,"tint": "scorp",  "name": "Warlord"},
}

static func get_tier(key: String) -> Dictionary:
	return TIERS.get(key, TIERS["soldier"])

static func has(key: String) -> bool:
	return TIERS.has(key)
