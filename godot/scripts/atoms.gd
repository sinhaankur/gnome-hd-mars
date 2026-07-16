extends RefCounted
class_name Atoms
## ATOMS — the smallest reusable building blocks, shared across every engine/library.
## Per the project's Atomic-Design + lean-coding policy: helpers that were duplicated in
## many scripts live here ONCE. Call as static functions, e.g. Atoms.find_anim_player(node).
##
## Contents:
##   find_anim_player(node)              -> AnimationPlayer or null
##   all_mesh_instances(node)            -> Array[MeshInstance3D]
##   ground_height(space, x, z, top,bot) -> float (NAN if no hit)
##   fade_and_free(node, tween, secs)    -> fades a node's materials out then frees it
##   flash_light(parent, pos, color, energy, range, secs) -> a brief point-light flash

# --- scene-tree search atoms ---------------------------------------------------
static func find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := find_anim_player(c)
		if r:
			return r
	return null

static func all_mesh_instances(n: Node, out: Array = []) -> Array:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		all_mesh_instances(c, out)
	return out

# --- world query atoms ---------------------------------------------------------
static func ground_height(space: PhysicsDirectSpaceState3D, x: float, z: float,
						   top: float = 300.0, bottom: float = -300.0) -> float:
	# straight-down raycast to the terrain surface Y; NAN if it misses (off-map)
	if space == null:
		return NAN
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, bottom, z))
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return NAN
	return hit.position.y

# --- geometry atoms ------------------------------------------------------------
static var _rock_cache: Array = []   # reuse a small pool of irregular rock meshes

static func rock_mesh(rng: RandomNumberGenerator) -> ArrayMesh:
	# an irregular boulder: a sphere with per-vertex noise displacement so rocks look
	# natural (lumpy/angular), not perfect balls. Cached + reused for performance.
	if _rock_cache.size() >= 8:
		return _rock_cache[rng.randi() % _rock_cache.size()]
	var sphere := SphereMesh.new()
	sphere.radius = 1.0; sphere.height = 2.0
	sphere.radial_segments = 8; sphere.rings = 6
	var arrays := sphere.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in range(verts.size()):
		# push each vertex in/out along its direction by a noise amount -> lumpy rock
		var d := verts[i].normalized()
		var n := 0.72 + 0.28 * sin(d.x * 5.0 + d.y * 7.0) * cos(d.z * 6.0)
		n *= rng.randf_range(0.85, 1.15)
		verts[i] = d * n
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_rock_cache.append(mesh)
	return mesh

static var _rock_mat_cache: Dictionary = {}   # base color -> shared ShaderMaterial

static func rock_material(base: Color) -> ShaderMaterial:
	# Photoreal-leaning rock shading (see reference/real_mars/): world-space noise so no
	# UVs are needed, patchy tone variation, fine grain, and — the detail that sells it —
	# tan regolith dust settled on every upward-facing surface. Cached per base color.
	var key := base.to_html()
	if _rock_mat_cache.has(key):
		return _rock_mat_cache[key]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform vec3 base_col = vec3(0.5, 0.4, 0.3);
