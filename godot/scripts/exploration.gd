extends Node3D
class_name Exploration
## Exploration layer — scatters discoverable Points of Interest across the Mars surface.
## The player finds them by driving near; each emits a discovery event once. Part of the
## Environment (the world holds the POIs); the level shows notifications and tracks progress.
##
## configure(env) then it self-populates. Signals:
##   poi_discovered(name, description, index, total)
##   all_discovered

signal poi_discovered(poi_name: String, description: String, index: int, total: int)
signal all_discovered

@export var discover_radius: float = 16.0

var _env: EnvironmentEngine
var _pois: Array = []          # {node, name, desc, found}
var _found_count := 0

# The set of things to find out on the Martian plains.
const CATALOG := [
	{"name": "Crashed Recon Probe", "desc": "A Union survey probe, half-buried in regolith. Data core intact.", "color": Color(0.6, 0.8, 1.0)},
	{"name": "Water-Ice Deposit", "desc": "Subsurface ice glinting in a crater wall. Strategic resource.", "color": Color(0.7, 0.9, 1.0)},
	{"name": "Derelict Rover", "desc": "A decades-old exploration rover, long dead. A relic of the first missions.", "color": Color(0.9, 0.7, 0.4)},
	{"name": "Anomaly Signal", "desc": "A faint repeating transmission from beneath the surface. Origin unknown.", "color": Color(0.5, 1.0, 0.5)},
	{"name": "AREX Supply Cache", "desc": "A corporate supply drop, still sealed. Salvageable munitions.", "color": Color(1.0, 0.5, 0.3)},
	{"name": "Ancient Riverbed", "desc": "A dry channel carved by water billions of years ago. Scientifically priceless.", "color": Color(0.8, 0.6, 0.4)},
]

func configure(env: EnvironmentEngine) -> void:
	_env = env

func populate() -> void:
	# place each POI on walkable ground, spread around the map, away from the base
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for entry in CATALOG:
		var pos := _find_spot(rng)
		if pos == Vector3.INF:
			continue
		var poi := _build_marker(entry["name"], entry["color"])
		add_child(poi)               # must be in-tree before setting a global transform
		poi.global_position = pos
		_pois.append({"node": poi, "name": entry["name"], "desc": entry["desc"], "found": false})

func _find_spot(rng: RandomNumberGenerator) -> Vector3:
	var half := _env.world_size * 0.5 - 30.0
	for _try in range(40):
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		# keep away from the player start and the installation
		if Vector2(x, z).distance_to(Vector2(0, 160)) < 40.0:
			continue
		if Vector2(x, z).distance_to(Vector2(_env.installation_pos.x, _env.installation_pos.z)) < 60.0:
			continue
		if not _env.is_walkable(x, z):
			continue
		var y := _env.ground_height(x, z)
		if is_nan(y):
			continue
		return Vector3(x, y, z)
	return Vector3.INF

