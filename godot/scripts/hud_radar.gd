extends Control
## Circular radar/minimap. Shows enemies (red), the installation (blue), exploration
## sites (cyan), all relative to the player, oriented to the player's facing (up = forward).

const SIZE := 160.0
const RANGE := 240.0   # world units mapped to the radar edge

var _player: Node
var _env: Node

func refresh(player: Node, env: Node) -> void:
	_player = player
	_env = env
	queue_redraw()

func _draw() -> void:
	var c := Vector2(SIZE, SIZE) * 0.5
	var r := SIZE * 0.5
	# backdrop
	draw_circle(c, r, Color(0.05, 0.07, 0.06, 0.7))
	draw_arc(c, r, 0, TAU, 48, Color(0.4, 0.7, 0.5, 0.8), 2.0)
	draw_arc(c, r * 0.5, 0, TAU, 32, Color(0.3, 0.5, 0.4, 0.5), 1.0)
	# player at center (a triangle pointing up = forward)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(-5, 5), c + Vector2(5, 5)]),
						 Color(0.8, 1.0, 0.9))
	if _player == null or not is_instance_valid(_player):
		return

	var pyaw: float = _player.rotation.y
	var ppos: Vector3 = _player.global_position

	# helper: world pos -> radar point (rotated so player-forward is up)
	var to_radar := func(wp: Vector3) -> Vector2:
		var d := wp - ppos
		# rotate by -pyaw so forward aligns with -Y (up on screen)
		var lx := d.x * cos(-pyaw) - d.z * sin(-pyaw)
		var lz := d.x * sin(-pyaw) + d.z * cos(-pyaw)
		var rp := Vector2(lx, lz) / RANGE * r
		return c + rp

	# installation
	if _env and "installation" in _env and _env.installation:
		var bp: Vector2 = to_radar.call(_env.installation.global_position)
		bp = c + (bp - c).limit_length(r - 4)
		draw_rect(Rect2(bp - Vector2(4, 4), Vector2(8, 8)), Color(0.4, 0.7, 1.0))

	# exploration sites (cyan diamonds) — read from the Exploration node if present
	var explore := _player.get_parent().get_node_or_null("Exploration") if _player.get_parent() else null
	if explore and "_pois" in explore:
		for poi in explore._pois:
			if poi.get("node") and is_instance_valid(poi["node"]):
				var pp: Vector2 = to_radar.call(poi["node"].global_position)
				if (pp - c).length() < r:
					var col := Color(0.4, 1.0, 0.6) if poi.get("found", false) else Color(0.3, 0.8, 0.9)
					draw_colored_polygon(PackedVector2Array([pp+Vector2(0,-4), pp+Vector2(4,0), pp+Vector2(0,4), pp+Vector2(-4,0)]), col)

	# enemies (red blips)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var ep: Vector2 = to_radar.call(e.global_position)
		if (ep - c).length() < r:
			draw_circle(ep, 3.0, Color(1.0, 0.3, 0.25))
		else:
			# clamp to the edge so you know the direction of off-radar enemies
			var edge := c + (ep - c).normalized() * (r - 3)
			draw_circle(edge, 2.0, Color(1.0, 0.3, 0.25, 0.6))
