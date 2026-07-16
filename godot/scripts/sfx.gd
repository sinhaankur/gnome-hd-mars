extends Node
## Procedural SFX (autoload as "Sfx"). Generates synth sounds at runtime — no audio
## files needed. Call Sfx.laser(), Sfx.hit(), Sfx.explosion(), Sfx.alarm(), Sfx.ui().
## Respects the master volume bus.

const RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}

func _ready() -> void:
	# a small pool of players so overlapping sounds don't cut each other off
	for i in range(12):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_cache["laser"] = _make_laser()
	_cache["hit"] = _make_hit()
	_cache["explosion"] = _make_explosion()
	_cache["alarm"] = _make_alarm()
	_cache["ui"] = _make_ui()

func _play(name: String, vol_db := 0.0, pitch := 1.0) -> void:
	if not _cache.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _cache[name]
	p.volume_db = vol_db
	p.pitch_scale = pitch * randf_range(0.95, 1.06)
	p.play()

func laser() -> void: _play("laser", -6.0)
func hit() -> void: _play("hit", -4.0)
func explosion() -> void: _play("explosion", -2.0)
func alarm() -> void: _play("alarm", -8.0)
func ui() -> void: _play("ui", -10.0)

# ---------------------------------------------------------------- synthesis
func _stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	s.data = bytes
	return s

func _make_laser() -> AudioStreamWAV:
	# descending zap
	var n := int(RATE * 0.18)
	var out := PackedFloat32Array(); out.resize(n)
	for i in range(n):
		var t: float = float(i) / n
		var freq: float = lerpf(900.0, 220.0, t)
		var env: float = (1.0 - t) * (1.0 - t)
		out[i] = sin(TAU * freq * (float(i) / RATE)) * env * 0.6
	return _stream(out)

func _make_hit() -> AudioStreamWAV:
	# short metallic tick + noise
	var n := int(RATE * 0.10)
	var out := PackedFloat32Array(); out.resize(n)
	for i in range(n):
		var t: float = float(i) / n
		var env: float = exp(-t * 20.0)
		out[i] = (sin(TAU * 620.0 * (float(i)/RATE)) * 0.5 + randf_range(-0.5, 0.5)) * env
	return _stream(out)

func _make_explosion() -> AudioStreamWAV:
	# noise burst with low rumble
	var n := int(RATE * 0.5)
	var out := PackedFloat32Array(); out.resize(n)
	for i in range(n):
		var t: float = float(i) / n
		var env: float = exp(-t * 5.0)
		var rumble: float = sin(TAU * lerpf(120.0, 40.0, t) * (float(i)/RATE))
		out[i] = (randf_range(-1.0, 1.0) * 0.6 + rumble * 0.4) * env
	return _stream(out)

func _make_alarm() -> AudioStreamWAV:
	# two-tone warning beep
	var n := int(RATE * 0.4)
	var out := PackedFloat32Array(); out.resize(n)
	for i in range(n):
		var t: float = float(i) / n
		var freq: float = 500.0 if t < 0.5 else 380.0
		var env: float = 0.5 * (1.0 - abs(fmod(t * 2.0, 1.0) - 0.5) * 2.0)
		out[i] = sin(TAU * freq * (float(i)/RATE)) * env
	return _stream(out)

func _make_ui() -> AudioStreamWAV:
	var n := int(RATE * 0.06)
	var out := PackedFloat32Array(); out.resize(n)
	for i in range(n):
		var t: float = float(i) / n
		out[i] = sin(TAU * 660.0 * (float(i)/RATE)) * exp(-t * 12.0) * 0.5
	return _stream(out)
