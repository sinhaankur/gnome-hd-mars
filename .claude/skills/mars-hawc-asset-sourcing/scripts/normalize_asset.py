"""Generic asset normalizer for Mars HAWC — enforces the orientation/axis/layout contract.

Turns any downloaded source model into a game-ready GLB:
  clean (drop cameras/lights/empties; optionally armatures) -> join -> face -Z ->
  scale to a real-world size in metres -> center X/Z, base to Y=0, origin to bounds ->
  apply all transforms -> export Y-up GLB into godot/assets/.

Run headless (never touches a GUI scene), e.g.:
  blender --background --python normalize_asset.py -- \
      --src blender_assets/sketchfab_src/src_dropship.glb \
      --out godot/assets/dropship.glb --name Dropship \
      --target-h 8.0 --facing 0,180,0

Or drive the functions directly via the Blender MCP connector.

Axis/layout contract (see SKILL.md):
  * export_yup=True  -> glTF Y-up (Godot convention). Blender stays Z-up internally.
  * forward = -Z in Godot; use --facing to rotate the source's forward before apply.
  * center X/Z on origin; base sits at Y=0 (Blender Z=0) so spawn at ground_point works.
  * 1 unit = 1 m; normalize to real height (--target-h) or longest footprint (--target-len).
  * apply location+rotation+scale before export.
"""
import bpy, os, sys, math, argparse, mathutils

PROJECT = "/Users/sinhaankur/Downloads/G-Nome_ISO"


def _argv():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--src", required=True, help="source model (glb/gltf/fbx/obj)")
    p.add_argument("--out", required=True, help="output .glb (relative to project or absolute)")
    p.add_argument("--name", default="Asset")
    p.add_argument("--target-h", type=float, default=0.0, help="scale so height (Z) = this many metres")
    p.add_argument("--target-len", type=float, default=0.0, help="…or so longest X/Y footprint = this")
    p.add_argument("--facing", default="0,0,0", help="pre-apply rotation degrees 'x,y,z' to fix forward")
    p.add_argument("--auto-upright", action="store_true",
                   help="rotate so the model's LONGEST axis is vertical (Blender Z -> Godot Y). "
                        "Fixes lying-down characters. Static path only.")
    p.add_argument("--keep-rig", action="store_true", help="keep armature+anim (hero mechs)")
    return p.parse_args(argv)


def _deselect():
    for o in bpy.context.scene.objects:
        o.select_set(False)


def _activate(o):
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o


def _bounds(o):
    lo = mathutils.Vector((1e18,) * 3); hi = -lo
    for c in o.bound_box:
        w = o.matrix_world @ mathutils.Vector(c)
        lo = mathutils.Vector((min(lo[i], w[i]) for i in range(3)))
        hi = mathutils.Vector((max(hi[i], w[i]) for i in range(3)))
    return lo, hi


def _import(src):
    path = src if os.path.isabs(src) else os.path.join(PROJECT, src)
    ext = os.path.splitext(path)[1].lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    elif ext == ".obj":
        bpy.ops.wm.obj_import(filepath=path)
    else:
        raise SystemExit("unsupported source: " + ext)


