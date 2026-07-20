extends Node3D
## The Mars base you defend — built procedurally in-engine, not from the old
## installation.glb (which was a bare cream dome + a lollipop dish that read as a
## placeholder blob against the real-photo bar). A real compound: prepared landing
## pad, command dome, linked hab modules, storage tanks, a comms mast, and a low
## blast wall ringing the pad. Dusty low-sat metals per the Perseverance palette —
## nothing bright-white or plastic. The engine adds the animated radar dish + lights.
##
## Usage:  var inst := Installation.new(); inst.pad_radius = 32.0; add_child(inst)

@export var pad_radius: float = 32.0

# --- Mars-base palette: weathered, dust-caked, low saturation (never bright white) ---
const COL_PANEL  := Color(0.62, 0.58, 0.52)   # habitat panelling, sun-bleached tan-grey
const COL_METAL  := Color(0.52, 0.51, 0.49)   # structural steel, dusty
const COL_DARK   := Color(0.30, 0.30, 0.32)   # shadowed recesses / trim
const COL_ACCENT := Color(0.80, 0.62, 0.20)   # faction/hazard yellow markings
const COL_PAD    := Color(0.34, 0.31, 0.28)   # graded pad surface, darker than regolith
const COL_TANK   := Color(0.58, 0.56, 0.53)

func _ready() -> void:
	_build()

func _mat(c: Color, metal := 0.4, rough := 0.75) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c; m.metallic = metal; m.roughness = rough
	return m

func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D, yaw := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	mi.scale = size
	mi.position = pos
	mi.rotation.y = yaw
	mi.material_override = mat
	add_child(mi)
	return mi

func _cyl(rt: float, rb: float, h: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new(); c.top_radius = rt; c.bottom_radius = rb; c.height = h
	mi.mesh = c; mi.position = pos; mi.material_override = mat
	add_child(mi)
	return mi

func _build() -> void:
	var panel := _mat(COL_PANEL, 0.35, 0.7)
	var metal := _mat(COL_METAL, 0.6, 0.55)
	var dark := _mat(COL_DARK, 0.5, 0.6)
	var tank := _mat(COL_TANK, 0.65, 0.4)
	var accent := _mat(COL_ACCENT, 0.3, 0.6)
	var pad_mat := _mat(COL_PAD, 0.2, 1.0)

	# --- graded landing pad: a low disc the base sits on (matches the flattened terrain) ---
	var pad := _cyl(pad_radius, pad_radius, 0.4, Vector3(0, 0.2, 0), pad_mat)
	# painted hazard ring near the pad edge
	var ring := _cyl(pad_radius * 0.94, pad_radius * 0.94, 0.42, Vector3(0, 0.22, 0), accent)
	var ring_inner := _cyl(pad_radius * 0.88, pad_radius * 0.88, 0.44, Vector3(0, 0.23, 0), pad_mat)

	# --- command dome (central): a hemisphere on a short drum ---
	var drum := _cyl(7.0, 7.5, 3.0, Vector3(0, 1.9, 0), panel)
	var dome := MeshInstance3D.new()
	var ds := SphereMesh.new(); ds.radius = 7.0; ds.height = 7.0
	dome.mesh = ds; dome.scale = Vector3(1.0, 0.6, 1.0)
	dome.position = Vector3(0, 3.4, 0); dome.material_override = panel
	add_child(dome)
	# a viewport band around the drum
	var band := _cyl(7.55, 7.55, 0.9, Vector3(0, 2.6, 0), dark)

	# --- hab modules: cylinders lying on their sides, linked to the dome by corridors ---
	var hab_angles := [0.7, 2.3, 3.9, 5.2]
	for a in hab_angles:
		var hx := cos(a) * 13.0
		var hz := sin(a) * 13.0
		var hab := _cyl(2.8, 2.8, 8.0, Vector3(hx, 2.8, hz), panel)
		hab.rotation = Vector3(0, -a, PI / 2.0)   # lay it down, point outward
		# end cap trim
		var cap := _cyl(2.9, 2.9, 0.5, Vector3(hx, 2.8, hz), dark)
		cap.rotation = Vector3(0, -a, PI / 2.0)
		# connecting corridor to the dome
		var mid := Vector3((hx) * 0.5, 1.6, (hz) * 0.5)
		var corr := _box(Vector3(1.6, 1.8, hx * 0.0 + 6.0), mid, metal, -a + PI / 2.0)
		# small solar panel beside each hab, tilted to the sun
		var soc := _mat(Color(0.16, 0.18, 0.28), 0.4, 0.35)
		var solar := _box(Vector3(5.0, 0.15, 3.0), Vector3(hx * 1.35, 3.2, hz * 1.35), soc, -a)
		solar.rotation.x = -0.5

	# --- storage tanks: a cluster of vertical fuel/water tanks ---
	for i in range(3):
		var tx := -16.0 + i * 3.2
		var t := _cyl(1.6, 1.6, 6.0, Vector3(tx, 3.0, 15.0), tank)
		# domed top
		var td := MeshInstance3D.new()
		var tds := SphereMesh.new(); tds.radius = 1.6; tds.height = 1.6
		td.mesh = tds; td.scale = Vector3(1, 0.6, 1)
		td.position = Vector3(tx, 6.0, 15.0); td.material_override = tank
		add_child(td)

	# --- comms mast: a tall lattice-look mast (the engine mounts the spinning dish) ---
	var mast := _cyl(0.25, 0.4, 20.0, Vector3(10, 10, 6), metal)
	# guy struts
	for a2 in [0.0, 2.09, 4.18]:
		var strut := _cyl(0.08, 0.08, 14.0, Vector3(10 + cos(a2) * 3.0, 7.0, 6 + sin(a2) * 3.0), metal)
		strut.look_at_from_position(strut.position, Vector3(10, 18, 6), Vector3.UP)
		strut.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	# --- low blast wall: segmented ring around the pad (cover + reads as fortified) ---
	var seg_count := 20
	var wcol := _mat(Color(0.50, 0.45, 0.39), 0.3, 0.85)
	for i in range(seg_count):
		var ang := float(i) / seg_count * TAU
		# leave a gap for the entrance facing +Z (toward the player approach)
		if absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.35:
			continue
		var wx := cos(ang) * (pad_radius - 1.0)
		var wz := sin(ang) * (pad_radius - 1.0)
		var seg := _box(Vector3(pad_radius * TAU / seg_count * 0.95, 2.2, 1.0),
						Vector3(wx, 1.1, wz), wcol, ang + PI / 2.0)
		# a thin hazard stripe along the top of each segment
		if i % 2 == 0:
			_box(Vector3(pad_radius * TAU / seg_count * 0.95, 0.3, 1.05),
				 Vector3(wx, 2.2, wz), accent, ang + PI / 2.0)

	# --- entrance markers: two short pylons flanking the wall gap ---
	for sx in [-4.5, 4.5]:
		var pyl := _cyl(0.5, 0.6, 3.0, Vector3(sx, 1.5, pad_radius - 1.0), dark)
		var top := _cyl(0.55, 0.55, 0.4, Vector3(sx, 3.1, pad_radius - 1.0), accent)
