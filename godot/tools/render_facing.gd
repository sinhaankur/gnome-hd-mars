extends SceneTree
## Verify the hero HAWC's walk facing. Reproduces exactly what hawc.gd does:
##   rotation.y = atan2(hv.x, hv.z)   -> body +Z points along movement.
## We rotate the model to the yaw it would have while walking in each cardinal
## direction and render from a FIXED world camera. If the face leads the arrow's
## direction, MECH_FACE_FLIP is correct (0.0); if the back leads, it needs PI.
##
## Camera looks down -Z (toward +Z scene). We walk the mech toward +X (screen
## right) and toward the camera (+Z -> -Z world... see labels) and check which
## side of the mech leads.  Run (needs display):
##   godot --path godot -s tools/render_facing.gd

const OUT := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"
const HERO := "res://assets/hawc_hero.glb"
const FACE_FLIP := 0.0   # mirror mission1.gd MECH_FACE_FLIP

func _stage(move_dir: Vector3, label: String) -> Node3D:
	var root := Node3D.new()

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 40, 0)
	sun.light_color = Color(1.0, 0.86, 0.72)
	sun.light_energy = 1.4
	root.add_child(sun)

	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.32, 0.24)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.4, 0.35)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	root.add_child(we)

	# a pivot that yaws like the body does; the model is a child (as in-game)
	var body := Node3D.new()
	var hv := move_dir
	body.rotation.y = atan2(hv.x, hv.z)   # EXACT copy of hawc.gd:109

	var scene: PackedScene = load(HERO)
	var hawk := scene.instantiate()
	hawk.scale = Vector3.ONE * 2.8
	hawk.rotation.y = FACE_FLIP
	load("res://scripts/hero_material_fix.gd").apply(hawk)
	body.add_child(hawk)
	root.add_child(body)

	# a bright arrow marker showing the movement direction, so the render is unambiguous
	var arrow := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0
	cyl.bottom_radius = 0.6
	cyl.height = 3.0
	arrow.mesh = cyl
	var am := StandardMaterial3D.new()
	am.albedo_color = Color(1.0, 0.2, 0.1)
	am.emission_enabled = true
	am.emission = Color(1.0, 0.2, 0.1)
	arrow.material_override = am
	# point the cone along move_dir, floating in front of the mech at chest height
	arrow.position = move_dir.normalized() * 6.0 + Vector3(0, 4.0, 0)
	arrow.look_at_from_position(arrow.position, arrow.position + move_dir.normalized(), Vector3.UP)
	arrow.rotate_object_local(Vector3.RIGHT, -PI / 2.0)   # cone tip -> +Z of look
	root.add_child(arrow)

	# fixed world camera, looking at the mech from screen-front (down -Z toward origin)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 5.0, 16)
	cam.look_at_from_position(cam.position, Vector3(0, 4, 0), Vector3.UP)
	cam.current = true
	root.add_child(cam)

	root.set_meta("label", label)
	return root

var _cases: Array = []

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_cases = [
		[Vector3(1, 0, 0), "facing_move_+X_right"],
		[Vector3(0, 0, 1), "facing_move_+Z_toward_cam"],
	]
	_run.call_deferred()

func _run() -> void:
	for c in _cases:
		var stage := _stage(c[0], c[1])
		get_root().add_child(stage)
		await process_frame
		await process_frame
		await process_frame
		var img := get_root().get_texture().get_image()
		img.save_png(OUT + c[1] + ".png")
		print("saved ", c[1])
		stage.queue_free()
		await process_frame
	print("done")
	quit()
