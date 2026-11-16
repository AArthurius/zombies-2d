extends Node
class_name HealthComponent

@export var max_health: int = 100 :
	set(value):
		max_health = value
		current_health = value  

var current_health: int = 100

signal health_changed(current_health)
signal dead()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		damage(10)

func damage(amount: int):
	if current_health <= 0:
		return
	current_health = max(current_health -amount, 0)
	health_changed.emit(current_health)
	if current_health <= 0:
		dead.emit()
