extends SceneTree
## Capture the orbital arrival cinematic over the Mars globe — verify it reads logically:
## mothership in orbit → sub-ship detaches with the HAWC → descends to the target point.
## Saves a strip of frames. Run: godot --path godot -s tools/render_arrival.gd
const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"
const GLOBE_R := 2.0

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT); _run.call_deferred()

func _run() -> void:
	var root := Node3D.new()
	# star-black space + a key sun
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 40, 0); sun.light_energy = 2.2
	root.add_child(sun)
	var we := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.02, 0.02, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.25, 0.25, 0.35); e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; we.environment = e
	root.add_child(we)

	# a stand-in Mars globe (sphere) so the descent has a planet to fall toward
	var globe := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = GLOBE_R; sm.height = GLOBE_R * 2
	sm.radial_segments = 64; sm.rings = 32; globe.mesh = sm
	var gm := StandardMaterial3D.new()
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/mars_globe.jpg"))
	if img: gm.albedo_texture = ImageTexture.create_from_image(img)
	gm.roughness = 1.0; globe.material_override = gm
	root.add_child(globe)

	var cam := Camera3D.new(); cam.fov = 60; cam.current = true
	root.add_child(cam)
	get_root().add_child(root)
	await process_frame

	# target point on the globe (a mid-latitude spot facing +X-ish)
	var target := Vector3(0.6, 0.4, 0.8).normalized() * GLOBE_R
	var arrival: Node = load("res://scripts/orbital_arrival.gd").new()
	root.add_child(arrival)
	arrival.play(target, GLOBE_R, cam)

	# grab frames across the ~6 s sequence
	var shots := 8
	for i in range(shots):
		for _f in range(int(6.0 * 60.0 / shots)):
			await process_frame
		get_root().get_texture().get_image().save_png(OUT + "arrival_%02d.png" % i)
		print("saved arrival_%02d" % i)
	print("done"); quit()
