"""Headless Blender build of the 5 ENEMY HAWC class archetypes.

The Enemy Engine currently routes every archetype (sentry/tactical/heavy/support/
hover) to ONE 243 MB warrior.glb, faction-tinted. That gives zero silhouette variety
and is far too heavy. This script builds five GENUINELY DISTINCT silhouettes so a
player can tell a Sentry from a Heavy at a glance (per design/HAWC_VARIETY_SPEC.md):

  A. sentry   — compact digitigrade biped, shoulder gun pods, cockpit up top   (~6.8 m)
  B. tactical — taller/bulkier biped, back rocket rack, heavier arms           (~8.5 m)
  C. heavy    — massive 4-legged multipedal artillery hull + twin top cannons  (~11 m)
  D. support  — low wide TRACKED tank hull + rotating turret (no legs)         (~3.5 m)
  E. hover    — sleek arrowhead on a glowing skirt, no legs                     (~3 m)

Rule (design spec): SILHOUETTE differs by CLASS; COLOR differs by FACTION. So these
meshes are faction-NEUTRAL grey-steel — Godot's Faction.tint() recolors them per
faction at spawn. We bake NO faction color here.

Runs with `blender --background --python` so it NEVER touches the artist's open GUI
scene. Materials are Principled-BSDF only (all that survives GLB export). Exports:
  enemy_sentry.glb  enemy_tactical.glb  enemy_heavy.glb  enemy_support.glb  enemy_hover.glb

All models built at IDENTITY facing (+Y = forward), feet/base at z=0, so the engine's
existing align_foot + face-flip logic works unchanged. Local +Z is up (Blender);
export_yup swaps to Godot's Y-up on the way out.
"""
import bpy, bmesh, math, os, random
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)

OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"


# ---------------------------------------------------------------- materials
# Faction-NEUTRAL: mid grey-steel hull, darker panels, dark sockets, and an emissive
# weapon glow. Godot's Faction.tint recolors the hull per faction; the glow stays.
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


HULL  = mat("mech_hull",  (0.46, 0.46, 0.48), 0.80, 0.50)   # tinted per faction in Godot
PANEL = mat("mech_panel", (0.34, 0.34, 0.36), 0.85, 0.55)
DARK  = mat("mech_dark",  (0.13, 0.13, 0.15), 0.80, 0.45)   # joints, sockets, barrels
TRACK = mat("mech_track", (0.10, 0.10, 0.11), 0.40, 0.75)   # rubber-ish tracks/skirt
GLOW  = mat("mech_glow",  (1.00, 0.55, 0.20), 0.00, 0.40, (1.0, 0.45, 0.15), 6.0)  # weapon/eye
SKIRT = mat("mech_skirt", (0.20, 0.55, 0.85), 0.00, 0.30, (0.2, 0.6, 1.0), 5.0)    # hover cushion


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
    # a small bevel on every hard edge = the single biggest "not a flat box" win
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
    # drop origin to the base so align_foot in Godot has a clean reference
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    o.location = (0, 0, 0)
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT, filename),
        export_format='GLB', use_selection=True,
        export_apply=True, export_yup=True,
    )


# ---------------------------------------------------------------- shared limbs
def digitigrade_leg(prefix, sx, hip, m):
    """Reverse-jointed bird leg (thigh fwd, knee fwd, shin back to a splayed foot).
    Returns the list of parts. `hip` = (x,y,z) of the hip joint. Faces +Y.

    Segments deliberately OVERLAP at every joint (each spans a little past the next
    joint sphere) so the leg reads as ONE connected limb, not an exploded diagram —
    the failure mode the first render showed. Geometry chain, top -> bottom:
      hip ball (at hip) -> thigh (angled fwd) -> knee ball -> shin (angled back) ->
      ankle ball -> foot pad + toes.  Vertical drop is ~3.0 m so feet land near z=0.
    """
    parts = []
    hx, hy, hz = hip
    # hip ball anchors the leg into the pelvis (overlaps the pelvis body)
    hipb = cyl(prefix + "_hip", 0.45, 0.8, (hx, hy, hz), DARK, rot=(0, math.radians(90), 0)); parts.append(hipb)
    # THIGH: from the hip forward-down to the knee. Longer so it overlaps both joints.
    knee_pos = (hx, hy + 0.7, hz - 1.15)
    thigh = cube(prefix + "_thigh", (0.6, 0.7, 1.7), (hx, hy + 0.35, hz - 0.55), m)
    thigh.rotation_euler = (math.radians(28), 0, 0); bevel(thigh, 0.05); parts.append(thigh)
    knee = cyl(prefix + "_knee", 0.38, 0.75, knee_pos, DARK, rot=(0, math.radians(90), 0)); parts.append(knee)
    # SHIN: from the knee back-down to the ankle (reverse joint = the bird-leg tell).
    ankle_pos = (hx, hy - 0.35, hz - 2.75)
    shin = cube(prefix + "_shin", (0.48, 0.6, 1.9), (hx, hy + 0.2, hz - 1.95), m)
    shin.rotation_euler = (math.radians(-32), 0, 0); bevel(shin, 0.05); parts.append(shin)
    ankle = cyl(prefix + "_ankle", 0.3, 0.6, ankle_pos, DARK, rot=(0, math.radians(90), 0)); parts.append(ankle)
    # FOOT: splayed claw pad tucked right under the ankle + two forward toes (overlap the pad)
    foot = cube(prefix + "_foot", (0.75, 1.6, 0.4), (hx, hy + 0.05, hz - 3.0), m); bevel(foot); parts.append(foot)
    for tsx in (-1, 1):
        toe = cube(prefix + "_toe", (0.24, 0.7, 0.28), (hx + tsx * 0.26, hy + 0.75, hz - 3.02), DARK); bevel(toe); parts.append(toe)
    return parts


