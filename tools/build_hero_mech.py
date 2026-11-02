"""Headless Blender build of the PLAYER hero HAWC — 100% our own geometry.

Replaces the borrowed CC-BY `hero_striker.glb` ("Medium Mech Striker" by MSGDI) with a
fully-custom, licensing-safe mech so the game's hero asset is ours. Depth-first: this is
the ONE mech we build to final quality first (project rule: "one great mech, then scale").

Contract the game expects (godot/scripts/mission1.gd + mech_animator.gd), DO NOT break:
  * ~7 m tall at identity scale (HERO_SCALE = 1.0 in mission1.gd).
  * Y-up, feet at Y = 0 (align_foot in Godot references a clean base).
  * -Z forward (faces away from camera on spawn).
  * A skinned armature + an AnimationPlayer with a WALK clip named "Motion"
    (mech_animator.gd's preferred clip), plus "Idle" and "Jump".

Silhouette (design/ASSET_BUILD_LIST.md §1 "Player hero — compact biped"):
  compact biped, cockpit/canopy, shoulder missile pods, a gun-arm, chunky digitigrade
  legs with splayed feet. Faction tint is applied by a Godot shader, so geometry is
  faction-NEUTRAL Union grey-steel with an emissive weapon/cockpit glow.

Runs headless so it NEVER touches the artist's open GUI scene:
  /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/build_hero_mech.py
Output: godot/assets/hero_striker.glb  (same path = zero Godot code change).
"""
import bpy, bmesh, math, os
from mathutils import Vector, Matrix

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.frame_set(1)

OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"

# ---- build in BLENDER's native Z-up metres, export with export_yup=True ----
# We author the mech standing on the Z=0 plane, facing -Y (Blender forward). The glTF
# exporter's Y-up conversion turns that into Godot's Y-up / -Z-forward automatically.
TARGET_H = 7.0   # metres, tip of cockpit to sole of foot


