extends SceneTree
## Render the Crashed Recon Probe POI (now using the Voyager model) on Mars ground.
## Saves reference/shots/poi_probe.png   Run: godot --path godot -s tools/render_poi.gd

const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_run.call_deferred()

func _run() -> void:
	var root := Node3D.new()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_color = Color(1.0, 0.86, 0.72); sun.light_energy = 1.3
	sun.shadow_enabled = true
	root.add_child(sun)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.66, 0.5, 0.38)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.42, 0.35); e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	root.add_child(we)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(60, 60)
	ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.62, 0.47, 0.36); gm.roughness = 1.0
	ground.material_override = gm
	root.add_child(ground)

	# build just the Crashed Recon Probe POI via the real Exploration builder
	var expl: Node = load("res://scripts/exploration.gd").new()
	root.add_child(expl)
	var poi: Node = expl._build_marker("Crashed Recon Probe", Color(0.6, 0.8, 1.0))
	root.add_child(poi)

	var cam := Camera3D.new()
	cam.position = Vector3(7, 5, 9)
	cam.look_at_from_position(cam.position, Vector3(0, 1.5, 0), Vector3.UP)
	cam.current = true
	root.add_child(cam)
	get_root().add_child(root)
	for _i in range(3):
		await process_frame
	get_root().get_texture().get_image().save_png(OUT + "poi_probe.png")
	print("saved poi_probe.png")
	quit()
