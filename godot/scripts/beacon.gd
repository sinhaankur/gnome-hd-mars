extends Node3D
class_name Beacon
## The "reach" objective landmark: a physical ally comms outpost you spot on the
## horizon and drive to. DIEGETIC per the art-pass rule — real hardware silhouette
## (hab module, antenna dish, comms mast), and the ONLY emission is a slow amber
## hazard strobe on the mast like actual planetary landing gear. No light pillar,
## no floating icon. The mech reaching it (within reach_radius) wins the mission.
##
## Usage:  var b := Beacon.new(); add_child(b); b.global_position = spot
##         b.reached.connect(...)   # emitted once, when the player gets close

signal reached

@export var reach_radius: float = 20.0

var _done := false
var _strobe: StandardMaterial3D
var _blink_t := 0.0

func _ready() -> void:
	_build()

func _build() -> void:
	# shared dusty-metal look, matching the installation + exploration hardware
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.55, 0.54, 0.52); metal.metallic = 0.7; metal.roughness = 0.5
	var dusty := StandardMaterial3D.new()
	dusty.albedo_color = Color(0.52, 0.46, 0.40); dusty.metallic = 0.35; dusty.roughness = 0.85
	var panel := StandardMaterial3D.new()   # solar/hab panelling, cool grey-blue
	panel.albedo_color = Color(0.22, 0.26, 0.34); panel.metallic = 0.4; panel.roughness = 0.4

	# --- landing pad ring: a low disc so the site reads as prepared ground ---
	var pad := MeshInstance3D.new()
	var pd := CylinderMesh.new(); pd.top_radius = 8.0; pd.bottom_radius = 8.0; pd.height = 0.2
	pad.mesh = pd
	var pad_mat := StandardMaterial3D.new()
	pad_mat.albedo_color = Color(0.34, 0.30, 0.26); pad_mat.roughness = 1.0
	pad.material_override = pad_mat; pad.position.y = 0.05
	add_child(pad)

	# --- hab module: a squat cylinder shelter on short legs ---
	var hab := MeshInstance3D.new()
	var hc := CylinderMesh.new(); hc.top_radius = 2.6; hc.bottom_radius = 2.8; hc.height = 3.2
	hab.mesh = hc; hab.material_override = dusty
	hab.position = Vector3(-3.5, 2.0, 1.0)
	add_child(hab)
	# a stripe of hab panelling
	var band := MeshInstance3D.new()
	var bc := CylinderMesh.new(); bc.top_radius = 2.82; bc.bottom_radius = 2.82; bc.height = 0.9
	band.mesh = bc; band.material_override = panel
	band.position = Vector3(-3.5, 2.6, 1.0)
	add_child(band)

	# --- antenna dish on a stand, tilted skyward (comms relay) ---
	var stand := MeshInstance3D.new()
	var sc := CylinderMesh.new(); sc.top_radius = 0.12; sc.bottom_radius = 0.16; sc.height = 3.4
	stand.mesh = sc; stand.material_override = metal
	stand.position = Vector3(3.2, 1.7, -1.0)
	add_child(stand)
	var dish := MeshInstance3D.new()
	# a shallow spherical cap reads as a dish; a squashed hemisphere is close enough
	var dm := SphereMesh.new(); dm.radius = 1.9; dm.height = 1.4
	dish.mesh = dm; dish.material_override = metal
	dish.scale = Vector3(1.0, 0.35, 1.0)
	dish.rotation_degrees = Vector3(-40, 20, 0)
	dish.position = Vector3(3.2, 3.6, -1.0)
	add_child(dish)

	# --- comms mast: tall thin pole with the amber hazard strobe on top ---
	var mast := MeshInstance3D.new()
	var mc := CylinderMesh.new(); mc.top_radius = 0.08; mc.bottom_radius = 0.14; mc.height = 9.0
	mast.mesh = mc; mast.material_override = metal
	mast.position = Vector3(0, 4.5, 0)
	add_child(mast)
	var strobe := MeshInstance3D.new()
	var ss := SphereMesh.new(); ss.radius = 0.22; ss.height = 0.44
	strobe.mesh = ss
	_strobe = StandardMaterial3D.new()
	_strobe.albedo_color = Color(0.5, 0.32, 0.08)
	_strobe.emission_enabled = true
	_strobe.emission = Color(1.0, 0.62, 0.12)   # amber, like real aviation hazard beacons
	_strobe.emission_energy_multiplier = 3.0
	strobe.material_override = _strobe
	strobe.name = "Strobe"
	strobe.position = Vector3(0, 9.2, 0)
	add_child(strobe)

func _process(delta: float) -> void:
	# slow amber pulse — a landing beacon, not a disco light. Solid ~0.35 s, dark between.
	if _strobe == null:
		return
	_blink_t += delta
	var on := fmod(_blink_t, 1.8) < 0.35
	_strobe.emission_energy_multiplier = 3.2 if on else 0.25

func check(player_pos: Vector3) -> void:
	if _done:
		return
	if player_pos.distance_to(global_position) < reach_radius:
		_done = true
		# strobe locks to steady green: "objective secured"
		if _strobe:
			_strobe.emission = Color(0.35, 1.0, 0.5)
			_strobe.emission_energy_multiplier = 2.0
		reached.emit()

func distance_from(p: Vector3) -> float:
	return p.distance_to(global_position)
