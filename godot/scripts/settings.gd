extends Node
## Global settings singleton (autoload as "Settings").
## Loads/saves player preferences and applies them. Simple + intuitive:
## every setting has a sane default and takes effect immediately.

const PATH := "user://gnome_settings.cfg"

var master_volume: float = 0.8       # 0..1
var mouse_sensitivity: float = 1.0   # multiplier
var day_length_sec: float = 1200.0   # one Mars sol in seconds — 20 min so the light
                                     # EVOLVES over a mission instead of time-lapsing
var high_detail: bool = true         # SSAO/SSIL/SSR/glow on
var fullscreen: bool = false

func _ready() -> void:
	_ensure_input_map()   # guarantee WASD/arrows/fire/jump are bound (project.godot may not load them)
	load_settings()
	apply_all()

func _ensure_input_map() -> void:
	# Bind keys in CODE so movement never depends on project.godot parsing.
	# Each action gets its primary key + an arrow-key/alt fallback.
	var binds := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back":    [KEY_S, KEY_DOWN],
		"turn_left":    [KEY_A, KEY_LEFT],
		"turn_right":   [KEY_D, KEY_RIGHT],
		"jump":         [KEY_SHIFT],
		"fire":         [KEY_SPACE],
		"interact":     [KEY_E],     # exit HAWC / commandeer a vacant one (G-NOME loop)
		"gashr":        [KEY_Q],     # non-lethal ejector launcher
	}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		# only (re)bind if the action has no key events yet
		var has_key := false
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				has_key = true
				break
		if has_key:
			continue
		for kc in binds[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = kc
			ev.keycode = kc
			InputMap.action_add_event(action, ev)
	# fire also on left mouse button
	var has_mb := false
	for e in InputMap.action_get_events("fire"):
		if e is InputEventMouseButton:
			has_mb = true
	if not has_mb:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", mb)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	day_length_sec = cfg.get_value("world", "day_length_sec", day_length_sec)
	high_detail = cfg.get_value("video", "high_detail", high_detail)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("world", "day_length_sec", day_length_sec)
	cfg.set_value("video", "high_detail", high_detail)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)

func apply_all() -> void:
	apply_volume()
	apply_fullscreen()

func apply_volume() -> void:
	var db := linear_to_db(clampf(master_volume, 0.0001, 1.0))
	if master_volume <= 0.001:
		db = -80.0
	AudioServer.set_bus_volume_db(0, db)

func apply_fullscreen() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
