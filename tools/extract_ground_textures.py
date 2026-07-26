"""Extract the photoreal regolith textures from the Gravel Ground Module Scan (Pers Scans,
CC-BY) so the Mars terrain shader can blend REAL scanned ground over its procedural detail.

The scan's Principled BSDF carries an albedo, a normal map, and an ORM/roughness image.
We save them as PNGs into godot/assets/mars_ground_* so mars_terrain.gd can sample them
triplanar. Only the ground TEXTURES are reused — the scan mesh itself isn't the terrain
(we keep the real HiRISE-displaced walkable terrain). Headless; never touches the GUI scene.
"""
import bpy, os

SRC = "/Users/sinhaankur/Downloads/G-Nome_ISO/blender_assets/sketchfab_src/src_ground_scan.glb"
OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/godot/assets"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)

# find the Principled BSDF and follow its albedo / normal / roughness inputs to images
saved = {}


def _img_from_input(bsdf, input_name):
    inp = bsdf.inputs.get(input_name)
    if not inp or not inp.links:
        return None
    node = inp.links[0].from_node
    # walk through a normal-map / separate-color node to the image
    for _ in range(4):
        if node.type == 'TEX_IMAGE':
            return node.image
        if node.inputs:
            linked = [i for i in node.inputs if i.links]
            if linked:
                node = linked[0].links[0].from_node
                continue
        break
    return None


for mat in bpy.data.materials:
    if not mat.use_nodes:
        continue
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if not bsdf:
        continue
    targets = {
        "albedo": ("Base Color", "mars_ground_albedo.png"),
        "normal": ("Normal", "mars_ground_normal.png"),
        "rough":  ("Roughness", "mars_ground_rough.png"),
    }
    for key, (inp_name, fname) in targets.items():
        if key in saved:
            continue
        img = _img_from_input(bsdf, inp_name)
        if img and img.size[0] > 0:
            path = os.path.join(OUT, fname)
            img.filepath_raw = path
            img.file_format = 'PNG'
            img.save()
            saved[key] = "%s (%dx%d)" % (fname, img.size[0], img.size[1])

print("GROUND_TEX_EXTRACT_OK")
for k, v in saved.items():
    print("  %-8s -> %s" % (k, v))
if not saved:
    print("  (nothing extracted — dumping material graph for debug)")
    for mat in bpy.data.materials:
        if mat.use_nodes:
            print("  mat", mat.name, "nodes:", [n.type for n in mat.node_tree.nodes])
