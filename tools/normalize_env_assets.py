"""Normalize the downloaded Mars-ENVIRONMENT sources into game-ready GLBs.

Produces:
  mars_rock_1..4.glb  — the best 4 individual rocks from the CC-BY 'Free Pack - Rocks
                        Stylized' (PolyOne), each its own centered/based GLB for scatter.
  mars_outcrop.glb    — one big weathered boulder from the Cliff Rock Boulder Field
                        (Pers Scans, photoscan) for a landmark rise, scaled to ~6 m.
  nasa_rover.glb      — NASA Curiosity (Clean) (Thomas Flynn), oriented upright facing +Y,
                        scaled to its real ~3 m length, as the Derelict Rover POI.

All faction-neutral / Mars-neutral geometry+texture; the env engine tints rocks to the
Mars palette via material_override at scatter time (existing behavior). Headless; never
touches the GUI scene. Reproducible.
"""
import bpy, os, math, mathutils

SRC = "/Users/sinhaankur/Downloads/G-Nome_ISO/blender_assets/sketchfab_src"
OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"


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


def _center_and_base(o):
    """Center X/Y on origin, drop base to z=0, origin to geometry."""
    lo, hi = _obj_bounds(o)
    cx = (lo.x + hi.x) / 2; cy = (lo.y + hi.y) / 2
    o.location = (o.location.x - cx, o.location.y - cy, o.location.z - lo.z)
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    o.location = (0, 0, 0)


def _export(o, fname):
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, fname), export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
    return os.path.getsize(os.path.join(OUT, fname))


def build_rocks():
    # the rock pack has 11 separate SM_Rocks objects; pick 4 with varied, useful sizes
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, "src_rocks_pack.glb"))
    rocks = sorted([o for o in bpy.context.scene.objects if o.type == 'MESH'],
                   key=lambda o: -max(o.dimensions))   # biggest first
    picks = rocks[:4]                                   # 4 largest = usable landmark rocks
    out = []
    for i, r in enumerate(picks, 1):
        _center_and_base(r)
        # normalize each to ~2 m longest axis so the env engine can scale predictably
        d = max(r.dimensions)
        if d > 1e-4:
            s = 2.0 / d
            r.scale = (s, s, s)
            _deselect(); r.select_set(True); bpy.context.view_layer.objects.active = r
            bpy.ops.object.transform_apply(scale=True)
        _center_and_base(r)
        sz = _export(r, "mars_rock_%d.glb" % i)
        out.append(("mars_rock_%d" % i, len(r.data.polygons), sz))
    return out


def build_outcrop():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, "src_boulder.glb"))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    # join all boulder parts, then scale the whole cliff-chunk to ~6 m tall
    _deselect()
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = "MarsOutcrop"
    lo, hi = _obj_bounds(o)
    h = hi.z - lo.z
    if h > 1e-4:
        s = 6.0 / h
        o.scale = (s, s, s)
        _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(scale=True)
    _center_and_base(o)
    return [("mars_outcrop", len(o.data.polygons), _export(o, "mars_outcrop.glb"))]


def build_rover():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, "src_rover.glb"))
    # drop any armature/empty, join all 100+ parts into one rover object
    for o in list(bpy.context.scene.objects):
        if o.type == 'ARMATURE':
            bpy.data.objects.remove(o, do_unlink=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    _deselect()
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = "NasaRover"
    # real Curiosity is ~3 m long, ~2.2 m tall with mast. Source dims [2.8,3.4,1.2] =
    # already ~real; scale so its longest footprint axis is ~3 m (keeps true proportions).
    lo, hi = _obj_bounds(o)
    longest = max(hi.x - lo.x, hi.y - lo.y)
    if longest > 1e-4:
        s = 3.0 / longest
        o.scale = (s, s, s)
        _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(scale=True)
    _center_and_base(o)
    return [("nasa_rover", len(o.data.polygons), _export(o, "nasa_rover.glb"))]


results = []
results += build_rocks()
results += build_outcrop()
results += build_rover()

print("ENV_NORMALIZE_OK")
for name, tris, sz in results:
    print("  %-14s tris=%-7d %5.2f MB" % (name, tris, sz / 1e6))
