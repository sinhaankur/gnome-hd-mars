extends SceneTree
## Look at the DEPLOY point where the HAWC lands (z=160): the real Perseverance
## mars_patch tile sunk into the terrain. Checks "the HAWC lands on something strange".
const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"
func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT); _run.call_deferred()
func _run() -> void:
	var Env := load("res://scripts/environment_engine.gd")
	var env = Env.new(); env.world_size = 800.0; env.height_scale = 34.0
	get_root().add_child(env)
	for _i in range(60): await process_frame
	var gy = env.ground_height(0, 160)
	if is_nan(gy): gy = 5.0
	var cam := Camera3D.new()
	cam.position = Vector3(0, gy + 30, 160 + 4)
	cam.look_at_from_position(cam.position, Vector3(0, gy, 160), Vector3.UP)
	cam.current = true; get_root().add_child(cam)
	for _i in range(6): await process_frame
	get_root().get_texture().get_image().save_png(OUT + "landing_zone.png")
	print("saved landing_zone gy=", gy); quit()