uniform vec3 dust_col = vec3(0.74, 0.67, 0.60);   // settled regolith, matches terrain highs
varying vec3 v_world; varying vec3 v_nrm;
void vertex(){
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
float hash(vec2 p){ return fract(sin(dot(p, vec2(41.3,289.1)))*43758.5); }
float noise(vec2 p){ vec2 i=floor(p),f=fract(p); float a=hash(i),b=hash(i+vec2(1,0)),c=hash(i+vec2(0,1)),d=hash(i+vec2(1,1)); vec2 u=f*f*(3.0-2.0*f); return mix(mix(a,b,u.x),mix(c,d,u.x),u.y); }
float fbm(vec2 p){ float v=0.0, a=0.5; for(int i=0;i<4;i++){ v+=a*noise(p); p*=2.07; a*=0.5; } return v; }
void fragment(){
	vec2 w = v_world.xz + vec2(v_world.y * 0.7);
	// patchy mineral tone variation across the boulder. COLOR is white for plain
	// MeshInstances; MultiMesh scatter sets a per-instance tint so one material
	// serves thousands of varied rocks.
	float patch = fbm(w * 1.4);
	vec3 col = base_col * COLOR.rgb * (0.82 + patch * 0.36);
	// fine surface grain
	float grain = noise(w * 22.0);
	col *= 0.93 + grain * 0.14;
	// tan dust settles on up-facing surfaces — like every rock in the rover photos
	// (kept subtle: a heavy dust cap made every rock brighter than the ground)
	float up = clamp(v_nrm.y, 0.0, 1.0);
	col = mix(col, dust_col, smoothstep(0.45, 0.95, up) * 0.35);
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("base_col", Vector3(base.r, base.g, base.b))
	_rock_mat_cache[key] = m
	return m

static func align_foot(visual: Node3D, body: Node3D, foot_y: float = 0.4) -> void:
	# GLB mech models rarely have their origin at the feet — the visual then hovers at
	# the model's arbitrary origin height while the physics capsule stands correctly
	# (measured: warrior.glb floated ~3 m). Shift the visual so its lowest mesh point
	# sits at the capsule bottom. Call AFTER the body is inside the tree.
	var bottom := INF
	var inv := body.global_transform.affine_inverse()
	for mi in all_mesh_instances(visual):
		var m := mi as MeshInstance3D
		var xf: Transform3D = inv * m.global_transform
		var aabb: AABB = m.get_aabb()
		for i in range(8):
			bottom = minf(bottom, (xf * aabb.get_endpoint(i)).y)
	if bottom != INF:
		visual.position.y -= bottom - foot_y

# --- effect atoms --------------------------------------------------------------
static var _radial_tex: GradientTexture2D   # shared soft-falloff sprite for all particles

static func radial_sprite() -> GradientTexture2D:
	# white center fading to transparent edge — an untextured particle quad renders as a
	# hard-edged floating SQUARE (the worst particle artifact); this makes it a soft puff
	if _radial_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = 64; t.height = 64
		_radial_tex = t
	return _radial_tex

static var _dust_mat_cache: Dictionary = {}   # color -> shared soft dust material

static func dust_material(color: Color) -> StandardMaterial3D:
	# soft round dust-puff material for GPU particle quads (wind dust, devils, thrusters,
	# landing bursts). Unshaded + billboard + radial falloff. Cached per color.
	var key := color.to_html()
	if _dust_mat_cache.has(key):
		return _dust_mat_cache[key]
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.albedo_texture = radial_sprite()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true   # lets the process material's color tint apply
	m.disable_receive_shadows = true
	_dust_mat_cache[key] = m
	return m

static func flash_light(parent: Node, pos: Vector3, color: Color, energy: float,
						rng: float, secs: float) -> void:
	# a brief point-light flash that fades out and frees itself (muzzle/impact/explosion)
	if parent == null:
		return
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	parent.add_child(l)        # must be in-tree BEFORE setting a global transform
	l.global_position = pos
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, secs)
	tw.tween_callback(l.queue_free)

static func spark_burst(parent: Node, pos: Vector3, color: Color, amount: int = 10) -> void:
	# a one-shot GPU spark/dust burst that self-frees (impacts, landings, deaths)
	if parent == null:
		return
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 1.0
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 90.0
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 11.0
	pm.gravity = Vector3(0, -12, 0)
	pm.scale_min = 0.15
	pm.scale_max = 0.4
	pm.color = color
	p.process_material = pm
	var qm := QuadMesh.new(); qm.size = Vector2(0.3, 0.3)
	p.draw_pass_1 = qm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 4.0
	m.albedo_color = color
	m.albedo_texture = radial_sprite()   # soft round spark, not a square
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	p.material_override = m
	parent.add_child(p)        # must be in-tree BEFORE setting a global transform
	p.global_position = pos
	p.emitting = true
	var t := p.get_tree().create_timer(1.0)
	t.timeout.connect(func(): if is_instance_valid(p): p.queue_free())
