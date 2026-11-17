extends Node
class_name MovComponent

var dir: Vector2 = Vector2.ZERO
var speed: float = 100

signal move(velocity: Vector2)

func _physics_process(delta: float) -> void:
	move.emit(dir * speed)


func change_dir(new_dir : Vector2) -> void:
	dir = new_dir
