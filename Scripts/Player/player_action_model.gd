extends RefCounted
var tuning: Resource
var phase: String = "free"
var phase_elapsed: float = 0.0
var locked_facing: int = 1
var running: bool = false
var cooldown_left: float = 0.0
var cooldown_running: bool = false
var waiting_for_landing: bool = false
var reward_used: bool = false
func is_invulnerable() -> bool:
	return phase == "dodge"
func begin_dodge(grounded: bool, facing: int) -> bool:
	if phase != "free" or cooldown_left > 0.0 or waiting_for_landing:
		return false
	phase = "dodge"
	phase_elapsed = 0.0
	locked_facing = facing
	running = false
	reward_used = false
	cooldown_left = tuning.dodge_cooldown
	cooldown_running = false
	waiting_for_landing = not grounded
	return true
func step(delta: float, direction: float, grounded: bool) -> void:
	var entered_recovery := false
	if cooldown_running:
		cooldown_left = maxf(0.0, cooldown_left - delta)
		if cooldown_left == 0.0:
			cooldown_running = false
	if phase != "dodge" and waiting_for_landing and grounded:
		waiting_for_landing = false
		cooldown_running = true
	if phase == "dodge":
		phase_elapsed += delta
		if phase_elapsed + 0.000001 >= tuning.dodge_duration:
			phase = "recovery"
			entered_recovery = true
			phase_elapsed = 0.0
			waiting_for_landing = not grounded
			cooldown_running = grounded
	if phase == "recovery":
		if not entered_recovery:
			phase_elapsed += delta
		if direction != 0.0:
			phase = "free"
			running = grounded
		elif phase_elapsed + 0.000001 >= tuning.dodge_recovery:
			phase = "free"
			running = false
	if direction == 0.0 or not grounded:
		running = false
func resolve_hit() -> String:
	if not is_invulnerable():
		return "hurt"
	if not reward_used:
		reward_used = true
		return "perfect"
	return "evaded"
