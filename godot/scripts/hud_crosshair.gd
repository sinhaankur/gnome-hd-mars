extends Control
## A simple combat crosshair drawn at screen center — four ticks around a center gap.

func _draw() -> void:
	var col := Color(0.9, 1.0, 0.9, 0.85)
	var gap := 6.0
	var len := 12.0
	var w := 2.0
	# four ticks
	draw_line(Vector2(0, -gap), Vector2(0, -gap - len), col, w)   # up
	draw_line(Vector2(0, gap), Vector2(0, gap + len), col, w)     # down
	draw_line(Vector2(-gap, 0), Vector2(-gap - len, 0), col, w)   # left
	draw_line(Vector2(gap, 0), Vector2(gap + len, 0), col, w)     # right
	# center dot
	draw_circle(Vector2.ZERO, 1.5, col)
