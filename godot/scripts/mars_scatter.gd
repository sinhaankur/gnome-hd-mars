extends Node3D
class_name MarsScatter
## Phase 1 of the Mars surface "ecosystem" (GitHub #2, epic #1).
## Scatters real 3D rocks across the terrain, placed by the terrain's own height() API so they
## sit ON the real HiRISE relief — never floating, never inside the flattened installation pad.
## Uses MultiMeshInstance3D: hundreds of rocks render in ONE draw call (perf-safe).
##
## Discovery-based variety (what the rovers actually find on Mars):
##   - breccia boulders  : angular, blocky impact rubble (most common)
##   - potato-chip plates: thin flat wind-scoured slabs
##   - meteorite         : rare dark iron-nickel hero-rock (the real "Phippsaksla")
## Palette: butterscotch regolith -> dark basalt (ART_DIRECTION.md), desaturated, never lava-orange.
##
## Usage:
##   var scatter := MarsScatter.make(terrain, 400.0, 30.0)   # terrain, world_size, pad_radius
##   add_child(scatter)

# per-kind tuning: [count, min_scale, max_scale, flatness, color, roughness]
const KINDS := {
	"breccia":  { "count": 240, "smin": 0.5, "smax": 2.6, "flat": 1.0, "col": Color(0.42, 0.30, 0.22), "rough": 1.0 },
	"chip":     { "count": 120, "smin": 0.6, "smax": 2.0, "flat": 0.25, "col": Color(0.50, 0.40, 0.30), "rough": 0.95 },
	"meteorite":{ "count": 5,   "smin": 1.2, "smax": 2.4, "flat": 0.8, "col": Color(0.14, 0.13, 0.13), "rough": 0.5 },
}

static func make(terrain: Node3D, world_size: float = 400.0, pad_radius: float = 30.0,
				 seed_val: int = 1337) -> Node3D:
	var root := Node3D.new()
	root.name = "MarsScatter"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var half := world_size * 0.5

	for kind in KINDS.keys():
		var cfg: Dictionary = KINDS[kind]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _rock_mesh(kind, cfg)

		# gather valid placements first so instance_count is exact
		var xforms: Array[Transform3D] = []
		var cols: Array[Color] = []
		var tries := 0
		var target: int = cfg["count"]
		while xforms.size() < target and tries < target * 8:
			tries += 1
			var x := rng.randf_range(-half + 4.0, half - 4.0)
			var z := rng.randf_range(-half + 4.0, half - 4.0)
			# keep rocks OUT of the flattened installation pad (with a margin)
			if Vector2(x, z).length() < pad_radius + 6.0:
				continue
			var y := 0.0
			if terrain and terrain.has_method("height"):
				y = terrain.height(x, z)
			# slope reject: skip near-vertical spots (rocks rest, they don't cling to cliffs)
			var slope := _slope_at(terrain, x, z)
			if slope > 0.55:
				continue
			# scale, biased small (few big boulders, many small — like the real fields)
			var t := rng.randf()
			var s: float = lerp(cfg["smin"], cfg["smax"], t * t)
			var basis := Basis()
			basis = basis.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			basis = basis.rotated(Vector3.RIGHT, rng.randf_range(-0.12, 0.12))
			basis = basis.scaled(Vector3(s, s * cfg["flat"] * rng.randf_range(0.7, 1.1), s))
			# sink slightly so the rock bases into the ground, not perched on it
			var xf := Transform3D(basis, Vector3(x, y - s * 0.12, z))
			xforms.append(xf)
			# per-instance colour variation around the kind's base (brightness > hue, per research)
			var c: Color = cfg["col"]
			var v := rng.randf_range(0.82, 1.18)
			cols.append(Color(c.r * v, c.g * v, c.b * v))

		mm.instance_count = xforms.size()
		for i in xforms.size():
			mm.set_instance_transform(i, xforms[i])
			mm.set_instance_color(i, cols[i])

		var mmi := MultiMeshInstance3D.new()
		mmi.name = "rocks_" + kind
		mmi.multimesh = mm
		mmi.material_override = _rock_material(cfg)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(mmi)

	return root

# a low-poly rock mesh per kind. A deformed icosphere reads as a real boulder cheaply.
static func _rock_mesh(kind: String, cfg: Dictionary) -> Mesh:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6
	sm.rings = 4          # faceted, not smooth — rocks are angular
	# SphereMesh is already a usable low-poly rock when flat-shaded by the material
	return sm

static func _rock_material(cfg: Dictionary) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true       # per-instance colour drives albedo
	m.albedo_color = cfg["col"]
	m.roughness = cfg["rough"]
	m.metallic = 0.0 if cfg["rough"] > 0.8 else 0.3   # the meteorite reads a touch metallic
	# flat/faceted shading so the low-poly rock looks like angular stone, not a smooth ball
	return m

# cheap central-difference slope magnitude (0 flat .. 1 steep) from the height field
static func _slope_at(terrain: Node3D, x: float, z: float) -> float:
	if terrain == null or not terrain.has_method("height"):
		return 0.0
	var e := 1.5
	var hx := terrain.height(x + e, z) - terrain.height(x - e, z)
	var hz := terrain.height(x, z + e) - terrain.height(x, z - e)
	return clamp(Vector2(hx, hz).length() / (2.0 * e), 0.0, 1.0)
