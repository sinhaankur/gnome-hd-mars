extends SceneTree
## Art-pass check: player (union tan) vs enemy (darken->new red) mechs side by side
## on tan ground, mid-distance, to confirm enemies READ and aren't "floating red bars".
## Run: godot --path godot -s tools/render_enemy_check.gd   (needs a display)
const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"
const MECH := "res://assets/warrior.glb"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT); _run.call_deferred()

func _run() -> void:
	var root := Node3D.new()
	# tan Mars-ish ground plane
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(120, 120); ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.72, 0.60, 0.46); gm.roughness = 1.0
	ground.material_override = gm; root.add_child(ground)
	# sun + tan ambient like the game
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0); sun.light_energy = 2.6
	sun.light_color = Color(1.0, 0.93, 0.83); root.add_child(sun)
	var we := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.78, 0.68, 0.55)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.70, 0.62, 0.55); e.ambient_light_energy = 0.9
	e.fog_enabled = true; e.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	e.fog_light_color = Color(0.74, 0.66, 0.56); e.fog_density = 0.006
	e.tonemap_mode = Environment.TONE_MAPPER_ACES; we.environment = e; root.add_child(we)
	get_root().add_child(root)

	var scene: PackedScene = load(MECH)
	# player (union tan) at left, enemy (darken=new red) at right, a few metres back
	for spec in [{"x": -8.0, "tint": "union"}, {"x": 8.0, "tint": "darken"}]:
		var m := scene.instantiate()
		m.scale = Vector3.ONE * 2.8
		root.add_child(m)
		m.position = Vector3(spec["x"], 0, -18.0)
		m.rotation.y = PI
		Faction.tint(m, spec["tint"])

	var cam := Camera3D.new()
	cam.position = Vector3(0, 9, 6); cam.look_at_from_position(cam.position, Vector3(0, 4, -18), Vector3.UP)
	cam.current = true; root.add_child(cam)
	for _i in range(4): await process_frame
	get_root().get_texture().get_image().save_png(OUT + "enemy_check.png")
	print("saved enemy_check"); quit()
