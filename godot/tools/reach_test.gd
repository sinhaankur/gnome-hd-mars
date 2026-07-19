extends SceneTree
## DEV ONLY — headless smoke test for the "reach the beacon" objective:
## a reach mission spawns a physical Beacon at a real distance, and driving the
## mech into it fires reached -> mission win.
## Run: godot --headless --path godot -s tools/reach_test.gd

func _initialize() -> void:
	_boot.call_deferred()

func _boot() -> void:
	# the scene tree is active now, so autoloads are reachable. Force a "reach" level
	# (index 1 is a reach mission in Campaign.LEVELS) BEFORE the mission reads it.
	await process_frame
	var cmp := root.get_node_or_null("Campaign")
	if cmp:
		cmp.set_current(1)
		print("TEST level: objective=", cmp.current().get("objective", "?"))
	else:
		print("TEST WARN: Campaign autoload not found")
	var m: Node = load("res://scenes/mission1.tscn").instantiate()
	root.add_child(m)
	_run(m)

func _run(m: Node) -> void:
	# let the environment build + _on_env_ready run (it spawns the beacon)
	for _i in range(60):
		await physics_frame

	var b: Node = m._beacon
	print("TEST beacon spawned: %s" % [b != null and is_instance_valid(b)])
	if b == null:
		print("TEST FAIL: no beacon on a reach mission")
		quit()
		return
	var start_dist: float = b.distance_from(m._player.global_position)
	print("TEST beacon distance from start: %.0f m (want >150)" % start_dist)

	# hand control over (as if intro finished) and confirm NOT yet won
	m._player.controlled = true
	print("TEST not won at start: over=%s" % m._over)

	# drive the mech to the beacon and step the check
	m._player.global_position = b.global_position + Vector3(3, 0, 0)
	for _j in range(4):
		await physics_frame
	# _process runs the beacon.check; give it a couple frames
	await process_frame
	await process_frame
	print("TEST reached -> won: over=%s (expect true)" % m._over)
	quit()
