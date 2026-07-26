"""Download the chosen Mars-ENVIRONMENT models (GLB) into blender_assets/sketchfab_src/.
Separate from the mech downloader so each set is independently re-fetchable. CC-BY —
attributions appended to CREDITS.md by the caller / written to ENV_ATTRIBUTIONS.json.

Serves the "true playable Mars" upgrade: photoreal scanned ground + real rocks + the
real NASA rover. Token from ~/.config/gnome_hd/sketchfab_token (never committed).

Usage:  python3 tools/sketchfab_download_env.py
"""
import json, os, urllib.request

TOKEN = open(os.path.expanduser("~/.config/gnome_hd/sketchfab_token")).read().strip()
OUT = "/Users/sinhaankur/Downloads/G-Nome_ISO/blender_assets/sketchfab_src"
os.makedirs(OUT, exist_ok=True)

# role -> (uid, dest). Real CC-BY Mars-environment sources.
PICKS = {
    "ground_scan": ("6ef549171a894560ad5d70cfad87343e", "src_ground_scan.glb"),  # Gravel Ground Module Scan (Pers Scans) — photoreal regolith tile
    "rockpile":    ("5206d4d96c2d428b9c1f7ee0e13bcffb", "src_rockpile.glb"),     # Rock Pile Scan Dry 1 (Pers Scans)
    "rocks_pack":  ("7c60b4d1b8ab4187965f30c5e0212fc0", "src_rocks_pack.glb"),   # Free Pack - Rocks Stylized (PolyOne) — light multi-rock
    "boulder":     ("d1f2ce6f71aa4c19adbdc541cc888194", "src_boulder.glb"),      # Cliff Rock Boulder Field (Pers Scans)
    "rover":       ("0696a383f3e841d2b5c7636ee8a58aba", "src_rover.glb"),        # NASA Curiosity (Clean) (Thomas Flynn)
}


def _get_json(url):
    req = urllib.request.Request(url, headers={"Authorization": "Token " + TOKEN})
    with urllib.request.urlopen(req) as r:
        return json.load(r)


def download(uid, dest):
    info = _get_json("https://api.sketchfab.com/v3/models/%s/download" % uid)
    glb = info.get("glb")
    if not glb or "url" not in glb:
        print("  NO GLB FLAVOUR for", uid); return None
    path = os.path.join(OUT, dest)
    urllib.request.urlretrieve(glb["url"], path)
    return path


def attribution(uid):
    d = _get_json("https://api.sketchfab.com/v3/models/%s" % uid)
    u = d.get("user") or {}
    return {"name": d.get("name", "?"),
            "author": u.get("displayName") or u.get("username", "?"),
            "license": (d.get("license") or {}).get("label", "?"),
            "url": d.get("viewerUrl", "")}


if __name__ == "__main__":
    attribs = {}
    for role, (uid, dest) in PICKS.items():
        p = download(uid, dest)
        if p:
            a = attribution(uid)
            attribs[role] = a
            print("OK  %-12s %-22s %6.1f MB  <- %s by %s" % (
                role, dest, os.path.getsize(p) / 1e6, a["name"], a["author"]))
    with open(os.path.join(OUT, "ENV_ATTRIBUTIONS.json"), "w") as f:
        json.dump(attribs, f, indent=2)
    print("ENV_DOWNLOAD_DONE %d models" % len(attribs))
