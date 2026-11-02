extends SceneTree
## Verify a rebuilt hero mech GLB meets the game contract before we swap it in.
##   godot --headless --path godot -s tools/verify_hero.gd
## Checks: AABB height ~7 m, feet near Y=0, X/Z centred, AnimationPlayer has clips.

const PATH := "res://assets/hero_custom_wip.glb"

var _acc := AABB()
var _has := false

func _collect(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var a := mi.get_aabb()
		var gx := mi.global_transform
		for i in range(8):
			var wp := gx * a.get_endpoint(i)
			if not _has:
				_acc = AABB(wp, Vector3.ZERO); _has = true
			else:
				_acc = _acc.expand(wp)
	for c in n.get_children():
		_collect(c)

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var r := _find_anim(c)
		if r: return r
	return null

func _init() -> void:
	var scene: PackedScene = load(PATH)
	if scene == null:
		print("FAIL: could not load ", PATH); quit(); return
	var root := scene.instantiate()
	var tmp := Node3D.new()
	tmp.add_child(root)
	get_root().add_child(tmp)
	# force global transforms to resolve
	tmp.force_update_transform()

	_collect(root)
	var bb: AABB = _acc
	print("=== hero GLB verify: ", PATH, " ===")
	print("AABB size  (w,h,d) = %.2f, %.2f, %.2f  (want h~7.0)" % [bb.size.x, bb.size.y, bb.size.z])
	print("AABB min.y = %.3f  (want ~0.0, feet on ground)" % bb.position.y)
	print("AABB centre x,z = %.3f, %.3f  (want ~0,0)" % [
		bb.position.x + bb.size.x * 0.5, bb.position.z + bb.size.z * 0.5])

	var ap := _find_anim(root)
	if ap:
		print("AnimationPlayer clips = ", ap.get_animation_list())
	else:
		print("FAIL: no AnimationPlayer found")

	# verdict
	var ok_h := absf(bb.size.y - 7.0) < 1.0
	var ok_feet := absf(bb.position.y) < 0.2
	var ok_anim := ap != null and ap.get_animation_list().size() >= 1
	print("VERDICT: height=%s feet=%s anim=%s" % [ok_h, ok_feet, ok_anim])
	quit()
