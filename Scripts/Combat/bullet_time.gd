extends Node
var seconds_left: float = 0.0
var active: bool = false
var trigger_count: int = 0
var previous_scale: float = 1.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func trigger(duration: float, scale: float) -> void:
	if active:
		return
	previous_scale = Engine.time_scale
	seconds_left = duration
	active = true
	trigger_count += 1
	Engine.time_scale = minf(previous_scale, scale)
func _process(delta: float) -> void:
	if not active:
		return
	seconds_left -= delta / maxf(Engine.time_scale, 0.001)
	if seconds_left <= 0:
		reset()
func reset() -> void:
	if active:
		Engine.time_scale = previous_scale
	active = false
	seconds_left = 0.0
func _exit_tree() -> void:
	reset()
