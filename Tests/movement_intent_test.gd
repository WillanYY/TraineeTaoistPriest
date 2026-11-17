extends SceneTree
var checks: int = 0
var failures: Array[String] = []
var scene
var player
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
func key(code: Key, pressed: bool, echo: bool = false) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	Input.parse_input_event(e)
func mouse(button: MouseButton, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	Input.parse_input_event(e)
func tap(code: Key) -> void:
	key(code,true)
	await frames(1)
	key(code,false)
	await frames(2)
func reset_fixture(pos: Vector2 = Vector2(210,580), facing: int = 1) -> void:
	for code in [KEY_A,KEY_D,KEY_W,KEY_SPACE]:
		key(code,false)
	mouse(MOUSE_BUTTON_LEFT,false)
	mouse(MOUSE_BUTTON_RIGHT,false)
	key(KEY_R,true)
	await frames(1)
	key(KEY_R,false)
	player.position = pos
	player.velocity = Vector2.ZERO
	player.facing = facing
	await frames(4)
func _run() -> void:
	root.size = Vector2i(1280,720)
	await frames(2)
	scene = load("res://Scenes/Tests/PlayerPlayground.tscn").instantiate()
	root.add_child(scene)
	await frames(20)
	player = scene.get_node("Player")
	await reset_fixture(Vector2(270,490))
	await frames(3)
	check(not player.climb.active and player.climb.climb_count == 0, "No input at reachable lip must not climb")
	await reset_fixture(Vector2(270,490))
	key(KEY_W,true)
	await frames(3)
	check(not player.climb.active and player.climb.climb_count == 0, "Jump alone at lip must not climb")
	await reset_fixture(Vector2(270,490))
	key(KEY_D,true)
	await frames(3)
	check(not player.climb.active and player.climb.climb_count == 0, "Direction alone at lip must not climb")
	await reset_fixture(Vector2(270,490))
	key(KEY_A,true)
	key(KEY_D,true)
	key(KEY_W,true)
	await frames(3)
	check(not player.climb.active, "Opposing directions plus jump do not climb")
	await reset_fixture(Vector2(270,490))
	key(KEY_D,true)
	key(KEY_W,true)
	await frames(3)
	check(player.climb.active, "Held jump and right toward lip climb")
	await reset_fixture(Vector2(980,520),-1)
	key(KEY_A,true)
	key(KEY_W,true)
	await frames(3)
	check(player.climb.active and player.climb.locked_facing == -1, "Held jump and left toward lip climb")
	await reset_fixture()
	key(KEY_D,true)
	await frames(40)
	check(not player.actions.running and absf(player.velocity.x) <= player.tuning.walk_speed+0.1, "Single hold stays walking")
	await reset_fixture()
	await tap(KEY_D)
	key(KEY_D,true)
	await frames(20)
	check(player.actions.running and player.velocity.x > player.tuning.walk_speed, "Double D enters run")
	check(player.view.animation == "run", "Double tap uses run animation")
	key(KEY_D,false)
	await frames(10)
	check(not player.actions.running, "Releasing direction exits running")
	await reset_fixture()
	await tap(KEY_A)
	key(KEY_A,true)
	await frames(20)
	check(player.actions.running and player.velocity.x < -player.tuning.walk_speed, "Double A enters run")
	await reset_fixture()
	await tap(KEY_D)
	await frames(25)
	key(KEY_D,true)
	await frames(12)
	check(not player.actions.running, "Late second tap does not run")
	await reset_fixture()
	await tap(KEY_A)
	key(KEY_D,true)
	await frames(12)
	check(not player.actions.running, "Opposite key taps do not count as double tap")
	await reset_fixture()
	key(KEY_D,true)
	await frames(2)
	for i in 3:
		key(KEY_D,true,true)
		await frames(2)
	check(not player.actions.running, "Keyboard echo cannot trigger double tap")
	await reset_fixture()
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	await tap(KEY_D)
	key(KEY_D,true)
	await frames(4)
	check(player.talismans.aiming and not player.actions.running, "Aim rejects double tap running")
	mouse(MOUSE_BUTTON_RIGHT,false)
	await frames(10)
	check(not player.actions.running, "Aim inputs do not queue later run")
	await reset_fixture()
	mouse(MOUSE_BUTTON_LEFT,true)
	await frames(1)
	mouse(MOUSE_BUTTON_LEFT,false)
	await tap(KEY_D)
	key(KEY_D,true)
	await frames(4)
	check(player.melee.model.is_attacking() and not player.actions.running, "Melee rejects double tap running")
	await frames(45)
	check(not player.actions.running, "Attack inputs do not queue later run")
	await reset_fixture()
	key(KEY_W,true)
	await frames(5)
	key(KEY_W,false)
	await tap(KEY_D)
	key(KEY_D,true)
	await frames(3)
	check(not player.actions.running, "Air double taps do not enter ground running")
	await reset_fixture()
	Engine.time_scale = 0.25
	await tap(KEY_D)
	await frames(20)
	key(KEY_D,true)
	await frames(2)
	check(not player.actions.running, "Double tap timeout uses real time during slow motion")
	Engine.time_scale = 1
	await reset_fixture()
	Engine.time_scale = 0.25
	await tap(KEY_D)
	await frames(3)
	key(KEY_D,true)
	await frames(2)
	check(player.actions.running, "Quick double taps still work during slow motion")
	Engine.time_scale = 1
	await reset_fixture()
	print("MOVEMENT_INTENT_CHECKS: ",checks-failures.size(),"/",checks)
	player.bullet_time.reset()
	scene.feedback.reset()
	quit(0 if failures.is_empty() else 1)
