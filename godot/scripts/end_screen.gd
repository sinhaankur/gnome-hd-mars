extends CanvasLayer
## Victory / Defeat end screen. Shown when the mission is won or lost.
## Pauses the game and offers Restart / Quit to Menu. Reusable for any level.

const MENU := "res://scenes/main_menu.tscn"
const PLANET := "res://scenes/planet.tscn"

func show_result(victory: bool, stats: String = "", has_next: bool = false) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_has_next = has_next

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.85) if victory else Color(0.10, 0.02, 0.02, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.position = Vector2(-180, -160)
	root.add_child(col)

	var title := Label.new()
	title.text = "INSTALLATION SECURED" if victory else "INSTALLATION OVERRUN"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if victory else Color(1.0, 0.35, 0.3))
	col.add_child(title)

	var sub := Label.new()
	sub.text = "MISSION ACCOMPLISHED" if victory else "MISSION FAILED"
	sub.add_theme_font_size_override("font_size", 22)
	col.add_child(sub)

	if stats != "":
		var st := Label.new()
		st.text = stats
		st.add_theme_font_size_override("font_size", 18)
		st.add_theme_color_override("font_color", Color(0.8, 0.78, 0.7))
		col.add_child(st)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	col.add_child(spacer)

	# on victory, return to the planet: watch the territory flip, pick the next one
	if victory and _has_next:
		_btn(col, "▶ RETURN TO ORBIT — NEXT TERRITORY", func():
			get_tree().paused = false
			get_tree().change_scene_to_file(PLANET))
	elif victory:
		var done := Label.new()
		done.text = "CAMPAIGN COMPLETE — Mars holds."
		done.add_theme_font_size_override("font_size", 20)
		done.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		col.add_child(done)

	_btn(col, "RESTART MISSION", func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	_btn(col, "QUIT TO MENU", func():
		get_tree().paused = false
		get_tree().change_scene_to_file(MENU))

var _has_next := false

func _btn(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 48)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	parent.add_child(b)
