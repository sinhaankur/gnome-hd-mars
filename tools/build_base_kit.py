"""Build a modular Mars-installation base kit — the ASSET_BUILD_LIST #11 blocker.

Procedurally generates clean, low-poly, game-ready structure pieces entirely in
Blender (no external source), each its own normalized GLB with baked ambient
occlusion vertex/texture detail. These are the reusable modules the named
structures (#12-19: Meson Tower, Shield Generator, Power Plant, turrets, bridge,
Citadel) get assembled from later.

Pieces (all our own geometry, licensing-safe):
  base_wall      — 4 m x 0.4 m x 3 m panelled wall segment
  base_pillar    — 0.6 m square x 3.5 m corner pillar with cap
  base_panel     — 2 m x 2 m flat greeble wall panel (thin)
  base_door      — 2 m x 0.3 m x 2.6 m doorway frame + recessed door
  base_floor      — 4 m x 4 m x 0.3 m floor tile

Conventions (from tools/normalize_env_assets.py + project memory):
  +Y up on export, real-world metres, origin centred on X/Y and base dropped to z=0,
  one headless call, GLB into godot/assets/basekit/. Rough PBR here; final tint via
  Godot shader. AO baked to a 1K image per piece and packed into the GLB.
"""
import bpy, os, math, mathutils

OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets/basekit"
os.makedirs(OUT, exist_ok=True)

AO_SAMPLES = 64          # Cycles AO bake samples — plenty for clean modules
AO_RES = 1024            # 1K AO map per piece (props/structures budget = 1K/2K)


# ---------------------------------------------------------------- helpers ----
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
    """Centre X/Y on origin, drop base to z=0 — same contract as env assets."""
    lo, hi = _obj_bounds(o)
    cx = (lo.x + hi.x) / 2; cy = (lo.y + hi.y) / 2
    o.location = (o.location.x - cx, o.location.y - cy, o.location.z - lo.z)
    _apply(o)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    o.location = (0, 0, 0)


def _cube(name, sx, sy, sz, loc=(0, 0, 0), bevel=0.03):
    """A box of full dimensions (sx,sy,sz) at loc, lightly bevelled for readable edges."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = (sx, sy, sz)
    _apply(o)
    if bevel > 0:
        m = o.modifiers.new("bev", 'BEVEL')
        m.width = bevel; m.segments = 2
        _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=m.name)
    return o


def _join(objs, name):
    _deselect()
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    return o


def _pbr_material(name, base_rgb, rough=0.7, metal=0.0):
    """Neutral rough-metal PBR; final faction tint happens in Godot."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base_rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    return m


def _bake_ao(o):
    """Cycles-bake ambient occlusion and composite it into Base Color.

    The bare Image-Texture-node approach does NOT survive glTF export (a lone AO
    node isn't wired into glTF's occlusion channel, so the exporter drops it).
    Instead we bake AO to an image, then multiply it into the material's Base
    Color via a MixRGB(MULTIPLY) node. That composite travels reliably inside the
    GLB and darkens crevices in Godot — the correct real-time result for neutral
    modules that get faction-tinted by shader afterwards.

    Uses Smart UV Project since these procedural boxes have no meaningful UVs yet.
    """
    # give it clean UVs
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')

    img = bpy.data.images.new(o.name + "_AO", AO_RES, AO_RES)
    # bake target: a temporary active image node per material (Cycles bakes to it)
    for mat in o.data.materials:
        nt = mat.node_tree
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.name = "AO_BAKE_TARGET"
        tex.image = img
        tex.select = True
        nt.nodes.active = tex

    scn = bpy.context.scene
    scn.render.engine = 'CYCLES'
    # Metal GPU on the M1 Max
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

    # composite AO * BaseColor so it exports inside the GLB albedo
    for mat in o.data.materials:
        nt = mat.node_tree
        bsdf = nt.nodes.get("Principled BSDF")
        if not bsdf:
            continue
        ao_tex = nt.nodes["AO_BAKE_TARGET"]
        ao_tex.image.colorspace_settings.name = 'Non-Color'
        # capture whatever the base colour currently is (flat RGBA)
        base_rgba = list(bsdf.inputs["Base Color"].default_value)
        mul = nt.nodes.new("ShaderNodeMixRGB")
        mul.blend_type = 'MULTIPLY'
        mul.inputs["Fac"].default_value = 1.0
        mul.inputs["Color1"].default_value = base_rgba
        nt.links.new(ao_tex.outputs["Color"], mul.inputs["Color2"])
        nt.links.new(mul.outputs["Color"], bsdf.inputs["Base Color"])
    return img


