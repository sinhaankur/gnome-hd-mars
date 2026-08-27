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

const PILOT_MODEL := "res://assets/pilot_trooper.glb"   # sourced Sci-Fi trooper (ART_LOLL, CC-BY)

func _build_visual() -> void:
	var vis := Node3D.new()
	vis.name = "Visual"
	add_child(vis)
	# real Union soldier model if present (normalized upright, 1.85 m, feet at y=0);
	# falls back to the primitive stand-in below if the asset is missing.
	var scene: PackedScene = load(PILOT_MODEL) if ResourceLoader.exists(PILOT_MODEL) else null
	if scene:
		var soldier := scene.instantiate()
		soldier.rotation.y = PI   # model faces -Z; pilot moves +Z
		vis.add_child(soldier)
		return
	# --- fallback: stand-in Union soldier from primitives (suit capsule, visor, pack, rifle) ---
	var suit := StandardMaterial3D.new()
	suit.albedo_color = Color(0.55, 0.56, 0.52); suit.roughness = 0.8
	var visor := StandardMaterial3D.new()
	visor.albedo_color = Color(0.9, 0.55, 0.15); visor.metallic = 0.8; visor.roughness = 0.2
	var gear := StandardMaterial3D.new()
	gear.albedo_color = Color(0.25, 0.26, 0.28); gear.roughness = 0.7

	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new(); cap.radius = 0.32; cap.height = 1.5
	body.mesh = cap; body.material_override = suit
	body.position.y = 0.85
	vis.add_child(body)
	var helmet := MeshInstance3D.new()
	var hs := SphereMesh.new(); hs.radius = 0.24; hs.height = 0.48
	helmet.mesh = hs; helmet.material_override = suit
	helmet.position.y = 1.72
	vis.add_child(helmet)
	var vzr := MeshInstance3D.new()
	var vb := BoxMesh.new(); vb.size = Vector3(0.3, 0.14, 0.12)
	vzr.mesh = vb; vzr.material_override = visor
	vzr.position = Vector3(0, 1.74, -0.18)
	vis.add_child(vzr)
	var pack := MeshInstance3D.new()
	var pb := BoxMesh.new(); pb.size = Vector3(0.4, 0.55, 0.22)
	pack.mesh = pb; pack.material_override = gear
	pack.position = Vector3(0, 1.1, 0.3)
	vis.add_child(pack)
	var rifle := MeshInstance3D.new()
	var rb := BoxMesh.new(); rb.size = Vector3(0.08, 0.12, 0.9)
	rifle.mesh = rb; rifle.material_override = gear
	rifle.position = Vector3(0.3, 1.0, -0.3)
	vis.add_child(rifle)

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
