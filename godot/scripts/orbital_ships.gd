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
# Real paneled drop-lander GLB (tools/build_ships.py -> assets/subship.glb): tapered
# lifting-body hull, recessed cockpit, 4 gimbaled descent thrusters, ventral cradle
# rails. Replaces the old primitive-box kitbash that read as a flat grey slab. Built
# +Z up in Blender, exported Y-up, so it drops in with Godot's Y-up convention.
const SUBSHIP_PATH := "res://assets/subship.glb"
const HAWC_POD_PATH := "res://assets/hawc_pod.glb"

static func subship() -> Node3D:
	var root := Node3D.new(); root.name = "SubShip"
	var scene: PackedScene = load(SUBSHIP_PATH)
	if scene:
		var m := scene.instantiate()
		# GLB hull is ~5 units; scale to the cinematic's tiny-near-a-2u-globe size.
		# The model's nose is -Y and it's Y-up; the cinematic look_at() aims it.
		m.scale = Vector3.ONE * 0.03
		root.add_child(m)
	else:
		# fallback: a plain slab so the cinematic still runs if the GLB is missing
		_box(root, Vector3(0.14, 0.04, 0.2), Vector3.ZERO, _mat(HULL))
	return root

# The HAWC riding the sub-ship's cradle — a real carrier-pod GLB reading as a mech
# clamped in a drop-frame (assets/hawc_pod.glb), not the old green box of cuboids.
static func hawc_pod() -> Node3D:
	var root := Node3D.new(); root.name = "HawcPod"
	var scene: PackedScene = load(HAWC_POD_PATH)
	if scene:
		var m := scene.instantiate()
		m.scale = Vector3.ONE * 0.018
		root.add_child(m)
	else:
		_box(root, Vector3(0.05, 0.08, 0.04), Vector3(0, 0.03, 0), _mat(Color(0.34, 0.40, 0.30), 0.5, 0.6))
	return root
