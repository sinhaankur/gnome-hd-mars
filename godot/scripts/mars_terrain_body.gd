extends StaticBody3D
## Attached to the MarsTerrain body so callers can do terrain.height(x, z) to seat
## props/enemies on the real HiRISE relief (matches the old terrain.gd API).
## The height grid + params are filled in by MarsTerrain.make().

var _heights: PackedFloat32Array
var _res: int = 0
var _world_size: float = 400.0

func setup(heights: PackedFloat32Array, res: int, world_size: float) -> void:
	_heights = heights
	_res = res
	_world_size = world_size

func height(x: float, z: float) -> float:
	if _res <= 0 or _heights.is_empty():
		return 0.0
	var half := _world_size * 0.5
	var u: float = clamp((x + half) / _world_size, 0.0, 1.0)
	var v: float = clamp((z + half) / _world_size, 0.0, 1.0)
	var fx := u * _res
	var fy := v * _res
	var i := int(fx)
	var j := int(fy)
	var stride := _res + 1
	i = clampi(i, 0, _res)
	j = clampi(j, 0, _res)
	return _heights[j * stride + i]
