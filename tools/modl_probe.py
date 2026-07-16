#!/usr/bin/env python3
"""Deep structural probe of a single MODL block to reverse the format."""
import struct, sys

def f32(d,o): return struct.unpack_from("<f",d,o)[0]
def u32(d,o): return struct.unpack_from("<I",d,o)[0]
def i32(d,o): return struct.unpack_from("<i",d,o)[0]
def u16(d,o): return struct.unpack_from("<H",d,o)[0]

def dump(path, start, length):
    d = open(path,"rb").read()
    o = start
    end = min(start+length, len(d))
    print(f"=== MODL probe {path} @ {start}, showing {end-start} bytes ===")
    assert d[o:o+4]==b"MODL", f"no MODL at {o}: {d[o:o+4]}"
    o += 4
    # Walk and annotate. Print each 4-byte word three ways.
    i = o
    col = 0
    while i < end:
        word = d[i:i+4]
        if len(word) < 4: break
        ui = struct.unpack("<I", word)[0]
        fi = struct.unpack("<f", word)[0]
        ii = struct.unpack("<i", word)[0]
        asc = "".join(chr(b) if 32<=b<127 else "." for b in word)
        # interpret
        note = ""
        if 0 < ui < 100000 and abs(fi) > 1e30: note = "int-ish"
        elif -1000 < fi < 1000 and (abs(fi) > 1e-4 or fi==0.0): note = f"f={fi:.4f}"
        print(f"  +{i-start:5d} (0x{i:06x}) hex={word.hex()} u32={ui:<11} i32={ii:<11} f32={fi: .5g} '{asc}' {note}")
        i += 4

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv)>1 else "/Users/sinhaankur/Downloads/G-Nome_ISO/assets/G-NOME/G-NOME.035"
    start = int(sys.argv[2]) if len(sys.argv)>2 else 0
    length = int(sys.argv[3]) if len(sys.argv)>3 else 584
    dump(path, start, length)
