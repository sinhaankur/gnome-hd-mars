"""Headless Blender build of the deployment craft for the orbital cinematic.

Replaces the primitive-box placeholders in scripts/orbital_ships.gd (which read as
"fake" — a grey slab, a sky-blue box, a green cuboid "mech") with real paneled GLB
assets: a drop-lander sub-ship and a HAWC-carrier pod that reads as a mech in a
drop-frame. Runs with `blender --background --python` so it NEVER touches the
artist's open GUI scene (which holds unrelated aircraft work).

Materials are Principled-BSDF only (the only thing that survives GLB export);
Mars/faction tinting is applied in Godot shaders, not baked here.
"""
import bpy, bmesh, math, os, random
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)

OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"


# ---------------------------------------------------------------- materials
def mat(name, color, metal=0.7, rough=0.5, emit=None, emit_str=4.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    if emit is not None:
        bsdf.inputs["Emission Color"].default_value = (*emit, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit_str
    return m


# weathered corporate-cargo palette — matches the dropship/installation, never neon
HULL   = mat("ship_hull",    (0.42, 0.41, 0.39), 0.85, 0.45)
PANEL  = mat("ship_panel",   (0.34, 0.33, 0.32), 0.85, 0.55)
DARK   = mat("ship_dark",    (0.14, 0.14, 0.16), 0.80, 0.50)
ACCENT = mat("ship_accent",  (0.80, 0.42, 0.10), 0.60, 0.50)
GLASS  = mat("ship_glass",   (0.05, 0.07, 0.09), 0.30, 0.08)   # dark tinted canopy, NOT a blue box
GLOW   = mat("ship_glow",    (1.00, 0.55, 0.20), 0.00, 0.40, (1.0, 0.45, 0.15), 6.0)
MECH   = mat("pod_mech",     (0.30, 0.32, 0.34), 0.80, 0.55)
MECHW  = mat("pod_mech_warn",(0.75, 0.55, 0.12), 0.60, 0.50)


# ---------------------------------------------------------------- primitives
def _deselect_all():
    for ob in bpy.context.scene.objects:
        ob.select_set(False)


def cube(name, size, loc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    o.rotation_euler = rot
    o.data.materials.append(m)
    return o


def cyl(name, r, h, loc, m, rot=(0, 0, 0), verts=16):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, vertices=verts)
    o = bpy.context.active_object
    o.name = name
    o.rotation_euler = rot
    o.data.materials.append(m)
    return o


def bevel(o, width=0.03, segs=1):
    # a small bevel on every hard edge is the single biggest "not a flat box" win
    _deselect_all()
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    b = o.modifiers.new("bevel", 'BEVEL')
    b.width = width
    b.segments = segs
    b.limit_method = 'ANGLE'
    b.angle_limit = math.radians(40)
    bpy.ops.object.modifier_apply(modifier=b.name)
    bpy.ops.object.shade_flat()


def squash_verts(o, fn):
    """Edit-mode vertex tweak via a callback fn(v) mutating v.co in place."""
    _deselect_all()
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT')
    bm = bmesh.from_edit_mesh(o.data)
    for v in bm.verts:
        fn(v)
    bmesh.update_edit_mesh(o.data)
    bpy.ops.object.mode_set(mode='OBJECT')


def join_as(name, parts):
    _deselect_all()
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    j = bpy.context.active_object
    j.name = name
    return j


def export(o, filename):
    _deselect_all()
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT, filename),
        export_format='GLB', use_selection=True,
        export_apply=True, export_yup=True,
    )


