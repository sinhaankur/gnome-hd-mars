extends Node3D
class_name MarsDustDevil
## Phase 3 of the Mars surface "ecosystem" (GitHub #4, epic #1).
## A wandering dust devil — the single most "alive" thing on a dead planet.
## Real behaviour (Perseverance, Jezero 2025): tall rotating dust columns up to ~65 m,
## winds to 44 m/s, that drift across the terrain, occasionally merge, and carry faint
## electrical sparks. Here: a GPUParticles3D column that spawns at a terrain edge, drifts
## with the prevailing wind while the player is near, then dissipates and respawns elsewhere.
##
## Usage:  add_child(MarsDustDevil.make(env))   # env exposes ground_height()/world_size

const HEIGHT := 55.0          # column height in metres (tall, but under the real ~65 m extreme)
const BASE_RADIUS := 2.2      # funnel foot radius
const TOP_RADIUS := 7.0       # it widens with height
const DRIFT_SPEED := 9.0      # m/s wander across the plain (well under the 44 m/s wind extreme)
const LIFE := 46.0            # seconds before it dissipates and respawns

var _env: Node
var _particles: GPUParticles3D
var _vel := Vector3.ZERO
var _age := 0.0
var _world := 400.0
var _rng := RandomNumberGenerator.new()

static func make(env: Node, seed_val: int = 99) -> MarsDustDevil:
	var dd := MarsDustDevil.new()
	dd.name = "DustDevil"
	dd._env = env
	dd._rng.seed = seed_val
	if env and "world_size" in env:
		dd._world = env.world_size
	return dd

func _ready() -> void:
	_particles = GPUParticles3D.new()
	_particles.amount = 220
	_particles.lifetime = 3.2
	_particles.preprocess = 3.0
	_particles.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	_particles.local_coords = false

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = BASE_RADIUS
	pm.emission_ring_inner_radius = 0.0
	pm.emission_ring_height = 0.5
	pm.emission_ring_axis = Vector3.UP
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = HEIGHT * 0.25
	pm.initial_velocity_max = HEIGHT * 0.4
	# a tangential swirl so the column rotates (the "devil")
	pm.tangential_accel_min = 10.0
	pm.tangential_accel_max = 16.0
	pm.radial_accel_min = 1.0
	pm.radial_accel_max = 3.0
	pm.gravity = Vector3(0, 4.0, 0)        # slight upward carry, dust lofts
	pm.scale_min = 2.0
	pm.scale_max = 5.0
	# fade: grow then thin out with height (handled by scale curve + alpha in the material)
	pm.color = Color(0.72, 0.56, 0.40, 0.5)  # butterscotch dust, semi-transparent
	_particles.process_material = pm

	# soft additive-ish dust billboard
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.74, 0.58, 0.42, 0.42)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(4, 4)
	_particles.draw_pass_1 = quad
	_particles.material_override = mat

	add_child(_particles)
	_respawn()

func _respawn() -> void:
	_age = 0.0
	# spawn at a random point on the plain, away from dead centre
	var a := _rng.randf_range(0.0, TAU)
	var r := _rng.randf_range(_world * 0.1, _world * 0.42)
	var x := cos(a) * r
	var z := sin(a) * r
	var y := _ground(x, z)
	global_position = Vector3(x, y, z)
	# drift in a random wander direction, biased by a prevailing wind
	var wind := Vector3(0.82, 0, 0.57).normalized()
	var jitter := Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)) * 0.5
	_vel = (wind + jitter).normalized() * DRIFT_SPEED
	_particles.emitting = true

func _process(delta: float) -> void:
	_age += delta
	# drift across the ground, staying on the relief
	var p := global_position + _vel * delta
	# bounce off the world edge so it stays in play
	var half := _world * 0.5 - 10.0
	if absf(p.x) > half:
		_vel.x = -_vel.x
	if absf(p.z) > half:
		_vel.z = -_vel.z
	p.x = clampf(p.x, -half, half)
	p.z = clampf(p.z, -half, half)
	p.y = _ground(p.x, p.z)
	global_position = p
	# fade the whole thing in at birth and out near death, then respawn elsewhere
	var fade := smoothstep(0.0, 4.0, _age) * (1.0 - smoothstep(LIFE - 6.0, LIFE, _age))
	if _particles.material_override:
		var mo := _particles.material_override as StandardMaterial3D
		mo.albedo_color.a = 0.42 * fade
	if _age >= LIFE:
		_respawn()

func _ground(x: float, z: float) -> float:
	if _env and _env.has_method("ground_height"):
		return _env.ground_height(x, z)
	return 0.0
