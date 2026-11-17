extends Node
class_name HealthComponent

@export var max_health: int = 100 :
	set(value):
		max_health = value
		current_health = value  

var current_health: int = 100

signal health_changed(current_health)
signal dead()

func damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health)
	if current_health <= 0:
		dead.emit()

func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health)
