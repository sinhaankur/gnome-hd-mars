extends CharacterBody3D
## Rival HAWC AI — a role-driven combat brain, not a straight-line rusher. Each unit
## picks a behavior from its role (set by EnemyTiers): rushers close in, snipers hold
## long range and reposition, anchors stand their ground, flankers circle and strafe.
## All of them strafe while shooting and RETREAT when badly hurt, so a fight has motion
## and reads differently per machine type instead of a firing line marching at you.

@export var hp: int = 3
@export var move_speed: float = 6.0
@export var detect_range: float = 80.0
@export var stop_range: float = 22.0      # keeps distance to shoot
@export var fire_range: float = 60.0
@export var fire_cooldown: float = 1.4
@export var gravity: float = 24.0
@export var role: String = "sniper"       # rusher | sniper | anchor | flanker

var _player: Node3D
var _cool := 0.0
var terrain: Node = null               # set by level for height (optional)
var primary_target: Node3D = null      # the installation to assault (set by EnemyEngine)

# --- behavior state ---
var _max_hp := 3
var _strafe_dir := 1.0                  # +1 / -1: which way this unit circles
var _strafe_timer := 0.0                # time until it reverses strafe direction
var _prefer_range := 22.0              # the standoff distance this role wants to hold
var _repos_timer := 0.0                 # snipers/flankers pick a new spot periodically
var _repos_offset := Vector3.ZERO       # current reposition nudge

signal destroyed

const LaserScene := preload("res://scenes/laser.tscn")

func _ready() -> void:
	add_to_group("enemies")
	_cool = randf() * fire_cooldown
	_max_hp = maxi(hp, 1)
	_strafe_dir = 1.0 if randf() < 0.5 else -1.0
	_strafe_timer = randf_range(1.5, 3.0)
	# role sets the standoff distance + how aggressively it moves
	match role:
		"rusher":  _prefer_range = 12.0; fire_range = 45.0
		"sniper":  _prefer_range = 48.0; fire_range = 80.0
		"anchor":  _prefer_range = 26.0; fire_range = 60.0
		"flanker": _prefer_range = 20.0; fire_range = 55.0
		_:         _prefer_range = stop_range

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
		# always face the target while engaged (so shots and the model read correctly)
		var look := global_position + to_player
		look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP)

		var dir := to_player.normalized()
		# perpendicular, for strafing/circling around the target
		var perp := Vector3(-dir.z, 0.0, dir.x)

		# reverse strafe direction on a timer so units weave instead of orbiting forever
		_strafe_timer -= delta
		if _strafe_timer <= 0.0:
			_strafe_dir *= -1.0
			_strafe_timer = randf_range(1.4, 2.8)

		# badly hurt units break contact and fall back (except anchors, who dig in)
		var hurt := hp <= maxi(1, int(_max_hp * 0.35)) and role != "anchor"

		var move := Vector3.ZERO
		if hurt:
			# RETREAT: back away while still facing/firing, with a little strafe jink
			move = (-dir * 1.0 + perp * _strafe_dir * 0.5).normalized() * move_speed
		else:
			# hold the role's preferred standoff range: close if too far, back off if
			# too close, and strafe once roughly in the pocket.
			var err := dist - _prefer_range
			var radial := 0.0
			if err > 4.0:
				radial = 1.0          # too far -> advance
			elif err < -4.0:
				radial = -0.7         # too close -> ease back
			var strafe_amt := 0.9
			if role == "anchor":
				strafe_amt = 0.25     # heavies barely move, just shuffle
				radial *= 0.5
			elif role == "flanker":
				strafe_amt = 1.15     # flankers circle hard
			elif role == "sniper":
				strafe_amt = 0.6
			move = (dir * radial + perp * _strafe_dir * strafe_amt)
			if move.length() > 0.01:
				move = move.normalized() * move_speed * (0.6 if radial == 0.0 else 1.0)

		velocity.x = move.x
		velocity.z = move.z

		# fire when in range and roughly facing — cadence from the tier
		_cool = max(0.0, _cool - delta)
		if dist < fire_range and _cool <= 0.0:
			_fire()
			# rushers/flankers fire a touch faster when close for pressure
			_cool = fire_cooldown * (0.85 if dist < _prefer_range * 1.3 else 1.0)
	else:
		# out of detection: advance on the primary target (installation) so waves still assault
		if primary_target and is_instance_valid(primary_target):
			var tp := (primary_target.global_position - global_position); tp.y = 0.0
			if tp.length() > 6.0:
				var d2 := tp.normalized()
				velocity.x = d2.x * move_speed
				velocity.z = d2.z * move_speed
				var lk := global_position + tp
				look_at(Vector3(lk.x, global_position.y, lk.z), Vector3.UP)
			else:
				velocity.x = 0.0; velocity.z = 0.0
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

