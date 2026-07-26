extends RefCounted
class_name MarsTerrain
## Builds a real-Mars terrain mesh from HiRISE DTM elevation data.
## The region heightmaps (assets/mars_<region>.png, 16-bit) are carved from a genuine
## ~1 m/px HiRISE DTM of Candor Chasma, Valles Marineris (DTEEC_001918_1735) — see
## tools/hirise_regions.py. At world_size 400 m the 400-grid gives 1 m cells, so the
## real Mars micro-relief becomes actual displaced geometry (not just shader paint).
## We displace a grid by the heightmap, flatten a pad for the installation, and add
## Mars-regolith shading + collision. (Legacy MOLA maps are in assets/_mola_backup/.)
##
## Usage:  var terrain := MarsTerrain.make(world_size, height_scale, flatten_center, flatten_radius)
##         add_child(terrain)

const HEIGHT_PATH := "res://assets/mars_height.png"
# distinct real-HiRISE regions, one per campaign level feel (see tools/hirise_regions.py)
const REGION_PATHS := {
	"plains":  "res://assets/mars_plains.png",
	"rugged":  "res://assets/mars_rugged.png",
	"canyon":  "res://assets/mars_canyon.png",
	"craters": "res://assets/mars_craters.png",
}

static func make(world_size: float = 400.0, height_scale: float = 60.0,
				 flatten_center := Vector3.ZERO, flatten_radius: float = 0.0,
				 region: String = "") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "MarsTerrain"

	# pick the region's heightmap if named, else the default
	var path: String = REGION_PATHS.get(region, HEIGHT_PATH)
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		var tex := load(path) as Texture2D
		if tex:
			img = tex.get_image()
	if img == null:
		push_error("MarsTerrain: could not load heightmap " + path)
		return body
	var w := img.get_width()
	var h := img.get_height()

	# build a grid mesh sampled from the heightmap. At world_size 400 m a 400-grid gives
	# 1 m cells — matching the ~1 m/px HiRISE source, so the real Mars micro-relief
	# (ripples, benches, gully texture) shows up as actual displaced geometry, not just
	# shader paint. 400x400 quads = 320k tris, fine for a single terrain body.
	var res := 400
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := _mars_material()
	mat.set_shader_parameter("height_span", height_scale)   # color bands match actual relief
	st.set_material(mat)     # bind material on the surface so commit() has one

	var half := world_size * 0.5
	# precompute heights so we can also do normals + flattening
	var heights := PackedFloat32Array()
	heights.resize((res + 1) * (res + 1))
	for j in range(res + 1):
		for i in range(res + 1):
			var u := float(i) / res
			var v := float(j) / res
			var e := _sample_bilinear(img, u, v, w, h)   # smooth 0..1 elevation
			var y := e * height_scale
			# flatten a circular pad for the installation
			if flatten_radius > 0.0:
				var wx := u * world_size - half
				var wz := v * world_size - half
				var d := Vector2(wx - flatten_center.x, wz - flatten_center.z).length()
				if d < flatten_radius:
					var t := smoothstep(flatten_radius * 0.6, flatten_radius, d)
					y = lerp(flatten_center.y, y, t)
			heights[j * (res + 1) + i] = y

	var stride := res + 1
	for j in range(res):
		for i in range(res):
			var x0 := float(i) / res * world_size - half
			var x1 := float(i + 1) / res * world_size - half
			var z0 := float(j) / res * world_size - half
			var z1 := float(j + 1) / res * world_size - half
			var y00 := heights[j * stride + i]
			var y10 := heights[j * stride + i + 1]
			var y01 := heights[(j + 1) * stride + i]
			var y11 := heights[(j + 1) * stride + i + 1]
			var p00 := Vector3(x0, y00, z0)
			var p10 := Vector3(x1, y10, z0)
			var p01 := Vector3(x0, y01, z1)
			var p11 := Vector3(x1, y11, z1)
			# winding order matters: the old (p00,p01,p11) order made these faces
			# BACK faces when seen from above — generate_normals() then pointed the
			# normals DOWN, so the ground ignored direct sunlight and could never
			# show a cast shadow (the root cause of the "dark terrain" saga)
			_tri(st, p00, p11, p01)
			_tri(st, p00, p10, p11)

	st.generate_normals()   # no UVs/tangents needed: the Mars shader is triplanar/world-space
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)

	# collision from the same mesh. Build the concave shape from our own vertex list
	# with backface collision on, so downward raycasts reliably hit the surface
	# (trimesh-from-mesh can miss rays that approach the back of a face).
	var col := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape()
	if shape:
		shape.backface_collision = true
	col.shape = shape
	body.add_child(col)
	body.collision_layer = 1
	body.collision_mask = 1
	return body

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)

