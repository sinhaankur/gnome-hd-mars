extends SceneTree
## DEV ONLY — headless smoke test for the G-NOME possession loop:
## dismount -> board own mech -> GASHR-eject an enemy -> steal the hull.
## Run: godot --headless --path godot -s tools/possess_test.gd

func _initialize() -> void:
	var m: Node = load("res://scenes/mission1.tscn").instantiate()
	root.add_child(m)
	_run(m)

func _run(m: Node) -> void:
	for _i in range(40):
		await physics_frame

	print("TEST state: paused=%s mech_controlled=%s mech_y=%.1f" % [paused, m._player.controlled, m._player.global_position.y])
	# hand control over as if the intro just finished, and settle the mech
	m._player.controlled = true
	m.env.place_on_ground(m._player, 1.0)
	for _j in range(5):
		await physics_frame
	# 1) dismount
	m._dismount()
	await process_frame
	var pilot: Node = m._pilot
	print("TEST dismount: pilot=%s player_group=%s mech_parked=%s" % [
		pilot != null, pilot and pilot.is_in_group("player"), not m._player.controlled])

	# 2) board own mech (pilot spawns within reach of it)
	print("TEST debug: pilot=%s mech=%s dist=%.2f" % [
		pilot.global_position, m._player.global_position,
		pilot.global_position.distance_to(m._player.global_position)])
	m._try_enter()
	await process_frame
	print("TEST remount: controlled=%s pilot_hidden=%s" % [m._player.controlled, not pilot.visible])

	# 3) eject an enemy pilot
	var e := CharacterBody3D.new()
	e.set_script(load("res://scripts/enemy_ai.gd"))
	root.add_child(e)
	e.global_position = m._player.global_position + Vector3(10, 0, 0)
	await process_frame
	e.eject_pilot()
	print("TEST eject: vacant=%s hijackable=%s hostile=%s" % [
		e.vacant, e.is_in_group("hijackable"), e.is_in_group("enemies")])

	# 4) steal the vacant hull
	var old_mech: Node = m._player
	m._dismount()
	await process_frame
	m._pilot.global_position = e.global_position + Vector3(2, 0, 0)
	m._try_enter()
	await process_frame
	print("TEST steal: new_mech=%s controlled=%s old_parked=%s" % [
		m._player != old_mech, m._player.controlled, not old_mech.controlled])
	quit()
