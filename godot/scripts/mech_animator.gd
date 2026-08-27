extends Node
class_name MechAnimator
## Drives a mech's walk animation from its movement, TPS-demo style: the "Motion"
## walk cycle plays only when the mech is moving, and its SPEED scales with velocity
## so the legs match the ground travel (no sliding, no walking-in-place when idle).
##
## Attach as a child of the mech's CharacterBody3D and call setup(visual_root).
## It reads the parent body's velocity each frame.

@export var walk_anim := "Motion"
@export var idle_frame := 0.35        # a neutral standing pose (fraction of the clip)
@export var speed_to_anim := 0.14     # anim playback speed per unit of world speed
@export var min_move := 0.6           # below this speed the mech is "stopped"

var _ap: AnimationPlayer
var _body: CharacterBody3D
var _anim_len := 1.0

const DUST_PATH := "res://assets/dust_cc0.glb"   # Kenney CC0 dust puff
var _dust_scene: PackedScene
var _dust_timer := 0.0
var _model: Node3D          # the mech visual (for idle bob/sway)
var _model_base_y := 0.0
var _bob_time := 0.0

func setup(visual_root: Node) -> void:
	_ap = Atoms.find_anim_player(visual_root)
	_body = get_parent() as CharacterBody3D
	_dust_scene = load(DUST_PATH)
	if visual_root is Node3D:
		_model = visual_root
		_model_base_y = _model.position.y
	# resolve the walk clip. Order of preference:
	#   1) the exact configured name ("Motion" on the warrior);
	#   2) any clip whose name looks like a walk cycle (e.g. striker's "a5WalkCycle") — but
	#      NOT a crippled/back/root-motion variant, which we don't want as the default gait;
	#   3) the first clip, as a last resort (keeps any rigged GLB animating).
	if _ap and not _ap.has_animation(walk_anim):
		var list := _ap.get_animation_list()
		var chosen := ""
		for n in list:
			var ln := (n as String).to_lower()
			if "walk" in ln and not ("cripple" in ln or "back" in ln or "rootmotion" in ln):
				chosen = n
				break
		if chosen == "" and list.size() > 0:
			chosen = list[0]
		if chosen != "":
			walk_anim = chosen
	if _ap and _ap.has_animation(walk_anim):
		var a := _ap.get_animation(walk_anim)
		a.loop_mode = Animation.LOOP_LINEAR
		_anim_len = a.length
		_ap.play(walk_anim)
		_ap.seek(idle_frame * _anim_len, true)
		_ap.pause()

func _physics_process(delta: float) -> void:
	if _ap == null or _body == null or not is_instance_valid(_body):
		return
	var speed := Vector3(_body.velocity.x, 0.0, _body.velocity.z).length()
	if speed > min_move:
		# moving: play the walk, scaled so the cadence matches ground speed
		if not _ap.is_playing():
			_ap.play(walk_anim)
		_ap.speed_scale = clampf(speed * speed_to_anim, 0.3, 2.5)
		# kick up dust puffs at the feet, faster when moving faster
		_dust_timer -= delta
		if _dust_timer <= 0.0 and _body.is_on_floor():
			_dust_timer = clampf(1.2 / maxf(speed, 1.0), 0.12, 0.5)
			_spawn_dust()
	else:
		# stopped: hold a neutral standing frame
		if _ap.is_playing():
			_ap.pause()
			_ap.seek(idle_frame * _anim_len, true)

	# --- idle bob/sway: subtle breathing motion when nearly still ---
	if _model:
		_bob_time += delta
		var idle_amt := clampf(1.0 - speed / maxf(min_move * 3.0, 1.0), 0.0, 1.0)
		var bob := sin(_bob_time * 1.6) * 0.06 * idle_amt      # gentle vertical bob
		var sway := sin(_bob_time * 0.9) * 0.012 * idle_amt    # gentle roll
		_model.position.y = _model_base_y + bob
		_model.rotation.z = sway

func _spawn_dust() -> void:
	if _dust_scene == null:
		return
	var dust: Node3D = _dust_scene.instantiate()
	var parent := _body.get_parent()
	if parent == null:
		return
	parent.add_child(dust)
	# at the feet, offset slightly behind, random size
	var back := _body.global_transform.basis.z   # behind the mech
	var jitter := Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	dust.global_position = _body.global_position + back * 1.5 + jitter
	var s := randf_range(2.0, 3.5)
	dust.scale = Vector3.ONE * s
	# rise and fade, then free
	var tw := dust.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dust, "global_position:y", dust.global_position.y + 2.5, 1.0)
	tw.tween_property(dust, "scale", Vector3.ONE * s * 2.2, 1.0)
	_fade_out(dust, tw)
	tw.chain().tween_callback(dust.queue_free)

func _fade_out(node: Node3D, tw: Tween) -> void:
	# fade all mesh materials to transparent (uses the shared Atoms mesh-search)
	for mi in Atoms.all_mesh_instances(node):
		var src: Material = mi.get_active_material(0)
		if src is BaseMaterial3D:
			var m: BaseMaterial3D = src.duplicate()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mi.material_override = m
			tw.tween_property(m, "albedo_color:a", 0.0, 1.0)
