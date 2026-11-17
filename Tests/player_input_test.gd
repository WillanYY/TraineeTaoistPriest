extends SceneTree
var failures: Array[String] = []
var check_count: int = 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	check_count += 1
	if not ok:
		failures.append(message)
		push_error(message)
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
func _run() -> void:
	var path := "res://Scenes/Tests/PlayerPlayground.tscn"
	if not ResourceLoader.exists(path):
		push_error("Missing player playground: " + path)
		quit(1)
		return
	var scene = load(path).instantiate()
	root.add_child(scene)
	await frames(15)
	var player = scene.get_node("Player")
	var body_min: float = player.position.y
	var body_max: float = player.position.y
	var offset_min: float = player.view.offset.y
	var offset_max: float = player.view.offset.y
	for i in 160:
		await frames(1)
		body_min = minf(body_min, player.position.y)
		body_max = maxf(body_max, player.position.y)
		offset_min = minf(offset_min, player.view.offset.y)
		offset_max = maxf(offset_max, player.view.offset.y)
	print("IDLE_STABILITY: body_range=", body_max-body_min, "; offset_range=", offset_max-offset_min)
	check(body_max-body_min < 0.01, "Idle physics body must stay still")
	check(offset_max-offset_min < 0.01, "Idle must keep a fixed visual anchor across frames")
	var start: Vector2 = player.position
	key(KEY_D, true)
	await frames(20)
	key(KEY_D, false)
	await frames(15)
	check(player.position.x > start.x + 30, "D must move right")
	key(KEY_A, true)
	await frames(10)
	key(KEY_A, false)
	await frames(15)
	check(player.facing == -1, "A must face left")
	var ground_y: float = player.position.y
	key(KEY_W, true)
	await frames(2)
	key(KEY_W, false)
	var short_top: float = player.position.y
	for i in 55:
		await frames(1)
		short_top = minf(short_top, player.position.y)
	await frames(15)
	check(player.is_on_floor(), "Short jump must land")
	key(KEY_W, true)
	var high_top: float = player.position.y
	for i in 45:
		await frames(1)
		high_top = minf(high_top, player.position.y)
	key(KEY_W, false)
	await frames(45)
	check(ground_y - high_top > ground_y - short_top + 20, "Held W must jump higher")
	check(player.is_on_floor(), "Held W cannot auto jump on landing")
	key(KEY_W, true)
	await frames(5)
	key(KEY_W, false)
	await frames(2)
	var before: float = player.velocity.y
	key(KEY_W, true)
	await frames(1)
	check(player.velocity.y > before, "No double jump")
	key(KEY_W, false)
	await frames(70)
	check(absf(player.position.y - ground_y) < 1, "Stable ground collision")
	# A real key path into a wall must not pass through it.
	key(KEY_A, true)
	await frames(200)
	key(KEY_A, false)
	check(player.position.x >= 40, "Wall collision must stop movement")
	player.position = Vector2(640, 390)
	player.velocity = Vector2.ZERO
	await frames(2)
	check(not player.is_on_floor(), "Airborne fixture")
	key(KEY_W, true)
	await frames(1)
	check(player.velocity.y >= 0, "No off-platform jump grace")
	key(KEY_W, false)
	await frames(60)
	# A ceiling intercepts a full jump.
	player.position = Vector2(850, 580)
	player.velocity = Vector2.ZERO
	await frames(5)
	key(KEY_W, true)
	var ceiling_top: float = player.position.y
	for i in 20:
		await frames(1)
		ceiling_top = minf(ceiling_top, player.position.y)
	check(ceiling_top >= 527.0, "Ceiling must stop jump")
	key(KEY_W, false)
	await frames(50)
	player.position = Vector2(495, 520)
	player.velocity = Vector2.ZERO
	await frames(5)
	key(KEY_D, true)
	key(KEY_W, true)
	await frames(36)
	key(KEY_D, false)
	key(KEY_W, false)
	await frames(12)
	check(player.is_on_floor() and absf(player.position.y - 420) < 1, "Platform reachable from step")
	check(absf(player.view.position.y + player.view.offset.y - player.view.sprite_frames.get_frame_texture(player.view.animation, player.view.frame).get_height() / 2.0 + player.view.sprite_frames.get_frame_texture(player.view.animation, player.view.frame).get_image().get_used_rect().end.y) <= 1, "Visible feet aligned with body origin")
	print("PLAYER_INPUT_CHECKS: ", check_count - failures.size(), "/", check_count, "; short_height=", ground_y-short_top, "; held_height=",ground_y-high_top)
	quit(0 if failures.is_empty() else 1)
