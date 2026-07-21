extends RefCounted
class_name OrbitalShips
## Procedural orbital craft for the arrival cinematic, sized to read against the
## planet globe (GLOBE_R ~ 2.0). Two craft, logically distinct:
##   mothership() — a big interplanetary carrier that STAYS in orbit (it never lands).
##   subship()    — a small drop-lander that DETACHES from the carrier, carries the
##                  HAWC in an open cradle, and descends to the surface.
## Built in code (no fragile GLB) with a weathered corporate-metal look matching the
## dropship/installation palette. Scale is deliberately tiny — these fly near a 2 m globe.

const HULL   := Color(0.55, 0.54, 0.52)   # dusty structural metal
const DARK    := Color(0.24, 0.24, 0.27)
const ACCENT := Color(0.85, 0.62, 0.18)   # corporate orange
const GLASS  := Color(0.20, 0.35, 0.45)
const GLOW   := Color(1.0, 0.55, 0.2)      # engine glow

static func _mat(c: Color, metal := 0.6, rough := 0.5, emit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c; m.metallic = metal; m.roughness = rough
	if emit:
		m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 4.0
	return m

static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new(); mi.scale = size; mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, r: float, h: float, pos: Vector3, mat: StandardMaterial3D, axis := "y") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new(); c.top_radius = r; c.bottom_radius = r; c.height = h
	mi.mesh = c; mi.position = pos; mi.material_override = mat
	if axis == "z": mi.rotation.x = PI / 2.0
	elif axis == "x": mi.rotation.z = PI / 2.0
	parent.add_child(mi)
	return mi

# ---------------------------------------------------------------- mothership (stays in orbit)
static func mothership() -> Node3D:
	# A ~0.9-unit interplanetary carrier: long spine, habitation drum, cargo spine with
	# docked sub-landers, big rear engine block, radiator fins. Reads as "the ride from
	# Earth" — too big to land, so it holds orbit and drops sub-ships.
	var s := 0.06   # overall scale so the whole ship is ~0.9 units near the 2u globe
	var root := Node3D.new(); root.name = "Mothership"
	var body := Node3D.new(); body.scale = Vector3.ONE * s
	root.add_child(body)
	var hull := _mat(HULL); var dark := _mat(DARK); var accent := _mat(ACCENT)
	var glass := _mat(GLASS, 0.3, 0.15, true); var glow := _mat(GLOW, 0.0, 0.4, true)

	# central spine
	_cyl(body, 0.9, 14.0, Vector3(0, 0, 0), hull, "z")
	# forward command module + bridge glass
	_cyl(body, 1.5, 2.2, Vector3(0, 0, -7.0), hull, "z")
	_box(body, Vector3(1.6, 0.7, 1.2), Vector3(0, 0.9, -7.4), glass)
	# habitation drum (mid)
	_cyl(body, 2.4, 3.0, Vector3(0, 0, -1.5), hull, "z")
	_cyl(body, 2.5, 0.6, Vector3(0, 0, -1.5), accent, "z")   # accent band
	# cargo spine with two docked sub-lander cradles (visual — the real one detaches)
	for sx in [-1.0, 1.0]:
		_box(body, Vector3(1.4, 1.4, 3.0), Vector3(sx * 3.2, 0, 3.0), dark)
	# rear engine block + nozzles + glow
	_cyl(body, 2.2, 2.0, Vector3(0, 0, 7.2), dark, "z")
	for a in range(4):
		var ang := a * TAU / 4.0
		var ex := cos(ang) * 1.1; var ey := sin(ang) * 1.1
		_cyl(body, 0.6, 1.2, Vector3(ex, ey, 8.4), dark, "z")
		var g := _cyl(body, 0.45, 0.3, Vector3(ex, ey, 9.1), glow, "z")
	# radiator fins
	for sx in [-1.0, 1.0]:
		_box(body, Vector3(0.1, 4.0, 4.0), Vector3(sx * 3.0, 0, 2.0), _mat(Color(0.3,0.3,0.34), 0.7, 0.3))
	return root

# ---------------------------------------------------------------- sub-ship (detaches, lands)
static func subship() -> Node3D:
	# The drop-lander: a compact lifting-body with an OPEN cradle underneath holding the
	# HAWC, four descent thrusters, a stubby cockpit. This is what actually goes to ground.
	var s := 0.035
	var root := Node3D.new(); root.name = "SubShip"
	var body := Node3D.new(); body.scale = Vector3.ONE * s
	root.add_child(body)
	var hull := _mat(HULL); var dark := _mat(DARK); var accent := _mat(ACCENT)
	var glass := _mat(GLASS, 0.3, 0.15, true); var glow := _mat(GLOW, 0.0, 0.4, true)

	# slab lifting-body hull
	_box(body, Vector3(4.0, 1.2, 6.0), Vector3(0, 0, 0), hull)
	# cockpit visor at the nose
	_box(body, Vector3(2.2, 0.8, 1.4), Vector3(0, 0.5, -3.2), glass)
	# accent stripe
	_box(body, Vector3(4.1, 0.3, 1.0), Vector3(0, 0.4, 0), accent)
	# four descent-thruster pods at the corners, with glow
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_cyl(body, 0.5, 1.4, Vector3(sx * 1.7, -0.9, sz * 2.2), dark)
			_cyl(body, 0.42, 0.3, Vector3(sx * 1.7, -1.7, sz * 2.2), glow)
	# OPEN under-cradle holding the HAWC (arms only — the mech mounts separately)
	for sx in [-1.0, 1.0]:
		_box(body, Vector3(0.25, 2.0, 4.5), Vector3(sx * 1.4, -2.0, 0), dark)
	_box(body, Vector3(3.0, 0.25, 0.4), Vector3(0, -3.0, -1.8), dark)   # cradle floor bar
	return root

# a small HAWC stand-in to ride the sub-ship cradle (silhouette only — real mech is in-mission)
static func hawc_pod() -> Node3D:
	var s := 0.02
	var root := Node3D.new(); root.name = "HawcPod"
	var body := Node3D.new(); body.scale = Vector3.ONE * s
	root.add_child(body)
	var hull := _mat(Color(0.34, 0.40, 0.30), 0.5, 0.6)
	_box(body, Vector3(2.2, 2.4, 1.6), Vector3(0, 1.4, 0), hull)   # torso
	_box(body, Vector3(1.4, 1.0, 1.2), Vector3(0, 3.0, 0), hull)   # head block
	for sx in [-1.0, 1.0]:
		_box(body, Vector3(0.8, 2.6, 0.8), Vector3(sx * 1.5, -0.6, 0), hull)  # legs
		_box(body, Vector3(0.7, 1.8, 0.7), Vector3(sx * 1.9, 1.6, 0), hull)   # arms
	return root
