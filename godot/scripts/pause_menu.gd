extends CanvasLayer
## In-mission pause menu. ESC toggles it. Resume / Restart / Settings / Quit to menu.
## Pauses the game tree while open and frees the mouse.

const MENU := "res://scenes/main_menu.tscn"

var _root: Control
var _buttons: Control
var _settings: Control
var _open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep working while tree is paused
	layer = 100
	_build()
	_set_open(false)

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.03, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	_buttons.set_anchors_preset(Control.PRESET_CENTER)
	_buttons.position = Vector2(-130, -120)
	_root.add_child(_buttons)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 34)
	_buttons.add_child(title)

	_btn("RESUME", _on_resume)
	_btn("RESTART MISSION", _on_restart)
	_btn("SETTINGS", _on_settings)
	_btn("QUIT TO MENU", _on_quit_menu)

	_settings = SettingsScreen.build(_close_settings)
	_settings.visible = false
	_root.add_child(_settings)

func _btn(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 46)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	_buttons.add_child(b)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if _settings.visible:
			_close_settings()
		else:
			_set_open(not _open)
		get_viewport().set_input_as_handled()

func _set_open(open: bool) -> void:
	_open = open
	_root.visible = open
	get_tree().paused = open
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_settings.visible = false
		_buttons.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume() -> void:
	_set_open(false)

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_settings() -> void:
	_buttons.visible = false
	_settings.visible = true

func _close_settings() -> void:
	_settings.visible = false
	_buttons.visible = true

func _on_quit_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU)
