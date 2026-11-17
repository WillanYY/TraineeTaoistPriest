extends SceneTree
var failures: Array[String] = []
var checks: int = 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func _run() -> void:
	var model_path := "res://Scripts/Player/player_action_model.gd"
	if not ResourceLoader.exists(model_path):
		push_error("Missing dodge action model")
		quit(1)
		return
	var tuning = load("res://Resources/Player/default_tuning.tres")
	var model = load(model_path).new()
	model.tuning = tuning
	check(model.begin_dodge(true, 1), "Ground dodge starts")
	check(model.phase == "dodge" and model.is_invulnerable(), "Action is invulnerable")
	model.step(0.10, -1.0, true)
	check(model.locked_facing == 1 and model.phase == "dodge", "Movement cannot redirect action")
	check(model.resolve_hit() == "perfect", "Real hit grants one perfect dodge")
	check(model.resolve_hit() == "evaded", "Repeated hits cannot grant reward again")
	model.step(0.101, 0.0, true)
	check(model.phase == "recovery" and not model.is_invulnerable(), "Recovery is vulnerable")
	check(model.resolve_hit() == "hurt", "Recovery hit hurts")
	check(not model.begin_dodge(true, 1), "Single charge blocks a second dodge")
	check(is_equal_approx(model.cooldown_left, tuning.dodge_cooldown), "Cooldown starts at action end")
	model.step(0.01, -1.0, true)
	check(model.phase == "free" and model.running, "Held move cancels recovery to run")
	model.step(0.01, 0.0, true)
	check(not model.running, "Releasing movement ends run")
	model.step(3.0, 0.0, true)
	check(model.begin_dodge(false, -1), "Air dodge starts")
	model.step(0.201, 0.0, false)
	var cd: float = model.cooldown_left
	model.step(3.0, 0.0, false)
	check(is_equal_approx(model.cooldown_left, cd) and model.waiting_for_landing, "Air dodge cannot recharge before landing")
	check(not model.begin_dodge(false, 1), "Air charge cannot be reused")
	model.step(0.01, 0.0, true)
	check(not model.waiting_for_landing and model.cooldown_running, "Landing starts recharge")
	model.step(0.25, 0.0, false)
	check(model.cooldown_left < cd, "Recharge already started continues airborne")
	model.step(3.0, 0.0, true)
	model.begin_dodge(true, 1)
	model.step(0.201, 0.0, true)
	model.step(tuning.dodge_recovery + 0.01, 0.0, true)
	check(model.phase == "free" and not model.running, "Natural recovery returns to walk/idle")
	model.step(3.0, 0.0, true)
	model.begin_dodge(false, 1)
	model.step(0.201, 0.0, false)
	model.step(0.01, 1.0, false)
	check(model.phase == "free" and not model.running, "Air cancel returns to air control not ground run")
	var boundary_model = load(model_path).new()
	boundary_model.tuning = tuning
	boundary_model.begin_dodge(true, 1)
	boundary_model.step(tuning.dodge_duration, 0.0, true)
	check(boundary_model.phase == "recovery" and is_zero_approx(boundary_model.phase_elapsed), "Action time cannot also consume recovery")
	boundary_model.step(tuning.dodge_recovery - 0.001, 0.0, true)
	check(boundary_model.phase == "recovery", "Recovery lasts its configured duration")
	boundary_model.step(0.002, 0.0, true)
	check(boundary_model.phase == "free", "Recovery exits after its duration")
	print("DODGE_RULE_CHECKS: ", checks-failures.size(), "/", checks)
	quit(0 if failures.is_empty() else 1)