def gun_pod(prefix, loc, m, barrels=2, length=1.6, r=0.16):
    """A boxy weapon pod with N glowing-tipped barrels facing +Y (forward)."""
    parts = []
    box = cube(prefix + "_pod", (0.7, 0.8, 0.7), loc, m); bevel(box, 0.04); parts.append(box)
    for i in range(barrels):
        off = (i - (barrels - 1) / 2.0) * 0.28
        bx = loc[0] + off
        bar = cyl(prefix + "_bar%d" % i, r, length, (bx, loc[1] + 0.7, loc[2]), DARK,
                  rot=(math.radians(90), 0, 0)); parts.append(bar)
        tip = cyl(prefix + "_tip%d" % i, r * 0.7, 0.12, (bx, loc[1] + 0.7 + length / 2, loc[2]), GLOW,
                  rot=(math.radians(90), 0, 0)); parts.append(tip)
    return parts


# ================================================================ A. SENTRY
# Compact digitigrade biped: squarish torso, forward cockpit head, twin shoulder
# gun pods, reverse-jointed legs. The agile front-line silhouette (~6.8 m).
def build_sentry():
    parts = []
    # legs first: hips at z=3.9 so the thigh tops reach up and overlap the pelvis body
    parts += digitigrade_leg("s_legL", -0.55, (-0.55, 0, 3.9), HULL)
    parts += digitigrade_leg("s_legR", 0.55, (0.55, 0, 3.9), HULL)
    # pelvis straddles the hips: its body spans z 3.4..4.4, so it fully overlaps the hip
    # balls (z~3.9) below and the torso above — no torso/leg void.
    pelvis = cube("s_pelvis", (1.7, 1.3, 1.4), (0, 0, 4.0), PANEL); bevel(pelvis, 0.05); parts.append(pelvis)
    torso = cube("s_torso", (2.2, 1.5, 2.2), (0, 0, 5.2), HULL); bevel(torso, 0.07, 2); parts.append(torso)
    chest = cube("s_chest", (1.5, 0.5, 1.0), (0, 0.65, 5.4), PANEL); bevel(chest, 0.04); parts.append(chest)
    # cockpit head set FORWARD, its base sunk into the torso top (torso top ~6.3)
    head = cube("s_head", (0.9, 1.1, 0.8), (0, 0.35, 6.35), HULL); bevel(head, 0.05); parts.append(head)
    visor = cube("s_visor", (0.7, 0.14, 0.3), (0, 0.9, 6.4), GLOW); parts.append(visor)
    # shoulders sit ON the torso sides (x overlaps the torso half-width 1.1); gun pods bolt
    # to the shoulders (pod box centered right at the shoulder so nothing floats)
    for sx in (-1, 1):
        sh = cube("s_shoulder", (1.0, 1.1, 1.1), (sx * 1.15, 0, 5.5), HULL); bevel(sh, 0.05); parts.append(sh)
        parts += gun_pod("s_gun%d" % (sx + 1), (sx * 1.35, 0.1, 5.5), PANEL, barrels=2, length=1.4)
    m = join_as("EnemySentry", parts)
    export(m, "enemy_sentry.glb")
    return m


