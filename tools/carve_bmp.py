#!/usr/bin/env python3
"""Carve embedded Windows BMP files out of the G-NOME archives.
A BMP starts with 'BM', u32 file size, 2x u16 reserved, u32 pixel-data offset,
then a 40-byte BITMAPINFOHEADER (biSize=40)."""
import struct, glob, os, sys

GAME="/Users/sinhaankur/Downloads/G-Nome_ISO/assets/G-NOME"
OUT="/Users/sinhaankur/Downloads/G-Nome_ISO/textures/bmp"

def valid_bmp_at(d, i):
    if d[i:i+2] != b"BM": return None
    if i+54 > len(d): return None
    size = struct.unpack_from("<I", d, i+2)[0]
    pix_off = struct.unpack_from("<I", d, i+10)[0]
    hdr_size = struct.unpack_from("<I", d, i+14)[0]
    width = struct.unpack_from("<i", d, i+18)[0]
    height = struct.unpack_from("<i", d, i+22)[0]
    planes = struct.unpack_from("<H", d, i+26)[0]
    bpp = struct.unpack_from("<H", d, i+28)[0]
    # sanity
    if hdr_size not in (40, 12, 108, 124): return None
    if planes != 1: return None
    if bpp not in (1,4,8,16,24,32): return None
    if not (0 < width <= 4096) or not (0 < abs(height) <= 4096): return None
    if not (54 <= size <= 16*1024*1024): return None
    if pix_off >= size: return None
    if i+size > len(d): return None
    return dict(size=size, w=width, h=height, bpp=bpp, off=i)

def main():
    os.makedirs(OUT, exist_ok=True)
    total=0
    manifest=[]
    for p in sorted(glob.glob(os.path.join(GAME, "G-NOME.*"))):
        d=open(p,"rb").read()
        base=os.path.basename(p)
        i=0; n=0
        while True:
            i=d.find(b"BM", i)
            if i==-1: break
            info=valid_bmp_at(d,i)
            if info:
                out=os.path.join(OUT, f"{base}_{i:08x}_{info['w']}x{abs(info['h'])}_{info['bpp']}bpp.bmp")
                open(out,"wb").write(d[i:i+info['size']])
                manifest.append((base,i,info['w'],abs(info['h']),info['bpp'],info['size']))
                n+=1; total+=1
                i+=info['size']
            else:
                i+=2
        if n: print(f"  {base}: carved {n} BMP(s)")
    print(f"\nTOTAL BMPs carved: {total}")
    # write manifest
    with open(os.path.join(OUT,"_manifest.tsv"),"w") as f:
        f.write("archive\toffset\twidth\theight\tbpp\tsize\n")
        for row in manifest:
            f.write("\t".join(str(x) for x in row)+"\n")

if __name__=="__main__":
    main()
