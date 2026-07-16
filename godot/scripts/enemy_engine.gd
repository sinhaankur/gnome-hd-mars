extends Node3D
class_name EnemyEngine
## ENEMY ENGINE — drives the game's opposition and story beats for a level.
## Owns the spawn director (waves, timing, difficulty curve), builds enemy mechs,
## and reports mission progress. It is the CONDUCTOR: it may read the HAWC and the
## Environment (its two knowns) through their public interfaces, and emits events the
## level/HUD listen to.
##
## Dependency direction: EnemyEngine -> HAWC + EnvironmentEngine (never the reverse).
##
## Public interface:
##   configure(env, player, mech_path, mech_scale)
##   start()                          # begin the wave sequence
##   signal wave_started(index, total, count)
##   signal wave_cleared(index)
##   signal mission_won
##   signal all_enemies : reads live via get_tree groups

signal wave_started(index: int, total: int, count: int)
signal wave_cleared(index: int)
signal mission_won
signal enemy_destroyed_signal   # relayed for scoring

# each wave: how many rival mechs, and their hp. Difficulty ramps up.
@export var waves: Array = [
	{"count": 2, "hp": 5},
	{"count": 3, "hp": 6},
	{"count": 4, "hp": 7},
	{"count": 5, "hp": 8},
]
@export var time_between_waves: float = 6.0
@export var mech_path: String = "res://assets/warrior.glb"
@export var mech_scale: float = 2.8

var _env: EnvironmentEngine
var _player: Node3D
var _wave_index := -1
var _rng := RandomNumberGenerator.new()
var _active := false

func configure(env: EnvironmentEngine, player: Node3D, path := "", scale := 0.0) -> void:
	_env = env
	_player = player
	if path != "":
		mech_path = path
	if scale > 0.0:
		mech_scale = scale
	_rng.seed = 90210

func start() -> void:
	if _active:
		return
	_active = true
	_next_wave()

func _next_wave() -> void:
	_wave_index += 1
	if _wave_index >= waves.size():
		mission_won.emit()
		_active = false
		return
	var w: Dictionary = waves[_wave_index]
	var count: int = w.get("count", 3)
	# a wave may name an enemy tier ("scout"/"soldier"/"heavy"/"boss"); else fall back to
	# the wave's raw hp for backward-compatibility with the older wave format.
	var tier_key: String = w.get("tier", "")
	for i in range(count):
		_spawn_enemy(tier_key, int(w.get("hp", 6)))
	wave_started.emit(_wave_index, waves.size(), count)

func _spawn_enemy(tier_key: String, fallback_hp: int) -> void:
	# resolve the tier (data-driven stats + look). Empty key => a plain "soldier"-ish unit.
	var tier: Dictionary = EnemyTiers.get_tier(tier_key) if tier_key != "" else {
		"hp": fallback_hp, "scale": 1.0, "move": 6.0, "fire_cd": 1.4, "detect": 80.0, "tint": "darken"}

	var e := CharacterBody3D.new()
	e.name = "RivalHAWC"
	e.set_script(load("res://scripts/enemy_ai.gd"))
	e.hp = tier["hp"]
	e.move_speed = tier["move"]
	e.fire_cooldown = tier["fire_cd"]
	e.detect_range = tier["detect"]

	var visual := Node3D.new()
	var scene: PackedScene = load(mech_path)
	var mech_model: Node = null
	if scene:
		var m := scene.instantiate()
		m.scale = Vector3.ONE * mech_scale * float(tier["scale"])   # tier sizes the mech
		# VERIFIED BY RENDER (from the target's view): the flipped model shows its FACE
		# toward the target, the unflipped shows its back. So enemies need the flip too.
		m.rotation.y = PI
		visual.add_child(m)
		Faction.tint(m, tier["tint"])   # tier picks the faction color scheme
		mech_model = m
	e.add_child(visual)

	# walk animation driven by movement
	if mech_model:
		var anim := MechAnimator.new()
		e.add_child(anim)
		anim.setup(mech_model)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.6; cap.height = 6.0
	col.shape = cap; col.position.y = 3.4
	e.add_child(col)

	# spawn at a walkable map edge (Environment decides where), march at the installation
	var spawn := Vector3(120, 10, 120)
	if _env:
		spawn = _env.random_edge_spawn(_rng)
	e.position = spawn
	# tell the AI what to attack: the installation is the primary target, player secondary
	if _env and _env.installation:
		e.set("primary_target", _env.installation)
	add_child(e)
	# clean up + wave tracking when it dies
	if e.has_signal("destroyed"):
		e.destroyed.connect(_on_enemy_destroyed)

func _on_enemy_destroyed() -> void:
	enemy_destroyed_signal.emit()   # relay for scoring
	# check if the wave is cleared on the next idle frame (after the node frees)
	call_deferred("_check_wave_cleared")

func _check_wave_cleared() -> void:
	if not _active:
		return
	var remaining := get_tree().get_nodes_in_group("enemies").size()
	if remaining == 0:
		wave_cleared.emit(_wave_index)
		get_tree().create_timer(time_between_waves).timeout.connect(_next_wave)

func enemies_alive() -> int:
	return get_tree().get_nodes_in_group("enemies").size()
