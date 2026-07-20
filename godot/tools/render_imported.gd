extends SceneTree
## Render a thumbnail of each imported Star-Cleaver asset so we can judge fit before
## wiring any into the game. Saves reference/shots/imp_<name>.png
## Run: godot --path godot -s tools/render_imported.gd   (needs a display)

const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"
const ASSETS := [
	"asteroid-stony", "asteroid-carbon", "voyager", "wreck", "cargo-container", "debris", "mars",
]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_run.call_deferred()

func _run() -> void:
	for name in ASSETS:
		var root := Node3D.new()
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-40, 35, 0)
		sun.light_color = Color(1.0, 0.9, 0.8); sun.light_energy = 1.4
		root.add_child(sun)
		var we := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.15, 0.15, 0.18)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.5, 0.5, 0.55); e.ambient_light_energy = 0.6
		e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		we.environment = e
		root.add_child(we)

		var scene: PackedScene = load("res://assets/imported/%s.glb" % name)
		if scene == null:
			print("MISS ", name); continue
		var inst := scene.instantiate()
		root.add_child(inst)
		get_root().add_child(root)
		await process_frame

		# frame the object by its merged AABB
		var aabb := _merged_aabb(inst)
		var ctr := aabb.get_center()
		var rad := maxf(aabb.size.length() * 0.6, 1.0)
		var cam := Camera3D.new()
		cam.position = ctr + Vector3(rad, rad * 0.7, rad)
		cam.look_at_from_position(cam.position, ctr, Vector3.UP)
		root.add_child(cam)
		for _i in range(3):
			await process_frame
		var img := get_root().get_texture().get_image()
		img.save_png(OUT + "imp_%s.png" % name)
		print("saved imp_%s.png  size=%s" % [name, str(aabb.size)])
		root.queue_free()
		await process_frame
	print("done")
	quit()

func _merged_aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for mi in _all_mesh(n, []):
		var b: AABB = (mi as MeshInstance3D).get_aabb()
		b = mi.global_transform * b
		if first: out = b; first = false
		else: out = out.merge(b)
	if first: out = AABB(Vector3.ZERO, Vector3.ONE)
	return out

func _all_mesh(n: Node, acc: Array) -> Array:
	if n is MeshInstance3D: acc.append(n)
	for c in n.get_children(): _all_mesh(c, acc)
	return acc
