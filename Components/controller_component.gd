extends Node
class_name ControllerComponent

@warning_ignore("unused_signal")
signal dir_changed(dir: Vector2)
@warning_ignore("unused_signal")
signal shoot_pressed()
@warning_ignore("unused_signal")
signal shoot_held()
@warning_ignore("unused_signal")
signal interact_pressed()
@warning_ignore("unused_signal")
signal reload_pressed()

var aim_target: Vector2 = Vector2.ZERO

func consume_buffer(_input: Signal) -> void:
	pass

func on_damaged() -> void:
	pass
