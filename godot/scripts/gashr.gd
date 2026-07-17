extends Area3D
## GASHR shell — G-NOME's non-lethal ejector round. Arcs like a grenade; on striking
## an enemy HAWC it EJECTS the pilot instead of dealing damage, leaving an intact
## vacant hull the player can walk up to and commandeer (the signature steal loop).
## Builds its own mesh/collision so no scene file is needed.

@export var speed: float = 38.0
@export var arc_gravity: float = 12.0   # gentle lob, easy to land at mid range
@export var life: float = 4.0

var _vel := Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	# stubby green shell + soft glow: clearly NOT a laser, reads as utility ordnance
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new(); cm.radius = 0.22; cm.height = 0.7
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.9, 0.5)
	m.emission_enabled = true
	m.emission = Color(0.35, 1.0, 0.5)
	m.emission_energy_multiplier = 2.0
	mi.material_override = m
	mi.rotation_degrees.x = 90
	add_child(mi)
	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new(); cs.radius = 0.4
	col.shape = cs
	add_child(col)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.4, 1.0, 0.5)
	glow.light_energy = 1.2
	glow.omni_range = 3.5
	add_child(glow)
	_vel = -global_transform.basis.z * speed

func _process(delta: float) -> void:
	_vel.y -= arc_gravity * delta
	global_position += _vel * delta
	if _vel.length() > 0.01:
		look_at(global_position + _vel.normalized(), Vector3.UP)
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_hit(other: Node) -> void:
	if other.is_in_group("player"):
		return   # never affects the shooter
	if other.is_in_group("enemies") and other.has_method("eject_pilot"):
		other.eject_pilot()
		_pop()
		queue_free()
	elif not other.is_in_group("enemies"):
		_pop()   # ground/prop: fizzle
		queue_free()

func _pop() -> void:
	var parent := get_parent()
	if parent == null or not is_inside_tree():
		return
	Atoms.flash_light(parent, global_position, Color(0.4, 1.0, 0.5), 5.0, 9.0, 0.3)
	Atoms.spark_burst(parent, global_position, Color(0.5, 1.0, 0.6), 14)
