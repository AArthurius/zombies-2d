extends ControllerComponent
class_name AIComponent

enum STATE {PATROL, INVESTIGATE, LOOK_FOR_PLAYER, HOSTILE, RETREAT, HEAL}

@export_group("Referências")
@export var nav_agent: NavigationAgent2D
@export var good_vision_area: Area2D
@export var bad_vision_area: Area2D
@export var obstacle_raycast: RayCast2D
@export var patrol_markers: Array[Marker2D]

@export_group("Parâmetros de Combate")
@export var ideal_min_distance: float = 60.0
@export var ideal_max_distance: float = 90.0
@export var retreat_distance: float = 140.0
@export var retreat_fire_interval: float = 2.0

@onready var vision_pivot: Node2D = $"../VisionPivot"
@onready var attack_timer: Timer = $"../AttackTimer"

var player: Node2D
var current_state: STATE = STATE.PATROL
var current_target_pos: Vector2
var player_last_seen_pos: Vector2
var lfp_points: Array[Vector2] = []
var timer: float = 0.0
var was_attacked: bool = false
var is_looking_around: bool = false
var look_angle_offset: float = 0.0
var look_tween: Tween

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	# 1. Aguarda o nav_agent entrar na árvore de física e receber o RID do mapa
	await get_tree().physics_frame
	
	# 2. Aguarda a primeira sincronização caso ainda não tenha terminado
	if nav_agent:
		var nav_map: RID = nav_agent.get_navigation_map()
		if nav_map.is_valid() and NavigationServer2D.map_get_iteration_id(nav_map) == 0:
			await NavigationServer2D.map_changed
	
	if patrol_markers.size() > 0:
		current_target_pos = patrol_markers[0].global_position
		_set_nav_target(current_target_pos)
	else:
		current_target_pos = get_parent().global_position

func _physics_process(delta: float) -> void:
	if get_parent().current_state == get_parent().STATE.DEAD:
		dir_changed.emit(Vector2.ZERO)
		if nav_agent:
			nav_agent.target_position = get_parent().global_position
		return

	if vision_pivot:
		var look_pos: Vector2 = aim_target if current_state in [STATE.HOSTILE, STATE.INVESTIGATE, STATE.LOOK_FOR_PLAYER, STATE.HEAL] else (get_parent().global_position + get_parent().velocity)
		if get_parent().global_position.distance_squared_to(look_pos) > 1.0:
			vision_pivot.look_at(look_pos)
	
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")

	match current_state:
		STATE.PATROL:
			_update_patrol_pos()
			_follow_nav_path()
			aim_target = current_target_pos

			var glimpsed_pos = _get_player_in_bad_vision()
			if glimpsed_pos != null:
				player_last_seen_pos = glimpsed_pos
				_set_nav_target(player_last_seen_pos)
				current_state = STATE.INVESTIGATE
			elif was_attacked:
				current_state = STATE.HOSTILE

		STATE.INVESTIGATE:
			_follow_nav_path()
			aim_target = player_last_seen_pos

			if _is_player_in_good_vision() or was_attacked:
				current_state = STATE.HOSTILE
			elif get_parent().global_position.distance_to(player_last_seen_pos) <= 6.0 or nav_agent.is_navigation_finished():
				_create_lfp_points()
				current_target_pos = lfp_points[0]
				_set_nav_target(current_target_pos)
				current_state = STATE.LOOK_FOR_PLAYER

		STATE.LOOK_FOR_PLAYER:
			if _is_player_in_good_vision() or was_attacked:
				_cancel_look_tween()
				current_state = STATE.HOSTILE
				return

			if lfp_points.is_empty() and not is_looking_around:
				current_state = STATE.PATROL
				return

			if nav_agent.is_navigation_finished():
				dir_changed.emit(Vector2.ZERO)
				if not is_looking_around and not lfp_points.is_empty():
					_start_look_around_tween()
				elif is_looking_around:
					var base_dir = (get_parent().global_position - player_last_seen_pos).normalized()
					if base_dir == Vector2.ZERO:
						base_dir = Vector2.RIGHT
					var rotated_dir = base_dir.rotated(deg_to_rad(look_angle_offset))
					aim_target = get_parent().global_position + rotated_dir * 30.0
			else:
				_follow_nav_path()
				aim_target = current_target_pos

		STATE.HOSTILE:
			if not is_instance_valid(player):
				current_state = STATE.PATROL
				return
			player_last_seen_pos = player.global_position
			aim_target = player.global_position
			_combat_movement(player.global_position)
			if get_parent().health_component.current_health <= get_parent().health_component.max_health * 0.5:
				current_state = STATE.RETREAT
				timer = 0.0
				return
			if attack_timer.is_stopped():
				_try_attack_or_reload()
				timer = 0.0

		STATE.RETREAT:
			was_attacked = false
			if not is_instance_valid(player):
				current_state = STATE.PATROL
				return

			aim_target = player.global_position
			_retreat_movement(player.global_position)

			if get_parent().global_position.distance_to(player.global_position) >= retreat_distance:
				player_last_seen_pos = player.global_position
				dir_changed.emit(Vector2.ZERO)
				current_state = STATE.HEAL
				timer = 0.0
				return

			timer += delta
			if timer >= retreat_fire_interval:
				_try_attack_or_reload()
				timer = 0.0

		STATE.HEAL:
			dir_changed.emit(Vector2.ZERO)
			aim_target = player_last_seen_pos

			if was_attacked:
				retreat_distance = get_parent().global_position.distance_to(player.global_position) + 30.0
				current_state = STATE.HOSTILE
				return

			if get_parent().health_component.current_health >= get_parent().health_component.max_health:
				_set_nav_target(player_last_seen_pos)
				current_state = STATE.INVESTIGATE
				timer = 0.0
				return

			timer += delta
			if timer >= 1.0:
				if get_parent().health_component.has_method("heal"):
					get_parent().health_component.heal(10)
				else:
					get_parent().health_component.current_health = min(get_parent().health_component.current_health + 1, get_parent().health_component.max_health)
				timer = 0.0