static func _sample_bilinear(img: Image, u: float, v: float, w: int, h: int) -> float:
	# bilinearly sample the normalized (red-channel) heightmap so the finer mesh grid
	# reads smooth, accurate elevations between texels instead of blocky nearest-neighbour.
	var fx: float = clamp(u, 0.0, 1.0) * float(w - 1)
	var fy: float = clamp(v, 0.0, 1.0) * float(h - 1)
	var x0 := int(fx); var y0 := int(fy)
	var x1 := mini(x0 + 1, w - 1); var y1 := mini(y0 + 1, h - 1)
	var tx: float = fx - float(x0); var ty: float = fy - float(y0)
	var e00 := img.get_pixel(x0, y0).r; var e10 := img.get_pixel(x1, y0).r
	var e01 := img.get_pixel(x0, y1).r; var e11 := img.get_pixel(x1, y1).r
	return lerp(lerp(e00, e10, tx), lerp(e01, e11, tx), ty)

static func _mars_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;   // solid from all angles (no see-through from below)
// palette sampled from the Perseverance panoramas (reference/real_mars/): caramel and
// butterscotch, low saturation — the old maroon-red read as lava, not Mars regolith
// MEASURED against reference/real_mars/PIA24921.jpg: mid-ground soil there averages
// sRGB(174,147,123) — bright, LOW-saturation caramel. The old palette rendered the
// plain at sRGB(80,61,35): half the brightness, twice the saturation ("dark mud").
// NOTE: the warm sun + tan fog supply most of the orange — the albedo itself must be
// near-grey pale caramel, or the lit result oversaturates far past the photos.
uniform vec3 low_col  = vec3(0.58, 0.50, 0.44);   // valley-floor regolith
uniform vec3 mid_col  = vec3(0.66, 0.57, 0.49);   // butterscotch mid-tones
uniform vec3 high_col = vec3(0.74, 0.66, 0.57);   // pale dust drifts
uniform vec3 slope_col= vec3(0.42, 0.36, 0.31);   // exposed basalt: grey-brown, never black
uniform float height_span = 22.0;                 // matches terrain height_scale
// REAL scanned regolith (Gravel Ground Module Scan, Pers Scans CC-BY) — extracted by
// tools/extract_ground_textures.py. Blended triplanar over the procedural base so the
// ground is grounded in genuine photogrammetry, strongest up close where grit reads.
uniform sampler2D ground_albedo : source_color, hint_default_white, repeat_enable, filter_linear;
uniform sampler2D ground_normal : hint_normal, repeat_enable, filter_linear;
uniform float ground_tile = 0.9;      // texture repeats per metre (bigger = smaller rocks; ~1.1 m repeat)
uniform float ground_blend = 0.7;     // how much the scan replaces the procedural color up close
varying vec3 v_world; varying vec3 v_nrm; varying float v_h;
// triplanar sample of a color texture in world space (no UVs needed on the terrain mesh)
vec3 triplanar(sampler2D tex, vec3 wp, vec3 n, float scale){
	vec3 bw = pow(abs(n), vec3(4.0)); bw /= (bw.x+bw.y+bw.z);
	vec3 x = texture(tex, wp.zy*scale).rgb;
	vec3 y = texture(tex, wp.xz*scale).rgb;
	vec3 z = texture(tex, wp.xy*scale).rgb;
	return x*bw.x + y*bw.y + z*bw.z;
}
void vertex(){
	v_world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL,0.0)).xyz);
	v_h = VERTEX.y;
}
float hash(vec2 p){ return fract(sin(dot(p, vec2(41.3,289.1)))*43758.5); }
float noise(vec2 p){ vec2 i=floor(p),f=fract(p); float a=hash(i),b=hash(i+vec2(1,0)),c=hash(i+vec2(0,1)),d=hash(i+vec2(1,1)); vec2 u=f*f*(3.0-2.0*f); return mix(mix(a,b,u.x),mix(c,d,u.x),u.y); }
float fbm(vec2 p){ float v=0.0, a=0.5; for(int i=0;i<5;i++){ v+=a*noise(p); p*=2.03; a*=0.5; } return v; }
void fragment(){
	vec2 w = v_world.xz;
	float t = clamp(v_h / height_span, 0.0, 1.0);
	vec3 col = mix(low_col, mid_col, smoothstep(0.0,0.5,t));
	col = mix(col, high_col, smoothstep(0.5,1.0,t));

	// large-scale regolith patchiness (lighter dust drifts vs darker soil)
	float patch = fbm(w*0.015);
	col = mix(col, high_col, smoothstep(0.5,0.8,patch)*0.5);
	col = mix(col, low_col, smoothstep(0.5,0.2,patch)*0.3);

	// SAND RIPPLES — directional wave pattern, subtle light/dark banding
	float ripple = sin(w.x*0.5 + fbm(w*0.08)*6.0) * 0.5 + 0.5;
	col *= 0.94 + ripple*0.10;

	// ROCK SPECKLE — scattered dark stones
	float rocks = noise(w*2.5);
	float rockMask = smoothstep(0.72, 0.8, rocks);
	col = mix(col, slope_col*0.8, rockMask*0.45);

	// CRACKS — thin dark fracture lines in dried regolith (kept faint: heavy dark
	// webbing was dragging the whole plain darker than the reference photos)
	float crack = fbm(w*0.9);
	float crackLine = smoothstep(0.02, 0.0, abs(crack-0.5)-0.005);
	col *= 1.0 - crackLine*0.22;

	// fine dust grain
	float grain = noise(w*14.0);
	col *= 0.95 + grain*0.10;

	// CLOSE-UP SOIL — extra detail fades in within ~45 m of the camera so the ground
	// reads as grit + pebble litter up close (the rover photos show dense fine rocks,
	// never a smooth colour wash)
	float dist = length(v_world - CAMERA_POSITION_WORLD);
	float near_d = 1.0 - smoothstep(8.0, 45.0, dist);
	if (near_d > 0.001) {
		float grit = noise(w*38.0);
		float peb  = noise(w*9.0);
		float pebMask = smoothstep(0.66, 0.78, peb);
		// pebbles alternate light caramel and dark basalt bits per cell
		vec3 pebCol = mix(slope_col*0.85, high_col*1.05, hash(floor(w*9.0)));
		col = mix(col, pebCol, pebMask * 0.5 * near_d);
		col *= 1.0 + (grit - 0.5) * 0.16 * near_d;
	}

	// broad iron-oxide staining: subtle warm-vs-grey patchiness across the plain
	float stain = fbm(w*0.05 + vec2(7.0, 3.0));
	col = mix(col, col*vec3(1.06, 0.97, 0.90), smoothstep(0.5, 0.75, stain)*0.45);

	// REAL SCANNED REGOLITH BLEND — sample the photogrammetry ground triplanar and mix it
	// into the procedural color. The scan has some Earthly green (moss); we desaturate it
	// and warm-tint to the Mars caramel palette so only its rocky STRUCTURE/VALUE carries
	// through, not its color. Strongest near the camera (where grit detail matters), fading
	// out with distance so the far plain keeps the clean calibrated palette + no tiling.
	// REAL SCANNED REGOLITH — two scales (coarse rock layout + fine grit) so it neither
	// tiles obviously nor blurs out. The scan carries some Earthly green (moss): we take its
	// LUMINANCE PATTERN (the real rock light/dark) and its de-greened fine chroma, and apply
	// them AS MODULATION over the calibrated Mars palette col — so genuine photographed rock
	// texture shows, but the hue stays Martian. Detail is strongest near the camera.
	vec3 scan  = triplanar(ground_albedo, v_world, v_nrm, ground_tile);
	vec3 scan2 = triplanar(ground_albedo, v_world, v_nrm, ground_tile * 0.23);
	vec3 scan_mix = scan * 0.55 + scan2 * 0.45;
	float scan_lum = dot(scan_mix, vec3(0.299, 0.587, 0.114));
	// de-green: pull the green channel toward the r/b average so moss reads as rock
	float rb = (scan_mix.r + scan_mix.b) * 0.5;
	scan_mix.g = min(scan_mix.g, rb * 1.05);
	// modulate the Mars color by the scan's value (centered on its ~mean 0.45 so it darkens
	// AND lightens), and let the de-greened chroma tint each grain warm/cool a touch
	vec3 scan_ground = col * (0.55 + scan_lum * 1.15);
	scan_ground *= mix(vec3(1.0), scan_mix / max(scan_lum, 0.001), 0.35);
	float dist2 = length(v_world - CAMERA_POSITION_WORLD);
	float scan_near = 1.0 - smoothstep(40.0, 260.0, dist2);
	col = mix(col, scan_ground, ground_blend * scan_near);

	// steep slopes = darker exposed basalt
	float slope = 1.0 - clamp(v_nrm.y, 0.0, 1.0);
	col = mix(col, slope_col, smoothstep(0.35,0.7,slope));

	// perturb normal slightly for a rougher, grittier surface under light
	vec3 n = v_nrm;
	float nx = fbm(w*3.0+vec2(1.0,0.0)) - fbm(w*3.0-vec2(1.0,0.0));
	float nz = fbm(w*3.0+vec2(0.0,1.0)) - fbm(w*3.0-vec2(0.0,1.0));
	n = normalize(n + vec3(nx, 0.0, nz)*(0.35 + near_d*0.45));   // grittier bump up close
	// add the REAL scanned normal map's micro-relief near the camera so lit rocks/gravel
	// catch highlights like true photographed ground (decoded from tangent-space RG)
	vec3 sn = triplanar(ground_normal, v_world, v_nrm, ground_tile) * 2.0 - 1.0;
	n = normalize(n + vec3(sn.x, 0.0, sn.y) * 0.6 * scan_near);
	NORMAL = (VIEW_MATRIX * vec4(n,0.0)).xyz;

	ALBEDO = col;
	ROUGHNESS = mix(0.85, 1.0, 1.0 - rockMask);
	SPECULAR = 0.12;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	# bind the real scanned regolith textures (extracted by tools/extract_ground_textures.py)
	# so the terrain blends genuine photogrammetry over its procedural detail. Guarded: if a
	# texture is missing the shader's hint_default_white keeps the procedural look intact.
	var alb := load("res://assets/mars_ground_albedo.png") as Texture2D
	if alb:
		m.set_shader_parameter("ground_albedo", alb)
	var nrm := load("res://assets/mars_ground_normal.png") as Texture2D
	if nrm:
		m.set_shader_parameter("ground_normal", nrm)
	# explicitly set the scalar uniforms — relying on the shader's in-source defaults left
	# ground_tile reading 0 at runtime (triplanar then sampled pixel 0,0 = flat color).
	m.set_shader_parameter("ground_tile", 0.9)
	m.set_shader_parameter("ground_blend", 0.7)
	return m
