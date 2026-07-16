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
	{
		"id": 1, "name": "Operation Red Wall",
		"subtitle": "Northern Plains, Arabia Terra",
		"region": "plains", "height_scale": 30.0, "day_start": 0.32,
		"objective": "defend",
		"waves": [
			{"count": 2, "tier": "scout"},
			{"count": 3, "tier": "soldier"},
			{"count": 2, "tier": "soldier"}, {"count": 1, "tier": "heavy"},
		],
		"brief": "AREX scouts probe Red Wall, then the line units move up. Hold the installation.",
	},
	{
		"id": 2, "name": "Dust Run",
		"subtitle": "Utopia Planitia crossing",
		"region": "craters", "height_scale": 22.0, "day_start": 0.15,   # dawn
		"objective": "reach",
		"waves": [
			{"count": 3, "tier": "scout"},
			{"count": 3, "tier": "soldier"},
		],
		"brief": "Reach the forward beacon across open ground. Fast scout patrols will harass you.",
	},
	{
		"id": 3, "name": "The Chasma",
		"subtitle": "Valles Marineris rim",
		"region": "canyon", "height_scale": 46.0, "day_start": 0.7,     # late afternoon
		"objective": "defend",
		"waves": [
			{"count": 3, "tier": "soldier"},
			{"count": 2, "tier": "heavy"},
			{"count": 4, "tier": "soldier"}, {"count": 1, "tier": "heavy"},
		],
		"brief": "A rugged canyon-rim outpost. Heavies are inbound — terrain is broken, use your jetpack.",
	},
	{
		"id": 4, "name": "Broken Ridge",
		"subtitle": "Highland ridgeline, midday",
		"region": "rugged", "height_scale": 40.0, "day_start": 0.5,     # harsh noon light
		"objective": "defend",
		"waves": [
			{"count": 4, "tier": "scout"},
			{"count": 3, "tier": "soldier"}, {"count": 2, "tier": "heavy"},
			{"count": 5, "tier": "soldier"}, {"count": 2, "tier": "heavy"},
		],
		"brief": "A relay station on a broken ridge. Fast probes first, then a heavy column. Hold it.",
	},
	{
		"id": 5, "name": "Cold Trench",
		"subtitle": "Frozen chasm floor, dawn",
		"region": "canyon", "height_scale": 50.0, "day_start": 0.12,    # cold dawn
		"objective": "reach",
		"waves": [
			{"count": 4, "tier": "scout"},
			{"count": 4, "tier": "soldier"},
			{"count": 2, "tier": "heavy"}, {"count": 3, "tier": "soldier"},
		],
		"brief": "Push through the trench to the extraction beacon. They'll try to pin you in the cold.",
	},
	{
		"id": 6, "name": "The Foundry",
		"subtitle": "AREX staging ground",
		"region": "craters", "height_scale": 26.0, "day_start": 0.6,
		"objective": "defend",
		"waves": [
			{"count": 5, "tier": "soldier"}, {"count": 2, "tier": "heavy"},
			{"count": 4, "tier": "heavy"},
			{"count": 6, "tier": "soldier"}, {"count": 3, "tier": "heavy"},
		],
		"brief": "Strike their forward foundry. Expect heavy resistance — this is where they build.",
	},
	{
		"id": 7, "name": "Last Light",
		"subtitle": "Polar approach, dusk",
		"region": "rugged", "height_scale": 34.0, "day_start": 0.85,    # dusk into night
		"objective": "defend",
		"waves": [
			{"count": 4, "tier": "soldier"},
			{"count": 3, "tier": "heavy"},
			{"count": 4, "tier": "soldier"}, {"count": 2, "tier": "heavy"}, {"count": 1, "tier": "boss"},
		],
		"brief": "The final push at nightfall — everything they have, led by a Warlord. Do not let them pass.",
	},
]

# --- TERRITORY MAP (planet layer). Each level is a territory at its REAL location on
# Mars (lat°, east-lon°) — the globe scene places markers from these. RIVAL_HOLDINGS are
# non-mission strongholds that dress the map so the war reads planet-wide.
const TERRITORY_INFO := [
	{"latlon": Vector2(21.0, 6.0),     "place": "Arabia Terra"},
	{"latlon": Vector2(46.7, 117.5),   "place": "Utopia Planitia"},
	{"latlon": Vector2(-6.5, 289.0),   "place": "Candor Chasma, Valles Marineris"},
	{"latlon": Vector2(-35.0, 145.0),  "place": "Terra Cimmeria highlands"},
	{"latlon": Vector2(83.0, 313.0),   "place": "Chasma Boreale, north pole"},
	{"latlon": Vector2(3.0, 154.7),    "place": "Elysium Planitia"},
	{"latlon": Vector2(-83.0, 160.0),  "place": "Planum Australe, south pole"},
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
