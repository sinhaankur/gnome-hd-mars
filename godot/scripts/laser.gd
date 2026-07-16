extends Area3D
## Laser bolt. Player bolts damage enemies; enemy bolts damage the player.

@export var speed: float = 90.0    # faster = reads as a real bolt
@export var life: float = 2.5
var from_enemy: bool = false

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	# a glowing light travels with the bolt so it lights up the ground/mechs it passes
	var glow := OmniLight3D.new()
	glow.name = "BoltGlow"
	glow.light_color = Color(1.0, 0.4, 0.15) if from_enemy else Color(1.0, 0.65, 0.2)
	glow.light_energy = 1.6   # restrained: a bolt lights its surroundings, it doesn't floodlight
	glow.omni_range = 4.0
	add_child(glow)
	# tint the bolt mesh red for enemy fire, orange for player
	if from_enemy:
		for mi in _meshes(self):
			var m := StandardMaterial3D.new()
			m.emission_enabled = true
			m.emission = Color(1.0, 0.3, 0.2)
			m.emission_energy_multiplier = 3.0
			m.albedo_color = Color(1.0, 0.3, 0.2)
			mi.material_override = m

func _process(delta: float) -> void:
	global_position += -global_transform.basis.z * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_hit(other: Node) -> void:
	# Enemy bolts only hurt the player; player bolts only hurt enemies.
	if from_enemy:
		if other.is_in_group("player") and other.has_method("take_damage"):
			other.take_damage(1)
			_impact()
			queue_free()
		elif other.is_in_group("enemies"):
			return   # pass through fellow enemies
		elif not other.is_in_group("enemies"):
			_impact()   # hit terrain / prop
			queue_free()
	else:
		if other.is_in_group("enemies") and other.has_method("take_hit"):
			other.take_hit()
			_impact()
			queue_free()
		elif other.is_in_group("player"):
			return   # don't self-hit
		else:
			_impact()
			queue_free()

func _impact() -> void:
	# a burst of sparks + a flash where the bolt lands — shared atoms, not bespoke code
	var parent := get_parent()
	if parent == null or not is_inside_tree():
		return
	var col := Color(1.0, 0.4, 0.2) if from_enemy else Color(1.0, 0.7, 0.3)
	Atoms.flash_light(parent, global_position, col, 6.0, 8.0, 0.25)
	Atoms.spark_burst(parent, global_position, col, 10)

func _meshes(n: Node, out: Array = []) -> Array:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_meshes(c, out)
	return out
