extends Node
## AUDIO MANAGER (autoload "Audio") — looping ambient + music beds, generated procedurally
## (no audio files). Separate from Sfx (one-shots) per the layer policy: this manages
## continuous background audio. Respects the master volume bus.
##
## Public:
##   Audio.play_ambient()   # Mars wind bed (call in a mission)
##   Audio.play_music(mood) # slow atmospheric drone; mood "tense"/"calm"
##   Audio.stop_all()

const RATE := 22050

var _wind: AudioStreamPlayer
var _music: AudioStreamPlayer
var _cache := {}

func _ready() -> void:
	_wind = _make_player(-16.0)
	_music = _make_player(-20.0)
	_cache["wind"] = _make_wind()
	_cache["music_tense"] = _make_music(true)
	_cache["music_calm"] = _make_music(false)

func _make_player(vol_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Master"
	p.volume_db = vol_db
	add_child(p)
	return p

func play_ambient() -> void:
	if _wind.stream != _cache["wind"]:
		_wind.stream = _cache["wind"]
	if not _wind.playing:
		_wind.play()

func play_music(mood: String = "tense") -> void:
	var key := "music_tense" if mood == "tense" else "music_calm"
	if _music.stream != _cache[key]:
		_music.stream = _cache[key]
		_music.play()
	elif not _music.playing:
		_music.play()

func stop_all() -> void:
	_wind.stop()
	_music.stop()

# ---------------------------------------------------------------- synthesis (looping)
func _stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = samples.size() - 1
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	s.data = bytes
	return s

func _make_wind() -> AudioStreamWAV:
	# thin, gusty Mars wind: filtered noise with a slow swell (loops seamlessly)
	var n := RATE * 4
	var out := PackedFloat32Array(); out.resize(n)
	var prev := 0.0
	for i in range(n):
		var t: float = float(i) / n
		# low-pass filtered white noise (rumbly), plus a slow gust envelope
		var noise := randf_range(-1.0, 1.0)
		prev = prev * 0.96 + noise * 0.04
		var gust: float = 0.5 + 0.5 * sin(t * TAU) * sin(t * TAU * 0.5)
		out[i] = prev * gust * 0.8
	# crossfade the seam so the loop is seamless
	var fade := RATE / 2
	for i in range(fade):
		var a: float = float(i) / fade
		out[i] = lerpf(out[n - fade + i], out[i], a)
	return _stream(out)

func _make_music(tense: bool) -> AudioStreamWAV:
	# slow atmospheric drone: a few detuned sine layers, minor for tense, open for calm.
	var n := RATE * 8
	var out := PackedFloat32Array(); out.resize(n)
	# root + intervals (semitone ratios). tense = minor 2nd/tritone tension; calm = fifth.
	var root := 55.0   # low A
	var freqs: Array = [root, root * 1.5] if not tense else [root, root * 1.189, root * 1.414]
	for i in range(n):
		var t: float = float(i) / RATE
		var v := 0.0
		for f in freqs:
			# slow tremolo + slight detune for movement
			var trem: float = 0.7 + 0.3 * sin(t * 0.3 + f)
			v += sin(TAU * f * t) * trem
			v += sin(TAU * (f * 1.003) * t) * 0.5   # detune layer
		out[i] = v / (freqs.size() * 2.0) * 0.6
	# gentle fade at the loop seam
	var fade := RATE
	for i in range(fade):
		var a: float = float(i) / fade
		out[i] = lerpf(out[n - fade + i], out[i], a)
	return _stream(out)
