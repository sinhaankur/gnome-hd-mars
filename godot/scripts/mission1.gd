extends Node3D
## LEVEL — Mars, "Operation Red Wall": defend the installation.
##
## This is a THIN level: it composes the three engines and wires their events.
##   - EnvironmentEngine : the Mars world (terrain, sun, scatter, installation)
##   - HAWC (player)     : the player mech (hawc.gd) + follow camera
##   - Enemies           : rival-nation mechs (enemy_ai.gd)
## The level asks the Environment where the ground is; it doesn't raycast itself.

# Enemy HAWCs are routed per-archetype by enemy_engine.gd (ARCH_MODELS). MECH_PATH is only
# the FALLBACK model used if an archetype key is ever missing — a lean enemy mech, not the
# retired 243 MB warrior.glb (removed 2026-08-27; player now uses hero_striker.glb).
const MECH_PATH := "res://assets/enemy_sentry.glb"
# player's hero HAWC: sourced "Medium Mech Striker" (MSGDI, CC-BY), normalized to a real
# ~7 m HAWC (tools: mars-hawc-asset-sourcing skill). 10.8k tris / 4.8 MB — a ~50x cut from
# the old 243 MB warrior.glb, with a proper HAWC silhouette (cockpit, missile pods, gun-arm,
# reverse-jointed legs). UNION-tinted so it reads distinct from the red enemy mechs.
const HERO_PATH := "res://assets/hero_striker.glb"
# Faction library: applies the player's union (tan) palette to the hero mech.
const FactionLib := preload("res://scripts/faction.gd")
# Loaded by path (not class_name) so it resolves even before the editor rescans
# the global class cache — a bare `-s` script run won't register new class_names.
const HERO_FIX := preload("res://scripts/hero_material_fix.gd")
# preload by path (not class_name) so a bare -s run resolves it before the editor
# rescans the global class cache — same reason as HERO_FIX above.
const BEACON_SCENE := preload("res://scripts/beacon.gd")
const MECH_SCALE := 2.8           # enemy warrior.glb: ~2.5u model -> ~7m tall
# hero_striker.glb is already normalized to 7 m at identity, so it needs no up-scaling.
const HERO_SCALE := 1.0
const MECH_FOOT_LIFT := 0.0
# Model face orientation vs movement. 0 = faces forward (model +Z = body +Z = movement dir).
# Flip to PI if it ever reads backward. Single source of truth so it's one edit to fix.
const MECH_FACE_FLIP := 0.0

var env: EnvironmentEngine
var enemies: EnemyEngine
var explore: Exploration
var _beacon: Node3D                    # "reach" objective landmark (Beacon; null on defend levels)
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
	env.world_size = 800.0   # 4x the roamable ground — "the ground is limited" playtest note
	env.height_scale = _level.get("height_scale", 34.0)   # per-level terrain relief
	env.day_start = _level.get("day_start", 0.32)          # per-level time of day
	env.region = _level.get("region", "")                  # per-level MOLA region heightmap
	env.palette = _level.get("palette", {})                # territory theme (ice/grass/volcanic)
	env.installation_pos = Vector3(0, 0, -180)
	env.installation_pad_radius = 32.0
	add_child(env)

	# --- HAWC Engine: the player mech + camera ---
	_player = _build_hawc(Vector3(0, 30, 160))
	_cam = _build_camera(_player)
	_player.camera = _cam
	_player.exit_requested.connect(_dismount)   # E: step out on foot (G-NOME loop)

	# --- Enemy Engine: the wave director, loaded with THIS level's wave script ---
	enemies = EnemyEngine.new()
	enemies.name = "EnemyEngine"
	if _level.has("waves"):
		enemies.waves = _level["waves"]
	add_child(enemies)
	enemies.configure(env, _player, MECH_PATH, MECH_SCALE)
	enemies.faction = _level.get("faction", "")   # territory fields its own machines
	enemies.wave_started.connect(_on_wave_started)
	enemies.wave_cleared.connect(_on_wave_cleared)
	enemies.mission_won.connect(_on_mission_won)
	enemies.enemy_destroyed_signal.connect(func():
		_kills += 1
		if _hud and is_instance_valid(_hud):
			_hud.kill_confirm())

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
	# "reach" missions get a PHYSICAL beacon outpost to drive to (diegetic landmark,
	# not a floating marker); reaching it wins. "defend" missions skip this entirely.
	if _level.get("objective", "defend") == "reach":
		_spawn_beacon()
	# play the intro cinematic (dropship delivers the mech) + briefing card, THEN assault.
	# The mech is parked during the cinematic so E/Q/fire can't trigger mid-landing.
	var intro := MissionIntro.new()
	add_child(intro)
	_player.controlled = false
	intro.finished.connect(func():
		_player.controlled = true
		enemies.start())
	intro.play(_level, env, _cam, _player)

func _spawn_beacon() -> void:
	# find walkable ground far from the player start (~250 m) so it's a real drive,
	# and away from the base. Try a spread of angles/distances; fall back to due north.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var start := _player.global_position
	var spot := Vector3.INF
	for _try in range(48):
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(220.0, 320.0)
		var x := start.x + cos(ang) * dist
		var z := start.z + sin(ang) * dist
		# stay inside the world and off the installation pad
		if absf(x) > env.world_size * 0.5 - 20.0 or absf(z) > env.world_size * 0.5 - 20.0:
			continue
		if Vector2(x, z).distance_to(Vector2(env.installation_pos.x, env.installation_pos.z)) < 60.0:
			continue
		if not env.is_walkable(x, z):
			continue
		var y := env.ground_height(x, z)
		if is_nan(y):
			continue
		spot = Vector3(x, y, z)
		break
	if spot == Vector3.INF:
		# guaranteed fallback: due north at a fixed range, clamped into the map
		var fz: float = minf(start.z + 260.0, env.world_size * 0.5 - 20.0)
		var fy := env.ground_height(start.x, fz)
		spot = Vector3(start.x, (0.0 if is_nan(fy) else fy), fz)
	_beacon = BEACON_SCENE.new()
	add_child(_beacon)
	_beacon.global_position = spot
	_beacon.reached.connect(func(): _end(true))
	_notice("OBJECTIVE: reach the ally beacon — follow the amber strobe on the horizon")

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

