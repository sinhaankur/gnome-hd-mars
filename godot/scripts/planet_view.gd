extends Node3D
## PLANET VIEW — the strategic layer above everything: the REAL Mars globe as the
## territory-war map. Rival nations hold regions of the actual planet; each campaign
## level is a territory at its true coordinates (Campaign.TERRITORY_INFO). Clicking a
## contested territory launches its ground mission; victories flip it player-held.
##
## Controls: DRAG rotate · WHEEL zoom (full globe → region close-up) · CLICK territory
## Globe imagery: NASA Viking mosaic via Solar System Scope (CC-BY 4.0) — see credits.

const MISSION := "res://scenes/mission1.tscn"
const MENU := "res://scenes/main_menu.tscn"
const GLOBE_R := 2.0

const COL_PLAYER    := Color(0.35, 1.0, 0.55)
const COL_CONTESTED := Color(1.0, 0.85, 0.3)
const COL_RIVAL     := Color(1.0, 0.32, 0.25)

var _tilt: Node3D           # pitch parent (so poles are reachable)
var _globe: Node3D          # yaw + markers live here
var _cam: Camera3D
var _cam_dist := 6.0        # wheel-zoom target distance
var _dragging := false
var _drag_moved := 0.0
var _hover_area: Area3D
var _info: Label
var _brief: Control         # mission brief popup (blocks globe input while open)
var _contested_mats: Array = []   # pulsing marker materials
var _t := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_space()
	_build_globe()
	_build_markers()
	_build_hud()

# ---------------------------------------------------------------- build
func _build_space() -> void:
	# deep space: black sky, one hard sun, faint fill so the night side still reads
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.45, 0.4)
	env.ambient_light_energy = 0.25
	env.glow_enabled = true
	env.glow_intensity = 0.5
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-15, 55, 0)
	sun.light_energy = 1.6
	sun.light_color = Color(1.0, 0.96, 0.9)
	add_child(sun)

	# starfield: hundreds of tiny unshaded points on a far shell
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var star := SphereMesh.new()
	star.radius = 0.06; star.height = 0.12; star.radial_segments = 4; star.rings = 2
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(0.9, 0.92, 1.0)
	star.material = sm
	mm.mesh = star
	mm.instance_count = 600
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(mm.instance_count):
		var dir := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		var xf := Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.4, 1.4)),
							  dir * rng.randf_range(55.0, 90.0))
		mm.set_instance_transform(i, xf)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)

	_cam = Camera3D.new()
	_cam.position = Vector3(0, 0, _cam_dist)
	_cam.current = true
	add_child(_cam)

