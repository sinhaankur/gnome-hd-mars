extends Node3D
class_name EnvironmentEngine
## ENVIRONMENT ENGINE — owns the Mars world: terrain (real MOLA mesh + collision),
## the day/night sun cycle, sky/fog/ambient, ground scatter, and the installation.
##
## It is PASSIVE and AUTHORITATIVE: it answers questions and emits events, but it
## does not know what a HAWC or an enemy is. Other engines depend on THIS one; it
## depends on nothing above it.
##
## Public interface:
##   ground_height(x, z) -> float      # surface Y, or NAN if off-map
##   place_on_ground(node, lift)       # snap a node onto the surface
##   slope_at(x, z) -> float           # 0=flat .. 1=vertical, from terrain normal
##   is_walkable(x, z) -> bool         # slope gentle enough for a walking mech
##   random_edge_spawn() -> Vector3    # a walkable point near the map edge (enemy spawns)
##   time_of_day() -> float            # 0..1 from the sun cycle
##   installation : Node3D             # the base to defend (may carry health)
##   signal day_phase_changed(phase)   # "dawn"/"day"/"dusk"/"night"
##   signal ready_built                # emitted once terrain physics is live

signal day_phase_changed(phase: String)
signal ready_built

@export var world_size: float = 400.0
@export var height_scale: float = 22.0
@export var installation_pos: Vector3 = Vector3(0, 0, -180)
@export var installation_pad_radius: float = 45.0
@export var max_walkable_slope: float = 0.55   # ~33° — steeper than this is "cliff"
@export var day_start: float = 0.32            # time-of-day the level begins (0..1)
@export var region: String = ""                # which MOLA region heightmap to use

# sculpted rocks reused from the user's star-cleaver-assets repo (repo-first rule)
const ASTEROID_STONY_PATH := "res://assets/imported/asteroid-stony.glb"
const ASTEROID_CARBON_PATH := "res://assets/imported/asteroid-carbon.glb"
@export var palette: Dictionary = {}           # territory terrain colors (low/mid/high/slope)

var terrain: StaticBody3D
var sun: MarsSun
var installation: Node3D

var _space: PhysicsDirectSpaceState3D
var _phase := ""

func _ready() -> void:
	# --- terrain ---
	terrain = MarsTerrain.make(world_size, height_scale, installation_pos, installation_pad_radius, region)
	add_child(terrain)
	# territory theme: override the terrain shader's Mars palette (ice/grass/volcanic —
	# Ruhelen's four environmental themes; see Campaign LEVELS)
	if not palette.is_empty():
		for mi in Atoms.all_mesh_instances(terrain):
			var m := mi.material_override as ShaderMaterial
			if m:
				for k in ["low", "mid", "high", "slope"]:
					if palette.has(k):
						var c: Color = palette[k]
						m.set_shader_parameter(k + "_col", Vector3(c.r, c.g, c.b))
	_build_safety_floor()   # solid ground below everything so nothing falls into the void
	# --- sky + sun day-cycle ---
	_build_sky_and_sun()
	# REAL Mars clouds: thin water-ice cirrus, high and faint (rovers photograph these).
	# Never Earth-style cumulus — the old scaled Kenney clouds read as white slabs.
	_build_clouds()
	_build_wind_dust()
	# --- installation to defend ---
	installation = _build_installation(installation_pos)
	add_child(installation)
	# terrain collision needs a couple physics frames before raycasts/scatter work
	_after_physics_ready()

func _after_physics_ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_space = get_world_3d().direct_space_state
	place_on_ground(installation, 0.0)
	_scatter_rocks()
	_scatter_detail()      # pebbles, landmark formations, half-buried wreckage
	_build_outposts()      # small forward bases dotting the territory
	_build_horizon()       # distant mountain/mesa silhouettes ringing the map
	ready_built.emit()

func _process(delta: float) -> void:
	# drift the clouds slowly across the sky
	if _clouds:
		for c in _clouds.get_children():
			c.position.x += delta * 2.0
			if c.position.x > 400.0:
				c.position.x = -400.0
	# keep the blowing dust centered on the camera so it's always around the player
	if _wind_dust:
		var cam := get_viewport().get_camera_3d()
		if cam:
			_wind_dust.global_position = Vector3(cam.global_position.x, 15.0, cam.global_position.z)

	# --- installation life: rotating radar, pulsing guide light, blinking hazards ---
	_anim_time += delta
	if _radar_mast:
		_radar_mast.rotation.y += delta * 0.8         # slow radar sweep
	if _base_light:
		_base_light.light_energy = 1.1 + sin(_anim_time * 1.2) * 0.15  # barely-there breathing
	for i in range(_blink_lights.size()):
		var bl: OmniLight3D = _blink_lights[i]
		if is_instance_valid(bl):
			# staggered blink
			bl.visible = fmod(_anim_time + i * 0.4, 1.2) < 0.15

	if sun == null:
		return
	var t := sun.time_of_day()
	var phase := _phase_for(t)
	if phase != _phase:
		_phase = phase
		day_phase_changed.emit(phase)