func on_damaged() -> void:
	was_attacked = true

func _try_attack_or_reload() -> void:
	if get_parent().current_equipment.current_ammo <= 0 and get_parent().current_equipment.max_ammo > 0:
		reload_pressed.emit()
	else:
		shoot_held.emit()

func _set_nav_target(target_pos: Vector2) -> void:
	if nav_agent:
		nav_agent.target_position = target_pos

func _follow_nav_path() -> void:
	if not nav_agent or nav_agent.is_navigation_finished():
		dir_changed.emit(Vector2.ZERO)
		return
	var next_point: Vector2 = nav_agent.get_next_path_position()
	var dir: Vector2 = get_parent().global_position.direction_to(next_point)
	dir_changed.emit(dir)

func _combat_movement(target_pos: Vector2) -> void:
	var dist: float = get_parent().global_position.distance_to(target_pos)
	var desired_pos: Vector2 = get_parent().global_position

	var has_obstacle := false
	if obstacle_raycast:
		obstacle_raycast.target_position = obstacle_raycast.to_local(target_pos)
		has_obstacle = obstacle_raycast.is_colliding()

	if has_obstacle:
		desired_pos = target_pos
	elif dist > ideal_max_distance:
		var dir_to_player = get_parent().global_position.direction_to(target_pos)
		desired_pos = target_pos - (dir_to_player * ideal_max_distance)
	elif dist < ideal_min_distance:
		var dir_away = target_pos.direction_to(get_parent().global_position)
		desired_pos = target_pos + (dir_away * ideal_min_distance)
	else:
		dir_changed.emit(Vector2.ZERO)
		return

	_set_nav_target(desired_pos)
	_follow_nav_path()

func _retreat_movement(threat_pos: Vector2) -> void:
	var dir_away: Vector2 = threat_pos.direction_to(get_parent().global_position)
	var escape_pos: Vector2 = threat_pos + (dir_away * (retreat_distance + 20.0))
	_set_nav_target(escape_pos)
	_follow_nav_path()

func _update_patrol_pos() -> void:
	if patrol_markers.size() < 2:
		return
	if nav_agent.is_navigation_finished():
		if current_target_pos.distance_to(patrol_markers[0].global_position) < 6.0:
			current_target_pos = patrol_markers[1].global_position
		else:
			current_target_pos = patrol_markers[0].global_position
		_set_nav_target(current_target_pos)

func _create_lfp_points() -> void:
	lfp_points.clear()
	lfp_points.append(player_last_seen_pos + Vector2(25, 25))
	lfp_points.append(player_last_seen_pos + Vector2(25, -25))
	lfp_points.append(player_last_seen_pos + Vector2(-25, -25))
	lfp_points.append(player_last_seen_pos + Vector2(-25, 25))

func _start_look_around_tween() -> void:
	is_looking_around = true
	look_angle_offset = -45.0
	look_tween = create_tween()
	look_tween.tween_property(self, "look_angle_offset", 45.0, 1.0)
	look_tween.tween_property(self, "look_angle_offset", -45.0, 1.0)
	look_tween.tween_callback(func():
		is_looking_around = false
		if not lfp_points.is_empty():
			lfp_points.pop_front()
			if not lfp_points.is_empty():
				current_target_pos = lfp_points[0]
				_set_nav_target(current_target_pos)
	)

func _cancel_look_tween() -> void:
	if look_tween and look_tween.is_running():
		look_tween.kill()
	is_looking_around = false

func _get_player_in_bad_vision() -> Variant:
	if not bad_vision_area:
		return null
	for body in bad_vision_area.get_overlapping_bodies():
		if body.is_in_group("Player"):
			return body.global_position
	return null

func _is_player_in_good_vision() -> bool:
	if not good_vision_area:
		return false
	for body in good_vision_area.get_overlapping_bodies():
		if body.is_in_group("Player"):
			return true
	return false
