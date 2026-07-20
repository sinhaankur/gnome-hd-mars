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
# Hover height for the deployment: high enough to lower a ~7 m mech clear beneath the
# ship's belly (underside ≈ -3.3 in the model), low enough that the winch reads.
const HOVER_Y := 15.0
const CABLE_TOP_Y := -3.0    # bay floor / winch anchor, local to the ship

func _run_landing() -> void:
	# The player's mech arrives by dropship as a diegetic deployment you watch:
	# descend -> hover -> BAY DOORS OPEN -> mech WINCHED DOWN on cables -> touchdown ->
	# cables release -> ship climbs away. No more "mech pops into existence".
	var ground: Vector3 = _player.global_position
	# hide the real gameplay mech; a stand-in visual rides the winch during the cinematic
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
	# 1) descent: fast then flaring to a hover; camera follows the ship
	tw.tween_property(_dropship, "global_position", ground + Vector3(0, HOVER_Y, 0), 5.0)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(_t: float):
		if _cine_cam and is_instance_valid(_cine_cam) and _dropship and is_instance_valid(_dropship):
			_cine_cam.look_at(_dropship.global_position - Vector3(0, 3.0, 0), Vector3.UP),
		0.0, 1.0, 5.0)
	# 2) settle, then the bay doors swing open (dust puff of downwash on the deck)
	tw.tween_callback(func(): _downwash(ground))
	tw.tween_interval(0.4)
	tw.tween_callback(_open_bay)
	tw.tween_interval(0.9)   # let the doors finish opening
	# 3) winch the mech down from the bay to the ground on cables
	tw.tween_callback(_begin_winch.bind(vis, ground))
	tw.tween_interval(2.4)   # matches the winch descent time below
	# 4) touchdown: dust ring, cables detach, hand the real mech to the player
	tw.tween_callback(func():
		_touchdown_dust(ground)
		_release_winch()
		if vis:
			vis.visible = true)
	tw.tween_interval(0.8)
	# 5) doors close and the ship climbs out and away
	tw.tween_callback(_close_bay)
	tw.tween_property(_dropship, "global_position", ground + Vector3(60, 150, -40), 3.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_method(func(t: float):
		if _cine_cam and is_instance_valid(_cine_cam) and _dropship and is_instance_valid(_dropship):
			_cine_cam.look_at(_dropship.global_position.lerp(ground + Vector3.UP * 6, t), Vector3.UP),
		0.0, 1.0, 3.0)
	tw.tween_callback(_finish)

# --- cargo bay + winch: parts parented to the ship so they move with it ---
var _bay_door_l: Node3D
var _bay_door_r: Node3D
var _winch_rig: Node3D      # holds the lowered mech stand-in + cables
var _winch_mech: Node3D

func _open_bay() -> void:
	if _bay_door_l == null or not is_instance_valid(_bay_door_l):
		return
	# doors swing down/outward on their hinges (rotation around local Z)
	var t := create_tween(); t.set_parallel(true)
	t.tween_property(_bay_door_l, "rotation:z", deg_to_rad(105), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_bay_door_r, "rotation:z", deg_to_rad(-105), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sfx := get_node_or_null("/root/Sfx")
	if sfx and sfx.has_method("ui"):
		sfx.ui()

func _close_bay() -> void:
	if _bay_door_l == null or not is_instance_valid(_bay_door_l):
		return
	var t := create_tween(); t.set_parallel(true)
	t.tween_property(_bay_door_l, "rotation:z", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	t.tween_property(_bay_door_r, "rotation:z", 0.0, 0.7).set_trans(Tween.TRANS_SINE)

func _begin_winch(gameplay_vis: Node3D, ground: Vector3) -> void:
	# build a stand-in mech + a pair of cables under the bay, then lower the rig so the
	# mech travels from the bay floor down to the ground. The rig is a child of the ship
	# so it inherits the ship's tiny hover bob, but we drive its local Y down to ground.
	if _dropship == null or not is_instance_valid(_dropship):
		return
	_winch_rig = Node3D.new()
	_dropship.add_child(_winch_rig)
	_winch_rig.position = Vector3(0, CABLE_TOP_Y, 0)   # start at the bay floor

	# stand-in mech: clone the player's visual so it matches the hero model exactly
	if gameplay_vis:
		_winch_mech = gameplay_vis.duplicate()
		_winch_mech.visible = true
		_winch_mech.position = Vector3.ZERO
		_winch_rig.add_child(_winch_mech)

	# two cables from the bay roof down to the mech's shoulders
	for sx in [-1.3, 1.3]:
		var cable := MeshInstance3D.new()
		var cc := CylinderMesh.new(); cc.top_radius = 0.06; cc.bottom_radius = 0.06; cc.height = 8.0
		cable.mesh = cc
		var cm := StandardMaterial3D.new(); cm.albedo_color = Color(0.1, 0.1, 0.1); cm.metallic = 0.3
		cable.material_override = cm
		# reaches from the rig up to the bay anchor (fixed length; the rig moves down)
		cable.position = Vector3(sx, 4.0, 0)
		cable.name = "Cable%d" % (0 if sx < 0 else 1)
		_winch_rig.add_child(cable)

	# lower the rig from the bay floor to ground level (local Y of the ship)
	var drop := (ground.y) - (_dropship.global_position.y + CABLE_TOP_Y) + 0.2
	var t := create_tween()
	t.tween_property(_winch_rig, "position:y", CABLE_TOP_Y + drop, 2.3)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _release_winch() -> void:
	# cables snap free; the stand-in mech + cables vanish as the real gameplay mech appears
	if _winch_rig and is_instance_valid(_winch_rig):
		_winch_rig.queue_free()
	_winch_rig = null
	_winch_mech = null

const DROPSHIP_PATH := "res://assets/dropship.glb"

func _build_dropship() -> Node3D:
	# real lifter model (Blender kitbash -> assets/dropship.glb): slab hull, visor
	# cockpit, four corner engine pods, mech cradle underneath. Grey weathered metal,
	# orange accents — corporate cargo hardware, not sci-fi neon.
	var ship := Node3D.new()
	ship.name = "Dropship"
	var scene: PackedScene = load(DROPSHIP_PATH)
	if scene:
		ship.add_child(scene.instantiate())
	else:
		# fallback marker if the model is missing
		var hull := MeshInstance3D.new()
		hull.mesh = BoxMesh.new(); hull.scale = Vector3(7.0, 3.0, 14.0)
		ship.add_child(hull)
	# translucent braking-thrust flames under the four pod nozzles
	# (pods sit at ±4.3 / ±4.9 in the model, nozzle exits at y ≈ -2.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var flame := MeshInstance3D.new()
			var fc := CylinderMesh.new(); fc.top_radius = 0.8; fc.bottom_radius = 0.35; fc.height = 1.6
			flame.mesh = fc
			var fm := StandardMaterial3D.new()
			fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			fm.albedo_color = Color(1.0, 0.55, 0.2, 0.65)
			fm.emission_enabled = true; fm.emission = Color(1.0, 0.5, 0.15)
			fm.emission_energy_multiplier = 3.0
			flame.material_override = fm
			flame.position = Vector3(sx * 4.3, -3.2, sz * 4.9)
			ship.add_child(flame)

	# --- underside cargo BAY: a recessed dark opening + two hinged doors that swing
	# open for the winch. The doors hinge along the ship's centreline (local X = ±0)
	# so they open outward like belly cargo doors. Parented to the ship so they ride it.
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.34, 0.33, 0.31); door_mat.metallic = 0.6; door_mat.roughness = 0.5
	var bay_dark := MeshInstance3D.new()
	var bd := BoxMesh.new()
	bay_dark.mesh = bd; bay_dark.scale = Vector3(4.4, 0.4, 7.0)
	var dm := StandardMaterial3D.new(); dm.albedo_color = Color(0.05, 0.05, 0.06); dm.roughness = 1.0
	bay_dark.material_override = dm
	bay_dark.position = Vector3(0, -3.15, 0)   # the dark bay interior, flush with the belly
	ship.add_child(bay_dark)
	# left + right doors: each pivots at the centreline via an offset child mesh
	_bay_door_l = Node3D.new(); _bay_door_l.position = Vector3(0, -3.1, 0); ship.add_child(_bay_door_l)
	var dlm := MeshInstance3D.new(); dlm.mesh = BoxMesh.new()
	dlm.scale = Vector3(2.2, 0.25, 7.0); dlm.position = Vector3(-1.1, 0, 0)   # extends left of the hinge
	dlm.material_override = door_mat; _bay_door_l.add_child(dlm)
	_bay_door_r = Node3D.new(); _bay_door_r.position = Vector3(0, -3.1, 0); ship.add_child(_bay_door_r)
	var drm := MeshInstance3D.new(); drm.mesh = BoxMesh.new()
	drm.scale = Vector3(2.2, 0.25, 7.0); drm.position = Vector3(1.1, 0, 0)    # extends right of the hinge
	drm.material_override = door_mat; _bay_door_r.add_child(drm)
	return ship

func _downwash(ground: Vector3) -> void:
	# a lighter, continuous-feeling dust kick from the hovering engines (before the mech
	# is lowered) — sells the ship holding station over the deck. Reuses the ring burst
	# at a smaller scale than the touchdown blast.
	var dust := GPUParticles3D.new()
	dust.one_shot = true
	dust.amount = 90
	dust.lifetime = 1.8
	dust.explosiveness = 0.7
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 3.0
	pm.emission_ring_inner_radius = 1.5
	pm.emission_ring_height = 0.4
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.direction = Vector3(1, 0.1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 13.0
	pm.gravity = Vector3(0, -2.0, 0)
	pm.scale_min = 0.9; pm.scale_max = 2.2
	pm.color = Color(0.68, 0.55, 0.42, 0.4)
	dust.process_material = pm
	var qm := QuadMesh.new(); qm.size = Vector2(1.6, 1.6)
	dust.draw_pass_1 = qm
	dust.material_override = Atoms.dust_material(Color(0.68, 0.55, 0.42, 0.38))
	_env.add_child(dust)
	dust.global_position = ground + Vector3.UP * 0.4
	dust.emitting = true
	get_tree().create_timer(3.5).timeout.connect(func():
		if is_instance_valid(dust):
			dust.queue_free())

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
		_dropship.queue_free()   # frees the winch rig too (it's a child)
	_winch_rig = null
	_winch_mech = null
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
