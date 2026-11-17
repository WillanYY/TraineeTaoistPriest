extends Node2D
signal activated(point, target)
var config: Resource
var direction: Vector2 = Vector2.RIGHT
var excluded: Array[RID] = []
var distance: float = 0
var resolved: bool = false
func _ready() -> void:
	add_to_group("talisman_projectile")
	rotation = direction.angle()
	z_index = 12
func _physics_process(delta: float) -> void:
	if resolved:
		return
	var feedback = get_tree().get_first_node_in_group("combat_feedback")
	if feedback != null and feedback.is_frozen():
		return
	var travel: float = minf(config.projectile_speed * delta, config.projectile_range-distance)
	var destination := global_position + direction * travel
	var ray := PhysicsRayQueryParameters2D.create(global_position, destination, 3, excluded)
	ray.hit_from_inside = true
	var collision := get_world_2d().direct_space_state.intersect_ray(ray)
	if not collision.is_empty():
		resolved = true
		global_position = collision.position
		var target = collision.collider
		if target.has_method("apply_immobilize"):
			target.apply_immobilize(config.bind_duration)
		activated.emit(global_position, target)
		queue_free()
		return
	global_position = destination
	distance += travel
	if distance >= config.projectile_range-0.01:
		resolved = true
		queue_free()
func _draw() -> void:
	draw_line(Vector2(-22,0),Vector2(-5,0),Color(0.8,0.9,1,0.4),3)
	draw_rect(Rect2(-5,-9,10,18),Color(1,0.85,0.42))
	draw_rect(Rect2(-5,-9,10,18),Color(0.65,0.32,0.1),false,1)
	draw_line(Vector2(0,-6),Vector2(0,6),Color(0.68,0.15,0.12),2)
	draw_line(Vector2(-3,-4),Vector2(3,0),Color(0.68,0.15,0.12),2)
	draw_line(Vector2(3,2),Vector2(-3,5),Color(0.68,0.15,0.12),2)
