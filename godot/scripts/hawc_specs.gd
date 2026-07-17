extends RefCounted
class_name HawcSpecs
## HAWC SPECS — the complete 19-vehicle roster from the original game's LABTEXT.DAT
## (see reference/GAME_BIBLE.md), as a pure DATA library. This is the single source
## of truth for vehicle identity: factions, classes, real stats, weapon loadouts.
##
## OWNERSHIP RULE (user-directed): stats and names are replicated from the 1997 disc
## data we extracted; every MODEL is our OWN build, made to the quality bar of the
## reference files in design/ — reinterpretations, never copies.
##
## Unit conversions to game terms:
##   hp     = armor / 150          (player laser does 1 per hit)
##   move   = speed / 10           (m/s in-game)
##   scale  = height / 6.8         (Prowler = 1.0, our base mech size)
##
## Archetypes (silhouettes — see design/HAWC_VARIETY_SPEC.md):
##   sentry (compact biped) · tactical (tall biped) · heavy (multipedal) ·
##   support (tracked tank) · hover (skirted scout)

const FACTIONS := {
	# color language per design/HAWC_VARIETY_SPEC.md — silhouette=class, color=faction
	"union":  {"base": Color(0.45, 0.44, 0.32), "glow": Color(1.0, 0.6, 0.2),  "label": "Union"},
	"darken": {"base": Color(0.38, 0.39, 0.42), "glow": Color(1.0, 0.25, 0.2), "label": "Darken"},
	"merc":   {"base": Color(0.30, 0.38, 0.55), "glow": Color(0.3, 0.9, 1.0),  "label": "Bendian Merc"},
	"scorp":  {"base": Color(0.25, 0.38, 0.28), "glow": Color(0.4, 1.0, 0.3),  "label": "Scorp"},
}

const ROSTER := {
	# name           faction   archetype   speed  armor  height  mass   weapons
	"Talon":       {"faction": "darken", "arch": "sentry",   "speed": 75.0,  "armor": 1000, "height": 6.3,  "mass": 18.0, "weapons": ["CHUM rack x2", "RUPP laser x2"]},
	"Stalker":     {"faction": "darken", "arch": "tactical", "speed": 67.5,  "armor": 1500, "height": 7.9,  "mass": 23.0, "weapons": ["HOMP11 laser x2", "DASY gun x2"]},
	"Boulder":     {"faction": "darken", "arch": "support",  "speed": 68.0,  "armor": 1300, "height": 3.8,  "mass": 6.2,  "weapons": ["CHUM rack", "DASY gun"]},
	"Vulture":     {"faction": "darken", "arch": "hover",    "speed": 95.0,  "armor": 1600, "height": 2.9,  "mass": 3.4,  "weapons": ["WART", "DASY"]},
	"Prowler":     {"faction": "union",  "arch": "sentry",   "speed": 70.0,  "armor": 1600, "height": 6.8,  "mass": 19.0, "weapons": ["FLECH gun x2", "FIL30 laser x2"]},
	"Rampage":     {"faction": "union",  "arch": "tactical", "speed": 60.0,  "armor": 1200, "height": 7.5,  "mass": 24.1, "weapons": ["P2MEC x2", "TCREAP x2", "TCROCK+SAG5T rockets"]},
	"Lion":        {"faction": "union",  "arch": "heavy",    "speed": 90.0,  "armor": 2200, "height": 14.7, "mass": 57.0, "weapons": ["P2MEC x2", "TCREAP x2", "TCROCK+VISOM"]},
	"Rapier":      {"faction": "union",  "arch": "hover",    "speed": 100.0, "armor": 1900, "height": 2.7,  "mass": 3.0,  "weapons": ["ARCM", "TCREAP"]},
	"Titan":       {"faction": "union",  "arch": "support",  "speed": 72.0,  "armor": 800,  "height": 3.1,  "mass": 7.0,  "weapons": ["TCROCK", "TCREAP x2"]},
	"Ogre":        {"faction": "merc",   "arch": "sentry",   "speed": 85.0,  "armor": 1100, "height": 6.9,  "mass": 17.9, "weapons": ["RAID laser x2", "CHUM"]},
	"Minotaur":    {"faction": "merc",   "arch": "tactical", "speed": 72.0,  "armor": 1700, "height": 9.5,  "mass": 26.0, "weapons": ["RAID", "DASY x2", "SAG5T x2"]},
	"WidowMaker":  {"faction": "merc",   "arch": "heavy",    "speed": 45.0,  "armor": 1000, "height": 12.4, "mass": 22.3, "weapons": ["FLECH x2", "GAUS20"]},
	"Venom":       {"faction": "merc",   "arch": "heavy",    "speed": 31.5,  "armor": 1800, "height": 7.9,  "mass": 27.3, "weapons": ["RUP x2", "zWASP x2", "PUG+VISOM"]},
	"Legionnaire": {"faction": "merc",   "arch": "support",  "speed": 90.0,  "armor": 1200, "height": 4.1,  "mass": 12.0, "weapons": ["CHUM", "FLECH"]},
	"Razor":       {"faction": "merc",   "arch": "hover",    "speed": 103.5, "armor": 1400, "height": 3.7,  "mass": 4.3,  "weapons": ["TAR12", "TCREAP", "DASY"]},
	"Jinx":        {"faction": "scorp",  "arch": "sentry",   "speed": 56.25, "armor": 800,  "height": 6.3,  "mass": 17.2, "weapons": ["CETI x2", "zWASP x2", "SREM"]},
	"Predator":    {"faction": "scorp",  "arch": "tactical", "speed": 54.0,  "armor": 1700, "height": 8.9,  "mass": 20.7, "weapons": ["RAID x2", "zWASP x2", "HSSO"]},
	"Scorpion":    {"faction": "scorp",  "arch": "heavy",    "speed": 30.0,  "armor": 1900, "height": 8.6,  "mass": 36.4, "weapons": ["zWASP x2", "LRIP x2", "HSSO+SREM+VISOM"]},
	"Stinger":     {"faction": "scorp",  "arch": "support",  "speed": 64.0,  "armor": 1200, "height": 4.2,  "mass": 8.9,  "weapons": ["SREM", "UNKPA", "zWASP x2"]},
	"Wasp":        {"faction": "scorp",  "arch": "hover",    "speed": 90.0,  "armor": 1500, "height": 3.7,  "mass": 4.1,  "weapons": ["TAR12", "zWASP"]},
}

# Merc quirk from the original: NO auto-eject — their pilots go down with the hull
# (GASHR still ejects them; destruction doesn't leave survivors).
const NO_AUTO_EJECT := ["merc"]

static func get_spec(name: String) -> Dictionary:
	return ROSTER.get(name, ROSTER["Prowler"])

static func hp(name: String) -> int:
	return int(round(get_spec(name)["armor"] / 150.0))

static func move(name: String) -> float:
	return get_spec(name)["speed"] / 10.0

static func scale(name: String) -> float:
	# clamped so even the 14.7 m Lion stays playable on our terrain
	return clampf(get_spec(name)["height"] / 6.8, 0.8, 1.9)

static func faction_of(name: String) -> Dictionary:
	return FACTIONS.get(get_spec(name)["faction"], FACTIONS["union"])

static func by_faction(fac: String) -> Array:
	var out: Array = []
	for n in ROSTER:
		if ROSTER[n]["faction"] == fac:
			out.append(n)
	return out
