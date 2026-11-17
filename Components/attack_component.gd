extends Node
class_name AttackComponent

const BULLET_SPEED = 400

func shoot(damage: int, spawn_pos: Vector2, target_pos: Vector2, projectile: PackedScene = null) -> void:
	assert(projectile != null, "Sem cena de projetil")
	var bullet: CharacterBody2D = projectile.instantiate()
	var shoot_dir: Vector2 = (target_pos - spawn_pos).normalized()
	# Proteção caso o mouse esteja colado no corpo do player (atrás da ponta do cano)
	if get_parent().global_position.distance_to(target_pos) < get_parent().global_position.distance_to(spawn_pos):
		shoot_dir = (target_pos - get_parent().global_position).normalized()
	bullet.global_position = spawn_pos
	bullet.rotation = shoot_dir.angle()
	bullet.velocity = shoot_dir * BULLET_SPEED
	bullet.damage = damage
	$"../../Projectiles".add_child(bullet)

func melee():
	pass