func _build_marker(poi_name: String, _color: Color) -> Node3D:
	# DIEGETIC sites (GTA-style discovery): each POI is a PHYSICAL landmark you spot by
	# silhouette and contrast — wreckage, hardware, geology — never a magic light pillar.
	# A small blinking beacon lamp (like real planetary hardware) is the only emission.
	var root := Node3D.new()
	root.name = "POI_" + poi_name.replace(" ", "_")
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.55, 0.54, 0.52); metal.metallic = 0.7; metal.roughness = 0.55
	var dusty_metal := StandardMaterial3D.new()
	dusty_metal.albedo_color = Color(0.52, 0.44, 0.36); dusty_metal.metallic = 0.35; dusty_metal.roughness = 0.85

	match poi_name:
		"Crashed Recon Probe":
			# tilted probe body dug into a dark scorch mark
			var body := MeshInstance3D.new()
			var cap := CapsuleMesh.new(); cap.radius = 1.1; cap.height = 5.0
			body.mesh = cap; body.material_override = metal
			body.rotation_degrees = Vector3(64, 30, 0); body.position.y = 0.9
			root.add_child(body)
			var scorch := MeshInstance3D.new()
			var disc := CylinderMesh.new(); disc.top_radius = 4.5; disc.bottom_radius = 4.5; disc.height = 0.1
			scorch.mesh = disc
			var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.30, 0.25, 0.21); sm.roughness = 1.0
			scorch.material_override = sm; scorch.position.y = 0.03
			root.add_child(scorch)
		"Water-Ice Deposit":
			# pale exposed ice patch + chunks — bright against the regolith
			var ice := StandardMaterial3D.new()
			ice.albedo_color = Color(0.85, 0.90, 0.95); ice.roughness = 0.25
			var patch := MeshInstance3D.new()
			var pd := CylinderMesh.new(); pd.top_radius = 3.6; pd.bottom_radius = 3.6; pd.height = 0.15
			patch.mesh = pd; patch.material_override = ice; patch.position.y = 0.05
			root.add_child(patch)
			for i in range(4):
				var chunk := MeshInstance3D.new()
				var cs := SphereMesh.new(); cs.radius = 0.6; cs.height = 0.9
				chunk.mesh = cs; chunk.material_override = ice
				chunk.position = Vector3(cos(i * 1.7) * 1.8, 0.25, sin(i * 1.7) * 1.8)
				root.add_child(chunk)
		"Derelict Rover":
			# boxy rover hull on six wheels, long dead and dust-caked
			var hull := MeshInstance3D.new()
			hull.mesh = BoxMesh.new(); hull.scale = Vector3(2.4, 1.1, 3.6)
			hull.material_override = dusty_metal; hull.position.y = 1.5
			root.add_child(hull)
			for sx in [-1.3, 1.3]:
				for z in [-1.4, 0.0, 1.4]:
					var wheel := MeshInstance3D.new()
					var wc := CylinderMesh.new(); wc.top_radius = 0.55; wc.bottom_radius = 0.55; wc.height = 0.4
					wheel.mesh = wc; wheel.material_override = metal
					wheel.rotation_degrees = Vector3(0, 0, 90)
					wheel.position = Vector3(sx, 0.55, z)
					root.add_child(wheel)
		"Anomaly Signal":
			# a half-buried dark monolith — the one site allowed a faint unnatural hum
			var slab := MeshInstance3D.new()
			slab.mesh = BoxMesh.new(); slab.scale = Vector3(0.9, 5.5, 2.2)
			var am := StandardMaterial3D.new()
			am.albedo_color = Color(0.16, 0.15, 0.17); am.roughness = 0.3; am.metallic = 0.5
			am.emission_enabled = true; am.emission = Color(0.35, 0.9, 0.6)
			am.emission_energy_multiplier = 0.25   # faint — a hum, not a lamp
			slab.material_override = am
			slab.rotation_degrees = Vector3(8, 25, -6); slab.position.y = 1.8
			root.add_child(slab)
		"AREX Supply Cache":
			# stacked drop crates under a torn tarp line
			for i in range(3):
				var crate := MeshInstance3D.new()
				crate.mesh = BoxMesh.new()
				crate.scale = Vector3.ONE * (1.6 - i * 0.25)
				crate.material_override = dusty_metal
				crate.position = Vector3(i * 0.8 - 0.8, 0.8 + i * 1.1, i * 0.3)
				crate.rotation.y = i * 0.4
				root.add_child(crate)
		"Ancient Riverbed":
			# a curve of smooth pale stones tracing the old channel
			for i in range(7):
				var stone := MeshInstance3D.new()
				var ss := SphereMesh.new(); ss.radius = 1.0; ss.height = 1.0
				stone.mesh = ss
				var pm := StandardMaterial3D.new()
				pm.albedo_color = Color(0.72, 0.62, 0.52); pm.roughness = 0.9
				stone.material_override = pm
				var tt := float(i) / 6.0
				stone.position = Vector3(sin(tt * 2.4) * 6.0, 0.15, tt * 14.0 - 7.0)
				stone.scale = Vector3(1.4, 0.4, 1.8)
				root.add_child(stone)

	# survey mast: thin pole + small red blinking beacon lamp (diegetic, like real hardware)
	var mast := MeshInstance3D.new()
	var mc := CylinderMesh.new(); mc.top_radius = 0.05; mc.bottom_radius = 0.08; mc.height = 3.2
	mast.mesh = mc; mast.material_override = metal; mast.position = Vector3(2.2, 1.6, 0)
	root.add_child(mast)
	var bulb := MeshInstance3D.new()
	var bs := SphereMesh.new(); bs.radius = 0.12; bs.height = 0.24
	bulb.mesh = bs
	var bm := StandardMaterial3D.new()
	bm.emission_enabled = true; bm.emission = Color(1.0, 0.25, 0.2)
	bm.emission_energy_multiplier = 2.0
	bm.albedo_color = Color(0.4, 0.1, 0.1)
	bulb.name = "BeaconBulb"
	bulb.material_override = bm
	bulb.position = Vector3(2.2, 3.3, 0)
	root.add_child(bulb)
	_beacons.append(bm)
	return root

var _beacons: Array = []   # beacon bulb materials — blinked in _process
var _blink_t := 0.0

func _process(delta: float) -> void:
	# staggered slow blink, the way real hazard beacons read at night
	_blink_t += delta
	for i in range(_beacons.size()):
		var m: StandardMaterial3D = _beacons[i]
		if is_instance_valid(m):
			var on := fmod(_blink_t + i * 0.45, 2.2) < 0.25
			m.emission_energy_multiplier = 2.4 if on else 0.15

func check(player_pos: Vector3) -> void:
	# call each frame from the level; fires discovery when the player is close enough
	for poi in _pois:
		if poi["found"]:
			continue
		var d := player_pos.distance_to(poi["node"].global_position)
		if d < discover_radius:
			poi["found"] = true
			_found_count += 1
			poi_discovered.emit(poi["name"], poi["desc"], _found_count, _pois.size())
			# fade the beam to show it's collected
			_mark_found(poi["node"])
			if _found_count >= _pois.size():
				all_discovered.emit()

func _mark_found(node: Node3D) -> void:
	# surveyed: the beacon lamp switches red -> steady green; stop blinking it
	var bulb := node.get_node_or_null("BeaconBulb") as MeshInstance3D
	if bulb and bulb.material_override is StandardMaterial3D:
		var mat := bulb.material_override as StandardMaterial3D
		_beacons.erase(mat)
		mat.emission = Color(0.35, 1.0, 0.5)
		mat.albedo_color = Color(0.1, 0.4, 0.15)
		mat.emission_energy_multiplier = 1.2

func found_count() -> int:
	return _found_count

func total() -> int:
	return _pois.size()
