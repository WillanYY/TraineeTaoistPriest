extends Resource
@export var walk_speed: float = 140.0
@export var acceleration: float = 1600.0
@export var deceleration: float = 2100.0
@export var gravity: float = 1500.0
@export var jump_speed: float = 610.0
@export_range(0.05, 1.0) var jump_release_ratio: float = 0.4
@export var max_fall_speed: float = 900.0

@export_group("Dodge")
@export var run_speed: float = 280.0
@export var dodge_duration: float = 0.2
@export var dodge_recovery: float = 0.16
@export var dodge_distance: float = 120.0
@export var dodge_cooldown: float = 2.0
@export var bullet_time_duration: float = 0.12
@export_range(0.05, 1.0) var bullet_time_scale: float = 0.25
