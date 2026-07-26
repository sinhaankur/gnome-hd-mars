"""Search the Sketchfab API for DOWNLOADABLE, permissively-licensed mech models per
archetype, so we can source real detailed geometry instead of hand-greebling primitives
(per the blender-asset skill: sourced CC model > kitbash > build from scratch).

Token is read from ~/.config/gnome_hd/sketchfab_token (never committed). Prints ranked
candidates: name, license, face count, animated?, uid, viewer URL. We then download the
picks with sketchfab_download.py.

Usage:  python3 tools/sketchfab_search.py "mech robot"  [max]
"""
import sys, json, os, urllib.request, urllib.parse

TOKEN = open(os.path.expanduser("~/.config/gnome_hd/sketchfab_token")).read().strip()
API = "https://api.sketchfab.com/v3/search"

# Licenses we can ship (game is MIT/public). Sketchfab SEARCH results carry a license
# LABEL (not a slug), so we match on the label text. Shippable = CC0 or plain CC-BY.
# EXCLUDED: any NonCommercial ("NC"), NoDerivatives ("ND"), "Free Standard"/"Editorial"
# (Sketchfab's non-open custom licenses).
def license_ok(label):
    if not label:
        return False
    l = label.lower()
    if "noncommercial" in l or "no derivative" in l or "noderiv" in l:
        return False
    if "standard" in l or "editorial" in l:
        return False
    if "cc0" in l or "public domain" in l:
        return True
    if "attribution" in l:   # plain CC-BY (NC/ND already excluded above)
        return True
    return False


def search(query, max_results=12):
    params = {
        "type": "models",
        "q": query,
        "downloadable": "true",
        "archives_flavours": "false",
        "count": 24,
        "sort_by": "-likeCount",   # popular = usually higher quality
    }
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"Authorization": "Token " + TOKEN})
    with urllib.request.urlopen(req) as r:
        data = json.load(r)
    rows = []
    for m in data.get("results", []):
        lic = (m.get("license") or {})
        label = lic.get("label", "")
        if not license_ok(label):
            continue
        # short license tag for the table
        tag = "CC0" if ("cc0" in label.lower() or "public" in label.lower()) else "CC-BY"
        rows.append({
            "name": m.get("name", "?")[:44],
            "lic": tag,
            "label": label,
            "faces": m.get("faceCount", 0),
            "anim": bool(m.get("animationCount", 0)),
            "uid": m.get("uid"),
            "url": m.get("viewerUrl", ""),
        })
    return rows[:max_results]


if __name__ == "__main__":
    q = sys.argv[1] if len(sys.argv) > 1 else "mech robot"
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 12
    rows = search(q, n)
    print("QUERY: %s  (%d shippable candidates)" % (q, len(rows)))
    print("%-46s %-5s %-9s %-5s %s" % ("name", "lic", "faces", "anim", "uid"))
    for r in rows:
        print("%-46s %-5s %-9d %-5s %s" % (
            r["name"], r["lic"], r["faces"], "yes" if r["anim"] else "-", r["uid"]))
