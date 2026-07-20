extends SceneTree
## Isolated render of the installation (base) under Mars lighting, to judge it
## against the real-photo bar. Saves reference/shots/installation.png
## Run: godot --path godot -s tools/render_installation.gd   (needs a display)

const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_run.call_deferred()

func _run() -> void:
	var root := Node3D.new()

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_color = Color(1.0, 0.86, 0.72)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	root.add_child(sun)

	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.68, 0.52, 0.40)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.42, 0.35)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	root.add_child(we)

	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(300, 300)
	ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.62, 0.47, 0.36); gm.roughness = 1.0
	ground.material_override = gm
	root.add_child(ground)

	var inst: Node = load("res://scripts/installation.gd").new()
	inst.set("pad_radius", 32.0)
	root.add_child(inst)

	# two angles: a hero 3/4 and a wide establishing
	get_root().add_child(root)
	var shots := [
		{"pos": Vector3(28, 16, 34), "look": Vector3(0, 6, 0), "name": "installation.png"},
		{"pos": Vector3(60, 28, 70), "look": Vector3(0, 4, 0), "name": "installation_wide.png"},
	]
	for s in shots:
		var cam := Camera3D.new()
		cam.position = s["pos"]
		cam.look_at_from_position(s["pos"], s["look"], Vector3.UP)
		cam.fov = 60.0
		cam.current = true
		root.add_child(cam)
		for _i in range(3):
			await process_frame
		var img := get_root().get_texture().get_image()
		img.save_png(OUT + s["name"])
		print("saved ", s["name"])
		cam.queue_free()
	quit()
