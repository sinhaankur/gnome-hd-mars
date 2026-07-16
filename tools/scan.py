#!/usr/bin/env python3
"""Scan G-NOME archive files: locate MODL magic, classify files, dump structure."""
import sys, os, struct, glob

GAME = "/Users/sinhaankur/Downloads/G-Nome_ISO/assets/G-NOME"

def find_all(data, needle):
    out, i = [], data.find(needle)
    while i != -1:
        out.append(i)
        i = data.find(needle, i + 1)
    return out

def classify(path):
    with open(path, "rb") as f:
        data = f.read()
    magic4 = data[:4]
    modl_offsets = find_all(data, b"MODL")
    # audio signature: 22050(0x5622) & 44100(0xAC44) & '0200 1000' near offset 0x10
    audio = (b"\x22\x56\x00\x00\x44\xac\x00\x00\x02\x00\x10\x00" in data[:64])
    # other known magics
    other = []
    for mg in (b"RIFF", b"BM", b"\x89PNG", b"FORM", b"PACK", b"WAVE"):
        if mg in data[:2048]:
            other.append(mg.decode("latin1"))
    return {
        "name": os.path.basename(path),
        "size": len(data),
        "magic4": magic4,
        "modl_count": len(modl_offsets),
        "modl_first": modl_offsets[0] if modl_offsets else None,
        "audio_hdr": audio,
        "other": other,
    }

def main():
    files = sorted(glob.glob(os.path.join(GAME, "G-NOME.0[0-9][0-9]")))
    print(f"{'file':14} {'size':>10} {'magic':10} {'MODLs':>6} {'1stMODL':>9} audio other")
    cat = {}
    for p in files:
        c = classify(p)
        m = c["magic4"]
        ascii_m = "".join(chr(b) if 32 <= b < 127 else "." for b in m)
        hexm = m.hex()
        key = "MODL" if m == b"MODL" else ("AUDIO" if c["audio_hdr"] else ("emb-MODL" if c["modl_count"] else hexm[:8]))
        cat.setdefault(key, []).append(c["name"])
        print(f"{c['name']:14} {c['size']:>10} {ascii_m:4}/{hexm:8} {c['modl_count']:>6} "
              f"{str(c['modl_first']):>9} {'Y' if c['audio_hdr'] else '-':>5} {','.join(c['other'])}")
    print("\n===== CATEGORY SUMMARY =====")
    for k, v in sorted(cat.items(), key=lambda kv: -len(kv[1])):
        print(f"{k:12} : {len(v):3} files  e.g. {', '.join(v[:6])}")

if __name__ == "__main__":
    main()
