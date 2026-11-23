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

    # 2) The source "Walk" action genuinely TIPS THE BODY OVER in Godot (confirmed in-engine
    #    2026-11-23 — the pilot lay crumpled on the ground once the clip played; the clip was
    #    authored in a different up-axis). We can't rotate it out (animated bones ignore an
    #    object rotation). So DROP the animation and ship the clean upright REST pose — a
    #    correct standing armored trooper. A retargeted walk is tracked (task #10). Keep the
    #    rig so that retarget is possible later.
    arm.data.pose_position = 'REST'
    if arm.animation_data:
        for t in list(arm.animation_data.nla_tracks):
            arm.animation_data.nla_tracks.remove(t)
        arm.animation_data.action = None
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)

    # 4) normalize to the contract. Rig root is the armature; the whole hierarchy hangs off
    #    it, so scaling + moving the armature node moves everything and (with export_apply
    #    =False) the glTF exporter writes that node transform cleanly — no risky apply on a
    #    rig that already carries NLA strips. Measure at the REST pose (stable bounds).
    root = arm
    while root.parent is not None:
        root = root.parent
    # force rest pose for a clean measurement (animated poses move the bounds around)
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
    root.scale = (root.scale.x * s, root.scale.y * s, root.scale.z * s)
    bpy.context.view_layer.update()

    lo, hi = world_bounds()
    cx = (lo.x + hi.x) / 2; cy = (lo.y + hi.y) / 2
    root.location = (root.location.x - cx, root.location.y - cy, root.location.z - lo.z)
    bpy.context.view_layer.update()
    lo, hi = world_bounds()
    print("NORM  scaled_h=%.3f base=%.3f cX=%.3f cY=%.3f  (s=%.3f)"
          % (hi.z - lo.z, lo.z, (lo.x + hi.x) / 2, (lo.y + hi.y) / 2, s))
    # restore pose mode so animations play on import
    arm.data.pose_position = 'POSE'

    # 5) export rigged GLB (Y-up, keep armature + skins + both animations)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=OUT, export_format='GLB', use_selection=True,
        export_yup=True, export_apply=False,
        export_animations=False, export_skins=True)

    tris = sum(len(m.data.polygons) for m in bpy.data.objects if m.type == 'MESH')
    print("PILOT_OK  tris=%d  actions=%s  %.2f MB  -> %s" % (
        tris, [a.name for a in bpy.data.actions],
        os.path.getsize(OUT) / 1e6, OUT))


if __name__ == "__main__":
    build()