# ================================================================ B. TACTICAL
# Taller, bulkier biped: heavier armor slabs, a BACK ROCKET RACK, chunkier arms.
# Clearly reads as a heavier trooper than the sentry (~8.5 m).
def build_tactical():
    parts = []
    # legs first — hips at z=4.0 tuck up into the pelvis (heavier trooper stands taller)
    parts += digitigrade_leg("t_legL", -0.7, (-0.75, 0, 4.0), HULL)
    parts += digitigrade_leg("t_legR", 0.7, (0.75, 0, 4.0), HULL)
    # pelvis spans z 3.7..5.1 so it overlaps the hips (z~4.0) and the torso above
    pelvis = cube("t_pelvis", (2.1, 1.6, 1.4), (0, 0, 4.4), PANEL); bevel(pelvis, 0.05); parts.append(pelvis)
    torso = cube("t_torso", (2.9, 1.9, 2.6), (0, 0, 5.8), HULL); bevel(torso, 0.08, 2); parts.append(torso)
    # heavy pauldrons cap the shoulders; arms hang off the torso sides (x overlaps the
    # torso half-width 1.45); gun pods bolt onto the arm fronts — nothing floats.
    for sx in (-1, 1):
        paul = cube("t_pauldron", (1.3, 1.6, 0.9), (sx * 1.5, 0, 6.6), HULL); bevel(paul, 0.06); parts.append(paul)
        arm = cube("t_arm", (1.1, 1.1, 2.4), (sx * 1.55, 0.2, 5.6), HULL); bevel(arm, 0.06); parts.append(arm)
        parts += gun_pod("t_gun%d" % (sx + 1), (sx * 1.55, 0.3, 5.0), PANEL, barrels=3, length=1.8, r=0.18)
    head = cube("t_head", (1.1, 1.2, 0.9), (0, 0.3, 7.1), HULL); bevel(head, 0.05); parts.append(head)
    visor = cube("t_visor", (0.85, 0.14, 0.3), (0, 0.9, 7.15), GLOW); parts.append(visor)
    # BACK ROCKET RACK — a canted slab of short tubes sitting low behind the shoulders.
    # Kept SHORT and tucked against the torso back so it doesn't spike the height.
    rack = cube("t_rack", (2.2, 0.7, 1.4), (0, -1.15, 6.3), PANEL)
    rack.rotation_euler = (math.radians(-15), 0, 0); bevel(rack, 0.04); parts.append(rack)
    for rx in range(-1, 2):
        for rz in range(2):
            tube = cyl("t_tube", 0.16, 0.6, (rx * 0.55, -1.4, 6.05 + rz * 0.45), DARK,
                       rot=(math.radians(75), 0, 0)); parts.append(tube)
    m = join_as("EnemyTactical", parts)
    # widen/deepen a touch so it reads bulkier than the sentry, WITHOUT stretching
    # height (the parts are already built taller — an extra Z scale over-stretched it
    # to ~15 m in the first pass). Keep Z at 1.0 so it lands ~8.5 m tall.
    m.scale = (1.12, 1.12, 1.0)
    _deselect_all(); m.select_set(True); bpy.context.view_layer.objects.active = m
    bpy.ops.object.transform_apply(scale=True)
    export(m, "enemy_tactical.glb")
    return m


