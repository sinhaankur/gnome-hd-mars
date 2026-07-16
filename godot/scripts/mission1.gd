extends Node3D
## LEVEL — Mars, "Operation Red Wall": defend the installation.
##
## This is a THIN level: it composes the three engines and wires their events.
##   - EnvironmentEngine : the Mars world (terrain, sun, scatter, installation)
##   - HAWC (player)     : the player mech (hawc.gd) + follow camera
##   - Enemies           : rival-nation mechs (enemy_ai.gd)
## The level asks the Environment where the ground is; it doesn't raycast itself.

# User-chosen mech: Oscar Creativo "Bot Mecha Warrior" (warrior.glb) — 50k tris,
# 57 textures, rigged with a "Motion" walk anim. Stands at identity rotation,
# native ~2.5u tall, feet at y=0. The user prefers this over any custom mech.
const MECH_PATH := "res://assets/warrior.glb"
const MECH_SCALE := 2.8           # ~2.5u model -> ~7m tall
const MECH_FOOT_LIFT := 0.0
# Model face orientation vs movement. 0 = faces forward (model +Z = body +Z = movement dir).
# Flip to PI if it ever reads backward. Single source of truth so it's one edit to fix.
const MECH_FACE_FLIP := 0.0

var env: EnvironmentEngine
var enemies: EnemyEngine
var explore: Exploration
var _hud: GameHUD
var _level: Dictionary = {}
var _discovery_text := ""
var _discovery_timer := 0.0
var _player: CharacterBody3D
var _cam: Camera3D
var _obj_label: Label
var _status_label: Label
var _over := false
var _wave_text := "Waiting for hostiles…"
var _base_hp := 100.0                 # installation armor; enemies erode it when close
const BASE_ATTACK_RANGE := 22.0       # an enemy within this range damages the base
const BASE_DPS := 6.0                 # armor lost per second per attacking enemy
var _kills := 0                       # enemies destroyed (for the end screen)
var _elapsed := 0.0                   # mission time
var _alarm_timer := 0.0               # throttle the base-under-attack alarm
var _dmg_flash: ColorRect             # red screen flash on player hit
var _warn_label: Label                # "UNDER ATTACK" warning
var _discovery_label: Label           # exploration discovery notice
var _last_health := 100               # to detect when the player takes damage

func _ready() -> void:
	# --- read the current level config from the Campaign (thin data drives everything) ---
	var cmp := get_node_or_null("/root/Campaign")
	_level = cmp.current() if cmp else {
		"name": "Operation Red Wall", "subtitle": "Northern Plains",
		"height_scale": 34.0, "day_start": 0.32, "objective": "defend",
		"waves": [ {"count": 2, "hp": 5}, {"count": 3, "hp": 6}, {"count": 4, "hp": 7} ] }

	# --- ambient wind + atmospheric music (night levels = tenser mood) ---
	var audio := get_node_or_null("/root/Audio")
	if audio:
		audio.play_ambient()
		var ds: float = _level.get("day_start", 0.32)
		audio.play_music("tense" if (ds > 0.7 or ds < 0.2) else "calm")

	# --- Environment Engine: owns terrain, sun, scatter, installation ---
	env = EnvironmentEngine.new()
	env.name = "EnvironmentEngine"
	env.world_size = 400.0
	env.height_scale = _level.get("height_scale", 34.0)   # per-level terrain relief
	env.day_start = _level.get("day_start", 0.32)          # per-level time of day
	env.region = _level.get("region", "")                  # per-level MOLA region heightmap
	env.installation_pos = Vector3(0, 0, -180)
	env.installation_pad_radius = 32.0
	add_child(env)

	# --- HAWC Engine: the player mech + camera ---
	_player = _build_hawc(Vector3(0, 30, 160))
	_cam = _build_camera(_player)
	_player.camera = _cam

	# --- Enemy Engine: the wave director, loaded with THIS level's wave script ---
	enemies = EnemyEngine.new()
	enemies.name = "EnemyEngine"
	if _level.has("waves"):
		enemies.waves = _level["waves"]
	add_child(enemies)
	enemies.configure(env, _player, MECH_PATH, MECH_SCALE)
	enemies.wave_started.connect(_on_wave_started)
	enemies.wave_cleared.connect(_on_wave_cleared)
	enemies.mission_won.connect(_on_mission_won)
	enemies.enemy_destroyed_signal.connect(func(): _kills += 1)

	_build_hud()

	# --- combat HUD: crosshair, armor bars, enemy health bars, hit markers, radar ---
	_hud = GameHUD.new()
	add_child(_hud)
	_hud.setup(_player, env, func(): return _base_hp)

	# --- pause menu (ESC): Resume / Restart / Settings / Quit to menu ---
	var pause := CanvasLayer.new()
	pause.set_script(load("res://scripts/pause_menu.gd"))
	add_child(pause)

	# --- Exploration: discoverable points of interest across Mars ---
	explore = Exploration.new()
	explore.name = "Exploration"
	add_child(explore)
	explore.configure(env)
	explore.poi_discovered.connect(_on_poi_discovered)

	# once terrain physics is live, snap the player onto the surface and start waves.
	# Connect the signal AND poll as a fallback (the emit can race the level's _ready).
	env.ready_built.connect(_on_env_ready)
	env.day_phase_changed.connect(_on_day_phase)
	_env_ready_fallback()

