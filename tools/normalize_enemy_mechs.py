"""Normalize the 5 downloaded Sketchfab source mechs into game-ready enemy_*.glb.

The sources are real, detailed CC-BY models (see sketchfab_src/ATTRIBUTIONS.json) but
each arrives at a different orientation, scale, and poly budget. This turns each into a
clean Godot asset WITHOUT hand-modeling: import -> drop armature -> join -> orient upright
facing +Y -> decimate if over budget -> scale to its class height -> origin to the base ->
export GLB (Principled-BSDF, Y-up). Godot's Faction.tint recolors per faction at spawn.

Runs headless so it never touches the artist's GUI scene. Reproducible: re-run any time.

PER-ARCHETYPE config (rot_euler_deg tuned by isolation render, see _render_mechs pass):
  target_h  = intended in-game height in metres (before Godot's ARCH_BASE_SCALE=1.0 now)
  rot       = degrees to rotate the imported source so it stands upright, faces +Y
  max_tris  = decimate down to roughly this many triangles if over
"""
import bpy, os, math, mathutils

SRC = "/Users/sinhaankur/Downloads/G-Nome_ISO/blender_assets/sketchfab_src"
OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"

CONFIG = {
    # arch:      (src file,           target_h, rot(x,y,z) deg,  max_tris)
    # All sources import upright (Z-up) after glTF conversion — verified by raw-bounds
    # probe (Z is a sensible height for each). No re-orient needed; tactical is just a
    # wide-armed design and heavy is a wide-footprint quadruped. Facing +Y = forward.
    "sentry":   ("src_sentry.glb",    6.8,  (0, 0, 0),      40000),
    "tactical": ("src_tactical.glb",  8.5,  (0, 0, 0),      60000),
    "heavy":    ("src_heavy.glb",    10.0,  (0, 0, 0),     120000),
    "support":  ("src_support.glb",   3.6,  (0, 0, 0),      30000),
    "hover":    ("src_hover.glb",     3.2,  (0, 0, 0),      60000),
}


def _all_meshes():
    return [o for o in bpy.context.scene.objects if o.type == 'MESH']


def _bounds():
    lo = mathutils.Vector((1e18,) * 3); hi = -lo
    for m in _all_meshes():
        for c in m.bound_box:
            w = m.matrix_world @ mathutils.Vector(c)
            lo = mathutils.Vector((min(lo[i], w[i]) for i in range(3)))
            hi = mathutils.Vector((max(hi[i], w[i]) for i in range(3)))
    return lo, hi


def _deselect():
    for o in bpy.context.scene.objects:
        o.select_set(False)


def normalize(arch, cfg):
    src, target_h, rot_deg, max_tris = cfg
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, src))

    # 1) drop armatures/empties — enemies animate the whole node (mech_animator bob),
    #    not the source rig; a stray armature just bloats and can offset the mesh.
    for o in list(bpy.context.scene.objects):
        if o.type in ('ARMATURE',):
            bpy.data.objects.remove(o, do_unlink=True)

    meshes = _all_meshes()
    if not meshes:
        print("NO_MESH", arch); return None

    # 2) apply each mesh's own transform, then JOIN to one object
    _deselect()
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = "Enemy" + arch.capitalize()

    # 3) orient upright / face +Y (per-arch rotation from the render tuning pass)
    obj.rotation_euler = tuple(math.radians(d) for d in rot_deg)
    _deselect(); obj.select_set(True); bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(rotation=True)

    # 4) decimate if over the triangle budget (keeps the look, cuts weight)
    tris = len(obj.data.polygons)
    if tris > max_tris:
        dec = obj.modifiers.new("dec", 'DECIMATE')
        dec.ratio = max_tris / float(tris)
        bpy.ops.object.modifier_apply(modifier=dec.name)

    # 5) scale to the class height (Z is up in Blender), center X/Y, base to z=0
    lo, hi = _bounds()
    h = hi.z - lo.z
    if h > 1e-6:
        s = target_h / h
        obj.scale = (s, s, s)
        _deselect(); obj.select_set(True); bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(scale=True)
    lo, hi = _bounds()
    cx = (lo.x + hi.x) / 2; cy = (lo.y + hi.y) / 2
    obj.location = (obj.location.x - cx, obj.location.y - cy, obj.location.z - lo.z)
    _deselect(); obj.select_set(True); bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True)
    # origin to geometry base so Godot's align_foot has a clean reference
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    obj.location = (0, 0, 0)

    # 6) export GLB, Y-up
    _deselect(); obj.select_set(True); bpy.context.view_layer.objects.active = obj
    out = os.path.join(OUT, "enemy_%s.glb" % arch)
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
    lo, hi = _bounds()
    return (obj.name, len(obj.data.polygons), [round(hi[i] - lo[i], 2) for i in range(3)],
            os.path.getsize(out))


results = []
for arch, cfg in CONFIG.items():
    r = normalize(arch, cfg)
    if r:
        results.append((arch,) + r)

print("NORMALIZE_OK")
for arch, name, tris, dims, size in results:
    print("  %-9s tris=%-7d dims(x,y,z)=%s  %5.2f MB" % (arch, tris, dims, size / 1e6))
