extends CharacterBody2D

var damage: int = 10

func _physics_process(delta: float) -> void:
	if move_and_collide(velocity * delta):
		queue_free() # Destrói a bala ao bater em qualquer coisa (parede ou inimigo)


func _on_hitbox_area_entered(area: Area2D) -> void:
	queue_free()
