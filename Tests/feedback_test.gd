extends SceneTree
var checks: int = 0
var failures: Array[String] = []
var scene
var player
var target
var feedback
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
func reset_fixture() -> void:
	mouse(false)
	key(KEY_R,true)
	await frames(1)
	key(KEY_R,false)
	player.position = Vector2(210,580)
	player.velocity = Vector2.ZERO
	player.facing = 1
	target.position = Vector2(310,580)
	target.velocity = Vector2.ZERO
	await frames(4)
func until_frozen() -> void:
	for i in 80:
		if feedback.is_frozen():
			return
		await frames(1)
	check(false, "Actual hit must begin feedback stop")
func _run() -> void:
	scene = load("res://Scenes/Tests/PlayerPlayground.tscn").instantiate()
	root.add_child(scene)
	await frames(20)
	feedback = get_first_node_in_group("combat_feedback")
	if feedback == null:
		push_error("Missing actual combat feedback")
		quit(1)
		return
	player = scene.get_node("Player")
	target = scene.get_node("PracticeTarget300")
	check(not feedback.audio.audio_enabled, "Headless tests default to muted audio")
	check(feedback.audio.sounds["swing"].data.size() > 1000 and feedback.audio.sounds["hit"].data.size() > 1000, "Real sound clips contain PCM data")
	await reset_fixture()
	target.position = Vector2(650,420)
	mouse(true)
	await frames(1)
	mouse(false)
	await frames(60)
	check(feedback.audio.swing_events == 1, "Miss plays one swing")
	check(feedback.audio.hit_events == 0 and feedback.freeze_count == 0 and feedback.impact_count == 0, "Miss has no impact feedback")
	await reset_fixture()
	# Delay hit until combo window, and use a long controlled stop for input inspection.
	var def: Resource = player.tuning.attack_one
	var original_start: float = def.hit_start
	var original_end: float = def.hit_end
	var original_stop: float = def.hitstop
	def.hit_start = 0.55
	def.hit_end = 0.8
	def.hitstop = 0.15
	mouse(true)
	await frames(1)
	mouse(false)
	await until_frozen()
	check(feedback.freeze_count == 1 and feedback.impact_count == 1, "Actual hit starts impact feedback")
	check(feedback.audio.hit_events == 1 and feedback.audio.audible_play_count == 0, "Hit triggers sound event but tests stay muted")
	check(feedback.effects.size() == 1 and feedback.shake_left > 0, "Hit creates VFX and camera impulse")
	var buffered_serial: int = player.melee.model.serial
	var progress: float = player.melee.model.progress()
	var pose: Vector2 = player.position
	var target_pose: Vector2 = target.position
	await frames(1)
	check(is_equal_approx(player.melee.model.progress(),progress) and player.position.is_equal_approx(pose), "Hitstop freezes actual attack model and movement")
	check(target.position.is_equal_approx(target_pose), "Hitstop freezes target knockback")
	mouse(true)
	await frames(1)
	mouse(false)
	check(player.melee.model.pending, "Combo input during stop is retained")
	check(is_equal_approx(player.melee.model.progress(),progress), "Input does not advance frozen animation")
	await frames(70)
	check(player.melee.model.serial == buffered_serial + 1, "Buffered stopped input chains exactly one attack")
	check(not feedback.is_frozen() and feedback.effects.is_empty(), "Stop and impact effects finish")
	check(feedback.camera.offset.is_equal_approx(feedback.camera_base), "Shake returns camera to original offset")
	check(is_equal_approx(Engine.time_scale,1), "Hitstop does not alter engine time scale")
	def.hit_start = original_start
	def.hit_end = original_end
	def.hitstop = original_stop
	await reset_fixture()
	var second = scene.get_node("PracticeTarget980")
	second.position = Vector2(325,580)
	second.velocity = Vector2.ZERO
	await frames(3)
	mouse(true)
	await frames(1)
	mouse(false)
	await until_frozen()
	check(target.received_count == 1 and second.received_count == 1, "One swing can hit multiple targets")
	check(feedback.freeze_count == 1 and feedback.audio.hit_events == 1 and feedback.impact_count == 2, "Multiple targets coalesce global stop and sound")
	await frames(60)
	await reset_fixture()
	def.hitstop = 0.15
	mouse(true)
	await frames(1)
	mouse(false)
	await until_frozen()
	key(KEY_SPACE,true)
	await frames(1)
	key(KEY_SPACE,false)
	check(player.actions.phase == "dodge" and not player.melee.model.is_attacking(), "Dodge still interrupts during hitstop")
	check(not feedback.is_frozen(), "Dodge releases stop for immediate control")
	await frames(30)
	def.hitstop = original_stop
	await reset_fixture()
	player.bullet_time.trigger(0.15,0.25)
	feedback.hitstop_left = 0.04
	await frames(35)
	check(not player.bullet_time.active and not feedback.is_frozen() and is_equal_approx(Engine.time_scale,1), "Bullet time and hitstop restore independently")
	await reset_fixture()
	check(feedback.effects.is_empty() and not feedback.is_frozen() and feedback.camera.offset.is_equal_approx(feedback.camera_base), "Reset clears transient feedback")
	player.bullet_time.reset()
	feedback.reset()
	print("FEEDBACK_CHECKS: ", checks-failures.size(), "/", checks)
	quit(0 if failures.is_empty() else 1)
