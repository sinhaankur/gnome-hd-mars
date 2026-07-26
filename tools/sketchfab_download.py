"""Download the chosen Sketchfab models (GLB) into blender_assets/sketchfab_src/ for
kitbashing. CC-BY — attributions are appended to CREDITS.md by the caller.

Token from ~/.config/gnome_hd/sketchfab_token (never committed). The download endpoint
returns a short-lived signed URL per model; we fetch the 'glb' flavour.

Usage:  python3 tools/sketchfab_download.py
"""
import json, os, urllib.request

TOKEN = open(os.path.expanduser("~/.config/gnome_hd/sketchfab_token")).read().strip()
OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/blender_assets/sketchfab_src"
os.makedirs(OUT, exist_ok=True)

# archetype -> (uid, dest filename). One detailed CC-BY model per class silhouette.
PICKS = {
    "sentry":   ("9271b28473454a53bf037963a2878338", "src_sentry.glb"),    # Bipedal Mech (rigged)
    "tactical": ("c3a05b54da27477089aeff3cff226c9e", "src_tactical.glb"),  # Magnetar Assault Combat Mech
    "heavy":    ("5a8a1d83d1674c3982340c38bf52f069", "src_heavy.glb"),     # Quadruped Mech walker
    "support":  ("6aebe7926d954a21b1abd0ca8fbfd5d5", "src_support.glb"),   # MBT-70 main battle tank
    "hover":    ("25376ae6a4674c21b164ebc7b84fd80f", "src_hover.glb"),     # Duster 46 Hovercraft
}


def _get_json(url):
    req = urllib.request.Request(url, headers={"Authorization": "Token " + TOKEN})
    with urllib.request.urlopen(req) as r:
        return json.load(r)


def download(uid, dest):
    info = _get_json("https://api.sketchfab.com/v3/models/%s/download" % uid)
    glb = info.get("glb")
    if not glb or "url" not in glb:
        print("  NO GLB FLAVOUR for", uid, "-> keys:", list(info.keys()))
        return None
    path = os.path.join(OUT, dest)
    urllib.request.urlretrieve(glb["url"], path)
    return path, glb.get("size", 0)


def attribution(uid):
    d = _get_json("https://api.sketchfab.com/v3/models/%s" % uid)
    u = d.get("user") or {}
    return {
        "name": d.get("name", "?"),
        "author": u.get("displayName") or u.get("username", "?"),
        "author_url": u.get("profileUrl", ""),
        "license": (d.get("license") or {}).get("label", "?"),
        "url": d.get("viewerUrl", ""),
    }


if __name__ == "__main__":
    attribs = []
    for arch, (uid, dest) in PICKS.items():
        res = download(uid, dest)
        if res:
            path, size = res
            a = attribution(uid)
            attribs.append((arch, a))
            print("OK  %-9s %-18s %6.1f MB  <- %s by %s" % (
                arch, dest, os.path.getsize(path) / 1e6, a["name"], a["author"]))
    # write a machine-readable attribution manifest next to the sources
    with open(os.path.join(OUT, "ATTRIBUTIONS.json"), "w") as f:
        json.dump({arch: a for arch, a in attribs}, f, indent=2)
    print("DOWNLOAD_DONE  %d models" % len(attribs))
