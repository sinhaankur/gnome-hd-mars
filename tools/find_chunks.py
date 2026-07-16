#!/usr/bin/env python3
"""Find all 4-char ASCII FourCC-like tags in MODL files to map the chunk vocabulary."""
import glob, os, re, struct, collections, sys

GAME="/Users/sinhaankur/Downloads/G-Nome_ISO/assets/G-NOME"

def fourccs(data):
    """Yield (offset, tag) for 4-byte windows that are all uppercase-ish ASCII letters/digits."""
    out=[]
    for i in range(0, len(data)-4):
        b=data[i:i+4]
        if all(48<=c<=90 or c in (95,) for c in b) and any(65<=c<=90 for c in b):
            # printable, has at least one letter
            tag=b.decode("latin1")
            out.append((i,tag))
    return out

def main():
    targets = sys.argv[1:] or ["G-NOME.035","G-NOME.005","G-NOME.001"]
    counter=collections.Counter()
    samples={}
    for name in targets:
        p=os.path.join(GAME,name)
        data=open(p,"rb").read()
        for off,tag in fourccs(data):
            counter[tag]+=1
            samples.setdefault(tag,(name,off))
    print("=== FourCC-like tags (tag : count : first-seen) ===")
    for tag,cnt in counter.most_common(60):
        n,o=samples[tag]
        print(f"  {tag!r:8} x{cnt:<5}  first @ {n}+{o}")

if __name__=="__main__":
    main()
