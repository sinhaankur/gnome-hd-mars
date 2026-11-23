extends CharacterBody3D
class_name Pilot
## PILOT ON FOOT — the G-NOME signature layer: you are not the mech, you're the
## soldier inside it. Small, fast, fragile; a light laser rifle and the GASHR
## launcher (non-lethal — ejects the pilot from an enemy HAWC so you can steal it).
## Movement mirrors hawc.gd (camera-relative WASD) so switching bodies feels seamless.
##
## Signals let the LEVEL coordinate possession — this script never touches mechs:
##   enter_requested   — player pressed interact; mission decides what's in reach
##   died              — pilot killed on foot

signal enter_requested
signal died

@export var max_speed: float = 9.0
@export var accel: float = 45.0
@export var decel: float = 55.0
@export var gravity: float = 30.0
@export var jump_velocity: float = 9.0
@export var fire_cooldown: float = 0.45   # rifle: slower + weaker than a HAWC (G-NOME rule)
@export var gashr_cooldown: float = 2.5
@export var max_health: int = 100

var health: int = 100
var camera: Node3D = null
var _cooldown := 0.0
var _gashr_cool := 0.0

const LaserScene := preload("res://scenes/laser.tscn")
const GashrScript := preload("res://scripts/gashr.gd")

func _ready() -> void:
	health = max_health
	_build_visual()
	_build_collider()

# Real armored trooper — "Halo-Infinite-Master-Chief-rigged-walk" by bensimulator2 (CC-BY,
# see CREDITS.md), normalized by tools/build_pilot.py (1.9 m, Y-up, base Y=0, forward -Z).
# Replaces the capsule+sphere+box figure ("doesn't even look human", user 2026-11-22). Ships
# the clean upright REST pose — its source Walk clip tips the body over in-engine (wrong
# up-axis), so a retargeted walk is a tracked follow-up (task #10).
const PILOT_MODEL := "res://assets/pilot_human.glb"

func _build_visual() -> void:
	var vis := Node3D.new()
	vis.name = "Visual"
	add_child(vis)

	var scene := load(PILOT_MODEL) as PackedScene
	if scene:
		var human := scene.instantiate()
		# source faces +Z; the body yaws so movement is local +Z — a +Z-facing model needs a
		# PI flip to face the -Z travel direction (same convention as the mechs in mission1.gd).
		human.rotation.y = PI
		vis.add_child(human)
	else:
		push_warning("pilot: %s failed to load — using primitive fallback" % PILOT_MODEL)
		_build_primitive_fallback(vis)

func _build_primitive_fallback(vis: Node3D) -> void:
	# last-resort stand-in if the GLB is missing (kept tiny; the real model is the default).
	var suit := StandardMaterial3D.new()
	suit.albedo_color = Color(0.33, 0.37, 0.30); suit.roughness = 0.85
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new(); cap.radius = 0.3; cap.height = 1.6
	body.mesh = cap; body.material_override = suit; body.position.y = 0.9
	vis.add_child(body)
	var helmet := MeshInstance3D.new()
	var hs := SphereMesh.new(); hs.radius = 0.22; hs.height = 0.44
	helmet.mesh = hs; helmet.material_override = suit; helmet.position.y = 1.72
	vis.add_child(helmet)

func _build_collider() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4; cap.height = 1.9
	col.shape = cap
	col.position.y = 0.95
	add_child(col)

func take_damage(amount: int) -> void:
	# on foot you are FRAGILE — a few mech-laser hits kill (G-NOME's risk/reward)
	health = max(0, health - amount * 25)
	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.5)
	if health <= 0:
		died.emit()

func _cam_yaw() -> float:
	if camera and is_instance_valid(camera):
		var y = camera.get("yaw")
		if y != null:
			return y
	return rotation.y

func _physics_process(delta: float) -> void:
	# camera-relative WASD, identical feel to the HAWC (see hawc.gd)
	var iy := Input.get_axis("move_back", "move_forward")
	var ix := Input.get_axis("turn_right", "turn_left")
	var yaw := _cam_yaw()
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
	if hv.length() > 0.5:
		rotation.y = lerp_angle(rotation.y, atan2(hv.x, hv.z), clampf(10.0 * delta, 0.0, 1.0))

	if is_on_floor():
		velocity.y = jump_velocity if Input.is_action_just_pressed("jump") else 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()

	# rifle (weak) + GASHR (ejects mech pilots) + enter/steal a HAWC
	_cooldown = maxf(0.0, _cooldown - delta)
	_gashr_cool = maxf(0.0, _gashr_cool - delta)
	if Input.is_action_pressed("fire") and _cooldown <= 0.0:
		_fire_rifle()
		_cooldown = fire_cooldown
	if Input.is_action_just_pressed("gashr") and _gashr_cool <= 0.0:
		_fire_gashr()
		_gashr_cool = gashr_cooldown
	if Input.is_action_just_pressed("interact"):
		enter_requested.emit()

func _fire_rifle() -> void:
	var laser := LaserScene.instantiate()
	get_parent().add_child(laser)
	var xf := global_transform
	xf.origin += Vector3.UP * 1.5
	xf.basis = Basis(Vector3.UP, rotation.y + PI)   # bolt travels along -basis.z = facing
	laser.global_transform = xf
	var sfx := get_node_or_null("/root/Sfx")
	if sfx:
		sfx.laser()

func _fire_gashr() -> void:
	var shell := Area3D.new()
	shell.set_script(GashrScript)
	get_parent().add_child(shell)
	var xf := global_transform
	xf.origin += Vector3.UP * 1.6
	xf.basis = Basis(Vector3.UP, rotation.y + PI)
	shell.global_transform = xf
