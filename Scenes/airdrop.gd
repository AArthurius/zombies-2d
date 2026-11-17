extends Node2D

var sprite_2d: Sprite2D 

var equipment: Equipment = preload("uid://b0m8e7b1qdaai")

func spawn_at(pos: Vector2):
	sprite_2d = $Sprite2D
	position = pos
	$AnimationPlayer.play("drop")
	visible = true
	if equipment.icon:
		sprite_2d.texture = equipment.icon

func _on_body_entered(body: Node2D) -> void:
	if body is Character:
		if body.is_in_group("Player"):
			body.change_equipment(equipment)
			queue_free()
