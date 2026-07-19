extends SceneTree
## Dump the hero HAWC's surface materials so a brighten pass can be tuned to real
## values instead of guesses. Run:
##   godot --headless --path godot -s tools/inspect_hero.gd

func _walk(n: Node, depth: int) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mesh := mi.mesh
		var scount := 0 if mesh == null else mesh.get_surface_count()
		print("MESH  ", mi.name, "  surfaces=", scount)
		for s in range(scount):
			var m := mi.get_active_material(s)
			if m is StandardMaterial3D:
				var sm := m as StandardMaterial3D
				print("   [%d] Std  albedo=%s  metal=%.2f  rough=%.2f  emis=%s emisE=%.2f  tex=%s" % [
					s, str(sm.albedo_color), sm.metallic, sm.roughness,
					str(sm.emission_enabled), sm.emission_energy_multiplier,
					"yes" if sm.albedo_texture else "no"])
			elif m == null:
				print("   [%d] <null>" % s)
			else:
				print("   [%d] %s" % [s, m.get_class()])
	for c in n.get_children():
		_walk(c, depth + 1)

func _init() -> void:
	var scene: PackedScene = load("res://assets/hawc_hero.glb")
	if scene == null:
		print("FAILED to load hawc_hero.glb")
		quit()
		return
	var root := scene.instantiate()
	print("=== hawc_hero.glb material dump ===")
	_walk(root, 0)
	print("=== end ===")
	quit()
