extends DirectionalLight3D
class_name MarsSun
## Drives a Mars day cycle. As the sun arcs across the sky, EVERYTHING dependent on
## sun position updates each frame: light direction, light color/energy, shadow length
## & direction (automatic from the light angle), sky top/horizon colors, ambient light,
## and dust-fog color. The terrain and mech are lit by this same light, so their shading
## and shadows change with the sun — no fixed lighting.

@export var day_length_sec: float = 1200.0  # one Mars "sol" = 20 min: light drifts, never races
@export var start_time: float = 0.30         # 0=dawn, 0.25=morning, 0.5=noon, 0.75=eve, 1=dusk
@export var paused: bool = false
@export var env: Environment                 # the WorldEnvironment's Environment (sky/fog/ambient)

var _t: float = 0.0
var _sky: ProceduralSkyMaterial
var _disc: MeshInstance3D          # explicit sun disc (procedural sky disc is unreliable)
const DISC_DIST := 900.0           # far away so it reads as the sky sun

# --- key colors for interpolation across the day ---
const SUN_DAWN  := Color(1.0, 0.55, 0.38)    # low red sun, dust-reddened
const SUN_NOON  := Color(1.0, 0.90, 0.78)    # pale, slightly cool Mars midday
const SUN_DUSK  := Color(1.0, 0.48, 0.34)

# REAL Mars palette, matched to the Perseverance Mastcam-Z panoramas in
# reference/real_mars/: butterscotch sky, tan dust haze. Martian twilight goes
# BLUE-GREY around the sun (the reverse of Earth), so dusk leans cool, not salmon.
const SKY_TOP_DAY   := Color(0.55, 0.47, 0.38)   # butterscotch-grey zenith
const SKY_TOP_NIGHT := Color(0.04, 0.05, 0.11)
const SKY_HZ_DAY    := Color(0.78, 0.68, 0.55)   # pale dusty-peach horizon
const SKY_HZ_DUSK   := Color(0.62, 0.55, 0.52)   # cool grey Martian twilight
const SKY_HZ_NIGHT  := Color(0.10, 0.11, 0.17)

const FOG_DAY   := Color(0.74, 0.63, 0.50)        # tan dust haze
const FOG_DUSK  := Color(0.58, 0.50, 0.46)
const FOG_NIGHT := Color(0.12, 0.13, 0.17)

func _ready() -> void:
	_t = start_time
	shadow_enabled = true
	# make THIS light draw the sun disc in the procedural sky
	sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY
	if env and env.sky and env.sky.sky_material is ProceduralSkyMaterial:
		_sky = env.sky.sky_material
		_sky.sun_angle_max = 12.0
		_sky.sun_curve = 0.3
	_build_disc()
	_apply(_t)

func _build_disc() -> void:
	# A bright emissive sphere far in the sun's direction — a guaranteed-visible sun disc
	# that tracks the day cycle (the procedural sky's own disc renders unreliably).
	_disc = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	# REAL scale: from Mars the sun spans ~0.35° — at DISC_DIST 900 that's ~r=5.5.
	# The old r=60 beach-ball sun was the single tackiest thing in the sky.
	sphere.radius = 6.0
	sphere.height = 12.0
	_disc.mesh = sphere
	var m := StandardMaterial3D.new()
	# UNSHADED shows albedo at full brightness regardless of lighting/tonemap -> reliably bright.
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.97, 0.88)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.97, 0.88)
	m.emission_energy_multiplier = 8.0      # feeds the glow/bloom for a halo
	m.disable_receive_shadows = true
	_disc.material_override = m

	# soft glow halo around the disc — dust scatter, kept tight to the disc
	var halo := MeshInstance3D.new()
	var hs := SphereMesh.new(); hs.radius = 16.0; hs.height = 32.0
	halo.mesh = hs
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color = Color(1.0, 0.85, 0.6, 0.25)
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo.material_override = hm
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.add_child(halo)
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# add to the scene (NOT as a child of the rotating light) so we can place it freely
	call_deferred("_attach_disc")

func _attach_disc() -> void:
	if _disc and _disc.get_parent() == null:
		get_parent().add_child(_disc)

