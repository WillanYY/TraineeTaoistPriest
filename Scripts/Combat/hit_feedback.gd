extends Node2D
const CombatAudio = preload("res://Scripts/Combat/combat_audio.gd")
var audio = CombatAudio.new()
var camera: Camera2D
var camera_base: Vector2
var hitstop_left: float = 0.0
var shake_left: float = 0.0
var shake_strength: float = 0.0
var freeze_count: int = 0
var impact_count: int = 0
var effects: Array[Dictionary] = []
var seen_serials: Dictionary = {}
var elapsed: float = 0.0
func _ready() -> void:
	add_to_group("combat_feedback")
	z_index = 50
	audio.name = "CombatAudio"
	add_child(audio)
	camera = get_viewport().get_camera_2d()
	if camera == null:
		camera = Camera2D.new()
		camera.name = "FeedbackCamera"
		camera.position = get_viewport_rect().size / 2
		add_child(camera)
		camera.make_current()
	camera_base = camera.offset
func bind_player(player) -> void:
	player.melee.swing_started.connect(_swing)
	player.melee.hit_confirmed.connect(_impact)
func is_frozen() -> bool:
	return hitstop_left > 0
func release_freeze() -> void:
	hitstop_left = 0.0
func _swing(_definition: Resource, _serial: int) -> void:
	audio.play_event("swing")
func _impact(_target: Node2D, point: Vector2, definition: Resource, serial: int) -> void:
	impact_count += 1
	effects.append({"point": to_local(point), "left": 0.22, "seed": impact_count})
	if not seen_serials.has(serial):
		seen_serials[serial] = true
		seen_serials.erase(serial - 64)
		hitstop_left = maxf(hitstop_left, definition.hitstop)
		if definition.hitstop > 0:
			freeze_count += 1
		shake_left = 0.14
		shake_strength = maxf(shake_strength, definition.shake)
		audio.play_event("hit")
func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale,0.001)
	elapsed += real_delta
	hitstop_left = maxf(0, hitstop_left - real_delta)
	shake_left = maxf(0, shake_left - real_delta)
	if is_instance_valid(camera):
		var amount := shake_strength * shake_left / 0.14
		camera.offset = camera_base + Vector2(sin(elapsed*157), cos(elapsed*193)) * amount
	if shake_left == 0:
		shake_strength = 0
	for i in range(effects.size()-1,-1,-1):
		effects[i]["left"] -= real_delta
		if effects[i]["left"] <= 0:
			effects.remove_at(i)
	queue_redraw()
func _draw() -> void:
	for effect in effects:
		var p: float = 1.0 - effect["left"] / 0.22
		var point: Vector2 = effect["point"]
		var seed_value: float = effect["seed"]
		for i in 9:
			var direction := Vector2.from_angle(i * TAU/9 + seed_value)
			draw_line(point + direction * (3 + p*12), point + direction*(12+p*32),
				Color(1.0,0.83,0.4,1-p), 2.0)
		draw_circle(point, maxf(1,8*(1-p)),Color(1,0.95,0.75,1-p))
func reset() -> void:
	release_freeze()
	effects.clear()
	seen_serials.clear()
	shake_left = 0
	shake_strength = 0
	freeze_count = 0
	impact_count = 0
	audio.reset()
	if is_instance_valid(camera):
		camera.offset = camera_base
	queue_redraw()
func _exit_tree() -> void:
	if is_instance_valid(camera):
		camera.offset = camera_base
