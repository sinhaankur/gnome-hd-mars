"""Build small POI / set-dressing props so the Mars world isn't bare.

Fully procedural, our-own geometry (licensing-safe), same headless one-call
pattern + AO-into-albedo bake as tools/build_base_kit.py. These are the little
things that make an open world read as inhabited: supply crates, fuel barrels,
antenna posts, cargo pallets, debris chunks.

Output: godot/assets/props/<name>.glb
  centred on X/Y, base at z=0, +Y up, real metres.
"""
import bpy, os, math, mathutils

OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets/props"
os.makedirs(OUT, exist_ok=True)

AO_SAMPLES = 48
AO_RES = 1024


# --- shared helpers (identical contract to build_base_kit.py) ----------------
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


def _cube(name, sx, sy, sz, loc=(0, 0, 0), bevel=0.02):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object; o.name = name; o.scale = (sx, sy, sz)
    _apply(o)
    if bevel > 0:
        m = o.modifiers.new("bev", 'BEVEL'); m.width = bevel; m.segments = 2
        _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=m.name)
    return o


def _cyl(name, r, h, loc=(0, 0, 0), verts=16):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, vertices=verts, location=loc)
    o = bpy.context.active_object; o.name = name
    _apply(o)
    return o


def _join(objs, name):
    _deselect()
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object; o.name = name
    return o


def _pbr(name, rgb, rough=0.7, metal=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    return m


def _bake_ao(o):
    """AO bake -> multiply into Base Color (survives GLB export)."""
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')

    img = bpy.data.images.new(o.name + "_AO", AO_RES, AO_RES)
    for mat in o.data.materials:
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
        ao = nt.nodes["AO_BAKE_TARGET"]
        ao.image.colorspace_settings.name = 'Non-Color'
        base_rgba = list(bsdf.inputs["Base Color"].default_value)
        mul = nt.nodes.new("ShaderNodeMixRGB")
        mul.blend_type = 'MULTIPLY'; mul.inputs["Fac"].default_value = 1.0
        mul.inputs["Color1"].default_value = base_rgba
        nt.links.new(ao.outputs["Color"], mul.inputs["Color2"])
        nt.links.new(mul.outputs["Color"], bsdf.inputs["Base Color"])
    return img


def _export(o, fname):
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    path = os.path.join(OUT, fname)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
    return os.path.getsize(path)


def _finish(o, mat, fname):
    o.data.materials.clear(); o.data.materials.append(mat)
    _center_and_base(o); _bake_ao(o)
    return (fname[:-4], len(o.data.polygons), _export(o, fname))


# ----------------------------------------------------------------- props -----
CRATE = (0.42, 0.38, 0.30)     # olive supply crate
BARREL = (0.30, 0.32, 0.34)    # dark fuel drum
METAL = (0.50, 0.50, 0.52)     # bare metal
DEBRIS = (0.38, 0.30, 0.24)    # rusted debris


def prop_crate():
    _reset()
    body = _cube("crate", 0.9, 0.9, 0.9, (0, 0, 0.45), bevel=0.03)
    # corner braces
    braces = []
    for sx in (-0.42, 0.42):
        for sy in (-0.42, 0.42):
            braces.append(_cube("b", 0.08, 0.08, 0.92, (sx, sy, 0.46), bevel=0.01))
    o = _join([body] + braces, "SupplyCrate")
    return _finish(o, _pbr("crate_mat", CRATE, rough=0.6), "prop_crate.glb")


def prop_barrel():
    _reset()
    body = _cyl("barrel", 0.28, 0.95, (0, 0, 0.475))
    rim_a = _cyl("ra", 0.30, 0.06, (0, 0, 0.3))
    rim_b = _cyl("rb", 0.30, 0.06, (0, 0, 0.65))
    o = _join([body, rim_a, rim_b], "FuelBarrel")
    return _finish(o, _pbr("barrel_mat", BARREL, rough=0.5, metal=0.3), "prop_barrel.glb")


def prop_antenna():
    _reset()
    base = _cube("base", 0.5, 0.5, 0.2, (0, 0, 0.1), bevel=0.02)
    mast = _cyl("mast", 0.05, 2.4, (0, 0, 1.3), verts=10)
    dish = _cyl("dish", 0.35, 0.06, (0, 0, 2.4), verts=20)
    dish.rotation_euler = (math.radians(35), 0, 0); _apply(dish)
    o = _join([base, mast, dish], "AntennaPost")
    return _finish(o, _pbr("ant_mat", METAL, rough=0.4, metal=0.5), "prop_antenna.glb")


def prop_pallet():
    _reset()
    deck = _cube("deck", 1.2, 1.0, 0.12, (0, 0, 0.18), bevel=0.01)
    feet = []
    for sx in (-0.5, 0.5):
        feet.append(_cube("f", 0.14, 1.0, 0.12, (sx, 0, 0.06), bevel=0.01))
    o = _join([deck] + feet, "CargoPallet")
    return _finish(o, _pbr("pallet_mat", DEBRIS, rough=0.85), "prop_pallet.glb")


def prop_debris():
    _reset()
    # a crumpled hull chunk: a few tilted plates
    p1 = _cube("p1", 1.4, 1.0, 0.1, (0, 0, 0.3), bevel=0.02)
    p1.rotation_euler = (math.radians(18), math.radians(-10), 0); _apply(p1)
    p2 = _cube("p2", 0.9, 0.7, 0.1, (0.4, 0.2, 0.55), bevel=0.02)
    p2.rotation_euler = (math.radians(-25), math.radians(20), math.radians(15)); _apply(p2)
    strut = _cyl("strut", 0.05, 1.3, (-0.3, -0.2, 0.4), verts=8)
    strut.rotation_euler = (math.radians(70), 0, math.radians(30)); _apply(strut)
    o = _join([p1, p2, strut], "HullDebris")
    return _finish(o, _pbr("debris_mat", DEBRIS, rough=0.7, metal=0.2), "prop_debris.glb")


results = [prop_crate(), prop_barrel(), prop_antenna(), prop_pallet(), prop_debris()]

print("PROPS_OK")
for name, tris, sz in results:
    print("  %-14s tris=%-6d %5.2f MB" % (name, tris, sz / 1e6))
