"""Build a rock-field library from the 4 real scanned Mars rocks.

Takes the genuine scanned mars_rock_1..4.glb already in godot/assets/ and derives
a spread of size / rotation / squash variants so the terrain can be scattered with
visual variety instead of 4 obviously-repeated stones. Each variant keeps the real
scanned geometry + its texture, adds a light Cycles AO pass composited into albedo
for grounded contact shadadow, and exports as its own normalized GLB.

Output: godot/assets/rockfield/rock_v01.glb .. rock_vNN.glb
  - centred on X/Y, base dropped to z=0, +Y up, real metres (longest axis per the
    size class), same contract as tools/normalize_env_assets.py.

These are DERIVED from our own already-shipped assets (no new external source), so
licensing is unchanged; attribution for the source scans stays as-is in CREDITS.md.
"""
import bpy, os, math, mathutils, random

ASSETS = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"
OUT = os.path.join(ASSETS, "rockfield")
os.makedirs(OUT, exist_ok=True)

SOURCES = ["mars_rock_1", "mars_rock_2", "mars_rock_3", "mars_rock_4"]
AO_SAMPLES = 48
AO_RES = 1024
random.seed(7)   # reproducible field

# (longest-axis metres, squash_z) per size class — pebbles to landmark boulders
SIZE_CLASSES = [
    ("pebble",  0.35, 0.9),
    ("stone",   0.8,  0.85),
    ("rock",    1.6,  0.8),
    ("boulder", 3.2,  0.75),
]


# --- helpers (same contract as build_base_kit.py / normalize_env_assets.py) ---
def _reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _deselect():
    for o in bpy.context.scene.objects:
        o.select_set(False)


def _obj_bounds(o):
    lo = mathutils.Vector((1e18,) * 3); hi = -lo
    for c in o.bound_box:
        w = o.matrix_world @ mathutils.Vector(c)
        lo = mathutils.Vector((min(lo[i], w[i]) for i in range(3)))
        hi = mathutils.Vector((max(hi[i], w[i]) for i in range(3)))
    return lo, hi


def _apply(o):
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def _center_and_base(o):
    lo, hi = _obj_bounds(o)
    cx = (lo.x + hi.x) / 2; cy = (lo.y + hi.y) / 2
    o.location = (o.location.x - cx, o.location.y - cy, o.location.z - lo.z)
    _apply(o)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    o.location = (0, 0, 0)


def _import_rock(name):
    """Import a source rock GLB and return its single joined mesh object."""
    bpy.ops.import_scene.gltf(filepath=os.path.join(ASSETS, name + ".glb"))
    for o in list(bpy.context.scene.objects):
        if o.type == 'ARMATURE':
            bpy.data.objects.remove(o, do_unlink=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    _deselect()
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    return bpy.context.active_object


def _bake_ao_into_albedo(o):
    """Light AO bake composited into Base Color — reuses the base-kit approach.

    Scanned rocks already carry a diffuse texture; we add a subtle AO multiply so
    they sit into the ground with contact occlusion. If a mesh has no material we
    give it a neutral one first so the multiply has somewhere to land.
    """
    if not o.data.materials:
        m = bpy.data.materials.new(o.name + "_mat"); m.use_nodes = True
        o.data.materials.append(m)

    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    # scanned rocks usually have UVs; only unwrap if missing
    if not o.data.uv_layers:
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
        bpy.ops.object.mode_set(mode='OBJECT')

    img = bpy.data.images.new(o.name + "_AO", AO_RES, AO_RES)
    for mat in o.data.materials:
        if not mat.use_nodes:
            mat.use_nodes = True
        nt = mat.node_tree
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.name = "AO_BAKE_TARGET"; tex.image = img; tex.select = True
        nt.nodes.active = tex

    scn = bpy.context.scene
    scn.render.engine = 'CYCLES'
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        prefs.compute_device_type = 'METAL'
        for d in prefs.devices:
            d.use = True
        scn.cycles.device = 'GPU'
    except Exception:
        scn.cycles.device = 'CPU'
    scn.cycles.samples = AO_SAMPLES
    scn.cycles.bake_type = 'AO'
    scn.render.bake.margin = 8

    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.bake(type='AO')
    img.pack()

    for mat in o.data.materials:
        nt = mat.node_tree
        bsdf = nt.nodes.get("Principled BSDF")
        if not bsdf:
            continue
        ao_tex = nt.nodes["AO_BAKE_TARGET"]
        ao_tex.image.colorspace_settings.name = 'Non-Color'
        mul = nt.nodes.new("ShaderNodeMixRGB")
        mul.blend_type = 'MULTIPLY'
        mul.inputs["Fac"].default_value = 0.7   # subtle — rocks keep scan albedo
        # feed existing base-colour source (texture link or flat value) into Color1
        bc = bsdf.inputs["Base Color"]
        if bc.is_linked:
            src = bc.links[0].from_socket
            nt.links.new(src, mul.inputs["Color1"])
        else:
            mul.inputs["Color1"].default_value = list(bc.default_value)
        nt.links.new(ao_tex.outputs["Color"], mul.inputs["Color2"])
        nt.links.new(mul.outputs["Color"], bc)


def _export(o, fname):
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    path = os.path.join(OUT, fname)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
    return os.path.getsize(path)


def build_variant(idx, src_name, size_m, squash_z, yaw_deg):
    _reset()
    o = _import_rock(src_name)
    o.name = "RockV%02d" % idx
    # random yaw for silhouette variety, then squash Z for the size class
    o.rotation_euler = (0, 0, math.radians(yaw_deg))
    _apply(o)
    lo, hi = _obj_bounds(o)
    longest = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
    s = (size_m / longest) if longest > 1e-4 else 1.0
    o.scale = (s, s, s * squash_z)
    _apply(o)
    _center_and_base(o)
    _bake_ao_into_albedo(o)
    sz = _export(o, "rock_v%02d.glb" % idx)
    return ("rock_v%02d" % idx, src_name, len(o.data.polygons), sz)


results = []
idx = 1
# 4 size classes x 4 source rocks = 16 varied field pieces
for cls_name, size_m, squash_z in SIZE_CLASSES:
    for src in SOURCES:
        yaw = random.uniform(0, 360)
        # vary size +-20% within a class so no two read identical
        jitter = size_m * random.uniform(0.85, 1.2)
        results.append(build_variant(idx, src, jitter, squash_z, yaw))
        idx += 1

print("ROCKFIELD_OK")
for name, src, tris, sz in results:
    print("  %-10s <- %-12s tris=%-7d %5.2f MB" % (name, src, tris, sz / 1e6))