func _phase_for(t: float) -> String:
	if t < 0.15 or t > 0.85: return "night"
	if t < 0.30: return "dawn"
	if t > 0.70: return "dusk"
	return "day"

# ---------------------------------------------------------------- QUERIES
func ground_height(x: float, z: float) -> float:
	# authoritative surface Y at (x,z). Returns NAN if the ray misses (off-map).
	if _space == null:
		_space = get_world_3d().direct_space_state
	return Atoms.ground_height(_space, x, z)   # shared raycast atom

func place_on_ground(node: Node3D, lift: float = 0.0) -> void:
	if node == null or not is_instance_valid(node):
		return
	if _space == null:
		_space = get_world_3d().direct_space_state
	# exclude the node's own collider or the ray lands on its head, not the ground
	var excl: Array = [node.get_rid()] if node is CollisionObject3D else []
	var y := Atoms.ground_height(_space, node.global_position.x, node.global_position.z,
								 300.0, -300.0, excl)
	if not is_nan(y):
		node.global_position.y = y + lift

func slope_at(x: float, z: float) -> float:
	# 0 = flat ground, 1 = vertical. Uses the terrain normal at the hit point.
	if _space == null:
		_space = get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 300, z), Vector3(x, -300, z))
	var hit := _space.intersect_ray(q)
	if hit.is_empty():
		return 1.0
	var n: Vector3 = hit.normal
	return 1.0 - clampf(n.y, 0.0, 1.0)

func is_walkable(x: float, z: float) -> bool:
	return slope_at(x, z) <= max_walkable_slope

func random_edge_spawn(rng: RandomNumberGenerator = null) -> Vector3:
	# a walkable point on the COMBAT PERIMETER — a fixed-radius ring around the
	# installation, independent of world size, so bigger maps don't slow the assault
	if rng == null:
		rng = RandomNumberGenerator.new()
	var radius := minf(world_size * 0.5 - 20.0, 240.0)
	for _try in range(24):
		var ang := rng.randf() * TAU
		var x := installation_pos.x + cos(ang) * radius
		var z := installation_pos.z + sin(ang) * radius
		if is_walkable(x, z):
			var y := ground_height(x, z)
			if not is_nan(y):
				return Vector3(x, y + 2.0, z)
	# fallback: due north of the base on the ring
	var fx := installation_pos.x
	var fz := installation_pos.z + radius
	return Vector3(fx, maxf(ground_height(fx, fz), 5.0) + 2.0, fz)

func time_of_day() -> float:
	return sun.time_of_day() if sun else 0.0

