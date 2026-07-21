extends SceneTree
## Environment showcase — boots the real EnvironmentEngine (Mars world: terrain, sky,
## sun, scatter, installation, real-rover landing zone) with NO HUD and captures a set
## of clean establishing shots from good vantage points. For SEEING the environment.
## Run: godot --path godot -s tools/env_showcase.gd   (needs a display)

const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_run.call_deferred()

func _run() -> void:
	# build the world exactly as a mission does
	var EnvEngine := load("res://scripts/environment_engine.gd")
	var env: Node = EnvEngine.new()
	env.set("world_size", 800.0)
	env.set("height_scale", 34.0)
	env.set("day_start", 0.34)              # mid-morning: long-ish shadows, bright sky
	env.set("installation_pos", Vector3(0, 0, -180))
	env.set("installation_pad_radius", 32.0)
	get_root().add_child(env)

	# let terrain physics + scatter + landing zone build
	for _i in range(90):
		await physics_frame

	var cam := Camera3D.new()
	cam.fov = 62
	cam.current = true
	get_root().add_child(cam)

	# a set of vantage points: name -> (position, look-at target)
	var shots := [
		["env_wide_installation", Vector3(60, 40, -110), Vector3(0, 6, -180)],
		["env_landing_zone",      Vector3(0, 14, 195),   Vector3(0, 2, 160)],
		["env_plains_low",        Vector3(120, 8, 40),   Vector3(0, 6, -60)],
		["env_hero_sunlit",       Vector3(-90, 22, 120), Vector3(0, 4, -30)],
		["env_horizon",           Vector3(200, 30, 200), Vector3(0, 8, 0)],
	]
	for s in shots:
		cam.global_position = s[1]
		cam.look_at(s[2], Vector3.UP)
		for _j in range(3):
			await process_frame
		get_root().get_texture().get_image().save_png(OUT + s[0] + ".png")
		print("saved ", s[0])
	print("done")
	quit()
