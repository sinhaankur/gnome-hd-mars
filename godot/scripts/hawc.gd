extends CharacterBody3D
## Player mech controller — third-person, camera-relative, responsive.
## WASD/arrows move relative to the camera; mouse orbits the camera; the mech turns
## to face where it walks. SHIFT jumps, SPACE / left-click fires. Kept deliberately
## simple and direct so input always responds.

@export var max_speed: float = 20.0
@export var accel: float = 40.0            # snappier than before (was floaty)
@export var decel: float = 50.0
@export var turn_rate: float = 10.0        # mech yaws to face movement (rad/s-ish)
@export var gravity: float = 30.0
@export var jump_velocity: float = 14.0
@export var jetpack_thrust: float = 34.0    # upward accel while holding jump (unlimited)
@export var jetpack_max_rise: float = 22.0  # max upward speed from the jetpack
@export var fire_cooldown: float = 0.18
@export var max_health: int = 100

var _cooldown := 0.0
var health: int = 100
var camera: Node3D = null
var _recoil := 0.0                    # firing recoil kick (decays each frame)
var _was_on_floor := true             # for landing-impact detection
var _fall_speed := 0.0                # downward speed while airborne
var _thrusters: GPUParticles3D        # jetpack flame particles (created on first use)
@onready var _visual: Node3D = get_node_or_null("Visual")

signal health_changed(current: int, maximum: int)
signal died

@onready var muzzle_l: Node3D = get_node_or_null("MuzzleL")
@onready var muzzle_r: Node3D = get_node_or_null("MuzzleR")

const LaserScene := preload("res://scenes/laser.tscn")

func _ready() -> void:
	add_to_group("player")
	health = max_health
	# Start with the mouse FREE so the player can move/resize the window. The camera only
	# captures the cursor once the player clicks INTO the game to look around.

## Mouse handling that never traps you:
##  - Left-click in the game  -> capture (mouse-look active)
##  - TAB                     -> free the cursor without pausing (resize window, etc.)
##  - ESC                     -> pause menu (owned by pause_menu.gd), which also frees it
func _input(event: InputEvent) -> void:
	# TAB toggles the cursor free at any time, no pause — so you can always get it back
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
	# click into the game to capture for mouse-look (only during active play)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func take_damage(amount: int) -> void:
	health = max(0, health - amount * 8)
	health_changed.emit(health, max_health)
	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.4)   # a solid jolt when hit
	if health <= 0:
		died.emit()

func _cam_yaw() -> float:
	if camera and is_instance_valid(camera):
		var y = camera.get("yaw")
		if y != null:
			return y
	return rotation.y

func _physics_process(delta: float) -> void:
	# --- camera-relative movement direction from WASD/arrows ---
	var iy := Input.get_axis("move_back", "move_forward")   # +1 = forward (W)
	var ix := Input.get_axis("turn_right", "turn_left")     # +1 = left (A)
	var yaw := _cam_yaw()
	# "into screen" (away from the camera, where W goes) and screen-right
	var into := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var wish := (into * iy - right * ix)
	wish.y = 0.0
	if wish.length() > 1.0:
		wish = wish.normalized()

	var target := wish * max_speed
	var hv := Vector3(velocity.x, 0, velocity.z)
	var rate := accel if target.length() >= hv.length() else decel
	hv = hv.move_toward(target, rate * delta)
	velocity.x = hv.x
	velocity.z = hv.z

	# --- face movement direction ---
	if hv.length() > 0.5:
		var want := atan2(hv.x, hv.z)
		rotation.y = lerp_angle(rotation.y, want, clampf(turn_rate * delta, 0.0, 1.0))

	# --- gravity + UNLIMITED JETPACK ---
	# Holding jump thrusts the mech upward with no fuel limit, so it can always fly
	# out of any pit or ravine. On the ground it also gives an initial hop.
	var jetting := Input.is_action_pressed("jump")
	if jetting:
		velocity.y += jetpack_thrust * delta
		velocity.y = minf(velocity.y, jetpack_max_rise)
		if is_on_floor() and velocity.y < jump_velocity:
			velocity.y = jump_velocity   # snappy initial kick off the ground
	elif is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	# jetpack thruster flames on/off (only when airborne + thrusting)
	_set_thrusters(jetting and not is_on_floor())

	var was_air := not _was_on_floor
	move_and_slide()
	# landing impact: dust burst + camera shake when touching down after a fall
	if is_on_floor() and was_air and _fall_speed > 8.0:
		_landing_impact(_fall_speed)
	_fall_speed = -velocity.y if not is_on_floor() else 0.0
	_was_on_floor = is_on_floor()

	# --- weapon ---
	_cooldown = max(0.0, _cooldown - delta)
	if Input.is_action_pressed("fire") and _cooldown <= 0.0:
		_fire()
		_cooldown = fire_cooldown

	# --- firing recoil: shove the visual back + pitch up a touch, then settle ---
	_recoil = move_toward(_recoil, 0.0, delta * 2.5)
	if _visual:
		_visual.position.z = -_recoil * 0.6      # kick backward (-Z of body = behind)
		_visual.rotation.x = _recoil * 0.12       # slight muzzle-climb pitch

