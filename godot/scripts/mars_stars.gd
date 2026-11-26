extends MeshInstance3D
class_name MarsStars
## A real night starfield for the Mars sky. Mars' atmosphere is thin, so its night sky is
## brilliant — far more stars than Earth's. This is the in-game sibling of the web cinematic's
## "universe engine": ~thousands of stars with real stellar colours (red→yellow→blue-white by
## temperature) and a power-law brightness spread, plus a faint Milky Way band, on a huge
## inverted sphere that sits behind everything. mars_sun.gd fades it in as the sun sets.
##
## Usage:  var stars := MarsStars.make(); add to the scene; each frame call stars.set_night(f)
##         where f = 0 (day, invisible) .. 1 (full night).

const RADIUS := 4000.0
var _mat: ShaderMaterial

static func make(seed_val: int = 7) -> MarsStars:
	var s := MarsStars.new()
	s.name = "MarsStars"
	s._build(seed_val)
	return s

func _build(seed_val: int) -> void:
	# a big sphere, rendered from the INSIDE (flip faces), unshaded, behind geometry
	var sph := SphereMesh.new()
	sph.radius = RADIUS
	sph.height = RADIUS * 2.0
	sph.radial_segments = 64
	sph.rings = 32
	sph.flip_faces = true
	mesh = sph
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# render behind everything, no depth test so it never clips the world
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;
uniform float night : hint_range(0.0, 1.0) = 0.0;   // 0 day (hidden) .. 1 full night
uniform vec3 galaxy = vec3(0.35, 0.75, 0.55);       // galactic-plane normal
varying vec3 v_dir;
void vertex() { v_dir = normalize(VERTEX); }
float h(vec3 p){ return fract(sin(dot(p, vec3(12.9,78.2,37.1))) * 43758.5); }
float n(vec3 p){ vec3 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(mix(h(i),h(i+vec3(1,0,0)),f.x),mix(h(i+vec3(0,1,0)),h(i+vec3(1,1,0)),f.x),f.y),
			   mix(mix(h(i+vec3(0,0,1)),h(i+vec3(1,0,1)),f.x),mix(h(i+vec3(0,1,1)),h(i+vec3(1,1,1)),f.x),f.y),f.z); }
float fbm(vec3 p){ float v=0.0,a=0.5; for(int i=0;i<5;i++){ v+=a*n(p); p*=2.1; a*=0.5; } return v; }
// stellar colour by temperature t: 0 cool/red .. 1 hot/blue-white
vec3 star_color(float t){
	if (t < 0.5){ float k=t/0.5; return vec3(1.0, 0.5+0.45*k, 0.25+0.35*k); }
	float k=(t-0.5)/0.5; return vec3(1.0-0.25*k, 0.95-0.05*k, 0.75+0.25*k);
}
void fragment() {
	vec3 d = normalize(v_dir);
	// --- Milky Way band: warm mottled glow near the galactic plane, with dark dust lanes ---
	float band = abs(dot(d, normalize(galaxy)));
	float milky = smoothstep(0.42, 0.0, band);
	float clouds = fbm(d*6.0)*0.6 + fbm(d*16.0)*0.4;
	float dust = smoothstep(0.45, 0.72, fbm(d*9.0 + 3.0));
	vec3 mw = mix(vec3(0.04,0.04,0.07), vec3(0.22,0.19,0.17), clouds) * milky * (1.0 - dust*0.8);
	// --- stars: hash a cell grid; a few cells hold bright stars, sized by magnitude ---
	vec3 col = mw * 0.5;
	// three octaves of star cells for a range of densities
	for (int oct = 0; oct < 3; oct++) {
		float scale = 180.0 + float(oct)*320.0;
		vec3 g = d * scale;
		vec3 cell = floor(g);
		vec3 f = fract(g);
		float rnd = h(cell + float(oct)*19.0);
		// density: more star-cells near the galactic plane
		float thresh = mix(0.986, 0.955, milky);
		if (rnd > thresh) {
			float star_rnd = h(cell + 7.3 + float(oct)*4.0);
			vec2 c = f.xy - 0.5 - (vec2(h(cell+1.0), h(cell+2.0)) - 0.5)*0.6;
			float r = length(c) * 2.0;
			float mag = pow(h(cell + 3.1), 3.0);              // few bright, many faint
			float size = 0.5 + mag*1.5;
			float point = smoothstep(size*0.1, 0.0, r) * (0.4 + mag*0.9);
			col += star_color(star_rnd) * point;
		}
	}
	ALBEDO = vec3(0.0);
	EMISSION = col * night;        // the whole field fades out in daylight
	ALPHA = clamp(night, 0.0, 1.0);
}
"""
	mat.shader = sh
	mat.render_priority = -10      // draw first, behind everything
	material_override = mat
	_mat = mat

func set_night(f: float) -> void:
	if _mat:
		_mat.set_shader_parameter("night", clampf(f, 0.0, 1.0))
