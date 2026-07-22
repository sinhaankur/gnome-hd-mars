extends Area3D
## Player secondary weapon: a rocket (the TCROCK/SAG5T-class ordnance every heavy/tactical
## HAWC in HawcSpecs carries). Flies straight, trails smoke, and on impact deals SPLASH
## damage in a radius — so it's a real tactical alternative to the single-target laser:
## slower, limited by a longer cooldown, but clears grouped enemies.

@export var speed: float = 55.0
@export var life: float = 4.0
@export var splash_radius: float = 8.0
@export var splash_hits: int = 3          # take_hit() calls applied to each enemy in radius

var _trail: GPUParticles3D

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	# a warm engine glow travelling with the rocket
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.6, 0.2); glow.light_energy = 2.0; glow.omni_range = 5.0
	add_child(glow)
	# the rocket body — a small dart so it reads as ordnance, not a bolt
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new(); cap.radius = 0.22; cap.height = 1.2
	mi.mesh = cap; mi.rotation.x = PI / 2.0
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.5, 0.5, 0.52); m.metallic = 0.6; m.roughness = 0.4
	mi.material_override = m
	add_child(mi)
	_trail = _make_trail()
	add_child(_trail)

func _make_trail() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 30; p.lifetime = 0.7; p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 1); pm.spread = 8.0
	pm.initial_velocity_min = 1.0; pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, 0.5, 0)
	pm.scale_min = 0.5; pm.scale_max = 1.4
	pm.color = Color(0.6, 0.55, 0.5, 0.4)
	p.process_material = pm
	var qm := QuadMesh.new(); qm.size = Vector2(0.8, 0.8); p.draw_pass_1 = qm
	var sm := StandardMaterial3D.new()
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0.55, 0.5, 0.46, 0.35)
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	p.material_override = sm
	p.emitting = true
	return p

func _process(delta: float) -> void:
	global_position += -global_transform.basis.z * speed * delta
	life -= delta
	if life <= 0.0:
		_detonate()

func _on_hit(other: Node) -> void:
	if other.is_in_group("player"):
		return   # don't self-detonate on the firer
	_detonate()

func _detonate() -> void:
	var parent := get_parent()
	if parent and is_inside_tree():
		# real area-of-effect: every enemy within splash_radius takes hits. Hits fall off
		# with distance — full splash_hits at ground zero, at least 1 at the rim.
		var hits: int = maxi(1, splash_hits)
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			var d: float = e.global_position.distance_to(global_position)
			if d <= splash_radius and e.has_method("take_hit"):
				var n: int = maxi(1, int(round(hits * (1.0 - d / splash_radius))))
				for _i in range(n):
					e.take_hit()
		# big impact FX (shared atoms) + a scorch-dust puff
		Atoms.flash_light(parent, global_position, Color(1.0, 0.55, 0.2), 10.0, splash_radius * 1.5, 0.35)
		Atoms.spark_burst(parent, global_position, Color(1.0, 0.6, 0.25), 20)
		var sfx := get_node_or_null("/root/Sfx")
		if sfx and sfx.has_method("explosion"):
			sfx.explosion()
	queue_free()
