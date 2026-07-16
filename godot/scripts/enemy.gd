extends StaticBody3D
## Simple destructible enemy target (stand-in Scorp/Talon).

@export var hp: int = 3

func take_hit() -> void:
	hp -= 1
	# flash by scaling down a touch as feedback
	scale = scale * 0.92
	if hp <= 0:
		queue_free()