# ================================================================ C. HEAVY
# Massive 4-legged multipedal artillery: dominant wide hull low-slung between four
# splayed legs, twin big top cannons + a missile block. The boss silhouette (~11 m).
def build_heavy():
    parts = []
    # dominant hull, wide and deep, slung between the legs
    hull = cube("h_hull", (4.6, 5.2, 2.2), (0, 0, 3.6), HULL); bevel(hull, 0.1, 2); parts.append(hull)
    deck = cube("h_deck", (3.6, 4.0, 0.5), (0, 0, 4.9), PANEL); bevel(deck, 0.05); parts.append(deck)
    # forward sensor prow
    prow = cube("h_prow", (2.0, 1.4, 1.0), (0, 2.6, 4.2), HULL); bevel(prow, 0.06); parts.append(prow)
    eye = cube("h_eye", (1.4, 0.16, 0.4), (0, 3.3, 4.3), GLOW); parts.append(eye)
    # TWIN big top cannons pointing forward (the artillery tell)
    for sx in (-1, 1):
        turret = cube("h_turret", (1.3, 1.5, 1.0), (sx * 1.2, 0.4, 5.4), HULL); bevel(turret, 0.05); parts.append(turret)
        barrel = cyl("h_barrel", 0.3, 3.4, (sx * 1.2, 2.0, 5.5), DARK, rot=(math.radians(90), 0, 0)); parts.append(barrel)
        muzz = cyl("h_muzzle", 0.36, 0.4, (sx * 1.2, 3.7, 5.5), GLOW, rot=(math.radians(90), 0, 0)); parts.append(muzz)
    # rear missile block
    mblock = cube("h_missiles", (2.6, 1.0, 1.4), (0, -2.4, 5.2), PANEL); bevel(mblock, 0.04); parts.append(mblock)
    for mx in range(-2, 3):
        for mz in range(2):
            t = cyl("h_mtube", 0.14, 0.5, (mx * 0.5, -2.95, 4.9 + mz * 0.55), DARK,
                    rot=(math.radians(90), 0, 0)); parts.append(t)
    # FOUR splayed legs — thick multi-segment, one at each corner. This is the tell.
    # Segments overlap at the hip ball and the knee so each leg reads as one connected
    # limb bracing out from the hull down to a foot near z=0 (not floating blocks).
    for sx in (-1, 1):
        for sy in (-1, 1):
            hipx, hipy = sx * 2.0, sy * 1.9
            hipjoint = cyl("h_hip", 0.65, 1.1, (hipx, hipy, 3.5), DARK, rot=(0, math.radians(90), 0)); parts.append(hipjoint)
            # upper leg braces outward from the hip (top overlaps the hip ball)
            upper = cube("h_upper", (0.75, 0.75, 1.6), (hipx + sx * 0.75, hipy, 3.0), HULL)
            upper.rotation_euler = (0, math.radians(sx * 42), 0); bevel(upper, 0.05); parts.append(upper)
            knee = cyl("h_knee", 0.45, 0.8, (hipx + sx * 1.45, hipy, 2.3), DARK, rot=(0, math.radians(90), 0)); parts.append(knee)
            # lower leg drops down-and-out to the foot (top overlaps the knee)
            lower = cube("h_lower", (0.6, 0.6, 2.6), (hipx + sx * 1.75, hipy, 1.1), HULL)
            lower.rotation_euler = (0, math.radians(sx * 16), 0); bevel(lower, 0.05); parts.append(lower)
            foot = cube("h_foot", (1.0, 1.1, 0.45), (hipx + sx * 2.05, hipy, 0.15), DARK); bevel(foot); parts.append(foot)
    m = join_as("EnemyHeavy", parts)
    export(m, "enemy_heavy.glb")
    return m


# ================================================================ D. SUPPORT
# Low wide TRACKED tank: sloped hull between two track units, a rotating turret with
# a main gun. No legs at all — the "not a mech" silhouette that reads as armor (~3.5 m).
def build_support():
    parts = []
    # two track runs (long low rounded boxes) flanking the hull, bases at z=0 and tops
    # at z~1.6 so the hull (seated at z=1.2) overlaps them — one chassis, no floating gap
    for sx in (-1, 1):
        track = cube("d_track", (1.2, 5.4, 1.6), (sx * 1.7, 0, 0.8), TRACK)
        bevel(track, 0.28, 3); parts.append(track)   # heavy bevel = rounded track loop
        # road wheels peeking out along the bottom
        for wy in (-2.0, -0.7, 0.7, 2.0):
            w = cyl("d_wheel", 0.55, 0.35, (sx * 1.7, wy, 0.55), DARK, rot=(0, math.radians(90), 0)); parts.append(w)
    # sloped glacis hull SPANNING the two tracks (its sides overlap the inner track faces,
    # so hull+tracks read as one chassis, not a slab hovering over loose treads)
    hull = cube("d_hull", (3.4, 5.0, 1.2), (0, 0, 1.2), HULL); bevel(hull, 0.06, 2)
    squash_verts(hull, lambda v: setattr(v.co, 'z', v.co.z - 0.45) if v.co.y > 2.0 else None)  # front slope
    parts.append(hull)
    # rotating turret + mantlet + long main gun forward, seated on the hull deck
    turret = cube("d_turret", (2.2, 2.2, 1.0), (0, -0.2, 2.2), HULL); bevel(turret, 0.08, 2); parts.append(turret)
    mantlet = cube("d_mantlet", (1.0, 0.8, 0.8), (0, 1.1, 2.2), PANEL); bevel(mantlet, 0.04); parts.append(mantlet)
    gun = cyl("d_gun", 0.24, 3.6, (0, 2.9, 2.2), DARK, rot=(math.radians(90), 0, 0)); parts.append(gun)
    muzz = cyl("d_muzzle", 0.3, 0.5, (0, 4.6, 2.2), GLOW, rot=(math.radians(90), 0, 0)); parts.append(muzz)
    cupola = cube("d_cupola", (0.7, 0.7, 0.5), (0.6, -0.8, 2.8), HULL); bevel(cupola, 0.03); parts.append(cupola)
    m = join_as("EnemySupport", parts)
    export(m, "enemy_support.glb")
    return m


