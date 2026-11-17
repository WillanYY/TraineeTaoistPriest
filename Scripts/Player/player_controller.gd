extends CharacterBody2D
@export var tuning: Resource
var facing: int = 1
var last_landing_speed: float = 0.0
var jump_count: int = 0
@onready var view: AnimatedSprite2D = $Visual
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		facing = 1 if direction > 0 else -1
	velocity.x = move_toward(velocity.x, direction * tuning.walk_speed,
		(tuning.acceleration if direction != 0 else tuning.deceleration) * delta)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -tuning.jump_speed
		jump_count += 1
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= tuning.jump_release_ratio
	velocity.y = minf(velocity.y + tuning.gravity * delta, tuning.max_fall_speed)
	var was_grounded := is_on_floor()
	var fall_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not was_grounded:
		last_landing_speed = fall_speed
	view.present(facing, is_on_floor(), velocity, was_grounded, delta)
	if position.y > 1000:
		position = Vector2(200, 580)
		velocity = Vector2.ZERO
