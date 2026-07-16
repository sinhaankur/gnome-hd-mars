extends Node3D
## Level 1 — Darken Republic, Mission 1 (prototype).
## Builds the playable world at runtime from the imported gnome_assets.glb:
## desert terrain (collision), player HAWC, crates, a building, and enemy targets.

const HAWC_SPEED := 12.0

var _scene_root: Node3D
var _terrain: StaticBody3D
var _total_enemies := 0
var _player: CharacterBody3D
var _status_label: Label
var _health_label: Label
var _game_over := false

func _ground_y(x: float, z: float) -> float:
	# Sample the dune height so props/enemies rest on the surface.
	if _terrain and _terrain.has_method("height"):
		return _terrain.height(x, z)
	return 0.0

func _ready() -> void:
	_build_environment()
	var glb := _load_assets()
	_spawn_player(glb)
	_spawn_props(glb)
	_spawn_enemies(glb)
	_spawn_camera()
	_spawn_hud()

# ---------------------------------------------------------------- environment
func _build_environment() -> void:
	# Sun
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 40, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)

	# Sky/world environment (warm desert)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(0.55, 0.55, 0.70)
	mat.sky_horizon_color = Color(0.78, 0.68, 0.50)
	mat.ground_horizon_color = Color(0.60, 0.50, 0.34)
	mat.ground_bottom_color = Color(0.45, 0.36, 0.24)
	sky.sky_material = mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.80, 0.70, 0.52)
	env.fog_density = 0.004
	we.environment = env
	add_child(we)

	# Desert dune terrain: procedural heightmap mesh + matching collision.
	_terrain = StaticBody3D.new()
	_terrain.name = "Terrain"
	_terrain.set_script(load("res://scripts/terrain.gd"))
	add_child(_terrain)

# ---------------------------------------------------------------- assets
func _load_assets() -> Node3D:
	var packed: PackedScene = load("res://assets/gnome_assets.glb")
	if packed == null:
		push_error("gnome_assets.glb failed to load")
		return null
	return packed.instantiate()

func _grab(glb: Node, prefix: String) -> Array:
	# Collect mesh nodes whose name starts with prefix (e.g. "HAWC_", "crate", "Bld", "Scorp").
	var out: Array = []
	_collect(glb, prefix, out)
	return out

func _collect(node: Node, prefix: String, out: Array) -> void:
	if node is MeshInstance3D and node.name.begins_with(prefix):
		out.append(node)
	for c in node.get_children():
		_collect(c, prefix, out)

func _clone_group(glb: Node3D, prefix: String) -> Node3D:
	# Duplicate all meshes of a prefix into a fresh Node3D, preserving relative transforms.
	var holder := Node3D.new()
	for m in _grab(glb, prefix):
		var dup: MeshInstance3D = m.duplicate()
		holder.add_child(dup)
		dup.transform = m.transform   # keep local layout relative to mech root
	return holder

# ---------------------------------------------------------------- player
func _spawn_player(glb: Node3D) -> void:
	var body := CharacterBody3D.new()
	body.name = "PlayerHAWC"
	body.set_script(load("res://scripts/hawc.gd"))
	body.max_speed = HAWC_SPEED

	# visual: the wr_hawk.glb model (exact copy), oriented & scaled to the level.
	# Source model is Z-up (~17 units tall); rotate -90° X to stand upright in Godot's Y-up,
	# and scale down to ~7 units tall to match level scale.
	var visual := Node3D.new()
	visual.name = "Visual"
	var hawk_scene: PackedScene = load("res://assets/wr_hawk.glb")
	if hawk_scene:
		var hawk := hawk_scene.instantiate()
		hawk.rotation_degrees = Vector3(-90, 0, 0)   # Z-up -> Y-up
		hawk.scale = Vector3.ONE * 0.42              # ~17 -> ~7 units tall
		visual.add_child(hawk)
	else:
		# fallback: old block meshes if the model fails to load
		visual = _clone_group(glb, "HAWC_")
		visual.name = "Visual"
	body.add_child(visual)

	# collision capsule sized to the mech
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.6
	cap.height = 6.0
	col.shape = cap
	col.position.y = 3.4
	body.add_child(col)

	# muzzles for weapon fire (at the shoulder gun tips, ~z forward)
	var ml := Node3D.new(); ml.name = "MuzzleL"; ml.position = Vector3(-1.6, 5.4, -2.6); body.add_child(ml)
	var mr := Node3D.new(); mr.name = "MuzzleR"; mr.position = Vector3( 1.6, 5.4, -2.6); body.add_child(mr)

	body.position = Vector3(0, _ground_y(0, 0) + 1.0, 0)
	add_child(body)