var vacant := false   # pilot ejected: hull is inert and can be commandeered

func eject_pilot() -> void:
	# GASHR hit (non-lethal): the pilot bails, the HAWC powers down intact.
	# Leaving the "enemies" group neutralizes it for the wave; joining "hijackable"
	# lets the on-foot player steal it — the G-NOME signature loop.
	if vacant:
		return
	vacant = true
	remove_from_group("enemies")
	add_to_group("hijackable")
	set_physics_process(false)
	velocity = Vector3.ZERO
	# canopy pop: flash + a small pilot capsule that flees and despawns (flavor)
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
	if parent and is_inside_tree():
		var top := global_position + Vector3.UP * 5.0
		Atoms.flash_light(parent, top, Color(0.5, 1.0, 0.6), 5.0, 10.0, 0.3)
		Atoms.spark_burst(parent, top, Color(0.7, 0.8, 0.7), 8)
		var runner := MeshInstance3D.new()
		var cm := CapsuleMesh.new(); cm.radius = 0.3; cm.height = 1.4
		runner.mesh = cm
		var rm := StandardMaterial3D.new(); rm.albedo_color = Color(0.4, 0.38, 0.35)
		runner.material_override = rm
		parent.add_child(runner)
		runner.global_position = global_position + Vector3.UP * 1.0
		var flee := (global_position - top).cross(Vector3.UP)
		flee = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() if flee.length() < 0.1 else flee.normalized()
		var tw := runner.create_tween()
		tw.tween_property(runner, "global_position", runner.global_position + flee * 40.0, 8.0)
		tw.tween_callback(runner.queue_free)

func take_hit() -> void:
	hp -= 1
	hit_registered.emit()
	_flash_red()
	# REAL damage state: as armor is stripped the hull darkens/scorches and (past half)
	# trails smoke — an honest read of how hurt it is, not a fake shrink.
	_apply_damage_state()
	var sfx := get_node_or_null("/root/Sfx")
	if hp <= 0:
		if sfx:
			sfx.explosion()
		_spawn_explosion()
		if not vacant:          # a vacant hull already left the wave count on eject
			destroyed.emit()
		queue_free()
	elif sfx:
		sfx.hit()

func _apply_damage_state() -> void:
	# darken the armor toward scorched metal in proportion to damage taken, and start a
	# smoke plume once it's below half integrity. Uses a persistent overlay so the damage
	# STAYS (unlike the brief red hit flash).
	var frac := 1.0 - clampf(float(hp) / float(_max_hp), 0.0, 1.0)   # 0 fresh -> 1 wrecked
	for mi in Atoms.all_mesh_instances(self):
		if mi.get_meta("dmg_overlay", false):
			continue   # already has the persistent scorch overlay; tint updates below
	# a shared scorch overlay whose darkness tracks damage
	if _scorch_mat == null:
		_scorch_mat = StandardMaterial3D.new()
		_scorch_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for mi in Atoms.all_mesh_instances(self):
			mi.material_overlay = _scorch_mat
			mi.set_meta("dmg_overlay", true)
	_scorch_mat.albedo_color = Color(0.05, 0.04, 0.03, frac * 0.55)   # soot builds up
	# smoke once badly hurt
	if frac >= 0.5 and _smoke == null:
		_start_smoke()

var _scorch_mat: StandardMaterial3D
var _smoke: GPUParticles3D

func _start_smoke() -> void:
	_smoke = GPUParticles3D.new()
	_smoke.amount = 18
	_smoke.lifetime = 1.6
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, 1.0, 0)          # smoke rises
	pm.scale_min = 0.8; pm.scale_max = 2.2
	pm.color = Color(0.15, 0.14, 0.13, 0.5)
	_smoke.process_material = pm
	var qm := QuadMesh.new(); qm.size = Vector2(1.2, 1.2)
	_smoke.draw_pass_1 = qm
	var sm := StandardMaterial3D.new()
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	sm.albedo_color = Color(0.12, 0.11, 0.10, 0.45)
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_smoke.material_override = sm
	_smoke.position = Vector3(0, 4.0, 0)
	add_child(_smoke)

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
