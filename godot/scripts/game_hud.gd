extends CanvasLayer
class_name GameHUD
## Full combat HUD: crosshair, player armor bar, base armor bar, floating enemy health
## bars, hit markers, and a radar/minimap. Driven by the level via setup() + update().

const RADAR_SIZE := 160.0
const RADAR_RANGE := 220.0   # world units the radar covers (half-map)

var _player: Node
var _env: Node
var _get_base_hp: Callable

# UI nodes
var _crosshair: Control
var _armor_bar: ProgressBar
var _base_bar: ProgressBar
var _armor_label: Label
var _radar: Control
var _hitmarker: Control
var _hit_time := 0.0
var _enemy_bars := {}   # enemy node -> {bar, holder}
var _bars_layer: Control

func setup(player: Node, env: Node, get_base_hp: Callable) -> void:
	_player = player
	_env = env
	_get_base_hp = get_base_hp
	layer = 10
	_build()

func _build() -> void:
	# --- crosshair (center reticle) ---
	_crosshair = Control.new()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.set_script(load("res://scripts/hud_crosshair.gd"))
	add_child(_crosshair)

	# --- hit marker (flashes when you damage an enemy) ---
	_hitmarker = Control.new()
	_hitmarker.set_anchors_preset(Control.PRESET_CENTER)
	_hitmarker.set_script(load("res://scripts/hud_hitmarker.gd"))
	_hitmarker.modulate.a = 0.0
	add_child(_hitmarker)

	# --- player armor bar (bottom-left) ---
	var pcol := VBoxContainer.new()
	pcol.position = Vector2(24, 560)
	add_child(pcol)
	var pl := Label.new(); pl.text = "HAWC ARMOR"; pl.add_theme_font_size_override("font_size", 14)
	pcol.add_child(pl)
	_armor_bar = _make_bar(Color(0.3, 0.9, 0.4))
	pcol.add_child(_armor_bar)
	_armor_label = Label.new(); _armor_label.add_theme_font_size_override("font_size", 13)
	pcol.add_child(_armor_label)

	# --- base armor bar (bottom-center) ---
	var bcol := VBoxContainer.new()
	bcol.position = Vector2(520, 620)
	add_child(bcol)
	var bl := Label.new(); bl.text = "INSTALLATION"; bl.add_theme_font_size_override("font_size", 14)
	bl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	bcol.add_child(bl)
	_base_bar = _make_bar(Color(0.4, 0.7, 1.0))
	bcol.add_child(_base_bar)

	# --- radar (top-right) ---
	_radar = Control.new()
	_radar.set_script(load("res://scripts/hud_radar.gd"))
	_radar.position = Vector2(1090, 24)
	_radar.custom_minimum_size = Vector2(RADAR_SIZE, RADAR_SIZE)
	add_child(_radar)

	# --- layer that holds floating enemy health bars (drawn in screen space) ---
	_bars_layer = Control.new()
	_bars_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bars_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bars_layer)

func _make_bar(col: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(240, 22)
	b.max_value = 100
	b.value = 100
	b.show_percentage = false
	var fill := StyleBoxFlat.new(); fill.bg_color = col; fill.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new(); bg.bg_color = Color(0.1, 0.1, 0.12, 0.8); bg.set_corner_radius_all(3)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", bg)
	return b

func flash_hit() -> void:
	_hit_time = 0.25

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	# player armor
	var hp: int = _player.health
	_armor_bar.value = hp
	_armor_label.text = "%d%%" % hp
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.3, 0.25) if hp < 30 else (Color(0.9, 0.8, 0.3) if hp < 60 else Color(0.3, 0.9, 0.4))
	fill.set_corner_radius_all(3)
	_armor_bar.add_theme_stylebox_override("fill", fill)

	# base armor
	if _get_base_hp.is_valid():
		_base_bar.value = _get_base_hp.call()

	# hit marker fade
	if _hit_time > 0.0:
		_hit_time -= delta
		_hitmarker.modulate.a = clampf(_hit_time / 0.25, 0.0, 1.0)

	_update_enemy_bars()
	if _radar and _radar.has_method("refresh"):
		_radar.refresh(_player, _env)

func _update_enemy_bars() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	# add bars for new enemies
	for e in enemies:
		if not _enemy_bars.has(e):
			var bar := ProgressBar.new()
			bar.custom_minimum_size = Vector2(56, 7)
			bar.max_value = 100
			bar.value = 100
			bar.show_percentage = false
			var fill := StyleBoxFlat.new(); fill.bg_color = Color(1.0, 0.35, 0.3); fill.set_corner_radius_all(2)
			var bg := StyleBoxFlat.new(); bg.bg_color = Color(0.0, 0.0, 0.0, 0.6); bg.set_corner_radius_all(2)
			bar.add_theme_stylebox_override("fill", fill)
			bar.add_theme_stylebox_override("background", bg)
			_bars_layer.add_child(bar)
			_enemy_bars[e] = {"bar": bar, "max": float(e.hp) if "hp" in e else 6.0}
	# update positions + remove dead
	for e in _enemy_bars.keys():
		var data: Dictionary = _enemy_bars[e]
		var bar: ProgressBar = data["bar"]
		if not is_instance_valid(e):
			bar.queue_free()
			_enemy_bars.erase(e)
			continue
		var head: Vector3 = e.global_position + Vector3.UP * 8.0
		if cam.is_position_behind(head):
			bar.visible = false
			continue
		bar.visible = true
		var sp := cam.unproject_position(head)
		bar.position = sp - bar.custom_minimum_size * 0.5
		var cur: float = float(e.hp) if "hp" in e else 0.0
		bar.value = clampf(cur / maxf(data["max"], 1.0) * 100.0, 0.0, 100.0)
