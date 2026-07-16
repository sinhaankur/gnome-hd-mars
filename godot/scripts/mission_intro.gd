extends CanvasLayer
class_name MissionIntro
## MISSION INTRO — a brief cinematic + briefing card shown at mission start. Reuses the
## level DATA (name/subtitle/brief) and a temporary camera that sweeps over the
## installation, then hands control to the gameplay camera. Emits `finished`.
##
## Usage:  var intro := MissionIntro.new(); add to tree; intro.play(level, env, gameplay_cam)

signal finished

var _level: Dictionary
var _env: Node
var _game_cam: Camera3D
var _cine_cam: Camera3D
var _player: Node3D
var _dropship: Node3D
var _thrusters: Array = []   # engine glow materials, animated during descent

func play(level: Dictionary, env: Node, game_cam: Camera3D, player: Node3D = null) -> void:
	_level = level
	_env = env
	_game_cam = game_cam
	_player = player
	layer = 50
	_build_card()
	if _player:
		_run_landing()   # deployment: the dropship delivers the mech from orbit
	else:
		_run_sweep()     # fallback: the old installation fly-over

func _build_card() -> void:
	# a lower-third briefing card: level name, subtitle, brief
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	# letterbox bars for a cinematic feel — anchored across the width via offsets so
	# they stay full-width at any resolution (no hardcoded pixel size to be overridden)
	var top := ColorRect.new(); top.color = Color(0,0,0,0.9)
	top.anchor_right = 1.0; top.offset_bottom = 70
	panel.add_child(top)
	var bot := ColorRect.new(); bot.color = Color(0,0,0,0.9)
	bot.anchor_top = 1.0; bot.anchor_right = 1.0; bot.anchor_bottom = 1.0
	bot.offset_top = -160
	panel.add_child(bot)

	var col := VBoxContainer.new()
	col.position = Vector2(60, 520)
	panel.add_child(col)
	var name := Label.new()
	name.text = _level.get("name", "Mission")
	name.add_theme_font_size_override("font_size", 40)
	name.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	col.add_child(name)
	var sub := Label.new()
	sub.text = "MARS · " + _level.get("subtitle", "")
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	col.add_child(sub)
	var brief := Label.new()
	brief.text = _level.get("brief", "")
	brief.add_theme_font_size_override("font_size", 17)
	brief.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	brief.custom_minimum_size = Vector2(900, 0)
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(brief)

	var skip := Label.new()
	skip.text = "▶ press any key to begin"
	skip.add_theme_font_size_override("font_size", 15)
	skip.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	skip.position = Vector2(60, 40)
	panel.add_child(skip)
	_card = panel

var _card: Control
var _done := false

# ---------------------------------------------------------------- dropship landing
func _run_landing() -> void:
	# The player's mech arrives by dropship: descend from high altitude, dust-off at
	# touchdown, release the mech, climb away. Connects the orbit DEPLOY click to the
	# ground — you watch your own insertion.
	var ground: Vector3 = _player.global_position
	# hide the mech until the ship sets it down
	var vis := _player.get_node_or_null("Visual")
	if vis:
		vis.visible = false

	_dropship = _build_dropship()
	_env.add_child(_dropship)
	_dropship.global_position = ground + Vector3(0, 130, 0)

	# camera: low and off to the side; TRACKS the ship the whole way down
	_cine_cam = Camera3D.new()
	_cine_cam.fov = 60
	add_child(_cine_cam)
	_cine_cam.current = true
	_cine_cam.look_at_from_position(ground + Vector3(26, 9, 26), _dropship.global_position, Vector3.UP)

	var tw := create_tween()
	# descent: fast then flaring to a hover just above the deck; camera follows the ship
	tw.tween_property(_dropship, "global_position", ground + Vector3(0, 9.5, 0), 5.0)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(_t: float):
		if _cine_cam and is_instance_valid(_cine_cam) and _dropship and is_instance_valid(_dropship):
			_cine_cam.look_at(_dropship.global_position - Vector3(0, 2.0, 0), Vector3.UP),
		0.0, 1.0, 5.0)
	tw.tween_callback(func():
		_touchdown_dust(ground)
		if vis:
			vis.visible = true)   # mech released under the hovering ship
	tw.tween_interval(0.9)
	# climb-out and away
	tw.tween_property(_dropship, "global_position", ground + Vector3(60, 150, -40), 3.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_method(func(t: float):
		if _cine_cam and is_instance_valid(_cine_cam) and _dropship and is_instance_valid(_dropship):
			_cine_cam.look_at(_dropship.global_position.lerp(ground + Vector3.UP * 6, t), Vector3.UP),
		0.0, 1.0, 3.0)
	tw.tween_callback(_finish)

func _build_dropship() -> Node3D:
	# kitbashed lifter: hull + cockpit + stub wings + four downward engine pods.
	# Grey weathered metal, orange thrust glow — corporate cargo hardware, not sci-fi neon.
	var ship := Node3D.new()
	ship.name = "Dropship"
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.52, 0.52, 0.54); metal.metallic = 0.6; metal.roughness = 0.5
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.22, 0.23, 0.26); dark.metallic = 0.3; dark.roughness = 0.6

	var hull := MeshInstance3D.new()
	hull.mesh = BoxMesh.new(); hull.scale = Vector3(7.0, 2.6, 12.0)
	hull.material_override = metal
	ship.add_child(hull)
	var nose := MeshInstance3D.new()
	nose.mesh = BoxMesh.new(); nose.scale = Vector3(4.2, 1.8, 3.0)
	nose.material_override = dark
	nose.position = Vector3(0, 0.7, -6.8)
	ship.add_child(nose)
	for sx in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		wing.mesh = BoxMesh.new(); wing.scale = Vector3(5.5, 0.35, 4.0)
		wing.material_override = metal
		wing.position = Vector3(sx * 5.8, 0.3, 1.0)
		ship.add_child(wing)
		for z in [-3.5, 4.5]:
			var pod := MeshInstance3D.new()
			var pc := CylinderMesh.new(); pc.top_radius = 0.9; pc.bottom_radius = 1.1; pc.height = 2.4
			pod.mesh = pc; pod.material_override = dark
			pod.position = Vector3(sx * 5.8, -1.2, z)
			ship.add_child(pod)
			# thrust glow disc under each pod
			var glow := MeshInstance3D.new()
			var gc := CylinderMesh.new(); gc.top_radius = 0.85; gc.bottom_radius = 0.5; gc.height = 1.2
			glow.mesh = gc
			var gm := StandardMaterial3D.new()
			gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(1.0, 0.55, 0.2, 0.7)
			gm.emission_enabled = true; gm.emission = Color(1.0, 0.5, 0.15)
			gm.emission_energy_multiplier = 3.0
			glow.material_override = gm
			glow.position = Vector3(sx * 5.8, -2.6, z)
			ship.add_child(glow)
			_thrusters.append(gm)
	return ship

