extends RefCounted
var tuning: Resource
var phase: String = "idle"
var elapsed: float = 0.0
var segment: int = 1
var locked_facing: int = 1
var pending: bool = false
var serial: int = 0
var startup_count: int = 0
func definition() -> Resource:
	return tuning.attack_one if segment == 1 else tuning.attack_two
func is_attacking() -> bool:
	return phase != "idle"
func progress() -> float:
	return clampf(elapsed / maxf(definition().action_duration, 0.001), 0, 1) if phase == "action" else 0.0
func can_damage() -> bool:
	var p := progress()
	return phase == "action" and p >= definition().hit_start and p <= definition().hit_end
func request_attack(grounded: bool, facing: int) -> bool:
	if not grounded:
		return false
	if phase == "idle":
		segment = 1
		locked_facing = facing
		phase = "startup"
		elapsed = 0.0
		pending = false
		startup_count += 1
		return true
	if phase == "action" and progress() > 0.5 + 0.000001:
		pending = true
		return true
	if phase == "recovery":
		_enter_action(3 - segment, facing)
		return true
	return false
func _enter_action(next_segment: int, facing: int) -> void:
	segment = next_segment
	locked_facing = facing
	phase = "action"
	elapsed = 0.0
	pending = false
	serial += 1
func step(delta: float, direction: float) -> void:
	if phase == "idle":
		return
	elapsed += delta
	var facing := locked_facing if direction == 0 else (1 if direction > 0 else -1)
	if phase == "startup" and elapsed + 0.000001 >= definition().startup_duration:
		_enter_action(1, locked_facing)
	elif phase == "action" and elapsed + 0.000001 >= definition().action_duration:
		if pending:
			_enter_action(3 - segment, facing)
		else:
			phase = "recovery"
			elapsed = 0.0
	elif phase == "recovery" and elapsed + 0.000001 >= definition().recovery_duration:
		cancel()
func cancel() -> void:
	phase = "idle"
	elapsed = 0.0
	pending = false