# ================================================================ materials
# Principled-BSDF only (the only thing that survives GLB export). Union-neutral
# grey-steel; Godot's Faction shader recolors the hull, the glow stays.
def mat(name, color, metal=0.8, rough=0.5, emit=None, emit_str=5.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if emit is not None:
        b.inputs["Emission Color"].default_value = (*emit, 1.0)
        b.inputs["Emission Strength"].default_value = emit_str
    return m


HULL   = mat("hero_hull",   (0.44, 0.45, 0.47), 0.80, 0.48)   # tinted per faction in Godot
PLATE  = mat("hero_plate",  (0.34, 0.35, 0.37), 0.82, 0.55)   # darker armor panels
DARK   = mat("hero_dark",   (0.12, 0.12, 0.14), 0.75, 0.50)   # recesses, joints, sockets
ACCENT = mat("hero_accent", (0.78, 0.40, 0.10), 0.55, 0.45)   # hazard trim
GLASS  = mat("hero_glass",  (0.05, 0.10, 0.14), 0.30, 0.08,
             emit=(0.10, 0.45, 0.70), emit_str=2.0)            # cockpit canopy, soft blue glow
GLOW   = mat("hero_glow",   (1.0, 0.55, 0.20), 0.0, 0.40, (1.0, 0.45, 0.15), 7.0)  # muzzle/thruster


# ================================================================ primitives
def _deselect():
    for o in bpy.context.scene.objects:
        o.select_set(False)


def cube(name, size, loc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    o.rotation_euler = rot
    o.data.materials.append(m)
    return o


def cyl(name, r, h, loc, m, rot=(0, 0, 0), verts=20):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, vertices=verts)
    o = bpy.context.active_object
    o.name = name
    o.rotation_euler = rot
    o.data.materials.append(m)
    return o


def sphere(name, r, loc, m, segs=16):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=segs, ring_count=segs // 2)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(m)
    bpy.ops.object.shade_smooth()
    return o


def bevel(o, width=0.03, segs=2):
    # a small bevel on every hard edge is the biggest "not a flat box" win
    _deselect(); o.select_set(True); bpy.context.view_layer.objects.active = o
    b = o.modifiers.new("bevel", 'BEVEL')
    b.width = width; b.segments = segs
    b.limit_method = 'ANGLE'; b.angle_limit = math.radians(40)
    bpy.ops.object.modifier_apply(modifier=b.name)


def join_as(name, parts):
    _deselect()
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    j = bpy.context.active_object
    j.name = name
    return j


# ================================================================ geometry
# Authored in Z-up metres, standing on Z=0, facing -Y. Rough proportions of a ~6 m
# model that we scale to exactly TARGET_H at the end.
# Left side built explicitly; right side is a mirror we bake in.

HIP_Z = 2.6           # pelvis height off the ground
SHOULDER_Z = 4.9      # shoulder height
LEG_X = 0.62          # leg offset from centre

parts = []

# ---- pelvis / core ----
pelvis = cube("pelvis", (1.7, 1.2, 0.9), (0, 0, HIP_Z), PLATE); parts.append(pelvis)
# ---- torso: a bevelled wedge that tapers forward (reads as a chest, not a box) ----
torso = cube("torso", (2.1, 1.5, 1.7), (0, -0.1, HIP_Z + 1.35), HULL)
def _taper_torso(v):
    # pinch the top-front so the chest slopes
    if v.co.z > 0:
        v.co.y += 0.22
    if v.co.z > 0 and v.co.y < 0:
        v.co.x *= 0.82
_deselect(); torso.select_set(True); bpy.context.view_layer.objects.active = torso
bpy.ops.object.mode_set(mode='EDIT')
bm = bmesh.from_edit_mesh(torso.data)
for v in bm.verts:
    _taper_torso(v)
bmesh.update_edit_mesh(torso.data)
bpy.ops.object.mode_set(mode='OBJECT')
parts.append(torso)

# ---- cockpit: angled canopy on the chest front (the "hero" read) ----
canopy = cube("canopy", (1.1, 0.6, 0.7), (0, -0.95, SHOULDER_Z - 0.2), GLASS,
              rot=(math.radians(22), 0, 0)); parts.append(canopy)
cowl = cube("cowl", (1.35, 0.7, 0.35), (0, -0.75, SHOULDER_Z + 0.35), PLATE); parts.append(cowl)

# ---- shoulder missile pods (both sides) ----
for sx in (-1, 1):
    pod = cube("pod_%d" % sx, (0.9, 1.3, 0.8), (sx * 1.55, -0.1, SHOULDER_Z + 0.25), PLATE)
    parts.append(pod)
    # tubes: a 2x3 grid of dark bores facing forward
    for i in range(2):
        for j in range(3):
            tube = cyl("tube_%d_%d_%d" % (sx, i, j), 0.12, 0.5,
                       (sx * 1.55 + (i - 0.5) * 0.4, -0.8, SHOULDER_Z + 0.55 - j * 0.32),
                       DARK, rot=(math.radians(90), 0, 0), verts=10)
            parts.append(tube)

# ---- shoulders / arms ----
# LEFT: a plain armored arm (the "free" hand). RIGHT: a gun-arm with a barrel.
for sx in (-1, 1):
    sh = sphere("shoulder_%d" % sx, 0.62, (sx * 1.35, -0.1, SHOULDER_Z), HULL)
    parts.append(sh)
    upper = cube("upper_%d" % sx, (0.7, 0.7, 1.5), (sx * 1.5, -0.1, SHOULDER_Z - 0.9), HULL)
    parts.append(upper)
    elbow = sphere("elbow_%d" % sx, 0.4, (sx * 1.5, -0.1, SHOULDER_Z - 1.7), DARK)
    parts.append(elbow)
    if sx == 1:
        # gun-arm: boxy forearm + a protruding cannon barrel + muzzle glow
        fore = cube("forearm_%d" % sx, (0.75, 1.0, 1.1), (sx * 1.5, -0.25, SHOULDER_Z - 2.35), PLATE)
        parts.append(fore)
        barrel = cyl("barrel", 0.26, 1.6, (sx * 1.5, -1.0, SHOULDER_Z - 2.35), DARK,
                     rot=(math.radians(90), 0, 0)); parts.append(barrel)
        muzzle = cyl("muzzle", 0.3, 0.2, (sx * 1.5, -1.85, SHOULDER_Z - 2.35), GLOW,
                     rot=(math.radians(90), 0, 0)); parts.append(muzzle)
    else:
        # free arm: forearm + a simple 3-finger clamp hand
        fore = cube("forearm_%d" % sx, (0.6, 0.6, 1.3), (sx * 1.5, -0.1, SHOULDER_Z - 2.3), HULL)
        parts.append(fore)
        hand = cube("hand_%d" % sx, (0.55, 0.7, 0.5), (sx * 1.5, -0.1, SHOULDER_Z - 3.05), DARK)
        parts.append(hand)

# ---- legs (digitigrade: thigh angled fwd, shin angled back, splayed foot) ----
for sx in (-1, 1):
    hipj = sphere("hipj_%d" % sx, 0.5, (sx * LEG_X, 0, HIP_Z - 0.3), DARK)
    parts.append(hipj)
    thigh = cube("thigh_%d" % sx, (0.85, 0.95, 1.5), (sx * LEG_X, -0.15, HIP_Z - 1.15), HULL,
                 rot=(math.radians(-10), 0, 0)); parts.append(thigh)
    knee = sphere("knee_%d" % sx, 0.42, (sx * LEG_X, 0.1, HIP_Z - 2.0), DARK)
    parts.append(knee)
    shin = cube("shin_%d" % sx, (0.7, 0.8, 1.5), (sx * LEG_X, 0.05, HIP_Z - 2.85), PLATE,
                rot=(math.radians(12), 0, 0)); parts.append(shin)
    ankle = sphere("ankle_%d" % sx, 0.34, (sx * LEG_X, -0.1, HIP_Z - 3.6), DARK)
    parts.append(ankle)
    # splayed foot: a flat sole plate + two forward toes (reads planted, not a peg)
    foot = cube("foot_%d" % sx, (0.95, 1.8, 0.35), (sx * LEG_X, -0.35, 0.2), PLATE)
    parts.append(foot)
    for tx in (-0.28, 0.28):
        toe = cube("toe_%d_%d" % (sx, int(tx * 100)), (0.34, 0.6, 0.28),
                   (sx * LEG_X + tx, -1.1, 0.16), DARK)
        parts.append(toe)

# bevel every part before the join (sharp boxes read as placeholder slop)
for p in parts:
    bevel(p, width=0.035, segs=2)

mech = join_as("HeroHAWC", parts)

# ---- seat on Z=0 + centre on X/Y (NO scaling yet) --------------------------
# We author the rig at these same seated coords, parent, THEN scale the whole
# rig+mesh assembly once at the end — so geometry and bones never drift apart.
_deselect(); mech.select_set(True); bpy.context.view_layer.objects.active = mech
bpy.context.view_layer.update()
bb = [mech.matrix_world @ Vector(c) for c in mech.bound_box]
minx = min(v.x for v in bb); maxx = max(v.x for v in bb)
miny = min(v.y for v in bb); maxy = max(v.y for v in bb)
minz = min(v.z for v in bb)
mech.location.x -= (minx + maxx) / 2
mech.location.y -= (miny + maxy) / 2
mech.location.z -= minz                       # feet -> Z=0
bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
bpy.ops.object.shade_flat()

# the amount we lowered the geometry by (authored HIP_Z etc. shift by the same)
z_off = minz
# authored landmark heights, re-seated to Z=0 (bones live in the SAME space as geo)
hip_z   = HIP_Z - z_off
knee_z  = (HIP_Z - 2.0) - z_off
ankle_z = (HIP_Z - 3.6) - z_off
sh_z    = SHOULDER_Z - z_off
elb_z   = (SHOULDER_Z - 1.7) - z_off
leg_x   = LEG_X
arm_x   = 1.5
H = 1.0   # placeholder; foot/arm tail lengths use fixed metres below


# ================================================================ armature
arm = bpy.data.armatures.new("HeroRig")
rig = bpy.data.objects.new("HeroRig", arm)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
eb = arm.edit_bones


def bone(name, head, tail, parent=None, connect=False):
    b = eb.new(name)
    b.head = head; b.tail = tail
    if parent:
        b.parent = parent
        b.use_connect = connect
    return b


root  = bone("Root",  (0, 0, 0),            (0, 0, hip_z * 0.5))
hips  = bone("Hips",  (0, 0, hip_z),        (0, 0, hip_z + 0.4), root)
spine = bone("Spine", (0, 0, hip_z + 0.4),  (0, 0, sh_z),        hips, True)
chest = bone("Chest", (0, 0, sh_z),         (0, 0, sh_z + 0.6),  spine, True)

legs = {}
for side, sx in (("L", -1), ("R", 1)):
    thigh = bone("Thigh.%s" % side, (sx * leg_x, 0, hip_z), (sx * leg_x, 0, knee_z), hips)
    shin  = bone("Shin.%s" % side,  (sx * leg_x, 0, knee_z), (sx * leg_x, 0, ankle_z), thigh, True)
    foot  = bone("Foot.%s" % side,  (sx * leg_x, 0, ankle_z), (sx * leg_x, -1.2, 0), shin, True)
    legs[side] = (thigh, shin, foot)

arms = {}
for side, sx in (("L", -1), ("R", 1)):
    up  = bone("UpperArm.%s" % side, (sx * arm_x, 0, sh_z), (sx * arm_x, 0, elb_z), chest)
    low = bone("LowerArm.%s" % side, (sx * arm_x, 0, elb_z), (sx * arm_x, 0, elb_z - 1.2), up, True)
    arms[side] = (up, low)

bpy.ops.object.mode_set(mode='OBJECT')

# ---- skin: parent mesh to armature with automatic weights ----
# (one merged mech mesh; auto weights are fine for a rigid-ish mech where we only
#  need plausible leg swing + arm sway, not organic deformation)
_deselect()
mech.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')

# ---- scale the WHOLE assembly (rig + child mesh) to exactly TARGET_H --------
# Done once, after skinning, so bones and geometry stay locked together.
_deselect(); rig.select_set(True); bpy.context.view_layer.objects.active = rig
bpy.context.view_layer.update()
# measure current world height from the mesh child
mbb = [mech.matrix_world @ Vector(c) for c in mech.bound_box]
cur_h = max(v.z for v in mbb) - min(v.z for v in mbb)
s = TARGET_H / cur_h
rig.scale = (s, s, s)
# apply scale to rig + mesh together (select both so apply recurses)
mech.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
# re-seat feet on Z=0 after scaling
bpy.context.view_layer.update()
mbb = [mech.matrix_world @ Vector(c) for c in mech.bound_box]
dz = min(v.z for v in mbb)
rig.location.z -= dz
bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)


