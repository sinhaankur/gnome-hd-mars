extends Control
## Main menu — intuitive game shell. Logo + Start / Story / Settings / Quit.
## Sub-panels (Story, Settings) slide in over the same screen. Clean and obvious.

const MISSION := "res://scenes/mission1.tscn"
const PLANET := "res://scenes/planet.tscn"   # strategic layer: territory globe

var _panel_main: VBoxContainer
var _panel_story: Control
var _panel_settings: Control
var _panel_select: Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()

func _build() -> void:
	# --- background: Mars from orbit (captured from the planet scene, DEV_CLEAN=1) ---
	var bg := TextureRect.new()
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/menu_bg.png"))
	if img:
		bg.texture = ImageTexture.create_from_image(img)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# gentle darkening so the logo/buttons stay readable over the planet
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	# --- centered vertical stack: logo above, buttons below ---
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 24)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(stack)

	# logo — sized to fit, aspect-correct, centered
	var logo := TextureRect.new()
	var tex := load("res://assets/logo.png")
	if tex:
		logo.texture = tex
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.custom_minimum_size = Vector2(560, 280)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(logo)

	# --- main button column, centered under the logo ---
	_panel_main = _vbox()
	_panel_main.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel_main.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_panel_main)
	_button(_panel_main, "START CAMPAIGN", _on_start)
	_button(_panel_main, "SELECT MISSION", _on_select)
	_button(_panel_main, "STORY / BRIEFING", _on_story)
	_button(_panel_main, "SETTINGS", _on_settings)
	_button(_panel_main, "QUIT", _on_quit)

	# --- copyright + attribution footer (see LICENSE / CREDITS.md at project root) ---
	var foot := Label.new()
	foot.text = "© 2026 Ankur Sinha · Mech: Oscar Creativo (CC-BY) · Globe: Solar System Scope (CC-BY) · Terrain: NASA HiRISE"
	foot.add_theme_font_size_override("font_size", 12)
	foot.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	foot.anchor_top = 1.0; foot.anchor_bottom = 1.0; foot.anchor_right = 1.0
	foot.offset_top = -28; foot.offset_left = 16
	add_child(foot)

	# --- sub-panels (hidden until opened) ---
	_panel_story = StoryScreen.build(_close_subpanels)
	_panel_story.visible = false
	add_child(_panel_story)
	_panel_settings = SettingsScreen.build(_close_subpanels)
	_panel_settings.visible = false
	add_child(_panel_settings)
	_panel_select = _build_level_select()
	_panel_select.visible = false
	add_child(_panel_select)

func _vbox() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(260, 0)
	return v

func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 48)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _on_start() -> void:
	# campaign goes through the PLANET: pick your territory on the real Mars globe
	get_tree().change_scene_to_file(PLANET)

func _on_select() -> void:
	_panel_main.visible = false
	_panel_select.visible = true

func _on_story() -> void:
	_panel_main.visible = false
	_panel_story.visible = true

func _on_settings() -> void:
	_panel_main.visible = false
	_panel_settings.visible = true

func _close_subpanels() -> void:
	_panel_story.visible = false
	_panel_settings.visible = false
	_panel_select.visible = false
	_panel_main.visible = true

func _build_level_select() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.06, 0.05, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)
	var title := Label.new()
	title.text = "SELECT MISSION"
	title.add_theme_font_size_override("font_size", 30)
	col.add_child(title)

	var cmp := get_node_or_null("/root/Campaign")
	if cmp:
		for i in range(cmp.level_count()):
			var lv: Dictionary = cmp.get_level(i)
			var locked: bool = i >= cmp.unlocked
			var label := "%d. %s — %s" % [lv["id"], lv["name"], lv.get("subtitle", "")]
			if locked:
				label = "🔒 " + label
			var b := _button(col, label, func():
				if not locked:
					cmp.set_current(i)
					get_tree().change_scene_to_file(MISSION))
			b.custom_minimum_size = Vector2(460, 44)
			b.disabled = locked
	_button(col, "◀ BACK", _close_subpanels).custom_minimum_size = Vector2(200, 40)
	return root

func _on_quit() -> void:
	get_tree().quit()
