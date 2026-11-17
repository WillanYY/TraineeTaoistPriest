extends Node2D
@onready var player = $Player
@onready var status: Label = $HUD/Status
func _process(_delta: float) -> void:
	status.text = "A / D   WALK       W   JUMP (HOLD FOR HEIGHT)\nPHASE 1   /   MOVE + JUMP\n\n%s    x: %.0f   y: %.0f\nvelocity: %.0f / %.0f" % [
		"GROUNDED" if player.is_on_floor() else "AIRBORNE", player.position.x,
		player.position.y, player.velocity.x, player.velocity.y]
func _draw() -> void:
	for x in range(0, 1281, 40):
		draw_line(Vector2(x,0),Vector2(x,720),Color(0.18,0.22,0.28),1)
	for y in range(0,721,40):
		draw_line(Vector2(0,y),Vector2(1280,y),Color(0.18,0.22,0.28),1)