def _export(o, fname):
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    path = os.path.join(OUT, fname)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
    return os.path.getsize(path)


def _finish(o, mat, fname):
    if o.data.materials:
        o.data.materials.clear()
    o.data.materials.append(mat)
    _center_and_base(o)
    _bake_ao(o)
    sz = _export(o, fname)
    return (fname[:-4], len(o.data.polygons), sz)


# ------------------------------------------------------------- the pieces ----
HULL = (0.55, 0.54, 0.52)   # neutral grey installation metal (tint in Godot)


def build_wall():
    _reset()
    body = _cube("wall_body", 4.0, 0.4, 3.0, (0, 0, 1.5))
    # two recessed horizontal ribs for panel-line detail
    rib_a = _cube("rib_a", 4.0, 0.46, 0.15, (0, 0, 1.0), bevel=0.02)
    rib_b = _cube("rib_b", 4.0, 0.46, 0.15, (0, 0, 2.1), bevel=0.02)
    o = _join([body, rib_a, rib_b], "BaseWall")
    return _finish(o, _pbr_material("wall_mat", HULL), "base_wall.glb")


def build_pillar():
    _reset()
    shaft = _cube("shaft", 0.6, 0.6, 3.5, (0, 0, 1.75))
    cap = _cube("cap", 0.8, 0.8, 0.25, (0, 0, 3.5), bevel=0.04)
    foot = _cube("foot", 0.85, 0.85, 0.2, (0, 0, 0.1), bevel=0.04)
    o = _join([shaft, cap, foot], "BasePillar")
    return _finish(o, _pbr_material("pillar_mat", HULL, rough=0.6), "base_pillar.glb")


def build_panel():
    _reset()
    plate = _cube("plate", 2.0, 0.12, 2.0, (0, 0, 1.0))
    # greeble: a few raised bosses
    g1 = _cube("g1", 0.5, 0.18, 0.5, (-0.5, 0, 1.3), bevel=0.02)
    g2 = _cube("g2", 0.4, 0.18, 0.9, (0.55, 0, 0.9), bevel=0.02)
    o = _join([plate, g1, g2], "BasePanel")
    return _finish(o, _pbr_material("panel_mat", HULL, rough=0.55, metal=0.2), "base_panel.glb")


def build_door():
    _reset()
    # frame = big block minus a doorway; use boolean cut
    frame = _cube("frame", 2.4, 0.3, 2.8, (0, 0, 1.4))
    cutter = _cube("cutter", 1.4, 0.6, 2.2, (0, 0, 1.1), bevel=0.0)
    _deselect(); frame.select_set(True); bpy.context.view_layer.objects.active = frame
    m = frame.modifiers.new("cut", 'BOOLEAN'); m.object = cutter; m.operation = 'DIFFERENCE'
    bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
    door = _cube("door", 1.3, 0.12, 2.1, (0, 0, 1.05), bevel=0.02)   # recessed leaf
    o = _join([frame, door], "BaseDoor")
    return _finish(o, _pbr_material("door_mat", HULL, rough=0.5, metal=0.25), "base_door.glb")


def build_floor():
    _reset()
    tile = _cube("tile", 4.0, 4.0, 0.3, (0, 0, 0.15))
    # inset seam cross for tiled floor read
    sx = _cube("sx", 4.0, 0.1, 0.34, (0, 0, 0.15), bevel=0.01)
    sy = _cube("sy", 0.1, 4.0, 0.34, (0, 0, 0.15), bevel=0.01)
    o = _join([tile, sx, sy], "BaseFloor")
    return _finish(o, _pbr_material("floor_mat", HULL, rough=0.8), "base_floor.glb")


results = []
results.append(build_wall())
results.append(build_pillar())
results.append(build_panel())
results.append(build_door())
results.append(build_floor())

print("BASEKIT_OK")
for name, tris, sz in results:
    print("  %-14s tris=%-6d %5.2f MB" % (name, tris, sz / 1e6))
