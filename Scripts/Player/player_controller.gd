extends CharacterBody2D
signal damaged
signal perfect_dodge
const ActionModel = preload("res://Scripts/Player/player_action_model.gd")
const LedgeClimb = preload("res://Scripts/Player/ledge_climb.gd")
const Talisman = preload("res://Scripts/Talisman/talisman_controller.gd")
const Melee = preload("res://Scripts/Combat/melee_controller.gd")
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
var melee = Melee.new()
var talismans = Talisman.new()
var climb = LedgeClimb.new()
@onready var view: AnimatedSprite2D = $Visual
func _ready() -> void:
	actions.tuning = tuning
	bullet_time.name = "BulletTime"
	add_child(bullet_time)
	melee.name = "Melee"
	melee.configure(self, tuning)
	add_child(melee)
	talismans.name = "Talismans"
	talismans.configure(self)
	add_child(talismans)
	melee.swing_started.connect(talismans.mark_combat)
	climb.name = "LedgeClimb"
	climb.configure(self)
	add_child(climb)
func receive_hit(damage: int = 10) -> String:
	talismans.mark_combat()
	var result: String = actions.resolve_hit()
	if result == "perfect":
		perfect_count += 1
		bullet_time.trigger(tuning.bullet_time_duration, tuning.bullet_time_scale)
		perfect_dodge.emit()
	elif result == "hurt":
		melee.cancel()
		talismans.cancel_aim()
		climb.cancel()
		actions.running = false
		health = maxi(0, health - damage)
		damage_count += 1
		hurt_left = 0.22
		damaged.emit()
	return result
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var was_grounded := is_on_floor()
	var feedback = get_tree().get_first_node_in_group("combat_feedback")
	if feedback != null and feedback.is_frozen():
		var input_facing := facing if direction == 0 else (1 if direction > 0 else -1)
		if Input.is_action_just_pressed("attack") and actions.phase == "free" and not talismans.aiming and not climb.active:
			melee.request_attack(was_grounded, input_facing)
		if not climb.active and Input.is_action_just_pressed("dodge") and actions.begin_dodge(was_grounded, facing):
			melee.cancel()
			talismans.cancel_aim()
			velocity.y = 0
			feedback.release_freeze()
		view.pause()
		return
	var previous_phase: String = actions.phase
	actions.step(delta, direction, was_grounded)
	if previous_phase == "dodge" and actions.phase != "dodge":
		# The fixed dodge velocity must not leak into recovery/run acceleration.
		velocity.x = 0.0
	hurt_left = maxf(0, hurt_left - delta)
	climb.tick(delta)
	talismans.step(delta, was_grounded, actions.phase == "free" and not melee.model.is_attacking() and hurt_left <= 0 and not climb.active)
	if climb.active:
		_step_climb(delta)
		return
	if talismans.aiming:
		actions.running = false
	if actions.phase == "free" and not melee.model.is_attacking() and not talismans.aiming and direction != 0:
		facing = 1 if direction > 0 else -1
	if Input.is_action_just_pressed("dodge") and actions.begin_dodge(was_grounded, facing):
		velocity.y = 0.0
		melee.cancel()
		talismans.cancel_aim()
	if actions.phase == "free" and Input.is_action_just_pressed("attack"):
		var attack_facing := facing if direction == 0 else (1 if direction > 0 else -1)
		if talismans.aiming:
			talismans.fire()
		else:
			melee.request_attack(was_grounded, attack_facing)
	if not was_grounded and actions.phase == "free" and not melee.model.is_attacking() and not talismans.aiming and hurt_left <= 0 and climb.try_start(facing):
		melee.cancel()
		talismans.cancel_aim()
		actions.running = false
		_step_climb(delta)
		return
	var attack_motion: float = melee.step(delta, direction, was_grounded)
	if melee.model.is_attacking():
		facing = melee.model.locked_facing
		actions.running = false
	if actions.phase == "dodge":
		facing = actions.locked_facing
		velocity.x = actions.locked_facing * tuning.dodge_distance / tuning.dodge_duration
		velocity.y = 0.0
	else:
		if melee.model.is_attacking():
			velocity.x = attack_motion / maxf(delta, 0.000001)
		elif actions.phase == "recovery" or talismans.aiming:
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
	melee.check_hits()
	if melee.model.is_attacking():
		view.present_melee(melee.model)
	else:
		view.present(facing, is_on_floor(), velocity, was_grounded, delta,
			actions.phase, actions.phase_elapsed, actions.running, hurt_left,
			tuning.dodge_duration, tuning.dodge_recovery)
	if position.y > 1000:
		melee.cancel()
		position = Vector2(200, 580)
		velocity = Vector2.ZERO

func _step_climb(delta: float) -> void:
	facing = climb.locked_facing
	climb.advance(delta)
	view.present_climb(climb.progress(), facing)
	if not climb.active:
		# move_and_collide does not update CharacterBody2D floor classification.
		velocity = Vector2(0,30)
		move_and_slide()
