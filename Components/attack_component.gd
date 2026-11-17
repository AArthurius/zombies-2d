extends Node
class_name AttackComponent

const BULLET_SPEED = 400
const BULLET = preload("uid://kj6jm7ivjh1d")

func shoot(damage: int, spawn_pos: Vector2, target_pos: Vector2, projectile: Texture, pellets: int = 1, spread_angle: float = 0.0) -> void:
	var base_dir: Vector2 = (target_pos - spawn_pos).normalized()
	# Proteção caso o mouse esteja colado no corpo do player (atrás da ponta do cano)
	if get_parent().global_position.distance_to(target_pos) < get_parent().global_position.distance_to(spawn_pos):
		base_dir = (target_pos - get_parent().global_position).normalized()
	
	var spread_rad: float = deg_to_rad(spread_angle)
	
	for i in pellets:
		var bullet: CharacterBody2D = BULLET.instantiate()
		if projectile:
			bullet.get_node("Sprite2D").texture = projectile
		
		var angle_offset: float = 0.0
		if pellets > 1:
			# Múltiplos projéteis: distribui em leque + leve variação aleatória
			var step: float = spread_rad / float(pellets - 1)
			angle_offset = (-spread_rad / 2.0) + (step * i) + randf_range(-0.04, 0.04)
		elif spread_angle > 0.0:
			# Projétil único: desvio aleatório dentro do cone de imprecisão
			angle_offset = randf_range(-spread_rad / 2.0, spread_rad / 2.0)
		
		var shoot_dir: Vector2 = base_dir.rotated(angle_offset)
		bullet.global_position = spawn_pos
		bullet.rotation = shoot_dir.angle()
		bullet.velocity = shoot_dir * BULLET_SPEED
		bullet.damage = damage
		get_tree().current_scene.add_child(bullet)

func melee():
	pass