# ================================================================ E. HOVER
# Sleek arrowhead fuselage riding a glowing anti-grav skirt. No legs, no tracks —
# the fast-scout silhouette. Nose-forward, weapon pods on the wing roots (~3 m tall).
def build_hover():
    parts = []
    # glowing skirt cushion — a flat oval pad it floats on (longer fore-aft than wide).
    # radius 1.6 -> ~3.2 m wide, *1.4 in Y -> ~4.5 m long: a sleek scout footprint.
    skirt = cyl("e_skirt", 1.6, 0.5, (0, 0, 0.5), SKIRT, verts=24)
    skirt.scale = (1.0, 1.4, 1.0)
    _deselect_all(); skirt.select_set(True); bpy.context.view_layer.objects.active = skirt
    bpy.ops.object.transform_apply(scale=True)
    parts.append(skirt)
    underglow = cyl("e_underglow", 1.3, 0.15, (0, 0, 0.2), SKIRT, verts=24)
    underglow.scale = (1.0, 1.4, 1.0)
    _deselect_all(); underglow.select_set(True); bpy.context.view_layer.objects.active = underglow
    bpy.ops.object.transform_apply(scale=True); parts.append(underglow)
    # arrowhead fuselage
    body = cube("e_body", (2.4, 4.4, 1.2), (0, 0, 1.4), HULL); bevel(body, 0.08, 2)

    def arrow(v):
        if v.co.y > 0:               # nose taper to a point
            v.co.x *= 0.15
            v.co.z *= 0.6
        if v.co.z > 0:               # canopy wedge
            v.co.x *= 0.7
    squash_verts(body, arrow); parts.append(body)
    # cockpit canopy near the nose
    canopy = cube("e_canopy", (0.9, 1.4, 0.5), (0, 1.0, 1.9), GLOW); bevel(canopy, 0.03); parts.append(canopy)
    # swept wing roots with a weapon pod each
    for sx in (-1, 1):
        wing = cube("e_wing", (1.6, 1.8, 0.3), (sx * 1.6, -0.4, 1.3), PANEL)
        wing.rotation_euler = (0, 0, math.radians(sx * -12)); bevel(wing, 0.04); parts.append(wing)
        pod = cyl("e_pod", 0.3, 1.8, (sx * 2.1, 0.3, 1.2), DARK, rot=(math.radians(90), 0, 0)); parts.append(pod)
        tip = cyl("e_tip", 0.22, 0.16, (sx * 2.1, 1.2, 1.2), GLOW, rot=(math.radians(90), 0, 0)); parts.append(tip)
    # twin rear thruster nacelles
    for sx in (-1, 1):
        naz = cyl("e_thruster", 0.4, 0.8, (sx * 0.8, -2.3, 1.4), DARK, rot=(math.radians(90), 0, 0)); parts.append(naz)
        glo = cyl("e_thglow", 0.34, 0.2, (sx * 0.8, -2.7, 1.4), GLOW, rot=(math.radians(90), 0, 0)); parts.append(glo)
    # tail fin
    fin = cube("e_fin", (0.2, 1.2, 1.2), (0, -1.8, 2.2), HULL); bevel(fin, 0.03); parts.append(fin)
    m = join_as("EnemyHover", parts)
    export(m, "enemy_hover.glb")
    return m


built = []
for fn in (build_sentry, build_tactical, build_heavy, build_support, build_hover):
    # each build leaves only its own joined object; clear scene between builds so
    # join_as never grabs a previous archetype's leftover parts.
    o = fn()
    built.append((o.name, len(o.data.vertices), [round(d, 2) for d in o.dimensions]))
    _deselect_all()
    for ob in list(bpy.context.scene.objects):
        bpy.data.objects.remove(ob, do_unlink=True)

print("MECH_BUILD_OK")
for name, verts, dims in built:
    print("  %-14s verts=%-6d dims(x,y,z)=%s" % (name, verts, dims))
