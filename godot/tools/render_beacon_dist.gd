extends SceneTree
## Does the beacon strobe read from the real reach distance through the real fog?
## Places the camera at mech eye height 228 m from the beacon, looking straight at
## it, with the game's actual exponential tan fog. Saves reference/shots/beacon_dist.png
## Run: godot --path godot -s tools/render_beacon_dist.gd

const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"
const DIST := 228.0

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_run.call_deferred()

func _run() -> void:
	var root := Node3D.new()

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 60, 0)   # side-ish so the strobe isn't washed by sun glare
	sun.light_color = Color(1.0, 0.86, 0.72)
	sun.light_energy = 1.3
	root.add_child(sun)

	# EXACT game fog: exponential tan haze, density 0.002 (environment_engine.gd)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.70, 0.55, 0.42)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.42, 0.35)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	e.fog_light_color = Color(0.74, 0.66, 0.56)
	e.fog_density = 0.002
	e.fog_sky_affect = 0.15
	we.environment = e
	root.add_child(we)

	# ground
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(700, 700)
	ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.62, 0.47, 0.36); gm.roughness = 1.0
	ground.material_override = gm
	root.add_child(ground)

	var beacon: Node = load("res://scripts/beacon.gd").new()
	root.add_child(beacon)   # at origin

	# camera at mech eye height (~6 m), DIST away on +Z, looking at the beacon top
	var cam := Camera3D.new()
	cam.position = Vector3(0, 6.0, DIST)
	cam.look_at_from_position(cam.position, Vector3(0, 12, 0), Vector3.UP)
	cam.fov = 70.0
	cam.current = true
	root.add_child(cam)

	get_root().add_child(root)
	# advance a few frames so the strobe is in its bright phase
	for _i in range(3):
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(OUT + "beacon_dist.png")
	# also a 3x center crop to judge the pinpoint
	var w := img.get_width(); var h := img.get_height()
	var region := Rect2i(int(w*0.40), int(h*0.20), int(w*0.20), int(h*0.35))
	var crop := img.get_region(region)
	crop.save_png(OUT + "beacon_dist_crop.png")
	print("saved beacon_dist.png @ %.0f m" % DIST)
	quit()