func _build_globe() -> void:
	_tilt = Node3D.new(); _tilt.name = "Tilt"
	add_child(_tilt)
	_globe = Node3D.new(); _globe.name = "Globe"
	_tilt.add_child(_globe)

	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = GLOBE_R; sphere.height = GLOBE_R * 2.0
	sphere.radial_segments = 96; sphere.rings = 48
	mi.mesh = sphere
	var m := StandardMaterial3D.new()
	# load from disk like mars_terrain.gd does — works even before the editor has
	# imported the file into Godot's resource database
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/mars_globe.jpg"))
	if img:
		m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 1.0
	mi.material_override = m
	_globe.add_child(mi)

	# thin dusty atmosphere rim — fresnel shell, the pale halo Mars shows from orbit
	var atmo := MeshInstance3D.new()
	var asph := SphereMesh.new()
	asph.radius = GLOBE_R * 1.03; asph.height = GLOBE_R * 2.06
	atmo.mesh = asph
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_front;
void fragment(){
	// Mars' limb haze from orbit is VERY thin — keep this a whisper, not an outline
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 5.0);
	ALBEDO = vec3(0.80, 0.62, 0.44) * rim;
	ALPHA = rim * 0.22;
}
"""
	var am := ShaderMaterial.new(); am.shader = sh
	atmo.material_override = am
	_globe.add_child(atmo)

func _latlon_to_point(latlon: Vector2) -> Vector3:
	# lat° / east-lon° -> point on the globe surface, matching SphereMesh's equirect UV
	# (u=0 seam at -180°). Verified against the Valles Marineris scar in the texture.
	var lat := deg_to_rad(latlon.x)
	var phi := deg_to_rad(fmod(latlon.y + 180.0, 360.0)) # 0..TAU around +Y from -Z seam
	var cl := cos(lat)
	return Vector3(sin(phi) * cl, sin(lat), cos(phi) * cl) * GLOBE_R

func _build_markers() -> void:
	var cmp := get_node_or_null("/root/Campaign")
	if cmp == null:
		return
	for i in range(cmp.level_count()):
		var status: String = cmp.territory_status(i)
		var color: Color = {"player": COL_PLAYER, "contested": COL_CONTESTED,
							"rival": COL_RIVAL}[status]
		var info: Dictionary = cmp.TERRITORY_INFO[i]
		_add_marker(_latlon_to_point(info["latlon"]), color, 1.0,
					{"kind": "level", "index": i}, status == "contested")
	for hold in cmp.RIVAL_HOLDINGS:
		_add_marker(_latlon_to_point(hold["latlon"]), COL_RIVAL, 0.7,
					{"kind": "rival", "place": hold["place"]}, false)

func _add_marker(pos: Vector3, color: Color, scale_mul: float, meta: Dictionary, pulse: bool) -> void:
	var n := pos.normalized()
	var root := Node3D.new()
	# build a basis whose local Y points out of the planet (radial)
	var up_ref := Vector3(0, 0, 1) if absf(n.dot(Vector3(0, 1, 0))) > 0.95 else Vector3(0, 1, 0)
	var x := n.cross(up_ref).normalized()
	root.basis = Basis(x, n, x.cross(n))
	root.position = pos
	_globe.add_child(root)

	# emissive core dot
	var core := MeshInstance3D.new()
	var cs := SphereMesh.new(); cs.radius = 0.045 * scale_mul; cs.height = 0.09 * scale_mul
	core.mesh = cs
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = color
	cm.emission_enabled = true; cm.emission = color; cm.emission_energy_multiplier = 1.6
	core.material_override = cm
	root.add_child(core)
	if pulse:
		_contested_mats.append(cm)

	# translucent territory ring on the surface
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.10 * scale_mul; t.outer_radius = 0.13 * scale_mul
	ring.mesh = t
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(color.r, color.g, color.b, 0.55)
	ring.material_override = rm
	root.add_child(ring)

	# pick area (hover + click)
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shp := SphereShape3D.new(); shp.radius = 0.16 * scale_mul
	col.shape = shp
	area.add_child(col)
	area.set_meta("info", meta)
	root.add_child(area)

# ---------------------------------------------------------------- HUD
func _build_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var title := Label.new()
	title.text = "MARS — TERRITORY CONTROL"
	title.position = Vector2(16, 12)
	title.add_theme_font_size_override("font_size", 26)
	cl.add_child(title)

	# faction legend
	var legend := Label.new()
	legend.text = "●  UNION-HELD      ●  CONTESTED — CLICK TO DEPLOY      ●  AREX CORP"
	legend.position = Vector2(16, 48)
	legend.add_theme_font_size_override("font_size", 14)
	cl.add_child(legend)
	# color the legend dots with three overlay labels (cheap, no RichText needed)
	for dot in [[16, COL_PLAYER], [175, COL_CONTESTED], [480, COL_RIVAL]]:
		var d := Label.new()
		d.text = "●"
		d.position = Vector2(dot[0], 48)
		d.add_theme_font_size_override("font_size", 14)
		d.add_theme_color_override("font_color", dot[1])
		cl.add_child(d)

	_info = Label.new()
	_info.position = Vector2(16, 620)
	_info.add_theme_font_size_override("font_size", 18)
	_info.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	cl.add_child(_info)

	var hint := Label.new()
	hint.text = "DRAG rotate · WHEEL zoom · CLICK territory · ESC menu\nGlobe imagery: NASA/Viking mosaic (Solar System Scope, CC-BY 4.0)"
	hint.position = Vector2(16, 660)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	cl.add_child(hint)

func _show_brief(index: int) -> void:
	var cmp := get_node_or_null("/root/Campaign")
	if cmp == null:
		return
	var lv: Dictionary = cmp.get_level(index)
	var info: Dictionary = cmp.TERRITORY_INFO[index]
	_close_brief()
	var cl := CanvasLayer.new(); cl.name = "BriefLayer"; cl.layer = 100
	add_child(cl)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260, -140)
	panel.custom_minimum_size = Vector2(520, 0)
	cl.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)
	var name_l := Label.new()
	name_l.text = "%s — %s" % [lv["name"], info["place"]]
	name_l.add_theme_font_size_override("font_size", 24)
	col.add_child(name_l)
	var brief_l := Label.new()
	brief_l.text = lv.get("brief", "")
	brief_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brief_l.add_theme_font_size_override("font_size", 16)
	col.add_child(brief_l)
	var status_l := Label.new()
	var status: String = cmp.territory_status(index)
	status_l.text = "STATUS: " + {"player": "UNION-HELD — replay available",
		"contested": "CONTESTED — deployment authorized", "rival": "AREX-HELD"}[status]
	status_l.add_theme_font_size_override("font_size", 14)
	col.add_child(status_l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var launch := Button.new()
	launch.text = "▶ DEPLOY"
	launch.custom_minimum_size = Vector2(200, 44)
	launch.pressed.connect(func():
		cmp.set_current(index)
		get_tree().change_scene_to_file(MISSION))
	row.add_child(launch)
	var back := Button.new()
	back.text = "CANCEL"
	back.custom_minimum_size = Vector2(140, 44)
	back.pressed.connect(_close_brief)
	row.add_child(back)
	_brief = panel

func _close_brief() -> void:
	var old := get_node_or_null("BriefLayer")
	if old:
		old.queue_free()
	_brief = null

# ---------------------------------------------------------------- input / frame
func _unhandled_input(event: InputEvent) -> void:
	if _brief != null and is_instance_valid(_brief):
		return   # popup open: globe input paused
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_drag_moved = 0.0
			else:
				_dragging = false
				if _drag_moved < 6.0:   # a click, not a drag
					_click()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_cam_dist = clampf(_cam_dist - 0.45, 2.9, 9.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_cam_dist = clampf(_cam_dist + 0.45, 2.9, 9.0)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging:
			_drag_moved += mm.relative.length()
			# zoomed in = finer rotation, so close-up inspection stays controllable
			var sens := 0.005 * (_cam_dist / 6.0)
			_globe.rotation.y += mm.relative.x * sens
			_tilt.rotation.x = clampf(_tilt.rotation.x + mm.relative.y * sens, -1.25, 1.25)
		else:
			_update_hover(mm.position)
	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MENU)

func _pick(screen_pos: Vector2) -> Area3D:
	var from := _cam.project_ray_origin(screen_pos)
	var dir := _cam.project_ray_normal(screen_pos)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 40.0)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.get("collider") if not hit.is_empty() else null

func _update_hover(screen_pos: Vector2) -> void:
	_hover_area = _pick(screen_pos)
	if _hover_area:
		var meta: Dictionary = _hover_area.get_meta("info")
		var cmp := get_node_or_null("/root/Campaign")
		if meta["kind"] == "level" and cmp:
			var lv: Dictionary = cmp.get_level(meta["index"])
			var info: Dictionary = cmp.TERRITORY_INFO[meta["index"]]
			_info.text = "%s — %s   [%s]" % [lv["name"], info["place"],
				cmp.territory_status(meta["index"]).to_upper()]
		else:
			_info.text = "%s   [AREX STRONGHOLD]" % meta.get("place", "")
	else:
		_info.text = ""

func _click() -> void:
	if _hover_area == null or not is_instance_valid(_hover_area):
		return
	var meta: Dictionary = _hover_area.get_meta("info")
	if meta["kind"] == "level":
		var cmp := get_node_or_null("/root/Campaign")
		if cmp and cmp.territory_status(meta["index"]) != "rival":
			_show_brief(meta["index"])

func _process(delta: float) -> void:
	_t += delta
	# smooth wheel zoom
	_cam.position.z = lerpf(_cam.position.z, _cam_dist, minf(delta * 8.0, 1.0))
	# idle: the planet turns slowly, like watching from parked orbit
	if not _dragging and (_brief == null or not is_instance_valid(_brief)):
		_globe.rotation.y += delta * 0.04
	# contested markers pulse to draw the eye
	for m in _contested_mats:
		if is_instance_valid(m):
			m.emission_energy_multiplier = 1.4 + sin(_t * 3.0) * 0.9
