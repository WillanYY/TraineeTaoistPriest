extends Node2D
const Projectile = preload("res://Scripts/Talisman/talisman_projectile.gd")
@export var config: Resource = preload("res://Resources/Player/talisman_config.tres")
var actor: CharacterBody2D
var aiming: bool = false
var blocked_until_release: bool = false
var aim_screen: Vector2 = Vector2.ZERO
var aim_point: Vector2 = Vector2.ZERO
var charges: int = 0
var recharge_progress: float = 0
var combat_left: float = 0
var interval_left: float = 0
var cast_count: int = 0
var target_hits: int = 0
var environment_hits: int = 0
var effects: Array[Dictionary] = []
var previous_mouse_mode: int
var symbol_font := SystemFont.new()
func configure(player: CharacterBody2D) -> void:
	actor = player
func _ready() -> void:
	symbol_font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	z_index = 30
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	aim_screen = get_viewport().get_mouse_position()
	charges = config.capacity
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_screen = event.position
func mark_combat(_definition: Resource = null, _serial: int = 0) -> void:
	combat_left = config.combat_memory
func cancel_aim() -> void:
	aiming = false
	blocked_until_release = true
	queue_redraw()
func advance_recharge(delta: float) -> void:
	var in_combat := combat_left > 0
	combat_left = maxf(0,combat_left-delta)
	if charges >= config.capacity:
		recharge_progress = 0
		return
	var duration: float = config.combat_recharge if in_combat else config.idle_recharge
	recharge_progress += delta / maxf(duration,0.01)
	while recharge_progress >= 1 and charges < config.capacity:
		charges += 1
		recharge_progress -= 1
	if charges == config.capacity:
		recharge_progress = 0
func step(delta: float, grounded: bool, can_aim: bool) -> void:
	advance_recharge(delta)
	interval_left = maxf(0,interval_left-delta)
	var held := Input.is_action_pressed("aim")
	if not held:
		blocked_until_release = false
	aiming = held and grounded and can_aim and not blocked_until_release
	aim_point = actor.get_canvas_transform().affine_inverse() * aim_screen
	queue_redraw()
func fire() -> bool:
	if not aiming or charges <= 0 or interval_left > 0:
		return false
	charges -= 1
	cast_count += 1
	interval_left = config.fire_interval
	mark_combat()
	var origin := actor.global_position + Vector2(0,-50)
	var direction := (aim_point-origin).normalized()
	if direction.is_zero_approx():
		direction = Vector2(actor.facing,0)
	var projectile := Projectile.new()
	projectile.config = config
	projectile.direction = direction
	projectile.excluded = [actor.get_rid()]
	projectile.activated.connect(_on_activated)
	actor.get_parent().add_child(projectile)
	projectile.global_position = origin
	return true
func _on_activated(point: Vector2, target) -> void:
	if target.has_method("apply_immobilize") and target.health > 0:
		target_hits += 1
	else:
		environment_hits += 1
	effects.append({"point": point, "left": 0.25})
func _process(delta: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		effects[i]["left"] -= delta
		if effects[i]["left"] <= 0:
			effects.remove_at(i)
	queue_redraw()
func _draw() -> void:
	for effect in effects:
		var p: float = 1 - effect["left"]/0.25
		draw_arc(to_local(effect["point"]),8+p*24,0,TAU,24,Color(0.7,0.9,1,1-p),2)
	if not aiming:
		return
	var center := Vector2(0,-58)
	var outline := PackedVector2Array()
	for i in 8:
		outline.append(center + Vector2.from_angle(i*TAU/8-PI/2)*69)
	outline.append(outline[0])
	draw_polyline(outline,Color(0.85,0.75,0.42,0.7),1.5)
	for i in 8:
		var pos := center + Vector2.from_angle(i*TAU/8-PI/2)*61
		draw_circle(pos,12,Color(0.9,0.78,0.32,0.95) if i == 0 else Color(0.16,0.2,0.28,0.85))
		if i == 0:
			draw_string(symbol_font,pos+Vector2(-8,7),"定",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color(0.4,0.12,0.08))
		else:
			draw_line(pos+Vector2(-3,-3),pos+Vector2(3,3),Color(0.4,0.45,0.5),1)
			draw_line(pos+Vector2(3,-3),pos+Vector2(-3,3),Color(0.4,0.45,0.5),1)
	var cursor := to_local(aim_point)
	draw_line(Vector2(0,-50),cursor,Color(0.8,0.85,0.6,0.3),1)
	draw_arc(cursor,8,0,TAU,20,Color(1,0.9,0.5),1.5)
	draw_line(cursor-Vector2(13,0),cursor+Vector2(13,0),Color(1,0.9,0.5),1)
	draw_line(cursor-Vector2(0,13),cursor+Vector2(0,13),Color(1,0.9,0.5),1)
func reset() -> void:
	aiming = false
	blocked_until_release = false
	charges = config.capacity
	recharge_progress = 0
	combat_left = 0
	interval_left = 0
	cast_count = 0
	target_hits = 0
	environment_hits = 0
	effects.clear()
	for projectile in get_tree().get_nodes_in_group("talisman_projectile"):
		projectile.queue_free()
	queue_redraw()
func _exit_tree() -> void:
	Input.mouse_mode = previous_mouse_mode
