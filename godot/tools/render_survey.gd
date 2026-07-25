extends SceneTree
## Art-pass survey: build the real EnvironmentEngine and fly a high wide camera over it
## so we can spot "useless clutter" on the Mars terrain (wreckage boxes, mesas, outposts).
## Run: godot --path godot -s tools/render_survey.gd   (needs a display)
const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT); _run.call_deferred()

func _run() -> void:
	var Env := load("res://scripts/environment_engine.gd")
	var env = Env.new()
	env.world_size = 800.0
	env.height_scale = 34.0
	get_root().add_child(env)
	# wait for terrain physics + scatter to build
	for _i in range(60): await process_frame
	var cam := Camera3D.new()
	# high oblique looking down over the installation/play area (installation at z=-180)
	cam.position = Vector3(120, 160, 120)
	cam.look_at_from_position(cam.position, Vector3(0, 0, 0), Vector3.UP)
	cam.far = 3000.0
	cam.current = true
	get_root().add_child(cam)
	for _i in range(6): await process_frame
	get_root().get_texture().get_image().save_png(OUT + "survey_wide.png")
	# a lower pass near the player deploy point (z=160) to see near-field clutter
	cam.position = Vector3(40, 45, 230)
	cam.look_at_from_position(cam.position, Vector3(0, 5, 160), Vector3.UP)
	for _i in range(6): await process_frame
	get_root().get_texture().get_image().save_png(OUT + "survey_deploy.png")
	print("saved survey"); quit()