# ---------------------------------------------------------------- WORLD BUILD
func _build_sky_and_sun() -> void:
	var s := MarsSun.new()
	s.name = "MarsSun"
	s.shadow_enabled = true
	# NOTE: added to tree after env is set, so its _ready sees the sky.

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	# REAL Mars daytime sky, calibrated to the Perseverance Mastcam-Z panoramas in
	# reference/real_mars/ — butterscotch-grey zenith, brighter peach-tan horizon.
	# Mars' sky is never blue: the dust scatters red light, the reverse of Earth.
	mat.sky_top_color = Color(0.55, 0.47, 0.38)      # butterscotch-grey zenith
	mat.sky_horizon_color = Color(0.78, 0.68, 0.55)  # pale dusty-peach horizon band
	mat.ground_horizon_color = Color(0.66, 0.52, 0.40)
	mat.ground_bottom_color = Color(0.48, 0.36, 0.27)
	# in the reference photos soil is nearly as bright as the sky (0.88:1)
	mat.sky_energy_multiplier = 0.95
	mat.sun_angle_max = 10.0
	sky.sky_material = mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.ambient_light_color = Color(0.70, 0.62, 0.55)
	env.fog_enabled = true
	# EXPONENTIAL, not DEPTH: in depth mode fog_density acts as a max OPACITY, so a
	# density-style value (0.004) made the fog invisible — no aerial perspective at all,
	# dark ground running to a hard horizon line. Exponential restores the tan dust wash.
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.74, 0.66, 0.56)
	env.fog_density = 0.002                           # dusty air: strong aerial perspective —
	env.fog_sky_affect = 0.15                         # distant relief fades to tan like the photos
	env.tonemap_mode = Environment.TONE_MAPPER_ACES   # nicer contrast than filmic here
	env.tonemap_white = 2.4                           # headroom for the bright sun
	env.tonemap_exposure = 1.0
	# detail render pass — depth/glow/reflections so every surface reads crisply
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 0.7                          # gentle: dusty skylight softens crevices
	env.ssil_enabled = true
	env.ssil_intensity = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.30                         # subtle halo only — heavy glow bloomed
	env.glow_bloom = 0.05                             # every bright surface into white slabs
	# threshold must sit ABOVE sunlit-surface radiance (sun energy ~3): at 1.0 every pale
	# rock/crater rim bloomed into a white blob — only true emitters should glow
	env.glow_hdr_threshold = 1.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.ssr_enabled = true
	env.ssr_max_steps = 32
	we.environment = env
	add_child(we)

	s.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	s.directional_shadow_max_distance = 220.0
	# bias tuning: too low dapples the displaced terrain with acne speckle; too much
	# normal bias (3.0) offset receivers ~3 m along their normals and ERASED all cast
	# shadows — dropship, mech, rocks all floated shadowless
	s.shadow_bias = 0.05
	s.shadow_normal_bias = 1.2
	s.env = env
	s.day_length_sec = 120.0
	s.start_time = day_start
	# apply player settings if the Settings autoload is present
	var cfg := get_node_or_null("/root/Settings")
	if cfg:
		s.day_length_sec = cfg.day_length_sec
		if not cfg.high_detail:
			env.ssao_enabled = false
			env.ssil_enabled = false
			env.ssr_enabled = false
			env.glow_enabled = false
	add_child(s)
	sun = s

	# soft warm FILL light from the opposite side (no shadows) so the mech's shadow side
	# and terrain aren't crushed to black — fixes the murky, underlit look.
	# Added AFTER the sun: light order affects which directional light gets shadow slots.
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-25, -140, 0)
	fill.light_color = Color(0.86, 0.76, 0.64)  # warm dust-bounce fill (Mars sky is tan, not blue)
	fill.light_energy = 0.25
	fill.shadow_enabled = false
	add_child(fill)

func _build_wind_dust() -> void:
	# Blowing dust drifting low across the surface — a big GPU particle box that follows
	# the camera so dust is always around the player. Gives the thin Mars air motion.
	var dust := GPUParticles3D.new()
	dust.name = "WindDust"
	dust.amount = 220
	dust.lifetime = 6.0
	dust.preprocess = 3.0
	dust.visibility_aabb = AABB(Vector3(-200, -10, -200), Vector3(400, 60, 400))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(160, 20, 160)
	pm.direction = Vector3(1, 0.05, 0.3)
	pm.spread = 20.0
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 12.0
	pm.gravity = Vector3(2.0, 0.0, 0.6)   # wind push
	# FINE haze, not floating chunks: real blowing dust reads as soft specks
	pm.scale_min = 0.12
	pm.scale_max = 0.4
	pm.color = Color(0.75, 0.6, 0.5, 0.13)
	dust.process_material = pm
	var qm := QuadMesh.new(); qm.size = Vector2(0.5, 0.5)
	dust.draw_pass_1 = qm
	dust.material_override = Atoms.dust_material(Color(0.78, 0.62, 0.5, 0.16))
	dust.position = Vector3(0, 15, 0)
	add_child(dust)
	_wind_dust = dust
	# a couple of distant dust devils (rotating dust columns) on the plains
	_build_dust_devils()

var _wind_dust: GPUParticles3D

func _build_dust_devils() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	_dust_devils = []
	for i in range(3):
		var devil := GPUParticles3D.new()
		devil.amount = 60
		devil.lifetime = 3.0
		devil.preprocess = 2.0
		devil.visibility_aabb = AABB(Vector3(-30, 0, -30), Vector3(60, 80, 60))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		pm.emission_ring_radius = 3.0
		pm.emission_ring_inner_radius = 1.0
		pm.emission_ring_height = 1.0
		pm.emission_ring_axis = Vector3(0, 1, 0)
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 10.0
		pm.initial_velocity_min = 8.0
		pm.initial_velocity_max = 14.0
		pm.gravity = Vector3(0, -1.0, 0)
		pm.tangential_accel_min = 12.0   # swirl
		pm.tangential_accel_max = 20.0
		pm.scale_min = 0.6
		pm.scale_max = 1.6
		pm.color = Color(0.72, 0.55, 0.44, 0.35)
		devil.process_material = pm
		var qm := QuadMesh.new(); qm.size = Vector2(2.0, 2.0)
		devil.draw_pass_1 = qm
		devil.material_override = Atoms.dust_material(Color(0.72, 0.55, 0.44, 0.3))
		# place far out on the plains
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(120, 170)
		var x := cos(ang) * dist
		var z := sin(ang) * dist
		devil.position = Vector3(x, 8, z)
		add_child(devil)
		_dust_devils.append(devil)

