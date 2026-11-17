extends AnimatedSprite2D
var foot_offsets: Dictionary = {}
func _ready() -> void:
	for animation_name in sprite_frames.get_animation_names():
		for i in sprite_frames.get_frame_count(animation_name):
			var texture := sprite_frames.get_frame_texture(animation_name, i)
			var bounds := texture.get_image().get_used_rect()
			foot_offsets[str(animation_name) + ":" + str(i)] = texture.get_height() - bounds.end.y
	frame_changed.connect(_align_feet)
	_align_feet()
func _align_feet() -> void:
	offset.y = float(foot_offsets.get(str(animation) + ":" + str(frame), 0.0))
var airborne_time: float = 0.0
var landing_left: float = 0.0
func present(facing: int, grounded: bool, velocity: Vector2, was_grounded: bool, delta: float) -> void:
	flip_h = facing < 0
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
		play("walk")
	else:
		play("idle")
