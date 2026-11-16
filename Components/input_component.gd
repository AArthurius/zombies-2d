extends Node
class_name InputComponent

signal dir_changed(dir: Vector2)
signal shoot_pressed()
signal interact_pressed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	dir_changed.emit(dir)
	if Input.is_action_pressed("shoot"):
		shoot_pressed.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("interact"):
		interact_pressed.emit()
