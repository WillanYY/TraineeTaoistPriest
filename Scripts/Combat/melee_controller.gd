extends Node
signal swing_started(definition, serial)
signal hit_confirmed(target, point, definition, serial)
const Model = preload("res://Scripts/Combat/melee_model.gd")
var model = Model.new()
var actor: CharacterBody2D
var tuning: Resource
var hit_ids: Dictionary = {}
var seen_serial: int = 0
var advance_left: float = 0.0
var advance_total: float = 0.0
var assist_used: float = 0.0
var hit_count: int = 0
var box := RectangleShape2D.new()
func configure(owner_actor: CharacterBody2D, config: Resource) -> void:
	actor = owner_actor
	tuning = config
	model.tuning = config
func cancel() -> void:
	model.cancel()
	hit_ids.clear()
	advance_left = 0.0
func request_attack(grounded: bool, facing: int) -> bool:
	return model.request_attack(grounded, facing)
func _visible(target: Node2D) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(actor.global_position + Vector2(0,-44), target.global_position + Vector2(0,-44), 1, [actor.get_rid()])
	return actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
func _prepare_action() -> void:
	hit_ids.clear()
	advance_total = model.definition().advance
	assist_used = 0.0
	var nearest: Node2D
	var nearest_distance: float = tuning.assist_range + 1
	for target in get_tree().get_nodes_in_group("practice_target"):
		if not is_instance_valid(target) or target.health <= 0:
			continue
		var separation: Vector2 = target.global_position - actor.global_position
		var forward: float = separation.x * model.locked_facing
		if forward <= 0 or forward > tuning.assist_range or absf(separation.y) > 45:
			continue
		if forward < nearest_distance and _visible(target):
			nearest = target
			nearest_distance = forward
	if nearest != null:
		var available: float = maxf(0, nearest_distance - tuning.target_spacing)
		advance_total = minf(advance_total + minf(tuning.assist_distance, maxf(0, available - advance_total)), available)
		assist_used = maxf(0, advance_total - model.definition().advance)
	advance_left = advance_total
	swing_started.emit(model.definition(), model.serial)
func step(delta: float, direction: float, grounded: bool) -> float:
	if not grounded and model.is_attacking():
		cancel()
		return 0.0
	model.step(delta, direction)
	if model.serial != seen_serial:
		seen_serial = model.serial
		_prepare_action()
	if model.phase != "action":
		return 0.0
	var distance := minf(advance_left, advance_total * delta / maxf(model.definition().action_duration,0.001))
	var ahead := actor.global_position + Vector2(model.locked_facing * (distance + 18), -4)
	var support := PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0, 20), 1, [actor.get_rid()])
	if actor.get_world_2d().direct_space_state.intersect_ray(support).is_empty():
		return 0.0
	advance_left -= distance
	return distance * model.locked_facing
func check_hits() -> void:
	if not model.can_damage():
		return
	var definition: Resource = model.definition()
	box.size = Vector2(definition.reach, 76)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = box
	query.transform = Transform2D(0, actor.global_position + Vector2(model.locked_facing * (definition.reach / 2 + 8), -44))
	query.collision_mask = 2
	query.exclude = [actor.get_rid()]
	for result in actor.get_world_2d().direct_space_state.intersect_shape(query, 32):
		var target = result.collider
		if not target.has_method("receive_melee_hit") or hit_ids.has(target.get_instance_id()) or target.health <= 0:
			continue
		if (target.global_position.x - actor.global_position.x) * model.locked_facing <= 0 or not _visible(target):
			continue
		hit_ids[target.get_instance_id()] = true
		target.receive_melee_hit(definition.damage, model.locked_facing * definition.knockback, definition.stagger_duration)
		hit_count += 1
		hit_confirmed.emit(target, target.global_position + Vector2(0,-50), definition, model.serial)
