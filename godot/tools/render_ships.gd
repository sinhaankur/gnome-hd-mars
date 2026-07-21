extends SceneTree
## Render the orbital mothership + sub-ship (with HAWC pod) to check the look.
## Run: godot --path godot -s tools/render_ships.gd
const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT); _run.call_deferred()

func _shot(name: String, node: Node3D, dist: float) -> void:
	var root := Node3D.new()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 40, 0); sun.light_energy = 2.0
	sun.light_color = Color(1, 0.95, 0.9); root.add_child(sun)
	var we := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.02, 0.02, 0.04)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.3, 0.3, 0.4); e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; we.environment = e
	root.add_child(we)
	root.add_child(node)
	get_root().add_child(root)
	for _i in range(2): await process_frame
	# frame by the ship's real merged AABB (its geometry is offset from origin)
	var aabb := _aabb(node)
	var ctr := aabb.get_center()
	var rad := maxf(aabb.size.length() * 0.62, 0.2)
	var cam := Camera3D.new()
	cam.position = ctr + Vector3(rad, rad * 0.55, rad)
	cam.look_at_from_position(cam.position, ctr, Vector3.UP)
	cam.current = true; root.add_child(cam)
	for _i in range(3): await process_frame
	get_root().get_texture().get_image().save_png(OUT + name + ".png")
	print("saved ", name)
	root.queue_free(); await process_frame

func _aabb(n: Node, acc := AABB(), first := [true]) -> AABB:
	if n is MeshInstance3D:
		var b: AABB = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).get_aabb()
		if first[0]: acc = b; first[0] = false
		else: acc = acc.merge(b)
	for c in n.get_children():
		acc = _aabb(c, acc, first)
	return acc

func _run() -> void:
	var ships := load("res://scripts/orbital_ships.gd")
	await _shot("ship_mother", ships.mothership(), 1.4)
	# sub-ship with the HAWC riding the cradle
	var sub: Node3D = ships.subship()
	var pod: Node3D = ships.hawc_pod()
	pod.position = Vector3(0, -0.09, 0); pod.scale = Vector3.ONE * 1.4
	sub.add_child(pod)
	await _shot("ship_sub_hawc", sub, 0.5)
	print("done"); quit()
