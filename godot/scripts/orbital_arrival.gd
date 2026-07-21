extends Node3D
class_name OrbitalArrival
## The arrival cinematic — logically bridges the strategic globe and the ground mission.
## Plays when the player DEPLOYS to a territory: the interplanetary MOTHERSHIP is
## already in orbit; it releases a SUB-SHIP carrying the HAWC; the sub-ship burns down
## toward the chosen territory's point on the globe; the camera follows it into the
## atmosphere; then we hand off to the ground mission (where the dropship lands).
##
## It runs ON the planet_view scene (over the real Mars globe), so the geography is
## consistent: the ship goes to the exact lat/lon the player picked.
##
## Usage:  var a := OrbitalArrival.new(); globe_root.add_child(a)
##         a.play(target_point_on_globe, globe_radius, cam); a.finished.connect(...)

signal finished

const Ships := preload("res://scripts/orbital_ships.gd")

var _cam: Camera3D
var _target: Vector3          # the territory point ON the globe surface (local)
var _globe_r: float
var _mother: Node3D
var _sub: Node3D
var _done := false

func play(target_point: Vector3, globe_r: float, cam: Camera3D) -> void:
	_cam = cam
	_target = target_point
	_globe_r = globe_r

	# --- mothership: park it in orbit ABOVE the target, tilted along its travel ---
	_mother = Ships.mothership()
	add_child(_mother)
	var up := target_point.normalized()
	var orbit_h := globe_r * 1.7
	# start the mothership off to one side of the target, at orbit altitude
	var side := up.cross(Vector3.UP).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	_mother.global_position = up * orbit_h + side * globe_r * 1.2
	_mother.look_at(up * orbit_h - side * globe_r, up)

	# --- sub-ship: starts docked at the mothership, carrying the HAWC ---
	_sub = Ships.subship()
	var pod := Ships.hawc_pod()
	pod.position = Vector3(0, -0.09, 0)
	_sub.add_child(pod)
	add_child(_sub)
	_sub.global_position = _mother.global_position + Vector3(0, -0.12, 0)

	# camera: start looking at the mothership from just outside orbit
	_cam.global_position = up * orbit_h * 1.35 + side * globe_r * 2.2
	_cam.look_at(_mother.global_position, up)

	_run()

func _run() -> void:
	var up := _target.normalized()
	var orbit_h := _globe_r * 1.7
	var surface := _target                    # the actual territory point on the globe
	var tw := create_tween()

	# 1) BEAT — establish: mothership cruises its orbit, camera drifts with it (2.2 s)
	tw.tween_method(func(t: float):
		if is_instance_valid(_mother):
			# slow orbital drift around the target's up-axis
			var ang := t * 0.5
			var side := up.cross(Vector3.UP).normalized()
			if side.length() < 0.1: side = Vector3.RIGHT
			var rot := side.rotated(up, ang)
			_mother.global_position = up * orbit_h + rot * _globe_r * 1.2
			if is_instance_valid(_sub) and t < 0.5:
				_sub.global_position = _mother.global_position + Vector3(0, -0.12, 0)
		if is_instance_valid(_cam) and is_instance_valid(_mother):
			_cam.look_at(_mother.global_position, up),
		0.0, 1.0, 2.2)

	# 2) BEAT — DETACH: the sub-ship drops away from the carrier toward the surface (0.6 s)
	tw.tween_callback(func():
		if is_instance_valid(_cam) and is_instance_valid(_sub):
			# cut the camera to follow the sub-ship now
			pass)
	var sub_start := _mother.global_position if is_instance_valid(_mother) else up * orbit_h
	tw.tween_method(func(t: float):
		if is_instance_valid(_sub):
			# ease the sub-ship out and slightly down, peeling off the carrier
			var p := sub_start.lerp(up * (orbit_h * 0.82) - up.cross(Vector3.UP).normalized() * _globe_r * 0.3, t)
			_sub.global_position = p
			_sub.look_at(surface, up)
		if is_instance_valid(_cam) and is_instance_valid(_sub):
			_cam.global_position = _cam.global_position.lerp(_sub.global_position + up * 0.5 + Vector3(0.3,0,0.3), 0.12)
			_cam.look_at(_sub.global_position, up),
		0.0, 1.0, 1.0)

	# 3) BEAT — DESCENT: sub-ship burns down toward the territory, camera chases it in (2.4 s)
	tw.tween_method(func(t: float):
		if is_instance_valid(_sub):
			var from := up * (orbit_h * 0.82)
			var to := surface + up * 0.06          # just above the surface point
			# ease-in so it accelerates into the atmosphere
			var e := t * t
			_sub.global_position = from.lerp(to, e)
			_sub.look_at(surface, up)
			# spin up thruster glow as it brakes near the end (visual only)
		if is_instance_valid(_cam) and is_instance_valid(_sub):
			var behind := (_sub.global_position - surface).normalized()
			_cam.global_position = _sub.global_position + behind * 0.35 + Vector3(0.05, 0.05, 0.05)
			_cam.look_at(surface, up),
		0.0, 1.0, 2.4).set_ease(Tween.EASE_IN)

	# 4) hand off to the ground mission
	tw.tween_interval(0.3)
	tw.tween_callback(_finish)

func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()

func skip() -> void:
	_finish()
