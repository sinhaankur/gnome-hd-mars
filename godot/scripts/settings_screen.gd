extends RefCounted
class_name SettingsScreen
## Reusable settings panel. Reads/writes the Settings autoload, applies immediately,
## and saves on Back. Intuitive: labelled sliders + toggles with live values.

static func build(on_back: Callable) -> Control:
	var S: Node = Engine.get_main_loop().root.get_node_or_null("Settings")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.06, 0.05, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(m, 120)
	for m in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 60)
	root.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	margin.add_child(col)

	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 30)
	col.add_child(title)

	# --- Master volume ---
	_slider(col, "Master Volume", 0.0, 1.0, 0.05, S.master_volume, func(v):
		S.master_volume = v; S.apply_volume())
	# --- Mouse sensitivity ---
	_slider(col, "Mouse Sensitivity", 0.2, 3.0, 0.1, S.mouse_sensitivity, func(v):
		S.mouse_sensitivity = v)
	# --- Day length (sun cycle speed) ---
	_slider(col, "Mars Day Length (sec)", 30.0, 2400.0, 10.0, S.day_length_sec, func(v):
		S.day_length_sec = v)

	# --- Toggles ---
	_toggle(col, "High Detail (shadows, glow, reflections)", S.high_detail, func(on):
		S.high_detail = on)
	_toggle(col, "Fullscreen", S.fullscreen, func(on):
		S.fullscreen = on; S.apply_fullscreen())

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	var back := Button.new()
	back.text = "◀ BACK  (saves)"
	back.custom_minimum_size = Vector2(220, 44)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(func():
		S.save_settings()
		on_back.call())
	col.add_child(back)
	return root

static func _slider(parent: Node, label: String, lo: float, hi: float, step: float,
					 value: float, on_change: Callable) -> void:
	var row := VBoxContainer.new()
	var head := HBoxContainer.new()
	var l := Label.new(); l.text = label; l.add_theme_font_size_override("font_size", 18)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val := Label.new(); val.add_theme_font_size_override("font_size", 18)
	val.text = "%.2f" % value
	head.add_child(l); head.add_child(val)
	row.add_child(head)
	var s := HSlider.new()
	s.min_value = lo; s.max_value = hi; s.step = step; s.value = value
	s.custom_minimum_size = Vector2(0, 24)
	s.value_changed.connect(func(v):
		val.text = "%.2f" % v
		on_change.call(v))
	row.add_child(s)
	parent.add_child(row)

static func _toggle(parent: Node, label: String, on: bool, on_change: Callable) -> void:
	var cb := CheckButton.new()
	cb.text = label
	cb.button_pressed = on
	cb.add_theme_font_size_override("font_size", 18)
	cb.toggled.connect(func(pressed): on_change.call(pressed))
	parent.add_child(cb)
