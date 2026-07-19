extends RefCounted
class_name HeroMaterialFix
## Rescue pass for the hero HAWC's baked materials.
##
## The Oscar Creativo "Bot Mecha Warrior" GLB exports every surface as
## metallic=1.0 AND roughness=1.0 with no metallic/roughness map (a common glTF
## quirk when the source had no ORM texture). A fully-metal, fully-rough surface
## has almost no diffuse response and a broken, energy-starved specular lobe, so
## under our single Mars sun the whole mech reads as near-black — which is the
## "renders very DARK" note in the possession-loop memory.
##
## We DON'T repaint it (that's HawcMaterial, for the low-poly Prowler). We keep
## every baked albedo/normal/emission texture and only correct the physically
## wrong metallic/roughness so the existing color shows under light.
##
## Usage:  HeroMaterialFix.apply(hawk_instance)

# A machined-metal mech is partly metal, not 100% — and never perfectly rough.
const METALLIC_CAP := 0.55   # let diffuse albedo come through
const ROUGHNESS := 0.42      # crisp-ish specular highlight instead of a dead matte
const ALBEDO_LIFT := 1.18    # gentle overall brighten on top of the texture

static func apply(model: Node) -> void:
	_walk(model)

static func _walk(node: Node) -> void:
	if node is MeshInstance3D:
		_fix_mesh(node as MeshInstance3D)
	for c in node.get_children():
		_walk(c)

static func _fix_mesh(mi: MeshInstance3D) -> void:
	var mesh := mi.mesh
	if mesh == null:
		return
	for s in range(mesh.get_surface_count()):
		var src := mi.get_active_material(s)
		if src is StandardMaterial3D:
			var m := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
			# Correct the physically wrong PBR values while keeping all textures.
			m.metallic = min(m.metallic, METALLIC_CAP)
			m.roughness = ROUGHNESS
			# Lift albedo a touch so the mech is legible in Mars shadow without
			# blowing out the baked detail. The texture stays; this only tints.
			m.albedo_color = Color(ALBEDO_LIFT, ALBEDO_LIFT, ALBEDO_LIFT, m.albedo_color.a)
			# Emission maps baked at 10x can bloom hot patches; tame unless it's a
			# genuine glow surface (cockpit/thruster) — those keep a readable pop.
			if m.emission_enabled and m.emission_energy_multiplier > 3.0:
				m.emission_energy_multiplier = 2.0
			mi.set_surface_override_material(s, m)
