extends SceneTree
var checks: int = 0
var failures: Array[String] = []
var scene
var player
var target
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
func key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)
func mouse(pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	Input.parse_input_event(e)
func click() -> void:
	mouse(true)
	await frames(1)
	mouse(false)
func reset_fixture() -> void:
	key(KEY_A, false)
	key(KEY_D, false)
	key(KEY_W, false)
	mouse(false)
	key(KEY_R, true)
	await frames(1)
	key(KEY_R, false)
	player.position = Vector2(210,580)
	player.facing = 1
	player.velocity = Vector2.ZERO
	target.position = Vector2(310,580)
	target.velocity = Vector2.ZERO
	await frames(4)
func progress(segment: int, amount: float) -> void:
	for i in 70:
		if player.melee.model.segment == segment and player.melee.model.phase == "action" and player.melee.model.progress() >= amount:
			return
		await frames(1)
	check(false, "Timed attack phase was reached")
func _run() -> void:
	scene = load("res://Scenes/Tests/PlayerPlayground.tscn").instantiate()
	root.add_child(scene)
	await frames(20)
	player = scene.get_node("Player")
	target = scene.get_node("PracticeTarget300")
	await reset_fixture()
	var startups: int = player.melee.model.startup_count
	var serial: int = player.melee.model.serial
	mouse(true)
	await frames(60)
	mouse(false)
	check(player.melee.model.serial == serial + 1 and player.melee.model.startup_count == startups + 1, "Holding mouse cannot auto combo")
	check(target.received_count == 1, "One segment hits each target once")
	check(target.health == target.max_health - player.tuning.attack_one.damage, "First hit uses configured damage")
	await reset_fixture()
	startups = player.melee.model.startup_count
	await click()
	await progress(1, 0.55)
	check(player.melee.assist_used > 0, "First segment uses short assist")
	# Move the already-hit dummy out again: a close dummy needs no extra assist.
	target.position = Vector2(player.position.x + 115, 580)
	target.velocity = Vector2.ZERO
	await click()
	await progress(2, 0.10)
	check(player.melee.assist_used > 0, "Second segment also uses assist")
	await frames(40)
	check(target.received_count == 2, "Two clicks hit twice")
	check(player.melee.model.startup_count == startups + 1, "Chained second segment has no startup")
	check(player.melee.model.phase == "idle", "No third click stops after recovery")
	await reset_fixture()
	await click()
	await progress(1, 0.55)
	key(KEY_A, true)
	await click()
	await progress(2, 0.05)
	check(player.melee.model.locked_facing == -1 and player.facing == -1, "Direction changes at actual segment boundary")
	key(KEY_A, false)
	await frames(40)
	await reset_fixture()
	await click()
	await progress(1, 0.6)
	await click()
	key(KEY_SPACE, true)
	await frames(1)
	key(KEY_SPACE, false)
	check(player.actions.phase == "dodge" and not player.melee.model.is_attacking(), "Space interrupts actual attack")
	check(not player.melee.model.pending and not player.melee.model.can_damage(), "Dodge clears queued attack and hit window")
	var hits: int = target.received_count
	await frames(40)
	check(target.received_count == hits, "Cancelled swing has no residual hits")
	await reset_fixture()
	target.position = Vector2(150,580)
	await click()
	await frames(50)
	check(target.received_count == 0, "Attacks cannot hit or pull targets behind")
	await reset_fixture()
	var wall := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20,100)
	collider.shape = shape
	wall.position = Vector2(270,530)
	wall.add_child(collider)
	scene.add_child(wall)
	await frames(3)
	await click()
	await frames(50)
	check(target.received_count == 0 and is_zero_approx(player.melee.assist_used), "Wall blocks both assistance and damage")
	check(player.position.x < 245, "Attack motion cannot pass through wall")
	wall.queue_free()
	await frames(2)
	await reset_fixture()
	key(KEY_W,true)
	await frames(5)
	key(KEY_W,false)
	await click()
	check(not player.melee.model.is_attacking(), "Air left click does not trigger melee")
	await frames(60)
	await reset_fixture()
	await click()
	await progress(1,0.6)
	await click()
	player.receive_hit()
	check(not player.melee.model.pending and not player.melee.model.is_attacking(), "Being hit clears pending attack")
	await frames(40)
	await reset_fixture()
	player.position = Vector2(710,420)
	target.position = Vector2(810,420)
	await frames(1)
	await click()
	await frames(40)
	check(player.position.x <= 730, "Attack assist cannot drag actor off platform edge")
	print("MELEE_INPUT_CHECKS: ", checks-failures.size(), "/", checks)
	player.bullet_time.reset()
	quit(0 if failures.is_empty() else 1)