var _dust_devils: Array = []

func _build_safety_floor() -> void:
	# A large solid collision plane just below the lowest terrain, so the mech can
	# never fall through the world into the void — worst case it lands on this.
	var floor_body := StaticBody3D.new()
	floor_body.name = "SafetyFloor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 1
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(world_size * 2.0, 4.0, world_size * 2.0)
	col.shape = box
	floor_body.add_child(col)
	# INVISIBLE — collision only. A visible giant plate blocks/darkens the whole view.
	floor_body.position.y = -8.0    # well under the terrain (terrain bottom is y=0)
	add_child(floor_body)

func _build_clouds() -> void:
	# Martian cirrus: huge horizontal quads high overhead with a procedural wisp shader —
	# faint, streaky water-ice clouds like the ones Curiosity/Perseverance photograph.
	# Unshaded + edge-faded so no quad outline ever shows; they drift via _process.
	var rng := RandomNumberGenerator.new()
	rng.seed = 8823
	var cloud_root := Node3D.new()
	cloud_root.name = "CirrusClouds"
	add_child(cloud_root)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float alpha_mul = 0.2;
uniform vec3 tint = vec3(0.92, 0.88, 0.82);   // pale ice, warmed by the dusty sky
float hash(vec2 p){ return fract(sin(dot(p, vec2(41.3,289.1)))*43758.5); }
float noise(vec2 p){ vec2 i=floor(p),f=fract(p); float a=hash(i),b=hash(i+vec2(1,0)),c=hash(i+vec2(0,1)),d=hash(i+vec2(1,1)); vec2 u=f*f*(3.0-2.0*f); return mix(mix(a,b,u.x),mix(c,d,u.x),u.y); }
float fbm(vec2 p){ float v=0.0, a=0.5; for(int i=0;i<5;i++){ v+=a*noise(p); p*=2.13; a*=0.5; } return v; }
void fragment(){
	// streaks: noise squashed hard along one axis reads as wind-sheared cirrus
	float streak = fbm(vec2(UV.x*6.0 + TIME*0.008, UV.y*22.0));
	float body   = fbm(UV*3.0);
	float a = smoothstep(0.45, 0.8, streak*0.6 + body*0.5);
	// fade to nothing at the quad edges so no rectangle outline shows
	float edge = smoothstep(0.0,0.3,UV.x)*smoothstep(1.0,0.7,UV.x)
	           * smoothstep(0.0,0.3,UV.y)*smoothstep(1.0,0.7,UV.y);
	ALBEDO = tint;
	ALPHA = a * edge * alpha_mul;
}
"""
	for i in range(5):
		var q := MeshInstance3D.new()
		var pm := PlaneMesh.new()   # faces +Y: a horizontal sheet overhead
		pm.size = Vector2(rng.randf_range(260, 480), rng.randf_range(90, 180))
		q.mesh = pm
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("alpha_mul", rng.randf_range(0.13, 0.24))
		q.material_override = m
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.position = Vector3(rng.randf_range(-350, 350),
							 rng.randf_range(190, 260),
							 rng.randf_range(-350, 350))
		q.rotation.y = rng.randf() * TAU
		cloud_root.add_child(q)
	_clouds = cloud_root

var _clouds: Node3D

# Procedural base built in-engine (scripts/installation.gd). The old installation.glb
# was a bare cream dome + a lollipop dish that read as a placeholder; the procedural
# compound (pad, dome, habs, tanks, comms mast, blast wall) holds up to the photo bar.
# preload BY PATH so a bare -s run resolves it before the class-cache rescan.
const INSTALLATION_BUILD := preload("res://scripts/installation.gd")

func _build_installation(pos: Vector3) -> Node3D:
	# the real Mars base (command dome, comms tower, habitats, tanks, landing pad, wall)
	var base := Node3D.new()
	base.name = "Installation"
	var compound: Node = INSTALLATION_BUILD.new()
	compound.set("pad_radius", installation_pad_radius)
	base.add_child(compound)
	# a modest warm work-light over the pad — real bases glow amber, not sci-fi blue
	var light := OmniLight3D.new()
	light.name = "GuideLight"
	light.light_color = Color(1.0, 0.78, 0.5)
	light.light_energy = 1.1
	light.omni_range = 32.0
	light.position.y = 12.0
	base.add_child(light)
	_base_light = light

	# --- rotating radar dish, mounted atop the compound's comms mast (x=10,z=6, ~20 m) ---
	var mast := Node3D.new()
	mast.name = "RadarMast"
	mast.position = Vector3(10, 20.0, 6)
	var dish := MeshInstance3D.new()
	var dm := CylinderMesh.new(); dm.top_radius = 2.4; dm.bottom_radius = 0.3; dm.height = 1.0
	dish.mesh = dm
	dish.rotation_degrees = Vector3(60, 0, 0)
	var dishmat := StandardMaterial3D.new()
	# dusty dish, not bright white — matches the compound palette
	dishmat.albedo_color = Color(0.60, 0.59, 0.56); dishmat.metallic = 0.55; dishmat.roughness = 0.5
	dish.material_override = dishmat
	mast.add_child(dish)
	base.add_child(mast)
	_radar_mast = mast

	# --- blinking hazard lights: one on the dome apex, one partway up the mast ---
	var blink_pos := [Vector3(0, 5.0, 0), Vector3(10, 14.0, 6)]
	for p in blink_pos:
		var blink := OmniLight3D.new()
		blink.light_color = Color(1.0, 0.2, 0.15)
		blink.light_energy = 1.0   # aircraft-light subtle, not carnival
		blink.omni_range = 6.0
		blink.position = p
		base.add_child(blink)
		_blink_lights.append(blink)

	base.position = pos
	return base

var _base_light: OmniLight3D
var _radar_mast: Node3D
var _blink_lights: Array = []
var _anim_time := 0.0

func _build_outposts() -> void:
	# Two small forward outposts per territory — hab dome, supply containers, comms mast
	# with a blinking hazard light. Landmarks for navigation now; capture points later.
	var rng := RandomNumberGenerator.new()
	rng.seed = 6021
	var dome_mat := StandardMaterial3D.new()
	dome_mat.albedo_color = Color(0.78, 0.76, 0.72); dome_mat.roughness = 0.4; dome_mat.metallic = 0.2
	var box_mat := StandardMaterial3D.new()
	box_mat.albedo_color = Color(0.50, 0.45, 0.40); box_mat.roughness = 0.8; box_mat.metallic = 0.3
	var half := world_size * 0.5 - 40.0
	var placed := 0
	for _try in range(60):
		if placed >= 2:
			break
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		# keep clear of the main base, the player start, and each other
		if Vector2(x, z).distance_to(Vector2(installation_pos.x, installation_pos.z)) < 110.0:
			continue
		if Vector2(x, z).distance_to(Vector2(0, 160)) < 70.0:
			continue
		if not is_walkable(x, z):
			continue
		var y := ground_height(x, z)
		if is_nan(y):
			continue
		var post := Node3D.new()
		post.name = "Outpost%d" % placed
		add_child(post)
		post.global_position = Vector3(x, y, z)
		# hab dome
		var dome := MeshInstance3D.new()
		var ds := SphereMesh.new(); ds.radius = 5.0; ds.height = 5.0   # squashed half-dome
		dome.mesh = ds; dome.material_override = dome_mat
		dome.position.y = 0.5
		post.add_child(dome)
		# supply containers
		for i in range(3):
			var c := MeshInstance3D.new()
			c.mesh = BoxMesh.new(); c.scale = Vector3(2.4, 1.6, 1.4)
			c.material_override = box_mat
			c.position = Vector3(7.0 + i * 0.6, 0.8, i * 2.6 - 2.6)
			c.rotation.y = i * 0.5
			post.add_child(c)
		# comms mast + blinking hazard light (reuses the staggered blink in _process)
		var mast := MeshInstance3D.new()
		var mc := CylinderMesh.new(); mc.top_radius = 0.08; mc.bottom_radius = 0.16; mc.height = 9.0
		mast.mesh = mc; mast.material_override = box_mat
		mast.position = Vector3(-5.5, 4.5, 2.0)
		post.add_child(mast)
		var blink := OmniLight3D.new()
		blink.light_color = Color(1.0, 0.25, 0.15)
		blink.light_energy = 1.6
		blink.omni_range = 12.0
		blink.position = Vector3(-5.5, 9.2, 2.0)
		post.add_child(blink)
		_blink_lights.append(blink)
		placed += 1

func _scatter_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 71997
	# rock palette sampled from the Perseverance panoramas: grey-brown basalt dusted
	# with tan regolith — never saturated red, never near-black. The shared rock shader
	# (Atoms.rock_material) adds patchiness, grain, and dust settled on top faces.
	var rock_dark := Atoms.rock_material(Color(0.44, 0.38, 0.32))
	var half := world_size * 0.5 - 15.0

	# --- natural boulders: ALL rounded (no angular debris boxes), Mars-toned, mostly
	# embedded low in the ground so they look weathered and sit like real Mars rocks.
	# MULTIMESH scatter (one draw call per rock-mesh variant, per-instance color tint)
	# lets density approach the rover photos — the ground there is LITTERED with rocks.
	# count scales with map area so density holds as world_size grows.
	var rock_count := int(1600.0 * (world_size * world_size) / (800.0 * 800.0))
	# neutral grey multipliers, all <= 1: in the rover photos rocks read DARKER than
	# the dusty soil — pale/HDR tints turned the plain into white confetti
	var tints := [Color(0.62, 0.60, 0.58), Color(0.80, 0.77, 0.74), Color(1.0, 0.96, 0.92)]
	var variants := 8
	var buckets: Array = []            # per rock-mesh variant: Array[{xform, color}]
	for v in range(variants):
		buckets.append([])
	for i in range(rock_count):
		var x: float = rng.randf_range(-half, half)
		var z: float = rng.randf_range(-half, half)
		if Vector2(x, z).distance_to(Vector2(0, 160)) < 22.0:
			continue
		if Vector2(x, z).distance_to(Vector2(installation_pos.x, installation_pos.z)) < 40.0:
			continue
		var y := ground_height(x, z)
		if is_nan(y):
			continue
		var sc := rng.randf_range(0.5, 2.2)
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.15, 0.15), rng.randf() * TAU, rng.randf_range(-0.15, 0.15)))
		# squashed, irregular boulders
		b = b.scaled(Vector3(sc * rng.randf_range(0.9, 1.4),
							 sc * rng.randf_range(0.4, 0.8),
							 sc * rng.randf_range(0.9, 1.4)))
		# embed so the bottom sinks into the ground (weathered look), not perched on top
		var xf := Transform3D(b, Vector3(x, y - sc * 0.25, z))
		var tint: Color = tints[rng.randi() % tints.size()]
		tint = tint * rng.randf_range(0.85, 1.1)
		buckets[rng.randi() % variants].append({"xform": xf, "color": tint})
	var boulder_mat := Atoms.rock_material(Color(0.46, 0.41, 0.36))   # grey basalt; tint via instance COLOR
	for v in range(variants):
		var entries: Array = buckets[v]
		if entries.is_empty():
			continue
		var bmm := MultiMesh.new()
		bmm.transform_format = MultiMesh.TRANSFORM_3D
		bmm.use_colors = true
		var bmesh := Atoms.rock_mesh(rng)
		bmesh.surface_set_material(0, boulder_mat)
		bmm.mesh = bmesh
		bmm.instance_count = entries.size()
		for i in range(entries.size()):
			bmm.set_instance_transform(i, entries[i]["xform"])
			bmm.set_instance_color(i, entries[i]["color"])
		var bmi := MultiMeshInstance3D.new()
		bmi.name = "Boulders%d" % v
		bmi.multimesh = bmm
		add_child(bmi)

	# --- a few impact craters (rings of raised rim) as landmarks ---
	for c in range(8):
		var cx := rng.randf_range(-half*0.85, half*0.85)
		var cz := rng.randf_range(-half*0.85, half*0.85)
		if Vector2(cx, cz).distance_to(Vector2(installation_pos.x, installation_pos.z)) < 70.0:
			continue
		_build_crater(cx, cz, rng.randf_range(10.0, 20.0), rock_dark, rng)

func _build_crater(cx: float, cz: float, radius: float, mat: Material, rng: RandomNumberGenerator) -> void:
	# a raised rim ring of rocks marking an impact crater
	var segs := int(radius * 1.5)
	for i in range(segs):
		var ang := float(i) / segs * TAU + rng.randf_range(-0.1, 0.1)
		var r := radius + rng.randf_range(-1.5, 1.5)
		var x := cx + cos(ang) * r
		var z := cz + sin(ang) * r
		var y := ground_height(x, z)
		if is_nan(y):
			continue
		var chunk := MeshInstance3D.new()
		chunk.mesh = Atoms.rock_mesh(rng)   # irregular rim boulder
		chunk.material_override = mat
		var s := rng.randf_range(1.2, 2.6)
		chunk.scale = Vector3(s, s * rng.randf_range(0.5, 0.9), s)
		chunk.rotation.y = rng.randf() * TAU
		chunk.position = Vector3(x, y - s * 0.1, z)   # embedded rim boulders
		add_child(chunk)

# ---------------------------------------------------------------- extra surface detail
func _scatter_detail() -> void:
	# Fine surface texture: many small pebbles, a few big landmark mesas, and half-buried
	# wreckage — layered so the ground reads as a real, lived-in place up close and far.
	var rng := RandomNumberGenerator.new()
	rng.seed = 31337
	var half := world_size * 0.5 - 10.0
	var pebble_mat := Atoms.rock_material(Color(0.48, 0.43, 0.39))   # darker than the soil

	# 1) PEBBLES — lots of tiny stones dusting the surface (cheap, big density payoff).
	# ONE MultiMesh node instead of hundreds of MeshInstance3Ds; count scales with the
	# map area so the 800 m world stays as littered as the rover photos. The rover
	# panoramas show ground carpeted with stones every few tens of cm, so the old
	# 1200 (~1 per 530 m² here) read as bare sand — density is ~10x now, still one
	# draw call. Pebbles also run a touch bigger so they register from mech height.
	var peb_mesh := SphereMesh.new()
	peb_mesh.radius = 1.0; peb_mesh.height = 2.0
	peb_mesh.radial_segments = 6; peb_mesh.rings = 3   # tiny on screen: low poly is plenty
	peb_mesh.material = pebble_mat
	var count := int(12000.0 * (world_size * world_size) / (800.0 * 800.0))
	var xforms: Array[Transform3D] = []
	for i in range(count):
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		if Vector2(x, z).distance_to(Vector2(installation_pos.x, installation_pos.z)) < 30.0:
			continue
		var y := ground_height(x, z)
		if is_nan(y):
			continue
		var s := rng.randf_range(0.2, 0.7)
		var b := Basis.from_euler(Vector3(0, rng.randf() * TAU, 0))
		b = b.scaled(Vector3(s, s * rng.randf_range(0.4, 0.7), s))
		xforms.append(Transform3D(b, Vector3(x, y - s * 0.2, z)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = peb_mesh
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
	var pebbles := MultiMeshInstance3D.new()
	pebbles.name = "Pebbles"
	pebbles.multimesh = mm
	pebbles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pebbles)

	# 1b) COBBLES — the fist-to-head-sized angular rocks that DOMINATE the rover
	# panoramas (the bridge between fine pebbles and the big boulders). Irregular
	# rock_mesh, not spheres, so they read as broken stone; these cast shadows (unlike
	# the pebbles) because at this size the little shadows are what sell "littered".
	var cobble_mat := Atoms.rock_material(Color(0.46, 0.41, 0.36))
	var cob_count := int(3500.0 * (world_size * world_size) / (800.0 * 800.0))
	var cob_meshes: Array = [Atoms.rock_mesh(rng), Atoms.rock_mesh(rng), Atoms.rock_mesh(rng)]
	for m in cob_meshes:
		(m as ArrayMesh).surface_set_material(0, cobble_mat)
	var cob_buckets: Array = [[], [], []]
	for i in range(cob_count):
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		if Vector2(x, z).distance_to(Vector2(installation_pos.x, installation_pos.z)) < 30.0:
			continue
		var y := ground_height(x, z)
		if is_nan(y):
			continue
		var s := rng.randf_range(0.5, 1.4)
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2)))
		b = b.scaled(Vector3(s * rng.randf_range(0.8, 1.3), s * rng.randf_range(0.4, 0.7), s * rng.randf_range(0.8, 1.3)))
		cob_buckets[rng.randi() % 3].append(Transform3D(b, Vector3(x, y - s * 0.18, z)))
	for bi in range(3):
		var entries: Array = cob_buckets[bi]
		if entries.is_empty():
			continue
		var cmm := MultiMesh.new()
		cmm.transform_format = MultiMesh.TRANSFORM_3D
		cmm.mesh = cob_meshes[bi]
		cmm.instance_count = entries.size()
		for i in range(entries.size()):
			cmm.set_instance_transform(i, entries[i])
		var cmi := MultiMeshInstance3D.new()
		cmi.name = "Cobbles%d" % bi
		cmi.multimesh = cmm
		add_child(cmi)

	# 2) LANDMARK OUTCROPS — clusters of giant lumpy rocks reading as weathered rocky
	# rises (the smooth CylinderMesh "mesas" read as giant plastic tubs with sun-blown
	# flat caps — the reference photos show broken rocky outcrops, not tidy cones)
	var mesa_mat := Atoms.rock_material(Color(0.52, 0.46, 0.41))
	for i in range(8):
		var x := rng.randf_range(-half * 0.9, half * 0.9)
		var z := rng.randf_range(-half * 0.9, half * 0.9)
		if Vector2(x, z).distance_to(Vector2(0, 160)) < 40.0:
			continue
		if Vector2(x, z).distance_to(Vector2(installation_pos.x, installation_pos.z)) < 70.0:
			continue
		var y := ground_height(x, z)
		if is_nan(y):
			continue
		for k in range(rng.randi_range(3, 5)):
			var rock := MeshInstance3D.new()
			rock.mesh = Atoms.rock_mesh(rng)
			rock.material_override = mesa_mat
			var s := rng.randf_range(5.0, 10.0)
			rock.scale = Vector3(s * rng.randf_range(1.2, 1.9),
								 s * rng.randf_range(0.45, 0.75),
								 s * rng.randf_range(1.2, 1.9))
			rock.rotation = Vector3(rng.randf_range(-0.12, 0.12), rng.randf() * TAU, rng.randf_range(-0.12, 0.12))
			var ox := x + rng.randf_range(-9.0, 9.0)
			var oz := z + rng.randf_range(-9.0, 9.0)
			var oy := ground_height(ox, oz)
			if is_nan(oy):
				continue
			# sunk deep so the cluster reads as bedrock breaking the surface
			rock.position = Vector3(ox, oy - rock.scale.y * 0.35, oz)
			add_child(rock)

	# 2b) HERO BOULDERS — sculpted asteroid meshes from the user's star-cleaver-assets
	# repo (repo-first rule). Real hand-sculpted geometry reads far better than the
	# procedural rock_mesh for the few big landmark stones you walk right up to. Tinted
	# to Mars basalt via a modulate/material override (the source mesh is pale cream).
	var ast_scenes: Array = []
	for p in [ASTEROID_STONY_PATH, ASTEROID_CARBON_PATH]:
		var sc: PackedScene = load(p)
		if sc:
			ast_scenes.append(sc)
	if not ast_scenes.is_empty():
		var mars_rock := Atoms.rock_material(Color(0.46, 0.40, 0.35))
		for i in range(10):
			var x := rng.randf_range(-half * 0.92, half * 0.92)
			var z := rng.randf_range(-half * 0.92, half * 0.92)
			if Vector2(x, z).distance_to(Vector2(0, 160)) < 40.0:
				continue
			if Vector2(x, z).distance_to(Vector2(installation_pos.x, installation_pos.z)) < 70.0:
				continue
			var y := ground_height(x, z)
			if is_nan(y):
				continue
			var boulder := (ast_scenes[rng.randi() % ast_scenes.size()] as PackedScene).instantiate()
			var s := rng.randf_range(2.2, 5.0)   # source asteroid ~2 m -> 4–10 m boulders
			boulder.scale = Vector3.ONE * s
			boulder.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
			# Mars-tone every surface so it doesn't read as a pale space rock
			for mi in Atoms.all_mesh_instances(boulder):
				(mi as MeshInstance3D).material_override = mars_rock
			# sunk a bit so it sits like a weathered surface boulder, not perched
			boulder.position = Vector3(x, y - s * 0.35, z)
			add_child(boulder)

	# 3) HALF-BURIED WRECKAGE — a couple of dead hulks tilted into the regolith (story detail)
	var wreck_mat := StandardMaterial3D.new()
	wreck_mat.albedo_color = Color(0.30, 0.30, 0.32); wreck_mat.metallic = 0.6; wreck_mat.roughness = 0.7
	for i in range(3):
		var x := rng.randf_range(-half * 0.8, half * 0.8)
		var z := rng.randf_range(-half * 0.8, half * 0.8)
		if Vector2(x, z).distance_to(Vector2(installation_pos.x, installation_pos.z)) < 60.0:
			continue
		var y := ground_height(x, z)
		if is_nan(y):
			continue
		var hulk := MeshInstance3D.new()
		hulk.mesh = BoxMesh.new()
		hulk.material_override = wreck_mat
		hulk.scale = Vector3(rng.randf_range(4, 7), rng.randf_range(2, 3), rng.randf_range(6, 10))
		hulk.rotation = Vector3(rng.randf_range(0.2, 0.6), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))
		hulk.position = Vector3(x, y - 1.0, z)   # sunk into the ground
		add_child(hulk)

func _build_horizon() -> void:
	# Distant mountain/mesa silhouettes ringing the map, far beyond the play area, so the
	# horizon has depth. Unshaded dark-warm cones, no collision — pure backdrop.
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var ring := Node3D.new(); ring.name = "Horizon"
	add_child(ring)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# pre-hazed tan: in the photos, relief a few km out is already washed nearly
	# to the sky color by dust — dark silhouettes on the horizon scream "fake"
	hm.albedo_color = Color(0.68, 0.56, 0.44)
	var dist := world_size * 0.75
	for i in range(28):
		var ang := float(i) / 28.0 * TAU + rng.randf_range(-0.05, 0.05)
		var r := dist + rng.randf_range(-40, 40)
		var peak := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		# LOW and WIDE: distant Mars relief is worn-down ridgeline, not alpine peaks —
		# tall cones read as smooth pyramids poking through the haze
		cone.top_radius = rng.randf_range(10.0, 30.0)   # flat-topped mesas, not pyramids
		cone.bottom_radius = rng.randf_range(90, 160)
		cone.height = rng.randf_range(10, 26)
		cone.radial_segments = 8
		peak.mesh = cone
		peak.material_override = hm
		peak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		peak.rotation.y = rng.randf() * TAU
		peak.position = Vector3(cos(ang) * r, cone.height * 0.35 - 6.0, sin(ang) * r)
		ring.add_child(peak)
