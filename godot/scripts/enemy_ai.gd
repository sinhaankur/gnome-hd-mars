extends CharacterBody3D
## Scorp enemy AI: detect player, chase within range, fire back, take damage.

@export var hp: int = 3
@export var move_speed: float = 6.0
@export var detect_range: float = 80.0
@export var stop_range: float = 22.0      # keeps distance to shoot
@export var fire_range: float = 60.0
@export var fire_cooldown: float = 1.4
@export var gravity: float = 24.0

var _player: Node3D
var _cool := 0.0
var terrain: Node = null               # set by level for height (optional)
var primary_target: Node3D = null      # the installation to assault (set by EnemyEngine)

signal destroyed

const LaserScene := preload("res://scenes/laser.tscn")

func _ready() -> void:
	add_to_group("enemies")
	_cool = randf() * fire_cooldown

func _current_target() -> Node3D:
	# March on the installation, but if the player HAWC gets close, engage it instead.
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	var tgt: Node3D = primary_target if (primary_target and is_instance_valid(primary_target)) else _player
	if _player and is_instance_valid(_player):
		var dp := (_player.global_position - global_position)
		dp.y = 0.0
		if dp.length() < 35.0:      # player is a threat nearby -> focus the player
			tgt = _player
	return tgt

func _physics_process(delta: float) -> void:
	var target := _current_target()
	if target == null or not is_instance_valid(target):
		return

	var to_player: Vector3 = target.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if dist < detect_range and dist > 0.1:
		# face the player
		var look := global_position + to_player
		look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP)
		# advance until within stop_range
		if dist > stop_range:
			var dir := to_player.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
		# fire
		_cool = max(0.0, _cool - delta)
		if dist < fire_range and _cool <= 0.0:
			_fire()
			_cool = fire_cooldown
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

func _fire() -> void:
	var laser := LaserScene.instantiate()
	laser.set("from_enemy", true)
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
	parent.add_child(laser)
	# spawn at "head" height, aimed forward at the player
	var spawn := global_transform
	spawn.origin += Vector3.UP * 4.0 + (-global_transform.basis.z) * 2.0
	laser.global_transform = spawn

signal hit_registered   # fired whenever this enemy is damaged (for HUD hit marker)

func take_hit() -> void:
	hp -= 1
	scale *= 0.93
	hit_registered.emit()
	_flash_red()
	var sfx := get_node_or_null("/root/Sfx")
	if hp <= 0:
		if sfx:
			sfx.explosion()
		_spawn_explosion()
		destroyed.emit()
		queue_free()
	elif sfx:
		sfx.hit()

func _flash_red() -> void:
	# briefly tint the mech red to show it took a hit (combat feedback)
	for mi in Atoms.all_mesh_instances(self):
		var flash := StandardMaterial3D.new()
		flash.albedo_color = Color(1.0, 0.2, 0.15)
		flash.emission_enabled = true
		flash.emission = Color(1.0, 0.2, 0.15)
		flash.emission_energy_multiplier = 2.0
		mi.material_overlay = flash
		var tw: Tween = mi.create_tween()
		tw.tween_interval(0.08)
		tw.tween_callback(func(): if is_instance_valid(mi): mi.material_overlay = null)

func _spawn_explosion() -> void:
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
	if parent == null:
		return
	if not is_inside_tree():
		return
	var pos := global_position + Vector3.UP * 3.0
	# 1) bright flash light (in-tree BEFORE setting a global transform)
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.6, 0.2)
	flash.light_energy = 10.0
	flash.omni_range = 20.0
	parent.add_child(flash)
	flash.global_position = pos
	var ft: Tween = flash.create_tween()
	ft.tween_property(flash, "light_energy", 0.0, 0.5)
	ft.tween_callback(flash.queue_free)
	# 2) expanding fireball shell
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 1.0; sm.height = 2.0
	ball.mesh = sm
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.emission_enabled = true
	bm.emission = Color(1.0, 0.55, 0.15)
	bm.emission_energy_multiplier = 3.0   # hot but not neon (FX restraint bar)
	bm.albedo_color = Color(1.0, 0.6, 0.2, 0.9)
	ball.material_override = bm
	parent.add_child(ball)
	ball.global_position = pos
	var bt: Tween = ball.create_tween()
	bt.set_parallel(true)
	bt.tween_property(ball, "scale", Vector3.ONE * 6.0, 0.4)
	bt.tween_property(bm, "albedo_color:a", 0.0, 0.4)
	bt.chain().tween_callback(ball.queue_free)
	# 3) flying debris chunks
	for i in range(8):
		var chunk := MeshInstance3D.new()
		chunk.mesh = BoxMesh.new()
		var cm := StandardMaterial3D.new()
		cm.albedo_color = Color(0.2, 0.22, 0.18)
		chunk.material_override = cm
		chunk.scale = Vector3.ONE * randf_range(0.3, 0.8)
		parent.add_child(chunk)
		chunk.global_position = pos
		var dir := Vector3(randf_range(-1,1), randf_range(0.5,1.5), randf_range(-1,1)).normalized()
		var ct: Tween = chunk.create_tween()
		ct.set_parallel(true)
		ct.tween_property(chunk, "global_position", pos + dir * randf_range(6, 14) + Vector3.DOWN * 4, 0.7)
		ct.tween_property(chunk, "rotation", Vector3(randf()*TAU, randf()*TAU, randf()*TAU), 0.7)
		ct.chain().tween_callback(chunk.queue_free)
	# sfx (explosion) already played by take_hit
