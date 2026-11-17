extends Area2D
var enabled: bool = false
var cycle: float = 0.0
var warning_time: float = 0.7
var interval: float = 2.4
var active_time: float = 0.10
var hit_targets: Dictionary = {}
var strikes: int = 0
var hit_count: int = 0
func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(200, 100)
	collider.shape = shape
	collider.position = Vector2(0, -50)
	add_child(collider)
func _physics_process(delta: float) -> void:
	if not enabled:
		queue_redraw()
		return
	var previous := cycle
	cycle += delta
	if previous < interval and cycle >= interval:
		strikes += 1
		hit_targets.clear()
	if cycle >= interval and cycle < interval + active_time:
		for body in get_overlapping_bodies():
			if body.has_method("receive_hit") and not hit_targets.has(body.get_instance_id()):
				hit_targets[body.get_instance_id()] = true
				body.receive_hit(10)
				hit_count += 1
	if cycle >= interval + active_time:
		cycle = 0.0
	queue_redraw()
func toggle() -> void:
	enabled = not enabled
	cycle = 0.0
	hit_targets.clear()
func _draw() -> void:
	var rect := Rect2(-100, -100, 200, 100)
	var color := Color(0.28, 0.32, 0.4, 0.2)
	if enabled and cycle >= interval:
		color = Color(1.0, 0.24, 0.2, 0.8)
	elif enabled and cycle >= interval - warning_time:
		color = Color(1.0, 0.7, 0.2, 0.35 + 0.15 * sin(cycle * 40))
	draw_rect(rect, color)
	draw_rect(rect, Color(1.0, 0.6, 0.2) if enabled else Color(0.4, 0.5, 0.6), false, 2)
	draw_line(Vector2(-100, 0), Vector2(100, 0), Color(1.0, 0.55, 0.2), 4)
