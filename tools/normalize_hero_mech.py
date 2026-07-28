"""Normalize the Walker mech (Kai Xiang, CC-BY) into the game's player hero HAWC.

Unlike the static env props, the HERO mech MUST keep its armature + walk animation (the
game's MechAnimator drives it). So we do NOT join meshes or strip the rig — we only:
  - scale the whole rig+mesh to ~2.5 blender-units tall (the game applies MECH_SCALE on top,
    like the other mechs), measured from the REST pose
  - drop the base to z=0 so feet sit on the ground
  - export GLB with animations + skinning, Y-up

Its materials are already metal=0/rough=0.5 (no dark-render problem, unlike the old
hawc_hero), so no material rescue is needed. Headless; never touches the GUI scene.
"""
import bpy, os, mathutils

SRC = "/Users/sinhaankur/Downloads/G-Nome_ISO/blender_assets/sketchfab_src/src_hero_walker.glb"
OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets/hawc_walker.glb"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)

# --- measure the REST-pose bounds (clear any action so we size the neutral pose) ---
for o in bpy.context.scene.objects:
    if o.animation_data:
        o.animation_data.action = None
for arm in [o for o in bpy.context.scene.objects if o.type == 'ARMATURE']:
    for pb in arm.pose.bones:
        pb.matrix_basis = mathutils.Matrix()
bpy.context.view_layer.update()


def bounds():
    lo = mathutils.Vector((1e18,) * 3); hi = -lo
    for m in [o for o in bpy.context.scene.objects if o.type == 'MESH']:
        m.data.update()
        for c in m.bound_box:
            w = m.matrix_world @ mathutils.Vector(c)
            lo = mathutils.Vector((min(lo[i], w[i]) for i in range(3)))
            hi = mathutils.Vector((max(hi[i], w[i]) for i in range(3)))
    return lo, hi


lo, hi = bounds()
height = hi.z - lo.z
TARGET = 2.5   # blender units tall at rest — matches the warrior/other mech convention
scale = TARGET / height if height > 1e-6 else 1.0

# scale + base-to-ground the ROOT objects (armature + any mesh not parented to it)
roots = [o for o in bpy.context.scene.objects if o.parent is None]
for r in roots:
    r.scale = (r.scale.x * scale, r.scale.y * scale, r.scale.z * scale)
bpy.context.view_layer.update()
lo, hi = bounds()
# center X/Y, drop feet (min z) to 0
cx = (lo.x + hi.x) / 2; cy = (lo.y + hi.y) / 2
for r in roots:
    r.location = (r.location.x - cx, r.location.y - cy, r.location.z - lo.z)
bpy.context.view_layer.update()

# --- export with the rig + animation intact ---
for o in bpy.context.scene.objects:
    o.select_set(True)
bpy.ops.export_scene.gltf(
    filepath=OUT, export_format='GLB', use_selection=True,
    export_apply=False,               # KEEP the armature deform (don't bake to a static mesh)
    export_yup=True,
    export_animations=True, export_skins=True,
)

lo, hi = bounds()
print("HERO_NORMALIZE_OK scale=%.3f rest_dims=[%.2f,%.2f,%.2f] size_MB=%.2f actions=%s" % (
    scale, hi.x - lo.x, hi.y - lo.y, hi.z - lo.z,
    os.path.getsize(OUT) / 1e6, [a.name for a in bpy.data.actions]))
