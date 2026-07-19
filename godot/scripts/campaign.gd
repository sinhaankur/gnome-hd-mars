extends Node
## Campaign definition (autoload as "Campaign"). Holds the list of levels and tracks
## progression. Each level is a thin DATA config that the mission composes with the three
## engines — no bespoke scenes. All on Mars, but each level varies region, terrain,
## objective, waves and mood so they feel distinct.

# --- level configs. terrain_seed picks a different MOLA-style region feel via height
# scale + tint; objective is "defend" (survive waves) or "reach" (get to the beacon). ---
# Each level is DATA: region terrain, time of day, objective, and a wave script that
# names enemy TIERS (see enemy_tiers.gd). Difficulty escalates: early = scouts/soldiers,
# later = heavies and a boss. "region" selects a distinct real-HiRISE heightmap.
const LEVELS := [
	# THE ORIGINAL 1997 CAMPAIGN, replicated from the game bible: Sgt. Joshua Gant's
	# covert UIA mission across planet Ruhelen's four territories. Each territory
	# fields ITS faction's real machines (HawcSpecs) and carries its environmental
	# theme via a terrain palette. Machines first; look-and-feel polish comes later.
	{
		"id": 1, "name": "Reenlistment",
		"subtitle": "Darken Republic border — Phygos crisis",
		"region": "plains", "height_scale": 30.0, "day_start": 0.32,
		"objective": "defend", "faction": "darken",
		"waves": [
			{"count": 2, "tier": "scout"},
			{"count": 3, "tier": "soldier"},
			{"count": 2, "tier": "soldier"}, {"count": 1, "tier": "heavy"},
		],
		"brief": "Ten years retired, reactivated by Director Wilkins. Cross into the Darken Republic and hold the UIA staging post while your cover settles.",
	},
	{
		"id": 2, "name": "Rendezvous: Kylie",
		"subtitle": "Deep Darken desert, dawn",
		"region": "craters", "height_scale": 22.0, "day_start": 0.15,
		"objective": "reach", "faction": "darken",
		"waves": [
			{"count": 3, "tier": "scout"},
			{"count": 3, "tier": "soldier"},
		],
		"brief": "Sgt. Stephen Kylie — munitions, old friend — waits at the beacon. Darken patrols hunt the crossing. Reach him.",
	},
	{
		"id": 3, "name": "The Crossing",
		"subtitle": "Bendian Merc territory — ice fields",
		"region": "canyon", "height_scale": 46.0, "day_start": 0.7,
		"objective": "reach", "faction": "merc",
		"palette": {"low": Color(0.60, 0.64, 0.70), "mid": Color(0.70, 0.74, 0.79),
					"high": Color(0.84, 0.87, 0.91), "slope": Color(0.44, 0.47, 0.52)},
		"waves": [
			{"count": 3, "tier": "scout"},
			{"count": 2, "tier": "soldier"}, {"count": 2, "tier": "scout"},
		],
		"brief": "Merc land: ice, salvage, no auto-eject — their pilots fight to the death. Cross to Dr. Thane's position.",
	},
	{
		"id": 4, "name": "The Citadel",
		"subtitle": "Mesa Caracon, Merc stronghold",
		"region": "rugged", "height_scale": 40.0, "day_start": 0.5,
		"objective": "defend", "faction": "merc",
		"palette": {"low": Color(0.60, 0.64, 0.70), "mid": Color(0.70, 0.74, 0.79),
					"high": Color(0.84, 0.87, 0.91), "slope": Color(0.44, 0.47, 0.52)},
		"waves": [
			{"count": 4, "tier": "scout"},
			{"count": 3, "tier": "soldier"}, {"count": 2, "tier": "heavy"},
			{"count": 3, "tier": "soldier"}, {"count": 1, "tier": "boss"},
		],
		"brief": "Thane found it: tech atop Mesa Caracon that can neutralize the G-Nome. Take the Citadel's ground and hold while she extracts it.",
	},
	{
		"id": 5, "name": "Scorp Border",
		"subtitle": "Grassland frontier, dusk infiltration",
		"region": "canyon", "height_scale": 50.0, "day_start": 0.75,
		"objective": "reach", "faction": "scorp",
		"palette": {"low": Color(0.33, 0.40, 0.26), "mid": Color(0.41, 0.48, 0.31),
					"high": Color(0.54, 0.58, 0.38), "slope": Color(0.38, 0.34, 0.28)},
		"waves": [
			{"count": 4, "tier": "scout"},
			{"count": 4, "tier": "soldier"},
		],
		"brief": "Bypass the Scorp border in the tall grass. The team's fourth member waits inside: Major Jack Sheridan — the man who lost Pearl.",
	},
	{
		"id": 6, "name": "The Laboratory",
		"subtitle": "Scorp genetics facility",
		"region": "craters", "height_scale": 26.0, "day_start": 0.6,
		"objective": "defend", "faction": "scorp",
		"palette": {"low": Color(0.33, 0.40, 0.26), "mid": Color(0.41, 0.48, 0.31),
					"high": Color(0.54, 0.58, 0.38), "slope": Color(0.38, 0.34, 0.28)},
		"waves": [
			{"count": 5, "tier": "soldier"}, {"count": 2, "tier": "heavy"},
			{"count": 4, "tier": "heavy"},
		],
		"brief": "The G-Nome lab. Sheridan leads you in — then turns: Kylie taken, the creature stolen. Fight clear of the Scorp response.",
	},
	{
		"id": 7, "name": "Shalten Frontier",
		"subtitle": "Volcanic wastes — rogue Union forces",
		"region": "rugged", "height_scale": 34.0, "day_start": 0.85,
		"objective": "defend", "faction": "union",
		"palette": {"low": Color(0.24, 0.22, 0.22), "mid": Color(0.32, 0.29, 0.28),
					"high": Color(0.44, 0.38, 0.34), "slope": Color(0.16, 0.15, 0.16)},
		"waves": [
			{"count": 4, "tier": "soldier"},
			{"count": 3, "tier": "heavy"},
			{"count": 4, "tier": "soldier"}, {"count": 2, "tier": "heavy"},
		],
		"brief": "The Scorp now cooperate: stop Sheridan cloning the G-Nome. His rogue Union units hold the volcanic frontier. Destroy the recombination lab.",
	},
	{
		"id": 8, "name": "G-NOME",
		"subtitle": "Shalten caldera — the truth about Pearl",
		"region": "canyon", "height_scale": 50.0, "day_start": 0.9,
		"objective": "defend", "faction": "union",
		"palette": {"low": Color(0.24, 0.22, 0.22), "mid": Color(0.32, 0.29, 0.28),
					"high": Color(0.44, 0.38, 0.34), "slope": Color(0.16, 0.15, 0.16)},
		"waves": [
			{"count": 4, "tier": "soldier"}, {"count": 2, "tier": "heavy"},
			{"count": 3, "tier": "heavy"}, {"count": 1, "tier": "boss"},
			{"count": 1, "tier": "boss"},
		],
		"brief": "Kylie is dead. Run Sheridan down in the caldera. When the cargo bay breaks open, tranquilize what comes out — and read the barcode on its paw.",
	},
]

