extends Node
class_name MovComponent

var dir: Vector2 = Vector2.ZERO
var speed: float = 100

func _physics_process(delta: float) -> void:
	get_parent().velocity = dir * speed
	get_parent().move_and_slide()

func change_dir(new_dir : Vector2) -> void:
	dir = new_dir
