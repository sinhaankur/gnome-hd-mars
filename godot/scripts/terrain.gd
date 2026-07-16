extends StaticBody3D
## Procedural desert dune terrain with matching visual mesh + collision.
## Both the rendered ArrayMesh and the HeightMapShape3D are built from the same
## height() function, so the HAWC walks exactly on the visible surface.

@export var size: float = 400.0      # world size (meters)
@export var resolution: int = 128    # grid cells per side
@export var dune_height: float = 6.0

var _noise: FastNoiseLite

func height(x: float, z: float) -> float:
	# big dunes + finer ripples
	var h := _noise.get_noise_2d(x * 0.6, z * 0.6) * dune_height
	h += _noise.get_noise_2d(x * 3.0, z * 3.0) * (dune_height * 0.12)
	return h

func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.01
	_noise.seed = 1997
	_build_visual()
	_build_collision()

func _build_visual() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := size / float(resolution)
	var half := size * 0.5
	for iz in range(resolution):
		for ix in range(resolution):
			var x0 := -half + ix * step
			var z0 := -half + iz * step
			var x1 := x0 + step
			var z1 := z0 + step
			var p00 := Vector3(x0, height(x0, z0), z0)
			var p10 := Vector3(x1, height(x1, z0), z0)
			var p01 := Vector3(x0, height(x0, z1), z1)
			var p11 := Vector3(x1, height(x1, z1), z1)
			_tri(st, p00, p01, p11)
			_tri(st, p00, p11, p10)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _soil_material()
	add_child(mi)

func _soil_material() -> ShaderMaterial:
	# Layered desert soil (DRT dirt + DRY dry sand + rock in low/steep areas), procedural.
	# Replaces the flat single-color look — the ground now varies by height, slope, and noise.
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec3 dirt_color = vec3(0.42, 0.32, 0.20);
uniform vec3 dry_color = vec3(0.72, 0.60, 0.40);
uniform vec3 rock_color = vec3(0.28, 0.24, 0.19);
uniform float grain = 0.06;

float hash(vec2 p){ return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453); }
float noise(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hash(i), b = hash(i+vec2(1,0)), c = hash(i+vec2(0,1)), d = hash(i+vec2(1,1));
	vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

varying vec3 v_world;
varying vec3 v_normal_w;

void vertex(){
	v_world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	v_normal_w = normalize((MODEL_MATRIX * vec4(NORMAL,0.0)).xyz);
}

void fragment(){
	vec2 p = v_world.xz;
	float patch = noise(p * 0.02);
	vec3 col = mix(dirt_color, dry_color, smoothstep(0.35, 0.65, patch));
	float med = noise(p * 0.15);
	col = mix(col, col * 0.8, med * 0.4);
	float slope = 1.0 - clamp(v_normal_w.y, 0.0, 1.0);
	col = mix(col, rock_color, smoothstep(0.25, 0.6, slope));
	col = mix(col, col * 0.75, smoothstep(2.0, -3.0, v_world.y) * 0.5);
	float g = noise(p * 8.0);
	col *= 1.0 - grain + g * grain * 2.0;
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)

func _build_collision() -> void:
	# HeightMapShape3D sampled on a square grid; spacing = size/(map_width-1).
	var n := resolution + 1
	var shape := HeightMapShape3D.new()
	shape.map_width = n
	shape.map_depth = n
	var data := PackedFloat32Array()
	data.resize(n * n)
	var step := size / float(resolution)
	var half := size * 0.5
	for iz in range(n):
		for ix in range(n):
			var x := -half + ix * step
			var z := -half + iz * step
			data[iz * n + ix] = height(x, z)
	shape.map_data = data
	var col := CollisionShape3D.new()
	col.shape = shape
	# HeightMapShape is centered at origin; cell spacing must match step → scale X/Z by step.
	col.scale = Vector3(step, 1.0, step)
	add_child(col)
