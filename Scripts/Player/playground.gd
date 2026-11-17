extends Node2D
const HitFeedback = preload("res://Scripts/Combat/hit_feedback.gd")
const Target = preload("res://Scripts/Combat/practice_target.gd")
const AttackDevice = preload("res://Scripts/Combat/practice_attack.gd")
@onready var player = $Player
@onready var status: Label = $HUD/Status
var feedback = HitFeedback.new()
var attack_device: Area2D
var spawn_point: Vector2
func _ready() -> void:
	for x in [300, 980]:
		var target := Target.new()
		target.name = "PracticeTarget" + str(x)
		target.position = Vector2(x, 580)
		add_child(target)
	feedback.name = "CombatFeedback"
	add_child(feedback)
	feedback.bind_player(player)
	spawn_point = player.position
	attack_device = AttackDevice.new()
	attack_device.name = "AttackDevice"
	attack_device.position = Vector2(1090, 580)
	add_child(attack_device)
	var label := Label.new()
	label.text = "T  TOGGLE ATTACK ZONE\nAMBER = WARNING   /   RED = HIT"
	label.position = Vector2(960, 620)
	label.add_theme_font_size_override("font_size", 13)
	add_child(label)
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			attack_device.toggle()
		elif event.keycode == KEY_R:
			feedback.reset()
			player.bullet_time.reset()
			player.bullet_time.trigger_count = 0
			player.melee.hit_count = 0
			player.actions = player.ActionModel.new()
			player.actions.tuning = player.tuning
			player.melee.cancel()
			for target in get_tree().get_nodes_in_group("practice_target"):
				target.reset_target()
			player.position = spawn_point
			player.velocity = Vector2.ZERO
			player.health = 100
			player.damage_count = 0
			player.perfect_count = 0
			player.hurt_left = 0.0
			attack_device.cycle = 0.0
func _process(_delta: float) -> void:
	var phase: String = player.actions.phase
	var ready_text := "WAIT FOR LANDING" if player.actions.waiting_for_landing else ("READY" if player.actions.cooldown_left <= 0 else "%.1f s" % player.actions.cooldown_left)
	status.text = "A / D  WALK    W  JUMP    SPACE  DODGE    T  ATTACK ZONE    R  RESET\nCLUB COMBAT PLAYGROUND\n\n%s  |  %s  |  DODGE: %s\nHP %d   HITS %d   PERFECT %d   ATTACK ZONE: %s\nCYAN = INVULNERABLE   /   RELEASE MOVE TO END RUN" % [
		"GROUNDED" if player.is_on_floor() else "AIRBORNE",
		"RUN" if player.actions.running else phase.to_upper(), ready_text,
		player.health, player.damage_count, player.perfect_count,
		"ON" if attack_device.enabled else "OFF"]
	status.text += "\nLMB  MELEE  |  %s %d  |  NEXT: %s  |  HITS: %d" % [
		player.melee.model.phase.to_upper(), player.melee.model.segment,
		"BUFFERED" if player.melee.model.pending else "-", player.melee.hit_count]
	queue_redraw()
func _draw() -> void:
	for x in range(0, 1281, 40):
		draw_line(Vector2(x,0),Vector2(x,720),Color(0.18,0.22,0.28),1)
	for y in range(0,721,40):
		draw_line(Vector2(0,y),Vector2(1280,y),Color(0.18,0.22,0.28),1)
	if is_instance_valid(player) and player.bullet_time.active:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.2,0.8,1.0,0.12))
