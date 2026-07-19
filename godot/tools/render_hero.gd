extends SceneTree
## Isolated before/after render of the hero HAWC material fix.
## Loads the mech under a single Mars-like sun and captures two PNGs:
##   reference/shots/hero_raw.png   (as the GLB ships)
##   reference/shots/hero_fixed.png (after HeroMaterialFix.apply)
## Run: godot --path godot -s tools/render_hero.gd   (needs a display / not --headless)

const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"

func _stage(apply_fix: bool) -> Node3D:
	var root := Node3D.new()

	# Mars-ish key light — warm, single directional, matching the game's mars_sun feel.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.light_color = Color(1.0, 0.86, 0.72)
	sun.light_energy = 1.3
	root.add_child(sun)

	# soft fill so the shadow side isn't pure black (matches ambient/world in-game)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.35, 0.25)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.38, 0.32)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	root.add_child(env)

	var scene: PackedScene = load("res://assets/hawc_hero.glb")
	var hawk := scene.instantiate()
	hawk.scale = Vector3.ONE * 2.8
	if apply_fix:
		# load by path — class_name globals may not be registered in a bare -s run
		var fix := load("res://scripts/hero_material_fix.gd")
		fix.apply(hawk)
	root.add_child(hawk)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 4.5, 12)
	cam.rotation_degrees = Vector3(-12, 0, 0)
	cam.current = true
	root.add_child(cam)
	return root

func _init() -> void:
	# ensure output dir exists
	DirAccess.make_dir_recursive_absolute(OUT)
	_run.call_deferred()

func _run() -> void:
	for pass_i in [false, true]:
		var stage := _stage(pass_i)
		get_root().add_child(stage)
		# let the renderer settle a couple frames before grabbing the frame
		await process_frame
		await process_frame
		await process_frame
		var img := get_root().get_texture().get_image()
		var name := "hero_fixed.png" if pass_i else "hero_raw.png"
		img.save_png(OUT + name)
		print("saved ", name)
		stage.queue_free()
		await process_frame
	print("done")
	quit()
