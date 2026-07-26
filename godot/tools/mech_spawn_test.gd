extends SceneTree
## DEV ONLY — headless check that the 5 new enemy archetype GLBs load through the same
## path the EnemyEngine uses, tint cleanly, and land at sane per-class heights after the
## ARCH_BASE_SCALE multiplier. Guards the wiring in enemy_engine.gd (ARCH_MODELS +
## ARCH_BASE_SCALE). Run: godot --headless --path godot -s tools/mech_spawn_test.gd

const ARCH_MODELS := {
	"sentry":   "res://assets/enemy_sentry.glb",
	"tactical": "res://assets/enemy_tactical.glb",
	"heavy":    "res://assets/enemy_heavy.glb",
	"support":  "res://assets/enemy_support.glb",
	"hover":    "res://assets/enemy_hover.glb",
}
const ARCH_BASE_SCALE := {
	"sentry": 1.0, "tactical": 1.0, "heavy": 1.0, "support": 1.15, "hover": 1.15,
}

func _init() -> void:
	var ok := true
	for arch in ARCH_MODELS:
		var scene: PackedScene = load(ARCH_MODELS[arch])
		if scene == null:
			print("FAIL %-9s could not load %s" % [arch, ARCH_MODELS[arch]])
			ok = false
			continue
		var m: Node3D = scene.instantiate()
		root.add_child(m)
		m.scale = Vector3.ONE * ARCH_BASE_SCALE[arch]
		# tint like the engine does (darken = enemy red) — must not error on these meshes
		Faction.tint(m, "darken")
		await process_frame   # let the AABB settle
		var aabb := _combined_aabb(m)
		var h := aabb.size.y
		# sane in-game class height: bipeds ~6–10 m, heavy tall hull, tank/hover low ~4–7 m
		var sane := h > 3.0 and h < 16.0
		print("%-9s %-26s height=%.1f m  %s" % [
			arch, ARCH_MODELS[arch].get_file(), h, "OK" if sane else "!! OUT OF RANGE"])
		if not sane:
			ok = false
		m.queue_free()
	print("MECH_SPAWN_TEST %s" % ("PASS" if ok else "FAIL"))
	quit()

func _combined_aabb(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in _all_meshes(node):
		var a: AABB = mi.get_aabb()
		a = mi.global_transform * a
		if first:
			box = a; first = false
		else:
			box = box.merge(a)
	return box

func _all_meshes(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out += _all_meshes(c)
	return out
