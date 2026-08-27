extends Camera3D
## Polished mech camera with three MODES (V key cycles, wheel zooms):
##   THIRD  — orbiting chase cam: back-and-above, spring-arm collision, speed FOV/pullback
##   FIRST  — cockpit view from the mech's head (mech visual hidden to avoid clipping)
##   FAR    — pulled-back tactical view for reading the whole battle
## Mouse orbits in every mode; wheel changes follow distance in THIRD/FAR.

enum Mode { THIRD, FIRST, FAR }

@export var target_path: NodePath
@export var distance: float = 12.0        # how far behind the mech (tighter = hero mech fills frame)
@export var height: float = 6.0           # pivot height on the mech
@export var min_pitch: float = -0.5       # look up limit (radians)
@export var max_pitch: float = 1.1        # look down limit (radians)
@export var mouse_sens: float = 0.005
@export var pos_smooth: float = 12.0      # position follow damping
@export var aim_smooth: float = 14.0      # look-target damping
@export var look_height: float = 4.5      # aim point height on the mech
@export var base_fov: float = 62.0
@export var speed_fov: float = 8.0        # extra FOV at full speed
@export var speed_pullback: float = 3.0   # extra distance at full speed
@export var collision_margin: float = 1.2 # keep the cam this far off surfaces

@export var cockpit_height: float = 6.2   # head height on the mech for first person
@export var far_mult: float = 2.3         # FAR mode distance multiplier

var _target: Node3D
var yaw: float = 0.0
var _pitch: float = 0.35
var _look_at: Vector3 = Vector3.ZERO
var _cur_dist: float = 12.0
var _shake: float = 0.0        # current shake trauma (0..1), decays over time
var _mode: Mode = Mode.THIRD
var _zoom: float = 0.0         # wheel zoom offset on top of base distance

## Called by the game to shake the camera (fire, explosions, landing).
func add_shake(amount: float) -> void:
	_shake = clampf(_shake + amount, 0.0, 1.0)

## Retarget to another body (possession: mech <-> pilot on foot). The follow
## geometry scales to the new body so a 1.8 m pilot isn't filmed like a 7 m mech.
func set_target(t: Node3D, dist: float, h: float, look_h: float) -> void:
	_target = t
	distance = dist
	height = h
	look_height = look_h
	_zoom = 0.0
	_cur_dist = dist

func _ready() -> void:
	_target = get_node_or_null(target_path)
	fov = base_fov
	_cur_dist = distance
	if _target:
		yaw = _target.rotation.y
		_look_at = _target.global_position + Vector3.UP * look_height
		global_position = _desired_pos(distance)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var sens := mouse_sens
		var cfg := get_node_or_null("/root/Settings")
		if cfg:
			sens *= cfg.mouse_sensitivity
		yaw -= event.relative.x * sens
		_pitch = clampf(_pitch + event.relative.y * sens, min_pitch, max_pitch)
	elif event.is_action_pressed("camera_mode"):
		_cycle_mode()
	elif event is InputEventMouseButton and event.pressed:
		# wheel zoom adjusts follow distance (not in first person)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom - 1.5, -8.0, 14.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom + 1.5, -8.0, 14.0)

func _cycle_mode() -> void:
	_mode = ((_mode + 1) % 3) as Mode
	# hide the mech model in first person so we don't look through its head
	var vis := _target.get_node_or_null("Visual") if _target else null
	if vis:
		vis.visible = _mode != Mode.FIRST
	# first person looks up naturally; widen limits there
	if _mode == Mode.FIRST:
		fov = base_fov + 8.0

func _pivot() -> Vector3:
	return _target.global_position + Vector3.UP * height

func _dir() -> Vector3:
	# unit vector from pivot toward the ideal camera position
	return Vector3(sin(yaw) * cos(_pitch), sin(_pitch), cos(yaw) * cos(_pitch))

func _desired_pos(dist: float) -> Vector3:
	return _pivot() + _dir() * dist

func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return

	# speed factor 0..1 for dynamic pull-back + FOV
	var speed_ratio := 0.0
	if _target.has_method("get_speed_ratio"):
		speed_ratio = _target.get_speed_ratio()

	# --- FIRST PERSON: camera rides in the mech's head; mouse aims directly ---
	if _mode == Mode.FIRST:
		var fwd := -_dir()   # reverse of the orbit vector = the pilot's look direction
		global_position = _target.global_position + Vector3.UP * cockpit_height + fwd * 0.9
		look_at(global_position + fwd, Vector3.UP)
		if _shake > 0.0:
			_shake = maxf(0.0, _shake - delta * 1.5)
			rotation.z = randf_range(-1, 1) * _shake * _shake * 0.03
		return

	# target distance: base per mode + wheel zoom + a little pull-back at speed
	var mode_dist := distance * (far_mult if _mode == Mode.FAR else 1.0)
	var want_dist := maxf(mode_dist + _zoom + speed_pullback * speed_ratio, 6.0)

	# --- spring arm: cast from pivot toward the ideal cam pos; stop before obstacles ---
	var pivot := _pivot()
	var ideal := pivot + _dir() * want_dist
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(pivot, ideal)
	q.exclude = [_target.get_rid()]
	var hit := space.intersect_ray(q)
	var clamped_dist := want_dist
	if not hit.is_empty():
		var d := pivot.distance_to(hit.position) - collision_margin
		clamped_dist = clampf(d, 3.0, want_dist)

	_cur_dist = lerpf(_cur_dist, clamped_dist, clampf(pos_smooth * delta, 0.0, 1.0))
	var goal := pivot + _dir() * _cur_dist
	global_position = global_position.lerp(goal, clampf(pos_smooth * delta, 0.0, 1.0))

	# --- aim: lead the mech slightly in its facing direction, damped ---
	var forward := -_target.global_transform.basis.z    # visual-ish forward for framing
	var want_look := _target.global_position + Vector3.UP * look_height + forward * (2.0 + 3.0 * speed_ratio)
	_look_at = _look_at.lerp(want_look, clampf(aim_smooth * delta, 0.0, 1.0))
	look_at(_look_at, Vector3.UP)

	# --- camera shake: jitter position + roll, decaying (trauma^2 for punchy falloff) ---
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.5)
		var s := _shake * _shake
		var jitter := Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)) * s * 0.6
		global_position += jitter
		rotation.z = randf_range(-1, 1) * s * 0.04

	# --- dynamic FOV: widen a touch at speed ---
	fov = lerpf(fov, base_fov + speed_fov * speed_ratio, clampf(6.0 * delta, 0.0, 1.0))