# ---------------------------------------------------------------- POSSESSION
# The G-NOME signature loop: exit your HAWC on foot, GASHR an enemy HAWC to eject
# its pilot, board the vacant hull. The LEVEL coordinates; bodies never touch
# each other (pilot emits enter_requested, hawc emits exit_requested).
const PilotScript := preload("res://scripts/pilot.gd")
var _pilot: CharacterBody3D
const BOARD_REACH := 7.0   # how close the pilot must be to board a hull

func _dismount() -> void:
	if _over or not _env_setup_done:
		return
	if _pilot == null:
		_pilot = PilotScript.new()
		_pilot.name = "PilotGant"
		add_child(_pilot)
		_pilot.enter_requested.connect(_try_enter)
		_pilot.died.connect(_on_player_died)
		_pilot.camera = _cam
	_pilot.visible = true
	_pilot.set_physics_process(true)
	# step out beside the mech's flank, snapped to the ground
	var side: Vector3 = _player.global_transform.basis.x
	_pilot.global_position = _player.global_position + side * 5.0 + Vector3.UP * 1.0
	env.place_on_ground(_pilot, 0.5)
	_player.controlled = false
	_player.remove_from_group("player")
	_pilot.add_to_group("player")
	_cam.set_target(_pilot, 7.0, 2.6, 1.8)
	_notice("ON FOOT — Q: GASHR ejects enemy pilots · E by a HAWC: board it")

func _try_enter() -> void:
	# board whatever HAWC is in reach: your own parked one, or a vacant enemy hull
	var pos: Vector3 = _pilot.global_position
	if _player and is_instance_valid(_player) and pos.distance_to(_player.global_position) < BOARD_REACH:
		_mount(_player)
		return
	for hull in get_tree().get_nodes_in_group("hijackable"):
		if is_instance_valid(hull) and pos.distance_to(hull.global_position) < BOARD_REACH:
			_steal(hull)
			return

func _mount(mech: CharacterBody3D) -> void:
	_pilot.remove_from_group("player")
	_pilot.visible = false
	_pilot.set_physics_process(false)
	mech.controlled = true
	mech.add_to_group("player")
	_cam.set_target(mech, 12.0, 6.0, 4.5)
	var sfx := get_node_or_null("/root/Sfx")
	if sfx:
		sfx.ui()

func _steal(hull: Node3D) -> void:
	# commandeer: swap the vacant enemy hull for a fresh player-controlled HAWC
	# (both use the same warrior model, so the silhouette carries over)
	var xf: Transform3D = hull.global_transform
	hull.queue_free()
	var m := _build_hawc(xf.origin + Vector3.UP * 0.5)
	m.rotation.y = xf.basis.get_euler().y
	m.camera = _cam
	m.exit_requested.connect(_dismount)
	_player = m
	if _hud:
		_hud.retarget(m)
	_mount(m)
	_notice("HAWC COMMANDEERED — enemy hull is yours")

func _notice(text: String) -> void:
	# reuse the exploration notice slot (bottom-left telemetry tone)
	_discovery_text = text
	_discovery_timer = 6.0

# ---------------------------------------------------------------- HAWC (player)
func _build_hawc(pos: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "PlayerHAWC"
	body.set_script(load("res://scripts/hawc.gd"))

	var visual := Node3D.new()
	visual.name = "Visual"   # hawc.gd applies recoil to this node
	var scene: PackedScene = load(HERO_PATH)
	if scene == null:
		scene = load(MECH_PATH)   # fall back to the shared mech model
	var mech_model: Node = null
	if scene:
		var hawk := scene.instantiate()
		hawk.scale = Vector3.ONE * HERO_SCALE
		# MECH_FACE_FLIP tunes which way the model faces relative to movement. hawc.gd yaws
		# the body so movement dir is local +Z; a model whose face is local -Z needs a PI
		# flip. hero_striker was normalized facing -Z (Godot forward), which matches +Z after
		# the standard flip below. If it ever reads backward in-game, toggle MECH_FACE_FLIP.
		hawk.rotation.y = MECH_FACE_FLIP + PI
		# UNION tint: warm tan/gold so the player HAWC reads as friendly and stands out from
		# the red enemy mechs. Recolors over the baked textures.
		FactionLib.tint(hawk, "union")
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
	# GLB origin isn't at the feet — align the model's lowest point to the capsule bottom
	Atoms.align_foot(visual, body)
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

	# enemies within range of the installation erode its armor — only meaningful on
	# DEFEND missions. On a reach mission you're driving AWAY from the base, so its
	# armor is irrelevant and mustn't fail you.
	var attackers := 0
	if env.installation and _beacon == null:
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

	# "reach" missions: run the beacon proximity check + show a distance readout so the
	# player has a diegetic target (the amber strobe) plus a number, no floating marker.
	if _beacon and is_instance_valid(_beacon):
		_beacon.check(_player.global_position)
		var dist := int(_beacon.distance_from(_player.global_position))
		_obj_label.text = "REACH THE ALLY BEACON · %d m · hostiles: %d\nYOUR ARMOR: %d%%" % [
			dist, alive, _player.health]
	else:
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
