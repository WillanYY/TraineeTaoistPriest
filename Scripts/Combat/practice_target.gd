extends CharacterBody2D
@export var max_health: int = 100
var health: int = 100
var received_count: int = 0
var stagger_left: float = 0.0
var flash_left: float = 0.0
var reset_left: float = 0.0
var last_damage: int = 0
var immobilized_left: float = 0.0
var patrol_enabled: bool = false
var patrol_direction: int = 1
var home: Vector2
func _ready() -> void:
	add_to_group("practice_target")
	collision_layer = 2
	collision_mask = 1
	home = position
	health = max_health
	var collider := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 15
	shape.height = 82
	collider.position = Vector2(0,-41)
	collider.shape = shape
	add_child(collider)
func receive_melee_hit(damage: int, impulse: float, stagger: float) -> void:
	if health <= 0:
		return
	health = maxi(0, health - damage)
	last_damage = damage
	received_count += 1
	velocity.x = 0.0 if immobilized_left > 0 else impulse
	stagger_left = stagger
	flash_left = 0.15
	if health == 0:
		reset_left = 1.5
	queue_redraw()
func apply_immobilize(duration: float) -> bool:
	if health <= 0:
		return false
	immobilized_left = duration
	velocity.x = 0
	queue_redraw()
	return true
func reset_target() -> void:
	health = max_health
	received_count = 0
	velocity = Vector2.ZERO
	position = home
	stagger_left = 0
	flash_left = 0
	reset_left = 0
	immobilized_left = 0
func _physics_process(delta: float) -> void:
	var feedback = get_tree().get_first_node_in_group("combat_feedback")
	if feedback != null and feedback.is_frozen():
		return
	immobilized_left = maxf(0, immobilized_left-delta)
	stagger_left = maxf(0, stagger_left-delta)
	flash_left = maxf(0, flash_left-delta)
	velocity.y = minf(900, velocity.y + 1500 * delta)
	if immobilized_left > 0:
		velocity.x = 0
	elif patrol_enabled and stagger_left == 0 and health > 0:
		if position.x > home.x + 25:
			patrol_direction = -1
		elif position.x < home.x - 25:
			patrol_direction = 1
		velocity.x = patrol_direction * 40.0
	else:
		velocity.x = move_toward(velocity.x, 0, 480 * delta)
	move_and_slide()
	if health == 0:
		reset_left -= delta
		if reset_left <= 0:
			reset_target()
	queue_redraw()
func _draw() -> void:
	var wood := Color(0.65,0.4,0.2) if flash_left == 0 else Color(1,0.9,0.7)
	if immobilized_left > 0:
		wood = Color(0.55,0.75,0.95)
	if health == 0:
		wood.a = 0.35
	draw_line(Vector2(0,-76), Vector2(0,-6), wood, 18)
	draw_line(Vector2(-26,-49), Vector2(26,-49), wood, 11)
	draw_circle(Vector2(0,-82), 14, wood)
	draw_circle(Vector2(-4,-85), 2, Color(0.16,0.1,0.08))
	draw_circle(Vector2(4,-85), 2, Color(0.16,0.1,0.08))
	draw_rect(Rect2(-8,-57,16,28), Color(0.95,0.79,0.43))
	draw_line(Vector2(-4,-52),Vector2(4,-38),Color(0.65,0.16,0.12),2)
	draw_line(Vector2(4,-48),Vector2(-4,-43),Color(0.65,0.16,0.12),2)
	draw_line(Vector2(-23,-3),Vector2(23,-3),wood,6)
	draw_rect(Rect2(-25,-110,50,5),Color(0.2,0.22,0.26))
	draw_rect(Rect2(-25,-110,50*float(health)/max_health,5),Color(0.78,0.9,0.55))
	if flash_left > 0:
		draw_string(ThemeDB.fallback_font,Vector2(14,-95),str(last_damage),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(1,0.85,0.45))

	# Control status is visible independently of hit flash.
	if immobilized_left > 0:
		for y in [-65,-43,-21]:
			draw_line(Vector2(-24,y),Vector2(24,y),Color(0.75,0.9,1.0),2)
		draw_string(ThemeDB.fallback_font,Vector2(-18,-119),"%.1fs" % immobilized_left,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(0.8,0.95,1))