func _env_ready_fallback() -> void:
	for _i in range(12):
		await get_tree().physics_frame
	if not _env_setup_done:
		_on_env_ready()

var _env_setup_done := false

func _on_env_ready() -> void:
	if _env_setup_done:
		return
	_env_setup_done = true
	env.place_on_ground(_player, 1.0)
	explore.populate()   # scatter points of interest on the walkable surface
	# play the intro cinematic (dropship delivers the mech) + briefing card, THEN assault
	var intro := MissionIntro.new()
	add_child(intro)
	intro.finished.connect(func(): enemies.start())
	intro.play(_level, env, _cam, _player)

func _on_poi_discovered(poi_name: String, description: String, index: int, total: int) -> void:
	_discovery_text = "SITE SURVEYED %d/%d — %s\n%s" % [index, total, poi_name, description]
	_discovery_timer = 6.0
	var sfx := get_node_or_null("/root/Sfx")
	if sfx:
		sfx.ui()

func _on_wave_started(index: int, total: int, count: int) -> void:
	_wave_text = "CONTACT — wave %d of %d · %d hostiles" % [index + 1, total, count]
	# drop the freshly spawned enemies onto the surface + wire their hit markers
	for e in get_tree().get_nodes_in_group("enemies"):
		env.place_on_ground(e, 2.0)
		if e.has_signal("hit_registered") and not e.hit_registered.is_connected(_on_enemy_hit):
			e.hit_registered.connect(_on_enemy_hit)

func _on_enemy_hit() -> void:
	if _hud:
		_hud.flash_hit()

func _on_wave_cleared(index: int) -> void:
	_wave_text = "Wave %d cleared — regroup" % [index + 1]

func _on_mission_won() -> void:
	_end(true)

func _on_day_phase(phase: String) -> void:
	# hook for later: enemies bolder at night, etc. For now just note it on the HUD.
	pass

# ---------------------------------------------------------------- HAWC (player)
func _build_hawc(pos: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "PlayerHAWC"
	body.set_script(load("res://scripts/hawc.gd"))

	var visual := Node3D.new()
	visual.name = "Visual"   # hawc.gd applies recoil to this node
	var scene: PackedScene = load(MECH_PATH)
	var mech_model: Node = null
	if scene:
		var hawk := scene.instantiate()
		hawk.scale = Vector3.ONE * MECH_SCALE
		# MECH_FACE_FLIP tunes which way the model faces relative to movement. The warrior
		# model's face is its local +Z; the body's +Z is the movement direction (atan2 in
		# hawc.gd), so at identity the face already points forward. Exposed as a constant so
		# it's a one-line change if the model ever reads backward in-game.
		hawk.rotation.y = MECH_FACE_FLIP
		visual.add_child(hawk)
		mech_model = hawk
	visual.position.y = MECH_FOOT_LIFT
	body.add_child(visual)

	# animation state machine: walk when moving, idle when stopped (no sliding)
	if mech_model:
		var anim := MechAnimator.new()
		body.add_child(anim)
		anim.setup(mech_model)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.6
	cap.height = 6.0
	col.shape = cap
	col.position.y = 3.4
	body.add_child(col)

	# Muzzles at the front of the mech at arm height, pointing FORWARD (-Z = mech facing).
	# Positioned in front (-Z) so shots leave from ahead of the chest, not the sides.
	var ml := Node3D.new(); ml.name = "MuzzleL"; ml.position = Vector3(-1.8, 4.2, -3.0); body.add_child(ml)
	var mr := Node3D.new(); mr.name = "MuzzleR"; mr.position = Vector3(1.8, 4.2, -3.0); body.add_child(mr)

	body.position = pos
	add_child(body)
	body.connect("died", Callable(self, "_on_player_died"))
	return body

func _build_camera(target: Node3D) -> Camera3D:
	var cam := Camera3D.new()
	cam.set_script(load("res://scripts/follow_camera.gd"))
	cam.target_path = target.get_path()
	cam.current = true
	# FOV is owned by follow_camera.gd (base_fov + speed widen)
	add_child(cam)
	return cam

# ---------------------------------------------------------------- HUD
func _build_hud() -> void:
	var cl := CanvasLayer.new()
	var title := Label.new()
	var lvl_name: String = _level.get("name", "Operation Red Wall")
	var lvl_sub: String = _level.get("subtitle", "")
	var obj: String = "Defend the installation" if _level.get("objective", "defend") == "defend" else "Reach the beacon"
	title.text = "MARS — %s · %s\n%s   ·   CLICK look · WASD move · SHIFT jetpack · SPACE fire · V camera · TAB cursor · ESC pause" % [
		lvl_name.to_upper(), lvl_sub, obj]
	title.position = Vector2(16, 12)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 0.9))
	cl.add_child(title)
	# controls hint doesn't squat on screen: fade it out once the player is oriented
	var fade := create_tween()
	fade.tween_interval(10.0)
	fade.tween_property(title, "modulate:a", 0.0, 1.5)

	# telemetry tone: dim warm amber, like cockpit readouts — not bright white UI text
	_obj_label = Label.new()
	_obj_label.position = Vector2(16, 56)
	_obj_label.add_theme_font_size_override("font_size", 16)
	_obj_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.50, 0.92))
	cl.add_child(_obj_label)

	_status_label = Label.new()
	_status_label.position = Vector2(16, 84)
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.50, 0.92))
	cl.add_child(_status_label)

	# red screen-flash overlay for player damage (starts invisible)
	_dmg_flash = ColorRect.new()
	_dmg_flash.color = Color(1.0, 0.1, 0.1, 0.0)
	_dmg_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dmg_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_dmg_flash)

	# exploration discovery notice (bottom-left) — same telemetry tone
	_discovery_label = Label.new()
	_discovery_label.position = Vector2(16, 620)
	_discovery_label.add_theme_font_size_override("font_size", 16)
	_discovery_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 0.9))
	cl.add_child(_discovery_label)

	# centered flashing warning — plain words, no emoji decoration
	_warn_label = Label.new()
	_warn_label.text = "INSTALLATION UNDER ATTACK"
	_warn_label.add_theme_font_size_override("font_size", 28)
	_warn_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	_warn_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_warn_label.position = Vector2(-230, 130)
	_warn_label.visible = false
	cl.add_child(_warn_label)
	add_child(cl)

