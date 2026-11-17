extends Node
@export var volume_db: float = -18.0
var audio_enabled: bool = DisplayServer.get_name() != "headless"
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var swing_events: int = 0
var hit_events: int = 0
var audible_play_count: int = 0
func _ready() -> void:
	sounds["swing"] = _synthesize(false)
	sounds["hit"] = _synthesize(true)
	for i in 6:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = volume_db
		add_child(voice)
		voices.append(voice)
func _synthesize(impact: bool) -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.14 if impact else 0.11
	var count := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4021 if impact else 9173
	var filtered := 0.0
	for i in count:
		var time := float(i) / rate
		var p := float(i) / count
		var noise := rng.randf_range(-1.0,1.0)
		filtered = filtered * 0.7 + noise * 0.3
		var value := 0.0
		if impact:
			value = (sin(TAU * (150.0 * time - 260.0 * time * time)) * 0.7 + filtered * 0.8) * exp(-time * 40) * 0.65
		else:
			value = filtered * sin(PI * p) * 0.45
		bytes.encode_s16(i*2, int(clampf(value,-1,1) * 32767))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = rate
	clip.stereo = false
	clip.data = bytes
	return clip
func play_event(kind: String) -> void:
	if kind == "swing":
		swing_events += 1
	else:
		hit_events += 1
	if not audio_enabled:
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = sounds[kind]
	voice.volume_db = volume_db
	voice.play()
	audible_play_count += 1
func reset() -> void:
	for voice in voices:
		voice.stop()
	swing_events = 0
	hit_events = 0
	audible_play_count = 0