# ---------------------------------------------------------------- props
func _spawn_props(glb: Node3D) -> void:
	# crates scattered (rest on the dune surface)
	var positions := [Vector2(14, -10), Vector2(-12, -18), Vector2(20, 8)]
	var crate_prefixes := ["crate_AMMO", "crate_HEALTH", "crate_WEAPON"]
	for i in range(positions.size()):
		var p: Vector2 = positions[i]
		var c := _clone_group(glb, crate_prefixes[i])
		c.position = Vector3(p.x, _ground_y(p.x, p.y) + 0.7, p.y)
		add_child(c)
	# a building
	var bld := _clone_group(glb, "Bld")
	bld.position = Vector3(-30, _ground_y(-30, -30), -30)
	add_child(bld)
	# bridge
	var brg := _clone_group(glb, "Brg")
	brg.position = Vector3(40, _ground_y(40, 20), 20)
	add_child(brg)

# ---------------------------------------------------------------- enemies
func _spawn_enemies(glb: Node3D) -> void:
	var spots := [Vector2(25, -25), Vector2(-20, 10), Vector2(10, -35), Vector2(-35, -15)]
	for s in spots:
		var enemy := CharacterBody3D.new()
		enemy.set_script(load("res://scripts/enemy_ai.gd"))
		enemy.terrain = _terrain
		var visual := _clone_group(glb, "Scorp")
		enemy.add_child(visual)
		var col := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 1.8
		cap.height = 6.0
		col.shape = cap
		col.position.y = 3.0
		enemy.add_child(col)
		enemy.position = Vector3(s.x, _ground_y(s.x, s.y) + 1.4, s.y)
		add_child(enemy)
	_total_enemies = spots.size()

# ---------------------------------------------------------------- camera
func _spawn_camera() -> void:
	var cam := Camera3D.new()
	cam.set_script(load("res://scripts/follow_camera.gd"))
	cam.target_path = NodePath("../PlayerHAWC")
	cam.current = true
	cam.fov = 65
	add_child(cam)

# ---------------------------------------------------------------- hud
func _spawn_hud() -> void:
	var cl := CanvasLayer.new()
	var title := Label.new()
	title.text = "G-NOME HD — Level 1: Darken Republic\nW/S throttle · MOUSE steer · SPACE fire · ESC release mouse"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 18)
	cl.add_child(title)

	_health_label = Label.new()
	_health_label.position = Vector2(20, 70)
	_health_label.add_theme_font_size_override("font_size", 20)
	cl.add_child(_health_label)

	_status_label = Label.new()
	_status_label.position = Vector2(20, 100)
	_status_label.add_theme_font_size_override("font_size", 20)
	cl.add_child(_status_label)
	add_child(cl)

	_player = get_node_or_null("PlayerHAWC")
	if _player:
		_player.connect("died", Callable(self, "_on_player_died"))
	_update_hud()

func _update_hud() -> void:
	if _player and is_instance_valid(_player):
		var spd := 0.0
		if _player.has_method("get_speed_ratio"):
			spd = _player.get_speed_ratio() * 100.0
		_health_label.text = "ARMOR: %d%%    THROTTLE: %d%%" % [_player.health, int(spd)]
	var alive := get_tree().get_nodes_in_group("enemies").size()
	_status_label.text = "SCORP REMAINING: %d / %d" % [alive, _total_enemies]

func _process(_delta: float) -> void:
	if _game_over:
		return
	_update_hud()
	# win condition: all enemies destroyed (and at least one existed)
	if _total_enemies > 0 and get_tree().get_nodes_in_group("enemies").size() == 0:
		_status_label.text = "MISSION ACCOMPLISHED"
		_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		_game_over = true

func _on_player_died() -> void:
	_status_label.text = "HAWC DESTROYED — MISSION FAILED"
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	_game_over = true
