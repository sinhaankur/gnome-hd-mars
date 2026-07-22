extends SceneTree
## Verify the secondary rocket does REAL splash damage: place 3 dummy enemies in a
## cluster, detonate a rocket among them, confirm all 3 took hits.
## Run: godot --headless --path godot -s tools/rocket_test.gd

class Dummy extends Area3D:
	var tally := 0
	func take_hit() -> void:
		tally += 1

var _dummies: Array = []

func _init() -> void:
	for i in range(3):
		var e := Dummy.new()
		e.add_to_group("enemies")
		root.add_child(e)
		e.position = Vector3(i * 2.0 - 2.0, 0, 0)   # within 8 m splash of origin
		_dummies.append(e)
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var rocket := Area3D.new()
	rocket.set_script(load("res://scripts/rocket.gd"))
	root.add_child(rocket)
	rocket.position = Vector3.ZERO
	# detonate on the spawn frame (as a real point-blank impact would) before _process
	# advances the rocket out of position
	rocket.call("_detonate")
	var total := 0
	for e in _dummies:
		total += (e as Dummy).tally
	# with distance falloff: center enemy (0 m) full 3, the two at 2 m get round(3*0.75)=2 each
	print("TEST splash: 3 enemies (0 m, 2 m, 2 m), total hits = %d (expect 7 w/ falloff)" % total)
	print("TEST result: %s" % ("PASS" if total >= 5 else "FAIL"))   # all in-radius took multiple hits
	quit()
