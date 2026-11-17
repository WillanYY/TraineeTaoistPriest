extends SceneTree
var checks: int = 0
var failures: Array[String] = []
var scene
var player
var ledge: StaticBody2D
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
func block(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.position = pos
	body.add_child(collider)
	scene.add_child(body)
	return body
func reset_fixture(pos: Vector2 = Vector2(270,580), facing: int = 1) -> void:
	key(KEY_A,false)
	key(KEY_D,false)
	key(KEY_W,false)
	key(KEY_SPACE,false)
	key(KEY_R,true)
	await frames(1)
	key(KEY_R,false)
	player.position = pos
	player.velocity = Vector2.ZERO
	player.facing = facing
	await frames(4)
func wait_for_climb() -> bool:
	for i in 90:
		if player.climb.active:
			return true
		await frames(1)
	return false
func _run() -> void:
	if not ResourceLoader.exists("res://Scripts/Player/ledge_climb.gd"):
		push_error("Missing automatic ledge climb")
		quit(1)
		return
	root.size = Vector2i(1280,720)
	await frames(2)
	scene = load("res://Scenes/Tests/PlayerPlayground.tscn").instantiate()
	root.add_child(scene)
	await frames(20)
	player = scene.get_node("Player")
	ledge = scene.get_node("ClimbPlatform")
	await frames(3)
	await reset_fixture()
	await frames(10)
	check(not player.climb.active and player.climb.climb_count == 0, "Ground idle cannot trigger climbing")
	key(KEY_D,true)
	key(KEY_W,true)
	var started := await wait_for_climb()
	check(started, "Jump near right-facing ledge automatically climbs")
	check(player.view.animation == "climb", "Uses supplied climb animation")
	key(KEY_D,false)
	key(KEY_W,false)
	var locked: int = player.facing
	key(KEY_A,true)
	key(KEY_SPACE,true)
	await frames(4)
	check(player.climb.active and player.facing == locked and player.actions.phase == "free", "Climb locks input without starting dodge")
	key(KEY_A,false)
	key(KEY_SPACE,false)
	await frames(45)
	check(not player.climb.active and player.is_on_floor(), "Climb finishes grounded")
	check(absf(player.position.y - 390) < 1 and player.position.x > 316, "Actor stands safely inside ledge")
	check(player.velocity.is_zero_approx(), "No launch velocity leaks from climbing")
	await reset_fixture(Vector2(990,580),-1)
	key(KEY_A,true)
	key(KEY_W,true)
	started = await wait_for_climb()
	check(started and player.climb.locked_facing == -1, "Left-facing ledge also climbs")
	key(KEY_A,false)
	key(KEY_W,false)
	await frames(45)
	check(absf(player.position.y - 420) < 1 and player.is_on_floor(), "Left climb lands on platform top")
	# Ledge exists, but there is not enough standing clearance.
	var roof := block(Vector2(360,300),Vector2(120,20))
	await reset_fixture()
	key(KEY_D,true)
	key(KEY_W,true)
	await frames(28)
	key(KEY_D,false)
	key(KEY_W,false)
	check(player.climb.climb_count == 0 and not player.climb.active, "Low ceiling blocks climbing")
	roof.queue_free()
	await frames(3)
	await reset_fixture()
	key(KEY_D,true)
	key(KEY_W,true)
	started = await wait_for_climb()
	check(started, "Interrupt fixture starts climb")
	key(KEY_D,false)
	key(KEY_W,false)
	player.receive_hit()
	await frames(1)
	check(not player.climb.active and player.health == 90, "Climb grants no invulnerability and hit interrupts")
	await reset_fixture()
	key(KEY_D,true)
	key(KEY_W,true)
	started = await wait_for_climb()
	check(started, "Dynamic obstruction fixture starts climb")
	key(KEY_D,false)
	key(KEY_W,false)
	var barrier := block(Vector2(280,335),Vector2(80,20))
	await frames(40)
	check(player.climb.abort_count > 0 and not player.climb.active, "New obstruction aborts climb instead of tunneling")
	barrier.queue_free()
	await frames(3)
	ledge.position.y = 250
	await reset_fixture()
	key(KEY_W,true)
	await frames(40)
	key(KEY_W,false)
	check(player.climb.climb_count == 0, "Unreachable high ledge cannot be grabbed")
	ledge.position.y = 400
	await reset_fixture(Vector2(270,490),-1)
	key(KEY_A,true)
	await frames(8)
	key(KEY_A,false)
	check(player.climb.climb_count == 0, "Facing away does not grab behind")
	await reset_fixture()
	key(KEY_D,true)
	key(KEY_W,true)
	started = await wait_for_climb()
	key(KEY_D,false)
	key(KEY_W,false)
	key(KEY_R,true)
	await frames(1)
	key(KEY_R,false)
	check(not player.climb.active and player.climb.climb_count == 0, "Reset clears climbing state")
	print("CLIMB_INPUT_CHECKS: ",checks-failures.size(),"/",checks)
	player.bullet_time.reset()
	scene.feedback.reset()
	quit(0 if failures.is_empty() else 1)
