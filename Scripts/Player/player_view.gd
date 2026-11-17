extends AnimatedSprite2D
var foot_offsets: Dictionary = {}
func _ready() -> void:
	sprite_frames = sprite_frames.duplicate()
	for library in ["res://Resources/Player/dodge_frames.tres", "res://Resources/Player/melee_frames.tres"]:
		var extra = load(library)
		for animation_name in extra.get_animation_names():
			if animation_name == "default":
				continue
			sprite_frames.add_animation(animation_name)
			sprite_frames.set_animation_speed(animation_name, extra.get_animation_speed(animation_name))
			sprite_frames.set_animation_loop(animation_name, extra.get_animation_loop(animation_name))
			for i in extra.get_frame_count(animation_name):
				sprite_frames.add_frame(animation_name, extra.get_frame_texture(animation_name, i))
	for animation_name in sprite_frames.get_animation_names():
		for i in sprite_frames.get_frame_count(animation_name):
			var texture := sprite_frames.get_frame_texture(animation_name, i)
			var bounds := texture.get_image().get_used_rect()
			foot_offsets[str(animation_name) + ":" + str(i)] = texture.get_height() - bounds.end.y
	# Idle frames share a canvas/stance. A one-pixel sole change must
	# not translate the entire character like a new foot placement.
	var idle_offset := INF
	for i in sprite_frames.get_frame_count("idle"):
		idle_offset = minf(idle_offset, float(foot_offsets["idle:" + str(i)]))
	for i in sprite_frames.get_frame_count("idle"):
		foot_offsets["idle:" + str(i)] = idle_offset
	animation_changed.connect(_align_feet)
	frame_changed.connect(_align_feet)
	_align_feet()
func _align_feet() -> void:
	offset.y = float(foot_offsets.get(str(animation) + ":" + str(frame), 0.0))
var airborne_time: float = 0.0
var landing_left: float = 0.0
func present(facing: int, grounded: bool, velocity: Vector2, was_grounded: bool, delta: float,
	phase: String = "free", phase_elapsed: float = 0.0, running: bool = false,
	hurt_left: float = 0.0, dodge_duration: float = 0.2, recovery_duration: float = 0.16) -> void:
	flip_h = facing < 0
	modulate = Color(0.55, 1.0, 1.0) if phase == "dodge" else (Color(1.0, 0.45, 0.45) if hurt_left > 0 else Color.WHITE)
	if phase == "dodge" or phase == "recovery":
		landing_left = 0.0
		play("dodge")
		pause()
		if phase == "dodge":
			frame = mini(7, int(phase_elapsed / dodge_duration * 8))
		else:
			frame = mini(11, 8 + int(phase_elapsed / recovery_duration * 4))
		return
	if hurt_left > 0 and grounded:
		play("hurt")
		return
	if not grounded:
		landing_left = 0.0
		if was_grounded:
			airborne_time = 0.0
		airborne_time += delta
		play("jump")
		pause()
		if velocity.y < -80:
			frame = mini(4, int(airborne_time / 0.06))
		else:
			frame = 5 if velocity.y < 160 else 6
		return
	if not was_grounded:
		landing_left = 0.10
	landing_left = maxf(0.0, landing_left - delta)
	if landing_left > 0:
		play("jump")
		pause()
		frame = 7 if landing_left > 0.05 else 8
	elif absf(velocity.x) > 5:
		play("run" if running else "walk")
	else:
		play("idle")

func present_melee(model) -> void:
	flip_h = model.locked_facing < 0
	modulate = Color.WHITE
	landing_left = 0.0
	var definition: Resource = model.definition()
	var bounds: Vector2i = definition.action_frames
	var duration: float = definition.action_duration
	if model.phase == "startup":
		bounds = definition.startup_frames
		duration = definition.startup_duration
	elif model.phase == "recovery":
		bounds = definition.recovery_frames
		duration = definition.recovery_duration
	play(definition.animation_name)
	pause()
	frame = mini(bounds.y, bounds.x + int(model.elapsed / maxf(duration, 0.001) * (bounds.y-bounds.x+1)))
