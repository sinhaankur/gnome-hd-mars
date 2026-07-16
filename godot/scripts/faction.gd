extends RefCounted
class_name Faction
## Tints a HAWC model to a faction palette, so one mesh reads as different factions.
## Per design/HAWC_VARIETY_SPEC.md: Union tan (player), Darken grey, Merc blue, Scorp green.
## Usage:  Faction.tint(hawk_instance, "darken")

# Strong, unmistakable faction identities (tint multiplied over albedo).
const PALETTE := {
	"union":  Color(0.90, 0.78, 0.45),   # warm tan/gold (player) — stands out on sand
	"darken": Color(0.35, 0.40, 0.50),   # dark blue-grey (enemies) — clearly darker/cooler
	"merc":   Color(0.30, 0.45, 0.95),   # strong blue
	"scorp":  Color(0.35, 0.75, 0.35),   # strong green
}

const GLOW := {
	"union":  Color(1.0, 0.55, 0.10),    # warm orange weapon glow
	"darken": Color(1.0, 0.25, 0.15),    # red
	"merc":   Color(0.20, 0.80, 1.0),    # cyan
	"scorp":  Color(0.30, 1.0, 0.35),    # toxic green
}

static func tint(model: Node, faction: String) -> void:
	var col: Color = PALETTE.get(faction, PALETTE["union"])
	_apply(model, col)

static func _apply(node: Node, col: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var count := mi.get_surface_override_material_count()
		# ensure we have per-surface overrides we can recolor without touching shared materials
		var mesh := mi.mesh
		if mesh:
			for s in range(mesh.get_surface_count()):
				var base := mi.get_active_material(s)
				var m: StandardMaterial3D
				if base is StandardMaterial3D:
					m = (base as StandardMaterial3D).duplicate()
				else:
					m = StandardMaterial3D.new()
				# multiply the faction color over the existing albedo for a recognizable tint
				m.albedo_color = m.albedo_color * col
				mi.set_surface_override_material(s, m)
	for c in node.get_children():
		_apply(c, col)