# ================================================================ animation
# Three clips via NLA: Idle (subtle), Motion (walk cycle), Jump (tuck + land).
# mech_animator.gd plays "Motion" on move, seeks a frame for idle, and plays a
# jump clip while airborne.
rig.animation_data_create()
scene = bpy.context.scene
scene.render.fps = 24


def pb(name):
    return rig.pose.bones[name]


def key_pose(frame, pose_fn):
    scene.frame_set(frame)
    pose_fn()
    for b in rig.pose.bones:
        b.keyframe_insert("rotation_quaternion", frame=frame)
        b.keyframe_insert("location", frame=frame)


def clear_pose():
    bpy.ops.object.mode_set(mode='POSE')
    bpy.ops.pose.select_all(action='SELECT')
    bpy.ops.pose.transforms_clear()


def rotx(bone_name, deg):
    import mathutils
    pb(bone_name).rotation_mode = 'QUATERNION'
    pb(bone_name).rotation_quaternion = mathutils.Quaternion((1, 0, 0), math.radians(deg))


def push_action(name, start, end):
    act = rig.animation_data.action
    act.name = name
    # use_fake_user so the action survives even with no strip, then push to NLA
    act.use_fake_user = True
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, int(start), act)
    rig.animation_data.action = None
    return act


bpy.ops.object.mode_set(mode='POSE')
for b in rig.pose.bones:
    b.rotation_mode = 'QUATERNION'

