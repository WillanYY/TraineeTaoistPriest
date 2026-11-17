extends CharacterBody2D
signal damaged
signal perfect_dodge
const ActionModel = preload("res://Scripts/Player/player_action_model.gd")
const BulletTime = preload("res://Scripts/Combat/bullet_time.gd")
@export var tuning: Resource
var facing: int = 1
var last_landing_speed: float = 0.0
var jump_count: int = 0
var health: int = 100
var damage_count: int = 0
var perfect_count: int = 0
var hurt_left: float = 0.0
var actions = ActionModel.new()
var bullet_time = BulletTime.new()
@onready var view: AnimatedSprite2D = $Visual
func _ready() -> void:
	actions.tuning = tuning
	bullet_time.name = "BulletTime"
	add_child(bullet_time)
func receive_hit(damage: int = 10) -> String:
	var result: String = actions.resolve_hit()
	if result == "perfect":
		perfect_count += 1
		bullet_time.trigger(tuning.bullet_time_duration, tuning.bullet_time_scale)
		perfect_dodge.emit()
	elif result == "hurt":
		health = maxi(0, health - damage)
		damage_count += 1
		hurt_left = 0.22
		damaged.emit()
	return result
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var was_grounded := is_on_floor()
	var previous_phase: String = actions.phase
	actions.step(delta, direction, was_grounded)
	if previous_phase == "dodge" and actions.phase != "dodge":
		# The fixed dodge velocity must not leak into recovery/run acceleration.
		velocity.x = 0.0
	hurt_left = maxf(0, hurt_left - delta)
	if actions.phase == "free" and direction != 0:
		facing = 1 if direction > 0 else -1
	if Input.is_action_just_pressed("dodge") and actions.begin_dodge(was_grounded, facing):
		velocity.y = 0.0
	if actions.phase == "dodge":
		facing = actions.locked_facing
		velocity.x = actions.locked_facing * tuning.dodge_distance / tuning.dodge_duration
		velocity.y = 0.0
	else:
		if actions.phase == "recovery":
			velocity.x = 0.0
		else:
			var speed: float = tuning.run_speed if actions.running else tuning.walk_speed
			velocity.x = move_toward(velocity.x, direction * speed,
				(tuning.acceleration if direction != 0 else tuning.deceleration) * delta)
			if was_grounded and Input.is_action_just_pressed("jump"):
				velocity.y = -tuning.jump_speed
				jump_count += 1
			if Input.is_action_just_released("jump") and velocity.y < 0:
				velocity.y *= tuning.jump_release_ratio
		velocity.y = minf(velocity.y + tuning.gravity * delta, tuning.max_fall_speed)
	var fall_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not was_grounded:
		last_landing_speed = fall_speed
	view.present(facing, is_on_floor(), velocity, was_grounded, delta,
		actions.phase, actions.phase_elapsed, actions.running, hurt_left,
		tuning.dodge_duration, tuning.dodge_recovery)
	if position.y > 1000:
		position = Vector2(200, 580)
		velocity = Vector2.ZERO