func _process(delta: float) -> void:
	if paused:
		return
	_t = fmod(_t + delta / max(day_length_sec, 1.0), 1.0)
	_apply(_t)

func _apply(t: float) -> void:
	# --- sun ELEVATION: an arc. t=0 dawn (horizon), 0.5 noon (high), 1 dusk (horizon).
	# elevation angle: -8deg (just set) .. 62deg (noon) .. -8deg
	var day: float = clampf(sin(t * PI), 0.0, 1.0)     # 0 at dawn/dusk, 1 at noon
	var elev: float = lerpf(-8.0, 62.0, day)           # degrees above horizon
	# --- sun AZIMUTH: sweeps east->west across the day ---
	var azim: float = lerpf(120.0, 240.0, t)
	rotation_degrees = Vector3(-elev, azim, 0.0)       # -elev: light points down as sun rises

	# place the visible sun disc up in the sky, in the direction the light comes FROM
	# (guard: the disc is attached deferred, so it may not be in the tree on frame 1)
	if _disc and is_instance_valid(_disc) and _disc.is_inside_tree() and is_inside_tree():
		var sun_dir: Vector3 = global_transform.basis.z   # points back toward the sun
		var cam := get_viewport().get_camera_3d()
		var origin: Vector3 = cam.global_position if cam else Vector3.ZERO
		_disc.global_position = origin + sun_dir * DISC_DIST
		_disc.visible = elev > -3.0                        # hide when below horizon (night)

	# --- light COLOR/ENERGY: warm & dim at horizon, pale & bright at noon ---
	var horizon: float = 1.0 - day                      # 1 at dawn/dusk
	var scol: Color
	if t < 0.5:
		scol = SUN_DAWN.lerp(SUN_NOON, day)
	else:
		scol = SUN_NOON.lerp(SUN_DUSK, horizon)
	light_color = scol
	# night: sun below horizon -> kill direct light
	var above: float = clampf((elev + 4.0) / 10.0, 0.0, 1.0)  # fades out as it dips below
	# brighter sun so the mech + terrain read clearly (was 1.25 — too dim/murky)
	light_energy = lerpf(0.0, 3.2, above) * lerpf(0.75, 1.0, day)
	shadow_opacity = clampf(above, 0.0, 0.75)           # softer shadows, fade as sun sets

	# tint the visible sun disc to match (warmer/redder low, pale high)
	if _disc and is_instance_valid(_disc):
		var dm := _disc.material_override as StandardMaterial3D
		if dm:
			var disc_col := scol.lerp(Color(1.0, 0.9, 0.75), day)
			dm.albedo_color = disc_col     # unshaded -> albedo IS the visible color
			dm.emission = disc_col

	if env == null:
		return
	# --- SKY: top darkens at night; horizon flushes salmon at dawn/dusk ---
	if _sky:
		var top: Color = SKY_TOP_DAY.lerp(SKY_TOP_NIGHT, 1.0 - above)
		var hz_day_dusk: Color = SKY_HZ_DAY.lerp(SKY_HZ_DUSK, horizon)
		var hz: Color = hz_day_dusk.lerp(SKY_HZ_NIGHT, 1.0 - above)
		_sky.sky_top_color = top
		_sky.sky_horizon_color = hz

	# --- AMBIENT: bright enough that shadows aren't crushed black; warm sky-fill.
	# Mars' dusty air scatters a LOT of light into shadows (see the reference photos:
	# shadow sides stay readable), so daytime ambient runs high. ---
	env.ambient_light_energy = lerpf(0.25, 1.7, above)
	env.ambient_light_color = Color(0.80, 0.72, 0.66).lerp(Color(0.28, 0.26, 0.34), 1.0 - above)

	# --- FOG (affects terrain + everything at distance): reddens at dusk, dims at night ---
	var fog: Color = FOG_DAY.lerp(FOG_DUSK, horizon).lerp(FOG_NIGHT, 1.0 - above)
	env.fog_light_color = fog

# expose current time-of-day 0..1 for HUD
func time_of_day() -> float:
	return _t
