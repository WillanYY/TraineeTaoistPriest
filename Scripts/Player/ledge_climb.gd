extends Node
@export var config: Resource = preload("res://Resources/Player/climb_config.tres")
var actor: CharacterBody2D
var active: bool = false
var elapsed: float = 0
var cooldown: float = 0
var locked_facing: int = 1
var start: Vector2
var outside: Vector2
var lift: Vector2
var across: Vector2
var landing: Vector2
var climb_count: int = 0
var abort_count: int = 0
func configure(player: CharacterBody2D) -> void:
	actor = player
func tick(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
func progress() -> float:
	return clampf(elapsed / maxf(config.duration,0.01),0,1)
func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var ray := PhysicsRayQueryParameters2D.create(from,to,actor.collision_mask,[actor.get_rid()])
	return actor.get_world_2d().direct_space_state.intersect_ray(ray)
func _query(feet: Vector2) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = actor.get_node("Body").shape
	query.transform = Transform2D(0,feet + actor.get_node("Body").position)
	query.collision_mask = actor.collision_mask
	query.exclude = [actor.get_rid()]
	query.margin = 0
	return query
func _clear_pose(feet: Vector2) -> bool:
	return actor.get_world_2d().direct_space_state.intersect_shape(_query(feet),1).is_empty()
func _clear_path(from: Vector2, to: Vector2) -> bool:
	var query := _query(from)
	query.motion = to-from
	var fractions := actor.get_world_2d().direct_space_state.cast_motion(query)
	return fractions.size() == 2 and fractions[0] >= 0.999
func try_start(facing: int) -> bool:
	if active or cooldown > 0 or actor.is_on_floor():
		return false
	var feet := actor.global_position
	var hand := feet + Vector2(0,-config.hand_height)
	var wall := _ray(hand,hand+Vector2(facing*config.reach,0))
	if wall.is_empty() or wall.normal.x * facing > -0.5:
		return false
	var probe_x: float = wall.position.x + facing * 8
	var top := _ray(Vector2(probe_x,feet.y-config.top_probe_height),Vector2(probe_x,feet.y-config.min_lip_height))
	if top.is_empty() or top.normal.y > -0.7:
		return false
	var height: float = feet.y-top.position.y
	if height < config.min_lip_height or height > config.max_lip_height:
		return false
	var end := Vector2(wall.position.x + facing*config.landing_inset,top.position.y-0.5)
	var support := _ray(end+Vector2(0,-2),end+Vector2(0,5))
	if support.is_empty() or absf(support.position.y-top.position.y) > 1:
		return false
	var radius: float = actor.get_node("Body").shape.radius
	var outside_x := minf(feet.x,wall.position.x-radius-2) if facing > 0 else maxf(feet.x,wall.position.x+radius+2)
	var outside_point := Vector2(outside_x,feet.y)
	var corner := Vector2(outside_x,top.position.y-config.lift_clearance)
	var upper_end := Vector2(end.x,corner.y)
	if not _clear_pose(corner) or not _clear_pose(upper_end) or not _clear_pose(end):
		return false
	if not _clear_path(feet,outside_point) or not _clear_path(outside_point,corner) or not _clear_path(corner,upper_end):
		return false
	start = feet
	outside = outside_point
	lift = corner
	across = upper_end
	landing = end
	elapsed = 0
	active = true
	locked_facing = facing
	climb_count += 1
	actor.velocity = Vector2.ZERO
	return true
func _smooth(p: float) -> float:
	p = clampf(p,0,1)
	return p*p*(3-2*p)
func advance(delta: float) -> void:
	if not active:
		return
	elapsed = minf(config.duration,elapsed+delta)
	var p := progress()
	var destination: Vector2
	if p < 0.15:
		destination = start.lerp(outside,_smooth(p/0.15))
	elif p < 0.58:
		destination = outside.lerp(lift,_smooth((p-0.15)/0.43))
	elif p < 0.9:
		destination = lift.lerp(across,_smooth((p-0.58)/0.32))
	else:
		destination = across.lerp(landing,_smooth((p-0.9)/0.1))
	var collision := actor.move_and_collide(destination-actor.global_position)
	if collision != null and not (p >= 0.9 and collision.get_normal().y < -0.7):
		abort_count += 1
		cancel()
		return
	actor.velocity = Vector2.ZERO
	if p >= 1:
		active = false
		cooldown = config.retry_delay
func cancel() -> void:
	active = false
	cooldown = config.retry_delay
func reset() -> void:
	cancel()
	elapsed = 0
	cooldown = 0
	climb_count = 0
	abort_count = 0
