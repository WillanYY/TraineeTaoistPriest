extends SceneTree
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
func tap(code: Key) -> void:
	key(code, true)
	await frames(1)
	key(code, false)
func _run() -> void:
	var scene = load("res://Scenes/Tests/PlayerPlayground.tscn").instantiate()
	root.add_child(scene)
	await frames(20)
	var player = scene.get_node("Player")
	var device = scene.get_node("AttackDevice")
	check(not device.enabled, "Attack device defaults off")
	var start: Vector2 = player.position
	await tap(KEY_SPACE)
	check(player.actions.phase == "dodge", "Space starts dodge")
	key(KEY_A, true)
	await frames(5)
	check(player.facing == 1 and player.position.x > start.x + 30, "Dodge locks direction against A")
	check(absf(player.position.y - start.y) < 1, "Ground dodge stays level")
	check(player.bullet_time.trigger_count == 0, "Empty dodge cannot trigger bullet time")
	await frames(12)
	check(player.actions.running and player.actions.phase == "free", "Held A cancels recovery to run")
	await frames(6)
	check(player.velocity.x < -player.tuning.walk_speed, "Run is faster than walk")
	check(player.view.animation == "run", "Run animation is shown")
	key(KEY_A, false)
	await frames(6)
	check(not player.actions.running, "Release ends run")
	await frames(140)
	check(player.actions.cooldown_left == 0, "Dodge recharges once")
	await tap(KEY_R)
	await frames(20)
	key(KEY_W, true)
	await frames(5)
	key(KEY_W, false)
	await frames(1)
	await tap(KEY_SPACE)
	var air_y: float = player.position.y
	await frames(5)
	check(absf(player.position.y - air_y) < 0.1 and player.velocity.y == 0, "Air dodge suspends gravity")
	check(player.actions.waiting_for_landing and not player.actions.cooldown_running, "Air use waits for landing")
	await frames(9)
	var cd: float = player.actions.cooldown_left
	check(not player.is_on_floor() and is_equal_approx(cd, player.tuning.dodge_cooldown), "Air recovery does not recharge")
	await frames(70)
	check(player.actions.cooldown_running and player.actions.cooldown_left < cd, "Landing begins recharge")
	await tap(KEY_R)
	await frames(20)
	player.position = Vector2(1090, 580)
	player.velocity = Vector2.ZERO
	await frames(4)
	await tap(KEY_T)
	check(device.enabled, "T enables real attack device")
	device.cycle = device.interval - 0.05
	await tap(KEY_SPACE)
	await frames(4)
	check(player.perfect_count == 1 and player.health == 100, "Real device strike is evaded")
	check(player.bullet_time.trigger_count == 1, "Real evasion triggers bullet time once")
	check(player.bullet_time.active and Engine.time_scale < 1, "Bullet time slows simulation")
	player.receive_hit()
	check(player.perfect_count == 1, "More hits in same dodge grant no repeat reward")
	await frames(50)
	check(not player.bullet_time.active and is_equal_approx(Engine.time_scale, 1.0), "Bullet time restores normal speed")
	await tap(KEY_T)
	await tap(KEY_R)
	await frames(20)
	player.position = Vector2(1090, 580)
	await frames(4)
	await tap(KEY_T)
	device.cycle = device.interval - 0.02
	await frames(5)
	check(player.damage_count == 1 and player.health == 90, "Device hurts unprotected player once per strike")
	check(player.perfect_count == 0 and not player.bullet_time.active, "Unprotected hit cannot grant bullet time")
	await tap(KEY_T)
	await tap(KEY_R)
	await frames(20)
	player.position = Vector2(1200, 580)
	player.velocity = Vector2.ZERO
	await frames(3)
	await tap(KEY_SPACE)
	await frames(15)
	check(player.position.x <= 1224.1, "Dodge cannot pass through wall")
	# Recovery is vulnerable after an empty dodge.
	check(player.actions.phase == "recovery", "Uncancelled dodge enters recovery")
	var health: int = player.health
	check(player.receive_hit() == "hurt" and player.health == health - 10, "Recovery damage reaches health")
	await frames(20)
	check(not player.bullet_time.active, "Recovery hit gives no bullet time")
	print("DODGE_INPUT_CHECKS: ", checks-failures.size(), "/", checks)
	player.bullet_time.reset()
	quit(0 if failures.is_empty() else 1)