# --- TERRITORY MAP (planet layer). The globe now reads as RUHELEN: one territory
# marker per campaign mission, tracing Gant's route Darken → Merc → Scorp → Shalten.
# (Coordinates are real Mars features standing in for Ruhelen's regions.)
const TERRITORY_INFO := [
	{"latlon": Vector2(21.0, 6.0),     "place": "Darken Republic border"},
	{"latlon": Vector2(46.7, 117.5),   "place": "Darken deep desert"},
	{"latlon": Vector2(83.0, 313.0),   "place": "Merc ice fields"},
	{"latlon": Vector2(-35.0, 145.0),  "place": "Mesa Caracon"},
	{"latlon": Vector2(3.0, 154.7),    "place": "Scorp border grasslands"},
	{"latlon": Vector2(-6.5, 289.0),   "place": "Scorp genetics facility"},
	{"latlon": Vector2(18.65, 226.2),  "place": "Shalten Frontier"},
	{"latlon": Vector2(24.8, 196.0),   "place": "Shalten caldera"},
]
const RIVAL_HOLDINGS := [
	{"latlon": Vector2(18.65, 226.2), "place": "Olympus Mons"},
	{"latlon": Vector2(-42.4, 70.5),  "place": "Hellas Basin"},
	{"latlon": Vector2(8.4, 69.5),    "place": "Syrtis Major"},
	{"latlon": Vector2(24.8, 196.0),  "place": "Amazonis Planitia"},
]

var current_index := 0
var unlocked := 1          # how many levels the player has unlocked
var completed: Array = []  # per-level victory flags — drives territory ownership

func _ready() -> void:
	completed.resize(LEVELS.size())
	completed.fill(false)

func territory_status(i: int) -> String:
	# ownership drives marker color on the globe: player-held / contested / rival-held
	if i < completed.size() and completed[i]:
		return "player"
	if i < unlocked:
		return "contested"
	return "rival"

func level_count() -> int:
	return LEVELS.size()

func get_level(i: int) -> Dictionary:
	return LEVELS[clampi(i, 0, LEVELS.size() - 1)]

func current() -> Dictionary:
	return get_level(current_index)

func set_current(i: int) -> void:
	current_index = clampi(i, 0, LEVELS.size() - 1)

func complete_current() -> bool:
	# unlock the next level; returns true if there IS a next level
	if current_index < completed.size():
		completed[current_index] = true   # territory flips to player on the globe
	unlocked = maxi(unlocked, current_index + 2)
	if current_index + 1 < LEVELS.size():
		current_index += 1
		return true
	return false

func is_last() -> bool:
	return current_index >= LEVELS.size() - 1
