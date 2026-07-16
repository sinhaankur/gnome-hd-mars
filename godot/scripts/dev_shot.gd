extends Node
## DEV ONLY — periodic viewport screenshots for the reference-vs-game compare loop.
## Saves a frame every INTERVAL seconds to reference/shots/, then quits the game
## after MAX_SHOTS so a scripted run is self-terminating. Remove from autoloads
## (project.godot) to disable; it has zero effect on gameplay.

const OUT_DIR := "/Users/sinhaankur/Downloads/G-Nome_ISO/reference/shots/"
const MAX_SHOTS := 10

var interval := 3.0
var _count := 0
var _timer := 2.0   # first-shot delay: let the scene settle

func _ready() -> void:
	# opt-in only: without DEV_SHOTS=1 in the environment this autoload does nothing,
	# so normal play sessions are never interrupted by the auto-quit below.
	if OS.get_environment("DEV_SHOTS") != "1":
		set_process(false)
	# keep shooting through pause/end screens — a paused tree froze the loop mid-run
	# and the scripted game never quit
	process_mode = Node.PROCESS_MODE_ALWAYS
	# optional cadence override, e.g. DEV_SHOTS_INTERVAL=1.2 for cinematic sequences
	var iv := OS.get_environment("DEV_SHOTS_INTERVAL")
	if iv.is_valid_float():
		interval = maxf(iv.to_float(), 0.2)
		_timer = interval

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = interval
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "shot_%02d.png" % _count)
	# log the player mech's physics state alongside each frame (diagnosis aid)
	var mech := get_tree().root.find_child("PlayerHAWC", true, false) as CharacterBody3D
	if mech:
		var p: Vector3 = mech.global_position
		var space: PhysicsDirectSpaceState3D = mech.get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, 300, p.z), Vector3(p.x, -300, p.z))
		q.exclude = [mech.get_rid()]
		var hit: Dictionary = space.intersect_ray(q)
		var gy: float = hit.position.y if not hit.is_empty() else NAN
		print("DEV mech y=%.2f floor=%s ground=%.2f vy=%.2f" % [p.y, mech.is_on_floor(), gy, mech.velocity.y])
	_count += 1
	if _count >= MAX_SHOTS:
		get_tree().quit()
