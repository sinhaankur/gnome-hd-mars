extends SceneTree
## Isolated render of the reach-objective Beacon outpost, to judge it against the
## art-pass "diegetic, not a light pillar" bar. Saves reference/shots/beacon.png
## Run: godot --path godot -s tools/render_beacon.gd   (needs a display)

const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_run.call_deferred()

func _run() -> void:
	var root := Node3D.new()

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.light_color = Color(1.0, 0.86, 0.72)
	sun.light_energy = 1.3
	root.add_child(sun)

	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.45, 0.34)   # butterscotch sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.42, 0.35)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	root.add_child(we)

	# ground plane in Mars tan
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(60, 60)
	ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.62, 0.47, 0.36); gm.roughness = 1.0
	ground.material_override = gm
	root.add_child(ground)

	var beacon: Node = load("res://scripts/beacon.gd").new()
	root.add_child(beacon)

	var cam := Camera3D.new()
	cam.position = Vector3(10, 7, 16)
	cam.look_at_from_position(cam.position, Vector3(0, 4, 0), Vector3.UP)
	cam.current = true
	root.add_child(cam)

	get_root().add_child(root)
	for _i in range(4):
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(OUT + "beacon.png")
	print("saved beacon.png")
	quit()