def _center_and_base(o):
    lo, hi = _bounds(o)
    cx = (lo.x + hi.x) / 2; cy = (lo.y + hi.y) / 2
    o.location = (o.location.x - cx, o.location.y - cy, o.location.z - lo.z)
    _activate(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # origin stays at the WORLD origin: centered X/Y, base at Z=0. Do NOT origin_set to
    # bounds center here — that re-centers the mesh vertically, so tall assets spawned at
    # ground level in Godot end up buried to the waist (found via shuttle_wreck AABB).


def _world_mesh_bounds():
    """World-space bounds over ALL mesh objects (for rigged hierarchies)."""
    lo = mathutils.Vector((1e18,) * 3); hi = -lo
    for o in bpy.context.scene.objects:
        if o.type != 'MESH':
            continue
        for c in o.bound_box:
            w = o.matrix_world @ mathutils.Vector(c)
            lo = mathutils.Vector((min(lo[i], w[i]) for i in range(3)))
            hi = mathutils.Vector((max(hi[i], w[i]) for i in range(3)))
    return lo, hi


def _normalize_rigged(a):
    """Rig-preserving path: keep armature + meshes + actions. Scale/base the hierarchy
    ROOT so skinning and all animations survive (do NOT join or apply on the meshes)."""
    arm = next((o for o in bpy.context.scene.objects if o.type == 'ARMATURE'), None)
    if not arm:
        raise SystemExit("--keep-rig set but no armature found")
    root = arm
    while root.parent is not None:
        root = root.parent

    # scale to real metres via world mesh bounds
    lo, hi = _world_mesh_bounds()
    if a.target_h > 0:
        d = hi.z - lo.z; s = a.target_h / d if d > 1e-5 else 1.0
    elif a.target_len > 0:
        d = max(hi.x - lo.x, hi.y - lo.y); s = a.target_len / d if d > 1e-5 else 1.0
    else:
        s = 1.0
    root.scale = (root.scale.x * s, root.scale.y * s, root.scale.z * s)
    bpy.context.view_layer.update()

    # center X/Y, base to Z=0 by moving the root
    lo, hi = _world_mesh_bounds()
    cx = (lo.x + hi.x) / 2; cy = (lo.y + hi.y) / 2
    root.location = (root.location.x - cx, root.location.y - cy, root.location.z - lo.z)
    bpy.context.view_layer.update()

    out = a.out if os.path.isabs(a.out) else os.path.join(PROJECT, a.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    for o in bpy.context.scene.objects:
        o.select_set(True)
    # export_apply=False keeps the armature; animations+skins on
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', use_selection=True,
                              export_yup=True, export_apply=False,
                              export_animations=True, export_skins=True)
    tris = sum(len(m.data.polygons) for m in bpy.context.scene.objects if m.type == 'MESH')
    print("NORMALIZE_OK  %s (rigged)  tris=%d  actions=%d  %.2f MB  -> %s"
          % (a.name, tris, len(bpy.data.actions), os.path.getsize(out) / 1e6, out))


def normalize(a):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _import(a.src)

    # 1) clean: always drop cameras/lights + common uploader junk; keep armature if --keep-rig
    JUNK_NAMES = {"Cube", "Icosphere", "Light", "Camera", "Sphere", "Plane"}
    for o in list(bpy.context.scene.objects):
        if o.type in {'CAMERA', 'LIGHT'} or o.name in JUNK_NAMES:
            bpy.data.objects.remove(o, do_unlink=True)

    # 1b) apply optional facing fix to the whole scene root(s) before measuring
    fx, fy, fz = (float(v) for v in a.facing.split(","))

    if a.keep_rig:
        if (fx, fy, fz) != (0, 0, 0):
            arm = next((o for o in bpy.context.scene.objects if o.type == 'ARMATURE'), None)
            root = arm
            while root and root.parent is not None:
                root = root.parent
            if root:
                root.rotation_euler = (math.radians(fx), math.radians(fy), math.radians(fz))
        _normalize_rigged(a)
        return

    # --- static path: drop armatures/empties, join into one mesh ---
    for o in list(bpy.context.scene.objects):
        if o.type in {'ARMATURE', 'EMPTY'}:
            bpy.data.objects.remove(o, do_unlink=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    if not meshes:
        raise SystemExit("no mesh found in source")
    _deselect()
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = a.name

    # auto-upright: make the LONGEST axis vertical (Blender Z, which export_yup maps to
    # Godot Y). Fixes source figures that import lying down. Measured in Godot space this
    # is what puts a character's height on Y. Applied before the explicit --facing.
    if a.auto_upright:
        lo, hi = _bounds(o)
        dx, dy, dz = hi.x - lo.x, hi.y - lo.y, hi.z - lo.z
        longest = max(('x', dx), ('y', dy), ('z', dz), key=lambda t: t[1])[0]
        if longest == 'y':
            o.rotation_euler = (math.radians(90), 0, 0)
        elif longest == 'x':
            o.rotation_euler = (0, math.radians(90), 0)
        if longest != 'z':
            _activate(o); bpy.ops.object.transform_apply(rotation=True)

    if (fx, fy, fz) != (0, 0, 0):
        o.rotation_euler = (math.radians(fx), math.radians(fy), math.radians(fz))
        _activate(o); bpy.ops.object.transform_apply(rotation=True)

    lo, hi = _bounds(o)
    if a.target_h > 0:
        d = hi.z - lo.z; s = a.target_h / d if d > 1e-5 else 1.0
    elif a.target_len > 0:
        d = max(hi.x - lo.x, hi.y - lo.y); s = a.target_len / d if d > 1e-5 else 1.0
    else:
        s = 1.0
    if abs(s - 1.0) > 1e-4:
        o.scale = (s, s, s)
        _activate(o); bpy.ops.object.transform_apply(scale=True)

    _center_and_base(o)

    out = a.out if os.path.isabs(a.out) else os.path.join(PROJECT, a.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    _activate(o)
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
    tris = sum(len(m.data.polygons) for m in bpy.context.scene.objects if m.type == 'MESH')
    print("NORMALIZE_OK  %s  tris=%d  %.2f MB  -> %s"
          % (a.name, tris, os.path.getsize(out) / 1e6, out))


if __name__ == "__main__":
    normalize(_argv())
