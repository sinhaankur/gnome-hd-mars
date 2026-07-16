extends Node3D
## Slice 1a — HAWC feel TUNING scene.
## Stripped to essentials: terrain + HAWC + follow camera + a live readout of the
## feel numbers. No enemies, no objectives. The ONLY thing to judge here is: does
## driving the mech feel good? Drive around, then tell me what's off and we adjust
## the exported values in hawc.gd / follow_camera.gd together.

const HAWK_SCALE := 0.42   # wr_hawk.glb source is ~17 tall; scale to ~7 units

var _player: CharacterBody3D
var _cam: Camera3D
var _readout: Label

func _ready() -> void:
	_build_terrain()
	_build_light_and_sky()
	_player = _build_hawc()
	_cam = _build_camera(_player)
	_spawn_talon(Vector3(0, 3, -45))   # one enemy to shoot at (Darken Talon)
	_build_readout()

# ---------------------------------------------------------------- one enemy (Talon)
func _spawn_talon(pos: Vector3) -> void:
	var e := CharacterBody3D.new()
	e.name = "Talon"
	e.set_script(load("res://scripts/enemy_ai.gd"))
	e.hp = 6

	# visual: reuse the HAWC mech look, tinted darker (Darken faction), for now.
	var visual := Node3D.new()
	var scene: PackedScene = load("res://assets/wr_hawk.glb")
	if scene:
		var m := scene.instantiate()
		m.scale = Vector3.ONE * HAWK_SCALE * 0.95
		visual.add_child(m)
	e.add_child(visual)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.6
	cap.height = 6.0
	col.shape = cap
	col.position.y = 3.4
	e.add_child(col)

	e.position = pos
	add_child(e)

# ---------------------------------------------------------------- terrain
@export var biome: String = "desert"   # desert | ice | molten | grass

func _build_terrain() -> void:
	# HD biome terrain (built in Blender, shaded in Godot). Swap `biome` to test others.
	add_child(Biome.make(biome))

# ---------------------------------------------------------------- light + sky
func _build_light_and_sky() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 40, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_horizon_color = Color(0.78, 0.68, 0.50)
	mat.ground_horizon_color = Color(0.60, 0.50, 0.34)
	sky.sky_material = mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.80, 0.70, 0.52)
	env.fog_density = 0.003
	we.environment = env
	add_child(we)

# ---------------------------------------------------------------- HAWC
func _build_hawc() -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "PlayerHAWC"
	body.set_script(load("res://scripts/hawc.gd"))

	# visual: the wr_hawk model, upright + scaled
	var visual := Node3D.new()
	visual.name = "Visual"
	var scene: PackedScene = load("res://assets/wr_hawk.glb")
	if scene:
		var hawk := scene.instantiate()
		# wr_hawk.glb is already Y-up (feet lowest, cabin/tower/cannon highest),
		# and Godot is Y-up, so NO rotation is needed. (The earlier -90 X tipped it over.)
		hawk.rotation_degrees = Vector3.ZERO
		hawk.scale = Vector3.ONE * HAWK_SCALE
		visual.add_child(hawk)
	body.add_child(visual)

	# collision capsule
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.6
	cap.height = 6.0
	col.shape = cap
	col.position.y = 3.4
	body.add_child(col)

	# muzzles (so firing works while we test)
	var ml := Node3D.new(); ml.name = "MuzzleL"; ml.position = Vector3(-1.6, 5.4, -2.6); body.add_child(ml)
	var mr := Node3D.new(); mr.name = "MuzzleR"; mr.position = Vector3(1.6, 5.4, -2.6); body.add_child(mr)

	body.position = Vector3(0, 14, 0)   # spawn above the dunes; gravity settles it onto the surface
	add_child(body)
	return body

# ---------------------------------------------------------------- camera
func _build_camera(target: Node3D) -> Camera3D:
	var cam := Camera3D.new()
	cam.name = "FollowCam"
	cam.set_script(load("res://scripts/follow_camera.gd"))
	cam.target_path = target.get_path()
	cam.current = true
	cam.fov = 65
	add_child(cam)
	return cam

# ---------------------------------------------------------------- live readout
func _build_readout() -> void:
	var cl := CanvasLayer.new()
	var title := Label.new()
	title.text = "HAWC FEEL TUNING — drive around. W/S throttle · MOUSE steer · SPACE fire · ESC free mouse"
	title.position = Vector2(16, 12)
	title.add_theme_font_size_override("font_size", 16)
	cl.add_child(title)

	_readout = Label.new()
	_readout.position = Vector2(16, 44)
	_readout.add_theme_font_size_override("font_size", 15)
	cl.add_child(_readout)
	add_child(cl)

func _process(_delta: float) -> void:
	if _player == null or _readout == null:
		return
	var p := _player
	var spd := 0.0
	if p.has_method("get_speed_ratio"):
		spd = p.get_speed_ratio() * 100.0
	# show the live feel values so you can see what each number is while driving
	_readout.text = "THROTTLE: %3d%%\n\nFEEL NUMBERS (edit in hawc.gd / follow_camera.gd):\n" \
		% int(spd) \
		+ "  max_speed=%.1f   accel=%.1f   decel=%.1f\n" % [p.max_speed, p.accel, p.decel] \
		+ "  mouse_turn=%.4f\n" % p.mouse_turn \
		+ "  cam distance=%.1f   height=%.1f   pos_smooth=%.1f" % [_cam.distance, _cam.height, _cam.pos_smooth]