# ================================================================ SUB-SHIP
# Tapered lifting-body drop-lander: paneled hull, recessed cockpit, 4 gimbaled
# descent thrusters, ventral cradle rails for the HAWC pod. Local +Z up.
def build_subship():
    parts = []
    hull = cube("sub_hull", (4.4, 7.0, 1.5), (0, 0, 0), HULL)

    def taper(v):
        if v.co.y < 0:            # nose
            v.co.x *= 0.55
            v.co.z *= 0.7
            v.co.y *= 1.15
        if v.co.z > 0:            # wedge top
            v.co.x *= 0.82
    squash_verts(hull, taper)
    bevel(hull, 0.08, 2)
    parts.append(hull)

    spine = cube("sub_spine", (1.0, 5.0, 0.35), (0, 0.4, 0.78), PANEL); bevel(spine, 0.04); parts.append(spine)
    for sx in (-1, 1):
        sp = cube("sub_side", (0.25, 4.6, 1.1), (sx * 2.05, 0.2, 0.0), PANEL); bevel(sp); parts.append(sp)

    # cockpit RECESSED into the dorsal nose: a dark socket sunk flush, canopy tucked in it
    socket = cube("sub_cockpit", (1.7, 1.8, 0.5), (0, -2.3, 0.6), DARK); bevel(socket); parts.append(socket)
    canopy = cube("sub_canopy", (1.35, 1.5, 0.35), (0, -2.35, 0.82), GLASS)
    squash_verts(canopy, lambda v: setattr(v.co, 'z', v.co.z - 0.18) if v.co.y < 0 else None)
    bevel(canopy, 0.02); parts.append(canopy)

    for sx in (-1, 1):
        st = cube("sub_stripe", (0.12, 4.0, 0.3), (sx * 2.18, 0.2, 0.1), ACCENT); parts.append(st)

    # 4 descent thrusters, mounted UP INTO the belly so they read as engines, not loose bells.
    # Pylons overlap the hull; gimbal ring + short nozzle sit just below the belly (z=-0.75).
    for sx in (-1, 1):
        for sy in (-1, 1):
            px, py = sx * 1.55, sy * 2.2
            pyl = cube("sub_pylon", (0.7, 0.7, 0.6), (px, py, -0.6), DARK); bevel(pyl); parts.append(pyl)
            ring = cyl("sub_gimbal", 0.6, 0.3, (px, py, -0.95), PANEL); parts.append(ring)
            noz = cyl("sub_nozzle", 0.5, 0.6, (px, py, -1.25), DARK)
            squash_verts(noz, lambda v: (setattr(v.co, 'x', v.co.x * 1.4), setattr(v.co, 'y', v.co.y * 1.4)) if v.co.z < 0 else None)
            parts.append(noz)
            glo = cyl("sub_glow", 0.44, 0.15, (px, py, -1.5), GLOW); parts.append(glo)

    # ventral cradle rails hug the belly centre (where the HAWC pod docks)
    for sx in (-1, 1):
        rail = cube("sub_rail", (0.3, 4.2, 0.4), (sx * 1.1, 0.2, -0.95), DARK); bevel(rail); parts.append(rail)
    cross = cube("sub_cross", (2.6, 0.4, 0.35), (0, 1.6, -0.95), DARK); bevel(cross); parts.append(cross)

    # greebles SUNK onto the dorsal skin (z just below the hull top ~0.78) so they read as
    # hull detail, not floating debris
    random.seed(7)
    for i in range(9):
        gg = cube("sub_greeble",
                  (random.uniform(0.25, 0.5), random.uniform(0.3, 0.7), 0.12),
                  (random.uniform(-1.3, 1.3), random.uniform(-1.0, 2.6), 0.72),
                  PANEL if i % 2 else DARK)
        parts.append(gg)

    ship = join_as("SubShip", parts)
    export(ship, "subship.glb")
    return ship


# ================================================================ HAWC POD
# A mech clamped in an armored drop-frame — reads as cargo, not a green box.
def build_pod():
    # A CLEAN mech silhouette held by two hazard clamp-arms + a docking spine. Kept simple
    # and TIGHT: in the cinematic this is a small shape docked under the sub-ship, so a
    # legible mech beats an elaborate cage that reads as an exploded diagram.
    # ALL parts centred on y=0 (depth) so it reads as one flat, coherent machine —
    # the earlier version staggered parts in Y and looked exploded from the side.
    parts = []
    # docking spine flush behind the torso (thin, just proud of the back at y=-0.8)
    spine = cube("pod_spine", (0.8, 0.5, 4.4), (0, -0.85, 0.4), DARK); bevel(spine, 0.04); parts.append(spine)
    torso = cube("pod_torso", (2.0, 1.4, 2.3), (0, 0, 1.2), MECH); bevel(torso, 0.06, 2); parts.append(torso)
    chest = cube("pod_chest", (1.3, 0.5, 1.1), (0, 0.55, 1.4), MECHW); bevel(chest, 0.04); parts.append(chest)  # front cockpit slab
    head = cube("pod_head", (1.0, 1.0, 0.8), (0, 0.0, 2.5), MECH); bevel(head, 0.05); parts.append(head)
    visor = cube("pod_visor", (0.8, 0.15, 0.3), (0, 0.52, 2.55), GLOW); parts.append(visor)
    for sx in (-1, 1):
        sh = cube("pod_shoulder", (0.95, 1.2, 1.0), (sx * 1.35, 0, 1.75), MECH); bevel(sh, 0.05); parts.append(sh)
        arm = cube("pod_arm", (0.7, 0.7, 1.8), (sx * 1.4, 0, 0.55), MECH); bevel(arm, 0.05); parts.append(arm)
        leg = cube("pod_leg", (0.85, 0.9, 2.0), (sx * 0.5, 0, -0.75), MECH); bevel(leg, 0.05); parts.append(leg)
        foot = cube("pod_foot", (1.0, 1.4, 0.45), (sx * 0.5, 0.2, -1.85), MECH); bevel(foot); parts.append(foot)
    # two hazard clamp-bars across the FRONT of the torso (y at the torso's front face)
    for sz in (0.35, 1.85):
        clamp = cube("pod_clamp", (2.5, 0.35, 0.4), (0, 0.75, sz), MECHW); bevel(clamp); parts.append(clamp)
    # lift eye on top-rear where the dropship cable hooks
    eye = cyl("pod_eye", 0.4, 0.5, (0, -0.8, 2.85), ACCENT, rot=(math.radians(90), 0, 0)); parts.append(eye)

    pod = join_as("HawcPod", parts)
    export(pod, "hawc_pod.glb")
    return pod


sub = build_subship()
pod = build_pod()
print("SHIP_BUILD_OK subship_verts=%d pod_verts=%d subship_dims=%s pod_dims=%s" % (
    len(sub.data.vertices), len(pod.data.vertices),
    [round(d, 2) for d in sub.dimensions], [round(d, 2) for d in pod.dimensions]))
