extends Control
## A hit marker — four diagonal ticks that flash when you damage an enemy.

func _draw() -> void:
	var col := Color(1.0, 0.9, 0.3)
	var inner := 8.0
	var outer := 16.0
	var w := 2.5
	for d in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		draw_line(d * inner, d * outer, col, w)
