extends SceneTree
var checks: int = 0
var failures: Array[String] = []
var scene
var player
var target
var spells
var held_mask: int = 0
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
func mouse(button: MouseButton, pressed: bool) -> void:
	if pressed:
		held_mask |= 1 << (button-1)
	else:
		held_mask &= ~(1 << (button-1))
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.button_mask = held_mask
	e.pressed = pressed
	Input.parse_input_event(e)
func point(world: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = scene.get_canvas_transform() * world
	e.global_position = e.position
	e.button_mask = held_mask
	Input.parse_input_event(e)
func click() -> void:
	mouse(MOUSE_BUTTON_LEFT,true)
	await frames(1)
	mouse(MOUSE_BUTTON_LEFT,false)
func reset_fixture() -> void:
	mouse(MOUSE_BUTTON_RIGHT,false)
	mouse(MOUSE_BUTTON_LEFT,false)
	key(KEY_A,false)
	key(KEY_D,false)
	key(KEY_W,false)
	key(KEY_R,true)
	await frames(1)
	key(KEY_R,false)
	player.position = Vector2(210,580)
	player.velocity = Vector2.ZERO
	player.facing = 1
	target.position = Vector2(310,580)
	target.velocity = Vector2.ZERO
	target.patrol_enabled = false
	await frames(4)
	point(target.position + Vector2(0,-50))
func _run() -> void:
	root.size = Vector2i(1280,720)
	await frames(2)
	if not ResourceLoader.exists("res://Scripts/Talisman/talisman_controller.gd"):
		push_error("Missing immobilizing talisman controller")
		quit(1)
		return
	scene = load("res://Scenes/Tests/PlayerPlayground.tscn").instantiate()
	root.add_child(scene)
	await frames(20)
	player = scene.get_node("Player")
	target = scene.get_node("PracticeTarget300")
	spells = player.talismans
	check(spells.charges == spells.config.capacity, "Starts with full charges")
	check(spells.config.combat_recharge > spells.config.idle_recharge, "Combat recovery is slower")
	key(KEY_Y,true)
	await frames(1)
	key(KEY_Y,false)
	check(target.patrol_enabled, "Y enables moving targets")
	key(KEY_Y,true)
	await frames(1)
	key(KEY_Y,false)
	check(not target.patrol_enabled, "Y disables moving targets")
	await reset_fixture()
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	check(spells.aiming, "Right hold enters ground aim")
	var pos: Vector2 = player.position
	key(KEY_D,true)
	key(KEY_W,true)
	await frames(8)
	check(player.position.distance_to(pos) < 0.2 and player.is_on_floor(), "Aim locks movement and jumping")
	key(KEY_D,false)
	key(KEY_W,false)
	check(player.facing == 1, "Mouse aim does not alter melee facing")
	check(spells.aim_point.distance_to(target.position+Vector2(0,-50)) < 1, "Mouse coordinates match the world target")
	var startups: int = player.melee.model.startup_count
	mouse(MOUSE_BUTTON_LEFT,true)
	await frames(25)
	mouse(MOUSE_BUTTON_LEFT,false)
	check(spells.cast_count == 1 and spells.charges == spells.config.capacity-1, "Held left fires only once and consumes one charge")
	check(player.melee.model.startup_count == startups, "Aimed left cannot start melee")
	check(target.immobilized_left > 0 and spells.target_hits == 1, "Actual projectile immobilizes target")
	check(target.health == target.max_health, "Immobilizing talisman does not invent direct damage")
	check(get_nodes_in_group("talisman_projectile").is_empty(), "Projectile resolves only once")
	check(spells.aiming, "Firing keeps right hold aim")
	mouse(MOUSE_BUTTON_RIGHT,false)
	await frames(2)
	check(not spells.aiming, "Right release exits aim")
	target.patrol_enabled = true
	var fixed: Vector2 = target.position
	await frames(30)
	check(target.position.is_equal_approx(fixed), "Immobilized moving target stays fixed")
	await click()
	await frames(30)
	check(target.health < target.max_health and target.immobilized_left > 0, "Melee can hurt a bound target without breaking control")
	await frames(80)
	check(target.immobilized_left == 0 and absf(target.velocity.x) > 1, "Target resumes movement after two seconds")
	await reset_fixture()
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	await click()
	await frames(15)
	var previous: float = target.immobilized_left
	check(previous > 1.5, "Refresh fixture was actually immobilized")
	await frames(20)
	point(target.position+Vector2(0,-50))
	await click()
	await frames(15)
	check(target.immobilized_left > previous-0.2 and target.immobilized_left <= spells.config.bind_duration, "Repeated hit refreshes duration instead of stacking")
	mouse(MOUSE_BUTTON_RIGHT,false)
	await reset_fixture()
	key(KEY_W,true)
	await frames(5)
	key(KEY_W,false)
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	await click()
	check(not spells.aiming and spells.cast_count == 0 and not player.melee.model.is_attacking(), "Air aim and air cast are disabled")
	mouse(MOUSE_BUTTON_RIGHT,false)
	await frames(70)
	await reset_fixture()
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	key(KEY_SPACE,true)
	await frames(1)
	key(KEY_SPACE,false)
	check(player.actions.phase == "dodge" and not spells.aiming, "Dodge cancels aim")
	await frames(28)
	check(not spells.aiming, "Held right cannot immediately reenter after interruption")
	mouse(MOUSE_BUTTON_RIGHT,false)
	await frames(1)
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	check(spells.aiming, "Release and rehold permits aiming again")
	player.receive_hit()
	await frames(2)
	check(not spells.aiming, "Being hit interrupts aim")
	mouse(MOUSE_BUTTON_RIGHT,false)
	await reset_fixture()
	await click()
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	check(player.melee.model.is_attacking() and not spells.aiming, "Aim cannot cut an ongoing melee attack")
	mouse(MOUSE_BUTTON_RIGHT,false)
	await frames(60)
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
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	await click()
	await frames(20)
	check(spells.environment_hits == 1 and spells.target_hits == 0 and target.immobilized_left == 0, "Wall activates talisman and blocks targets behind")
	wall.queue_free()
	mouse(MOUSE_BUTTON_RIGHT,false)
	await frames(2)
	await reset_fixture()
	point(Vector2(210,0))
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	await click()
	await frames(100)
	check(get_nodes_in_group("talisman_projectile").is_empty() and spells.target_hits == 0, "Missed projectile expires at max range")
	mouse(MOUSE_BUTTON_RIGHT,false)
	await reset_fixture()
	spells.charges = 0
	spells.recharge_progress = 0
	spells.combat_left = 4
	spells.advance_recharge(0.5)
	var combat_progress: float = spells.recharge_progress
	spells.recharge_progress = 0
	spells.combat_left = 0
	spells.advance_recharge(0.5)
	check(spells.recharge_progress > combat_progress, "Actual recharge method runs faster outside combat")
	spells.advance_recharge(20)
	check(spells.charges == spells.config.capacity, "Recharge caps at capacity")
	await reset_fixture()
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	await click()
	await frames(1)
	mouse(MOUSE_BUTTON_RIGHT,false)
	key(KEY_R,true)
	await frames(1)
	key(KEY_R,false)
	check(get_nodes_in_group("talisman_projectile").is_empty() and target.immobilized_left == 0 and spells.charges == spells.config.capacity, "Reset removes projectiles and control and restores charges")
	await reset_fixture()
	mouse(MOUSE_BUTTON_RIGHT,true)
	await frames(2)
	for i in spells.config.capacity:
		await click()
		await frames(17)
	check(spells.charges == 0 and spells.cast_count == spells.config.capacity, "All charges can be spent individually")
	await click()
	check(spells.cast_count == spells.config.capacity, "Empty charges cannot cast")
	mouse(MOUSE_BUTTON_RIGHT,false)
	print("TALISMAN_INPUT_CHECKS: ", checks-failures.size(), "/", checks)
	player.bullet_time.reset()
	scene.feedback.reset()
	quit(0 if failures.is_empty() else 1)
