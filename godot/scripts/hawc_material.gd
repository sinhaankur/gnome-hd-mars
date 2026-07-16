extends RefCounted
class_name HawcMaterial
## Hero-quality procedural PBR material for the Prowler HAWC.
## Renders panel seams, rivets, brushed-metal micro-detail, edge wear and scorch
## per-pixel — sharp at any display resolution ("every pixel matters"), no texture
## files to load and nothing that can be lost to a Blender disconnect.
## Faction palette per design/HAWC_VARIETY_SPEC.md.
##
## Usage:  HawcMaterial.apply(hawk_instance, "union")

const FACTION := {
	"union":  {"base": Vector3(0.34, 0.31, 0.18), "accent": Vector3(0.85, 0.75, 0.20), "glow": Vector3(1.0, 0.50, 0.10)},
	"darken": {"base": Vector3(0.20, 0.22, 0.26), "accent": Vector3(0.55, 0.10, 0.08), "glow": Vector3(1.0, 0.25, 0.15)},
	"merc":   {"base": Vector3(0.16, 0.24, 0.48), "accent": Vector3(0.90, 0.55, 0.10), "glow": Vector3(0.20, 0.80, 1.0)},
	"scorp":  {"base": Vector3(0.16, 0.30, 0.14), "accent": Vector3(0.30, 0.45, 0.10), "glow": Vector3(0.30, 1.0, 0.35)},
}

static func _shader() -> Shader:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_col;
uniform vec3 accent_col;
uniform vec3 glow_col;

// ---- hash / value noise for procedural surface detail ----
float h21(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	float a = h21(i), b = h21(i+vec2(1,0)), c = h21(i+vec2(0,1)), d = h21(i+vec2(1,1));
	vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}
float fbm(vec2 p){
	float v=0.0, a=0.5;
	for(int i=0;i<5;i++){ v+=a*vnoise(p); p*=2.03; a*=0.5; }
	return v;
}

varying vec3 v_obj;      // object-space position -> triplanar coords
varying vec3 v_nrm;

void vertex(){
	v_obj = VERTEX;
	v_nrm = NORMAL;
}

// triplanar sample of a scalar field so detail wraps the whole mech seamlessly
float tri_fbm(vec3 p, vec3 n, float scale){
	vec3 b = abs(normalize(n)); b /= (b.x+b.y+b.z);
	float x = fbm(p.yz*scale);
	float y = fbm(p.zx*scale);
	float z = fbm(p.xy*scale);
	return x*b.x + y*b.y + z*b.z;
}

// hard panel seams: dark grooves on a grid, triplanar
float panels(vec3 p, vec3 n, float cell, out float rivet){
	vec3 b = abs(normalize(n)); b /= (b.x+b.y+b.z);
	// per-plane grid distance to nearest seam
	vec2 gx = fract(p.yz/cell); vec2 gy = fract(p.zx/cell); vec2 gz = fract(p.xy/cell);
	float sx = min(min(gx.x,1.0-gx.x), min(gx.y,1.0-gx.y));
	float sy = min(min(gy.x,1.0-gy.x), min(gy.y,1.0-gy.y));
	float sz = min(min(gz.x,1.0-gz.x), min(gz.y,1.0-gz.y));
	float seam_d = sx*b.x + sy*b.y + sz*b.z;
	float seam = 1.0 - smoothstep(0.0, 0.045, seam_d);   // 1 at the groove
	// rivets: dots near panel corners
	vec2 rc = abs(fract(p.xy/cell)-0.5);
	rivet = 1.0 - smoothstep(0.03, 0.06, length(rc-0.42));
	return seam;
}

void fragment(){
	vec3 p = v_obj;
	vec3 n = v_nrm;

	// base brushed-metal micro variation
	float micro = tri_fbm(p, n, 6.0);
	vec3 col = base_col * (0.85 + 0.30*micro);

	// large paint patches / weathering
	float patch = tri_fbm(p, n, 0.6);
	col = mix(col, base_col*1.25, smoothstep(0.55, 0.85, patch));

	// panel seams + rivets
	float rivet;
	float seam = panels(p, n, 0.55, rivet);
	col = mix(col, base_col*0.35, seam*0.9);              // dark grooves
	col = mix(col, base_col*1.6, clamp(rivet,0.0,1.0)*0.7); // bright rivet highlights

	// edge wear: exposed bright metal where noise is high on convex bits
	float wear = smoothstep(0.62, 0.9, tri_fbm(p, n, 3.0));
	vec3 bare = vec3(0.55, 0.55, 0.58);
	col = mix(col, bare, wear*0.5);

	// scorch / grime in the low, recessed areas
	float grime = smoothstep(0.35, 0.0, tri_fbm(p, n, 1.3));
	col *= (1.0 - grime*0.45);

	// faction accent stripe band (a painted marking ring around the hull)
	float band = smoothstep(0.02, 0.0, abs(fract(p.z*0.35)-0.5)-0.03);
	col = mix(col, accent_col, band*0.5*(1.0-seam));

	// metallic/roughness driven by wear (bare metal = shinier)
	float metal = mix(0.55, 0.95, wear);
	float rough = mix(0.62, 0.30, wear);
	rough = mix(rough, 0.95, seam*0.6);                   // grooves are rough
	rough = mix(rough, 1.0, grime*0.5);

	ALBEDO = col;
	METALLIC = metal;
	ROUGHNESS = clamp(rough, 0.08, 1.0);
	SPECULAR = 0.5;
}
"""
	return sh

static var _cached_shader: Shader = null

static func apply(model: Node, faction: String) -> void:
	if _cached_shader == null:
		_cached_shader = _shader()
	var f: Dictionary = FACTION.get(faction, FACTION["union"])
	_apply(model, f)

static func _apply(node: Node, f: Dictionary) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh := mi.mesh
		if mesh:
			for s in range(mesh.get_surface_count()):
				# keep the emissive surfaces (cockpit glass, muzzle glow) readable:
				# detect by the baked albedo of the source material and leave those bright.
				var src := mi.get_active_material(s)
				var is_glow := false
				var is_cockpit := false
				if src is StandardMaterial3D:
					var sm := src as StandardMaterial3D
					if sm.emission_enabled:
						is_glow = true
				if is_glow:
					var em := StandardMaterial3D.new()
					em.albedo_color = Color(f["glow"].x, f["glow"].y, f["glow"].z)
					em.emission_enabled = true
					em.emission = Color(f["glow"].x, f["glow"].y, f["glow"].z)
					em.emission_energy_multiplier = 5.0
					mi.set_surface_override_material(s, em)
				else:
					var mat := ShaderMaterial.new()
					mat.shader = _cached_shader
					mat.set_shader_parameter("base_col", f["base"])
					mat.set_shader_parameter("accent_col", f["accent"])
					mat.set_shader_parameter("glow_col", f["glow"])
					mi.set_surface_override_material(s, mat)
	for c in node.get_children():
		_apply(c, f)
