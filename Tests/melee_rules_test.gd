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
func _run() -> void:
	var path := "res://Scripts/Combat/melee_model.gd"
	if not ResourceLoader.exists(path):
		push_error("Missing melee model")
		quit(1)
		return
	var tuning = load("res://Resources/Player/default_tuning.tres")
	var model = load(path).new()
	model.tuning = tuning
	check(not model.request_attack(false, 1), "Air attack disabled")
	check(model.request_attack(true, 1) and model.phase == "startup", "Ground start has startup")
	check(not model.request_attack(true, -1), "Startup clicks ignored")
	model.step(tuning.attack_one.startup_duration, -1.0)
	check(model.phase == "action" and model.segment == 1 and model.locked_facing == 1, "Startup locks initial facing")
	model.step(tuning.attack_one.action_duration * 0.49, -1.0)
	check(not model.request_attack(true, -1) and not model.pending, "49 percent click ignored")
	model.step(tuning.attack_one.action_duration * 0.01, -1.0)
	check(not model.request_attack(true, -1), "Exactly 50 percent ignored")
	model.step(tuning.attack_one.action_duration * 0.01, -1.0)
	check(model.request_attack(true, -1) and model.pending, "51 percent buffers next")
	model.request_attack(true, -1)
	model.request_attack(true, -1)
	check(model.segment == 1 and model.locked_facing == 1, "Buffer cannot turn or cut current action")
	model.step(tuning.attack_one.action_duration * 0.5, -1.0)
	check(model.phase == "action" and model.segment == 2 and model.locked_facing == -1, "Buffered segment skips recovery and turns at boundary")
	check(model.startup_count == 1 and not model.pending, "No second startup or multi-click queue")
	model.step(tuning.attack_two.action_duration, 0.0)
	check(model.phase == "recovery", "No new clicks means recovery")
	check(model.request_attack(true, 1), "Recovery click cancels immediately")
	check(model.phase == "action" and model.segment == 1 and model.locked_facing == 1, "Recovery loops to first action without startup")
	check(model.startup_count == 1, "Looping first segment skips startup")
	model.step(tuning.attack_one.action_duration, 0.0)
	model.step(tuning.attack_one.recovery_duration, 0.0)
	check(model.phase == "idle", "Unchained recovery finishes")
	model.request_attack(true, -1)
	check(model.phase == "startup" and model.startup_count == 2, "New sequence restores startup")
	model.step(tuning.attack_one.startup_duration, 0.0)
	model.step(tuning.attack_one.action_duration * 0.6, 0.0)
	model.request_attack(true, 1)
	model.cancel()
	check(model.phase == "idle" and not model.pending and not model.can_damage(), "Cancel clears pending and damage")
	model.request_attack(true, 1)
	model.step(tuning.attack_one.startup_duration, 0.0)
	model.step(tuning.attack_one.action_duration, 0.0)
	check(not model.can_damage(), "Recovery never damages")
	print("MELEE_RULE_CHECKS: ", checks-failures.size(), "/", checks)
	quit(0 if failures.is_empty() else 1)
