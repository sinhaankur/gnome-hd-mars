"""Normalize the on-foot pilot GLB from a rigged, animated HALO-style trooper.

The old pilot was a capsule + sphere + 3 boxes ("doesn't even look human"); a first
attempt with a CC0 KayKit body read as a baby (chibi proportions). This uses a REAL
armored adult trooper:

  master_chief.glb — "Halo-Infinite-Master-Chief-rigged-walk" by bensimulator2,
                     CC-BY (credit in CREDITS.md). 113-bone rig, ~29.5k tris, one
                     "Walk" action. Armored HALO-style silhouette, adult proportions.

We keep the rig + its Walk clip, normalize to the contract (1.9 m tall, Y-up, base at
Y=0, forward -Z), and export. The game's MechAnimator plays Walk when moving and holds
a paused Walk frame as the idle pose (no separate idle clip needed).

Run headless:
    /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
        --python tools/build_pilot.py
"""
import bpy
import os
import math
import mathutils

SRC = "/Users/sinhaankur/Downloads/G-Nome_ISO/blender_assets/sketchfab_src/pilot_src"
SRC_MODEL = "master_chief.glb"
OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets/pilot_human.glb"
TARGET_H = 1.9           # Master Chief is tall; real-metres height
JUNK = {"Icosphere", "Cube", "Camera", "Light"}   # drop any uploader junk


def _clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _import(name):
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, name))


def build():
    # 1) import the rigged trooper (armature + armor meshes + its Walk action)
    _clear()
    _import(SRC_MODEL)

    # drop any uploader junk; keep armature + armor meshes
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and o.name.split(".")[0] in JUNK:
            bpy.data.objects.remove(o, do_unlink=True)
        elif o.type in {'CAMERA', 'LIGHT'}:
            bpy.data.objects.remove(o, do_unlink=True)

    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')

    # 2) THE REAL BUG (found 2026-11-23): the Sketchfab root empty carries a baked -90deg X
    #    world rotation. Blender's importer compensates so the skeleton SHOWS upright (feet at
    #    Z~0, head at Z~2.9), but on glTF Y-up re-export that baked -90X double-applies and the
    #    pilot lies down in Godot. FIX: bake the whole hierarchy's transforms flat so there's no
    #    hidden rotation for the exporter to mishandle. We unparent the armature (keep transform),
    #    drop the now-empty Sketchfab hierarchy, and apply the armature's transform. The skeleton
    #    is genuinely upright, so its own "Walk" clip then plays correctly standing.
    #    Keep the Walk action (do NOT delete) — the skeleton was never the problem, the root
    #    transform was.
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    # unparent armature + its mesh children, keeping world transform (Alt+P "clear and keep")
    bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
    # also unparent the skinned meshes from the armature-empty chain while keeping their skin
    # (meshes stay parented to the armature via the Armature modifier, not object parenting)
    bpy.context.view_layer.update()
    # drop leftover empties (Sketchfab_model / RootNode / fbx / Object_2) now that nothing needs them
    for o in list(bpy.data.objects):
        if o.type == 'EMPTY':
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.context.view_layer.update()
    # bake the armature's (now world-correct) rotation+scale into its data so the export is clean
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.context.view_layer.update()

    # 3) scale to 1.9 m and base to Z=0. Measure at REST (stable bounds). Scale is applied into
    #    the armature data too (consistent with the rotation we just baked) so the exported rig
    #    is clean; only the final location stays on the node (a translation Godot honours).
    arm.data.pose_position = 'REST'
    bpy.context.view_layer.update()

    def world_bounds():
        bpy.context.view_layer.update()
        deps = bpy.context.evaluated_depsgraph_get()
        lo = mathutils.Vector((1e18,) * 3); hi = -lo
        for o in bpy.data.objects:
            if o.type != 'MESH':
                continue
            oe = o.evaluated_get(deps)
            for c in oe.bound_box:
                w = oe.matrix_world @ mathutils.Vector(c)
                lo = mathutils.Vector((min(lo[i], w[i]) for i in range(3)))
                hi = mathutils.Vector((max(hi[i], w[i]) for i in range(3)))
        return lo, hi

    lo, hi = world_bounds()
    d = hi.z - lo.z
    s = TARGET_H / d if d > 1e-5 else 1.0
    arm.scale = (arm.scale.x * s, arm.scale.y * s, arm.scale.z * s)
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.context.view_layer.update()

    lo, hi = world_bounds()
    cx = (lo.x + hi.x) / 2; cy = (lo.y + hi.y) / 2
    arm.location = (arm.location.x - cx, arm.location.y - cy, arm.location.z - lo.z)
    bpy.context.view_layer.update()
    lo, hi = world_bounds()
    print("NORM  scaled_h=%.3f base=%.3f cX=%.3f cY=%.3f  (s=%.3f)"
          % (hi.z - lo.z, lo.z, (lo.x + hi.x) / 2, (lo.y + hi.y) / 2, s))

    # 4) KEEP the Walk clip: put it on an NLA strip so the glTF exporter emits it. The skeleton
    #    is now genuinely upright (root -90X baked out), so Walk plays standing. MechAnimator in
    #    Godot drives it on move and holds a paused frame as idle.
    arm.data.pose_position = 'POSE'
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = None
    for a in list(bpy.data.actions):
        a.use_fake_user = True
        track = arm.animation_data.nla_tracks.new()
        track.name = a.name
        track.strips.new(a.name, int(a.frame_range[0]), a)

    # 5) export rigged GLB (Y-up, keep armature + skins + both animations)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=OUT, export_format='GLB', use_selection=True,
        export_yup=True, export_apply=False,
        export_animations=True, export_skins=True)

    tris = sum(len(m.data.polygons) for m in bpy.data.objects if m.type == 'MESH')
    print("PILOT_OK  tris=%d  actions=%s  %.2f MB  -> %s" % (
        tris, [a.name for a in bpy.data.actions],
        os.path.getsize(OUT) / 1e6, OUT))


if __name__ == "__main__":
    build()