func _touchdown_dust(ground: Vector3) -> void:
	# one-shot dust ring blasted out by the engines at touchdown
	var dust := GPUParticles3D.new()
	dust.one_shot = true
	dust.amount = 160
	dust.lifetime = 2.2
	dust.explosiveness = 0.9
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 4.0
	pm.emission_ring_inner_radius = 2.0
	pm.emission_ring_height = 0.5
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.direction = Vector3(1, 0.15, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 10.0
	pm.initial_velocity_max = 22.0
	pm.gravity = Vector3(0, -2.5, 0)
	pm.scale_min = 1.2; pm.scale_max = 3.0
	pm.color = Color(0.68, 0.55, 0.42, 0.5)
	dust.process_material = pm
	var qm := QuadMesh.new(); qm.size = Vector2(2.0, 2.0)
	dust.draw_pass_1 = qm
	dust.material_override = Atoms.dust_material(Color(0.68, 0.55, 0.42, 0.45))
	_env.add_child(dust)
	dust.global_position = ground + Vector3.UP * 0.5
	dust.emitting = true
	# self-clean after the burst
	get_tree().create_timer(4.0).timeout.connect(func():
		if is_instance_valid(dust):
			dust.queue_free())

func _run_sweep() -> void:
	# a temporary camera that arcs over the installation, then fades to gameplay
	_cine_cam = Camera3D.new()
	_cine_cam.fov = 55
	add_child(_cine_cam)
	_cine_cam.current = true
	var base: Vector3 = _env.installation.global_position if _env and "installation" in _env and _env.installation else Vector3.ZERO
	# arc from high/wide down toward the base
	var start_pos := base + Vector3(90, 70, 90)
	var end_pos := base + Vector3(30, 30, 60)
	_cine_cam.look_at_from_position(start_pos, base + Vector3.UP * 8, Vector3.UP)
	var tw := create_tween()
	tw.tween_method(_sweep_step.bind(start_pos, end_pos, base), 0.0, 1.0, 4.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_finish)

func _sweep_step(t: float, a: Vector3, b: Vector3, look: Vector3) -> void:
	if _cine_cam and is_instance_valid(_cine_cam):
		var p := a.lerp(b, t)
		_cine_cam.look_at_from_position(p, look + Vector3.UP * 8, Vector3.UP)

func _input(event: InputEvent) -> void:
	# any key/click skips the intro
	if not _done and (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_finish()
		get_viewport().set_input_as_handled()

func _finish() -> void:
	if _done:
		return
	_done = true
	# if the intro was skipped mid-descent: make sure the mech is visible and the ship gone
	if _player and is_instance_valid(_player):
		var vis := _player.get_node_or_null("Visual")
		if vis:
			vis.visible = true
	if _dropship and is_instance_valid(_dropship):
		_dropship.queue_free()
	if _game_cam and is_instance_valid(_game_cam):
		_game_cam.current = true
	if _cine_cam and is_instance_valid(_cine_cam):
		_cine_cam.queue_free()
	# fade the card out then free the whole intro
	if _card:
		var tw := create_tween()
		tw.tween_property(_card, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func(): finished.emit(); queue_free())
	else:
		finished.emit()
		queue_free()
