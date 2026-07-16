extends RefCounted
class_name Biome
## Loads an HD biome terrain (built in Blender) and gives it the right Godot surface shader.
## Blender procedural materials don't survive glTF export, so we reapply the look here per biome.
## Usage:  var terrain := Biome.make("desert")   # returns a StaticBody3D with mesh + collision
##         add_child(terrain)

const SCALE := 1.6

# biome -> (glb path, [dirt/base, second, rock/accent] colors, roughness, emissive)
const DATA := {
	# Mars regolith: rust/ochre base, lighter dusty drifts, dark basalt on slopes.
	# Reuses the desert heightmesh (dunes/craters read fine as Martian terrain).
	"mars": {
		"glb": "res://assets/env_desert_hd.glb",
		"c0": Vector3(0.42, 0.20, 0.12), "c1": Vector3(0.66, 0.38, 0.24), "c2": Vector3(0.22, 0.14, 0.11),
		"rough": 0.98, "emissive": false,
	},
	"desert": {
		"glb": "res://assets/env_desert_hd.glb",
		"c0": Vector3(0.42, 0.32, 0.20), "c1": Vector3(0.72, 0.60, 0.40), "c2": Vector3(0.28, 0.24, 0.19),
		"rough": 0.95, "emissive": false,
	},
	"ice": {
		"glb": "res://assets/ice_hd.glb",
		"c0": Vector3(0.62, 0.72, 0.82), "c1": Vector3(0.85, 0.92, 0.98), "c2": Vector3(0.40, 0.52, 0.62),
		"rough": 0.35, "emissive": false,
	},
	"molten": {
		"glb": "res://assets/molten_hd.glb",
		"c0": Vector3(0.18, 0.12, 0.10), "c1": Vector3(0.32, 0.20, 0.15), "c2": Vector3(0.90, 0.35, 0.08),
		"rough": 0.8, "emissive": true,   # c2 = glowing lava in the low channels
	},
	"grass": {
		"glb": "res://assets/grass_hd.glb",
		"c0": Vector3(0.24, 0.34, 0.16), "c1": Vector3(0.36, 0.46, 0.22), "c2": Vector3(0.30, 0.26, 0.18),
		"rough": 0.9, "emissive": false,
	},
}

static func make(kind: String) -> StaticBody3D:
	var d = DATA.get(kind, DATA["desert"])
	var body := StaticBody3D.new()
	body.name = "Biome_" + kind

	var packed: PackedScene = load(d["glb"])
	if packed == null:
		return body
	var model := packed.instantiate()
	model.scale = Vector3.ONE * SCALE
	body.add_child(model)

	var mi := _find_mesh(model)
	if mi:
		mi.material_override = _make_shader(d)
		var col := CollisionShape3D.new()
		col.shape = mi.mesh.create_trimesh_shape()
		col.scale = Vector3.ONE * SCALE
		body.add_child(col)
	return body

static func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for c in node.get_children():
		var r := _find_mesh(c)
		if r:
			return r
	return null

static func _make_shader(d: Dictionary) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec3 c0; uniform vec3 c1; uniform vec3 c2;
uniform float rough = 0.9;
uniform float emissive = 0.0;   // 1.0 = c2 glows in low channels (lava)

float hash(vec2 p){ return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453); }
float noise(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	float a=hash(i), b=hash(i+vec2(1,0)), c=hash(i+vec2(0,1)), dd=hash(i+vec2(1,1));
	vec2 u=f*f*(3.0-2.0*f);
	return mix(mix(a,b,u.x), mix(c,dd,u.x), u.y);
}
varying vec3 v_world; varying vec3 v_nrm;
void vertex(){
	v_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	v_nrm=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);
}
void fragment(){
	vec2 p=v_world.xz;
	float patch=noise(p*0.02);
	vec3 col=mix(c0, c1, smoothstep(0.35,0.65,patch));
	float slope=1.0-clamp(v_nrm.y,0.0,1.0);
	col=mix(col, c2, smoothstep(0.3,0.7,slope));
	// low channels: darker, or glowing if emissive (lava)
	float low=smoothstep(1.0,-4.0,v_world.y);
	if(emissive>0.5){
		EMISSION = c2 * low * 3.0;
		col = mix(col, c2*0.5, low*0.6);
	} else {
		col = mix(col, col*0.7, low*0.4);
	}
	float g=noise(p*8.0);
	col*=0.94+g*0.12;
	ALBEDO=col; ROUGHNESS=rough; SPECULAR=0.15;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("c0", d["c0"])
	mat.set_shader_parameter("c1", d["c1"])
	mat.set_shader_parameter("c2", d["c2"])
	mat.set_shader_parameter("rough", d["rough"])
	mat.set_shader_parameter("emissive", 1.0 if d["emissive"] else 0.0)
	return mat
