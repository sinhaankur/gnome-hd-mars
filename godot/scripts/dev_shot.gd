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
		print("DEV mech y=%.2f floor=%s ground=%.2f vy=%.2f %s" % [p.y, mech.is_on_floor(), gy, mech.velocity.y, _aabb_report(mech, "Visual")])
	# AXIS DIAG: report the on-foot pilot's upright-ness + foot-vs-ground (the Pilot body is
	# the one in the "player" group that exposes max_speed and has a Visual child)
	for g in get_tree().get_nodes_in_group("player"):
		if g and g.get("max_speed") != null and g.has_node("Visual"):
			print("DEV pilot ", _aabb_report(g, "Visual"), " worldY=%.2f" % (g as Node3D).global_position.y)
			break
	_count += 1
	if _count >= MAX_SHOTS:
		get_tree().quit()

# AXIS DIAG helper: world-space AABB of a body's Visual, reporting height, tallest axis,
# and how far the lowest mesh point sits above/below the body origin (feet-at-origin check).
func _aabb_report(body: Node, visual_name: String) -> String:
	var vis := body.get_node_or_null(visual_name) as Node3D
	if vis == null:
		return "[no Visual]"
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	var stack: Array = [vis]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var ab := mi.get_aabb()
			var xf := mi.global_transform
			for i in range(8):
				var wp: Vector3 = xf * ab.get_endpoint(i)
				lo = Vector3(minf(lo.x, wp.x), minf(lo.y, wp.y), minf(lo.z, wp.z))
				hi = Vector3(maxf(hi.x, wp.x), maxf(hi.y, wp.y), maxf(hi.z, wp.z))
		for c in n.get_children():
			stack.append(c)
	if lo.x == INF:
		return "[no meshes]"
	var dx := hi.x - lo.x
	var dy := hi.y - lo.y
	var dz := hi.z - lo.z
	var tallest := ("Y" if (dy >= dx and dy >= dz) else ("X" if dx >= dz else "Z"))
	var by: float = (body as Node3D).global_position.y
	return "[dims %.2fx%.2fx%.2f tallest=%s footY=%.2f(vs bodyY=%.2f -> %+.2f)]" % [dx, dy, dz, tallest, lo.y, by, lo.y - by]
