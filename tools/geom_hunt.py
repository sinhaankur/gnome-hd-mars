#!/usr/bin/env python3
"""Hunt for vertex arrays and index arrays inside a MODL/OB3D region by signature."""
import struct, sys, math

def f(d,o): return struct.unpack_from("<f",d,o)[0]
def u(d,o): return struct.unpack_from("<I",d,o)[0]

def is_vert(x,y,z):
    for v in (x,y,z):
        if math.isnan(v) or math.isinf(v): return False
        if abs(v) > 2000: return False
    return (abs(x)+abs(y)+abs(z)) > 1e-4

def scan_vertex_runs(d, start, end, minrun=8):
    """Find longest runs where consecutive 12-byte groups look like plausible vertices."""
    runs=[]
    i=start
    while i < end-12:
        x,y,z=struct.unpack_from("<3f",d,i)
        if is_vert(x,y,z):
            j=i; cnt=0
            while j < end-12:
                x,y,z=struct.unpack_from("<3f",d,j)
                if is_vert(x,y,z): cnt+=1; j+=12
                else: break
            if cnt>=minrun:
                runs.append((i,cnt,(j)))
            i=j
        else:
            i+=4
    return runs

def main():
    path=sys.argv[1]; start=int(sys.argv[2]); end=int(sys.argv[3]) if len(sys.argv)>3 else None
    d=open(path,"rb").read()
    if end is None: end=len(d)
    runs=scan_vertex_runs(d,start,end)
    runs.sort(key=lambda r:-r[1])
    print(f"=== vertex-like runs in {path} [{start}:{end}] ===")
    for off,cnt,nxt in runs[:15]:
        print(f"  @ {off:8d}  ~{cnt} verts  ends@{nxt}")
        # show preceding u32 (could be count)
        if off>=4:
            print(f"      preceding u32 @ {off-4} = {u(d,off-4)}  (run count={cnt})")
        # sample first 3 verts
        for k in range(min(3,cnt)):
            x,y,z=struct.unpack_from("<3f",d,off+k*12)
            print(f"      v{k}: ({x:.3f},{y:.3f},{z:.3f})")

if __name__=="__main__":
    main()
