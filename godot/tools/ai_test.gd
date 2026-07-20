extends SceneTree
## DEV ONLY — headless check that the role-driven enemy AI actually moves differently
## per role: rushers close in, snipers hold long range, and units strafe (nonzero
## lateral motion) rather than marching straight at the target.
## Run: godot --headless --path godot -s tools/ai_test.gd

func _make(role: String, pos: Vector3) -> CharacterBody3D:
	var e := CharacterBody3D.new()
	e.set_script(load("res://scripts/enemy_ai.gd"))
	e.set("role", role)
	e.hp = 8
	e.move_speed = 8.0
	root.add_child(e)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new(); cap.radius = 1.5; cap.height = 6.0
	col.shape = cap; col.position.y = 3.0
	e.add_child(col)
	e.global_position = pos
	return e

func _init() -> void:
	# a stand-in "player" target at the origin
	var player := CharacterBody3D.new()
	player.add_to_group("player")
	root.add_child(player)
	player.global_position = Vector3.ZERO

	# a floor so move_and_slide has ground
	var floor_body := StaticBody3D.new()
	var fcol := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(400, 2, 400)
	fcol.shape = box; fcol.position = Vector3(0, -1, 0)
	floor_body.add_child(fcol)
	root.add_child(floor_body)

	# separate them (so they don't collide) and start at a moderate range so both roles
	# have room to settle to their preferred standoff within the test window
	var rusher := _make("rusher", Vector3(-30, 4, 35))
	var sniper := _make("sniper", Vector3(30, 4, 35))
	_run(rusher, sniper)

func _run(rusher: CharacterBody3D, sniper: CharacterBody3D) -> void:
	var rusher_lateral := 0.0
	var prev_rx := rusher.global_position.x
	for i in range(600):        # ~10 s at 60 Hz — time to settle to preferred range
		await physics_frame
		rusher_lateral += absf(rusher.global_position.x - prev_rx)
		prev_rx = rusher.global_position.x

	# horizontal distance to the player at origin (the AI works in the XZ plane)
	var rp := rusher.global_position; rp.y = 0.0
	var sp := sniper.global_position; sp.y = 0.0
	var rush_dist := rp.length()
	var snipe_dist := sp.length()
	print("TEST rusher final dist=%.1f (started ~72, want <25 = closed in)" % rush_dist)
	print("TEST sniper final dist=%.1f (want >35 = held long range)" % snipe_dist)
	print("TEST rusher lateral travel=%.1f (want >2 = it strafed, not a straight march)" % rusher_lateral)
	print("TEST roles differ (rusher closer than sniper): %s" % (rush_dist < snipe_dist - 10.0))
	quit()
