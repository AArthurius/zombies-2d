extends AnimatedSprite2D
class_name AnimComponent

var dir: Vector2 = Vector2.ZERO
var cardinal: String = "down" # Guarda a última direção válida

func play_anim(anim_name: String, anim_offset: Vector2 = Vector2.ZERO): # offset por padrão é zero
	offset = anim_offset
	play(anim_name + "_" + cardinal)

func change_dir(new_dir: Vector2) -> void:
	dir = new_dir
	# Só atualiza para onde o boneco olha se houver movimento
	if dir != Vector2.ZERO:
		if abs(dir.x) > abs(dir.y):
			cardinal =  "right" if dir.x > 0 else "left"
		else:
			cardinal =  "down" if dir.y > 0 else "up"