# ---------- Idle: slow weight-shift, arms hang, a tiny breathing bob ----------
rig.animation_data.action = bpy.data.actions.new("Idle")
clear_pose()
def idle_a():
    rotx("Spine", 2); rotx("Thigh.L", 1); rotx("Thigh.R", -1)
def idle_b():
    rotx("Spine", -2); rotx("Thigh.L", -1); rotx("Thigh.R", 1)
key_pose(1, idle_a)
key_pose(24, idle_b)
key_pose(48, idle_a)
scene.frame_start = 1; scene.frame_end = 48
push_action("Idle", 1, 48)

# ---------- Motion: a 2-step walk cycle (what MechAnimator drives) ----------
rig.animation_data.action = bpy.data.actions.new("Motion")
clear_pose()
# contact L fwd / R back -> pass -> contact R fwd / L back -> pass -> loop
def walk_contactL():
    rotx("Thigh.L", 24); rotx("Shin.L", -8);  rotx("Foot.L", -10)
    rotx("Thigh.R", -22); rotx("Shin.R", 18); rotx("Foot.R", 8)
    rotx("UpperArm.L", -18); rotx("UpperArm.R", 18); rotx("Spine", 3)
def walk_passL():
    rotx("Thigh.L", 0); rotx("Shin.L", 10)
    rotx("Thigh.R", 0); rotx("Shin.R", 10)
    rotx("UpperArm.L", 0); rotx("UpperArm.R", 0)