func get_speed_ratio() -> float:
	return Vector3(velocity.x, 0, velocity.z).length() / max_speed

func _fire() -> void:
	# The mech faces movement via atan2(hv.x, hv.z), which points its +Z axis forward.
	# So the true forward is +Z (NOT -Z). Fire along +Z or shots leave out the back.
	var forward := global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	for m in [muzzle_l, muzzle_r]:
		if m == null:
			continue
		var laser := LaserScene.instantiate()
		_spawn_parent().add_child(laser)
		# spawn at the muzzle position, but ORIENTED to look forward (so travel = forward)
		var origin: Vector3 = m.global_position
		laser.global_transform = Transform3D(Basis.looking_at(forward, Vector3.UP), origin)
		_muzzle_flash(m)
	_recoil = 0.35   # kick the mech back a touch (decays in _physics_process)
	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.12)   # small kick per shot
	var sfx := get_node_or_null("/root/Sfx")
	if sfx:
		sfx.laser()

func _muzzle_flash(at: Node3D) -> void:
	# bright light + a visible glowing flare sprite at the barrel
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.7, 0.25)
	flash.light_energy = 10.0
	flash.omni_range = 7.0
	at.add_child(flash)
	var flare := MeshInstance3D.new()
	var sph := SphereMesh.new(); sph.radius = 0.5; sph.height = 1.0
	flare.mesh = sph
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.emission_enabled = true
	fm.emission = Color(1.0, 0.8, 0.4)
	fm.emission_energy_multiplier = 8.0
	fm.albedo_color = Color(1.0, 0.85, 0.5)
	flare.material_override = fm
	at.add_child(flare)
	var tw: Tween = flash.create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "light_energy", 0.0, 0.08)
	tw.tween_property(flare, "scale", Vector3.ONE * 0.1, 0.08)
	tw.chain().tween_callback(func():
		if is_instance_valid(flash): flash.queue_free()
		if is_instance_valid(flare): flare.queue_free())

func _set_thrusters(on: bool) -> void:
	if _thrusters == null:
		# lazily create the jetpack flame emitter under the mech
		_thrusters = GPUParticles3D.new()
		_thrusters.amount = 40
		_thrusters.lifetime = 0.5
		_thrusters.local_coords = false
		_thrusters.position = Vector3(0, 2.5, 0)   # under the chassis
		var pm := ParticleProcessMaterial.new()
		pm.direction = Vector3(0, -1, 0)
		pm.spread = 18.0
		pm.initial_velocity_min = 10.0
		pm.initial_velocity_max = 18.0
		pm.gravity = Vector3(0, -4, 0)
		pm.scale_min = 0.4
		pm.scale_max = 0.9
		pm.color = Color(1.0, 0.7, 0.3, 0.9)
		_thrusters.process_material = pm
		var qm := QuadMesh.new(); qm.size = Vector2(0.8, 0.8)
		_thrusters.draw_pass_1 = qm
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.emission_enabled = true
		fm.emission = Color(1.0, 0.6, 0.2)
		fm.emission_energy_multiplier = 4.0
		fm.albedo_color = Color(1.0, 0.7, 0.3, 0.9)
		fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_thrusters.material_override = fm
		_thrusters.emitting = false
		add_child(_thrusters)
	if _thrusters.emitting != on:
		_thrusters.emitting = on

func _landing_impact(fall_speed: float) -> void:
	# dust ring + camera shake proportional to the fall
	if camera and camera.has_method("add_shake"):
		camera.add_shake(clampf(fall_speed / 40.0, 0.1, 0.5))
	var burst := GPUParticles3D.new()
	burst.amount = 24
	burst.lifetime = 0.7
	burst.one_shot = true
	burst.explosiveness = 0.9
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 85.0
	pm.initial_velocity_min = 5.0
	pm.initial_velocity_max = 12.0
	pm.gravity = Vector3(0, -8, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	pm.color = Color(0.72, 0.56, 0.45, 0.5)
	burst.process_material = pm
	var qm := QuadMesh.new(); qm.size = Vector2(1.2, 1.2)
	burst.draw_pass_1 = qm
	var dm := StandardMaterial3D.new()
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(0.72, 0.56, 0.45, 0.5)
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	burst.material_override = dm
	_spawn_parent().add_child(burst)
	burst.global_position = global_position   # set after entering the tree
	burst.emitting = true
	var t := get_tree().create_timer(1.0)
	t.timeout.connect(func(): if is_instance_valid(burst): burst.queue_free())
	if sfx_ref():
		sfx_ref().hit()   # a thud on landing

func sfx_ref() -> Node:
	return get_node_or_null("/root/Sfx")

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_parent()