func _process(delta: float) -> void:
	if _over or _player == null or not is_instance_valid(_player) or env == null:
		return
	_elapsed += delta
	var alive: int = enemies.enemies_alive() if enemies else 0

	# exploration: discover nearby points of interest, show the notice, then fade it
	if explore:
		explore.check(_player.global_position)
	if _discovery_timer > 0.0:
		_discovery_timer -= delta
		_discovery_label.text = _discovery_text
	else:
		_discovery_label.text = "SURVEY %d/%d" % [
			explore.found_count(), explore.total()] if explore else ""

	# player-damage screen flash: trigger when health drops, then fade out
	if _player.health < _last_health:
		_dmg_flash.color.a = 0.45
	_last_health = _player.health
	if _dmg_flash.color.a > 0.0:
		_dmg_flash.color.a = maxf(0.0, _dmg_flash.color.a - delta * 1.2)

	# enemies within range of the installation erode its armor
	var attackers := 0
	if env.installation:
		var base_pos: Vector3 = env.installation.global_position
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.global_position.distance_to(base_pos) < BASE_ATTACK_RANGE:
				attackers += 1
		# flashing UNDER ATTACK warning
		_warn_label.visible = attackers > 0 and (int(_elapsed * 3.0) % 2 == 0)
		if attackers > 0:
			_base_hp = maxf(0.0, _base_hp - BASE_DPS * attackers * delta)
			_alarm_timer -= delta
			if _alarm_timer <= 0.0:
				_alarm_timer = 1.5
				var sfx := get_node_or_null("/root/Sfx")
				if sfx:
					sfx.alarm()
			if _base_hp <= 0.0:
				_on_base_destroyed()

	_obj_label.text = "DEFEND THE INSTALLATION · %s · hostiles: %d\nBASE ARMOR: %d%%   ·   YOUR ARMOR: %d%%" % [
		_wave_text, alive, int(_base_hp), _player.health]

func _on_base_destroyed() -> void:
	_end(false)

func _on_player_died() -> void:
	_end(false)

func _end(victory: bool) -> void:
	if _over:
		return
	_over = true
	var mins := int(_elapsed) / 60
	var secs := int(_elapsed) % 60
	var stats := "Enemies destroyed: %d      Time: %d:%02d      Base armor: %d%%" % [
		_kills, mins, secs, int(_base_hp)]
	# on victory, unlock + advance the campaign (so "Next Level" restarts into the next one)
	var has_next := false
	var cmp := get_node_or_null("/root/Campaign")
	if victory and cmp:
		has_next = cmp.complete_current()   # advances current_index if another level exists
	var end := CanvasLayer.new()
	end.set_script(load("res://scripts/end_screen.gd"))
	add_child(end)
	end.show_result(victory, stats, has_next)