def walk_contactR():
    rotx("Thigh.R", 24); rotx("Shin.R", -8);  rotx("Foot.R", -10)
    rotx("Thigh.L", -22); rotx("Shin.L", 18); rotx("Foot.L", 8)
    rotx("UpperArm.R", -18); rotx("UpperArm.L", 18); rotx("Spine", -3)
def walk_passR():
    rotx("Thigh.L", 0); rotx("Shin.L", 10)
    rotx("Thigh.R", 0); rotx("Shin.R", 10)
    rotx("UpperArm.L", 0); rotx("UpperArm.R", 0)
key_pose(1, walk_contactL)
key_pose(7, walk_passL)
key_pose(13, walk_contactR)
key_pose(19, walk_passR)
key_pose(25, walk_contactL)   # == frame 1, closes the loop
scene.frame_start = 1; scene.frame_end = 24
push_action("Motion", 1, 24)

# ---------- Jump: crouch -> launch tuck -> land absorb ----------
rig.animation_data.action = bpy.data.actions.new("Jump")
clear_pose()
def jump_crouch():
    rotx("Thigh.L", 35); rotx("Shin.L", -45); rotx("Thigh.R", 35); rotx("Shin.R", -45)
    rotx("Spine", 8)
def jump_tuck():
    rotx("Thigh.L", 55); rotx("Shin.L", -70); rotx("Thigh.R", 55); rotx("Shin.R", -70)
    rotx("UpperArm.L", -30); rotx("UpperArm.R", -30); rotx("Spine", -5)
def jump_land():
    rotx("Thigh.L", 30); rotx("Shin.L", -40); rotx("Thigh.R", 30); rotx("Shin.R", -40)
    rotx("Spine", 6)
key_pose(1, jump_crouch)
key_pose(10, jump_tuck)
key_pose(20, jump_land)
scene.frame_start = 1; scene.frame_end = 20
push_action("Jump", 1, 20)

bpy.ops.object.mode_set(mode='OBJECT')


# ================================================================ export
_deselect()
mech.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
scene.frame_set(1)

out_path = os.path.join(OUT, "hero_custom_wip.glb")
bpy.ops.export_scene.gltf(
    filepath=out_path,
    export_format='GLB',
    use_selection=True,
    export_apply=False,          # keep the armature modifier (don't flatten the rig)
    export_yup=True,             # Z-up (Blender) -> Y-up (Godot)
    export_animations=True,
    export_anim_single_armature=True,
    export_nla_strips=True,      # one glTF animation per NLA track (Idle/Motion/Jump)
)
print("WROTE", out_path)
