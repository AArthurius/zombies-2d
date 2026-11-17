extends CharacterBody2D
class_name Character

@export var current_equipment: Equipment = Equipment.new()
@onready var controller_component: ControllerComponent = $ControllerComponent
@onready var mov_component: MovComponent = $MovComponent
@onready var anim_body: AnimComponent = $AnimBody
@onready var anim_hands: AnimComponent = $AnimHands
@onready var muzzle: Marker2D = $AnimHands/Muzzle
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_component: AttackComponent = $AttackComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: BarComponent = $HealthBar

enum STATE {IDLE, RUN, PICKUP, DEAD} # estados

var current_state: STATE = STATE.IDLE
var move_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	# O equipamento atual precisa ser uma cópia para não alterar outros do mesmo tipo
	current_equipment = current_equipment.duplicate()
	current_equipment.current_ammo = current_equipment.max_ammo
	health_bar.change_max(health_component.max_health)

func _process(_delta: float) -> void:
	if current_equipment.follow_mouse and current_state != STATE.DEAD:
		var target_pos: Vector2 = controller_component.aim_target
		var look_dir: Vector2 = (target_pos - global_position).normalized()
		if look_dir != Vector2.ZERO:
			anim_body.change_dir(look_dir) # Faz o corpo olhar na direção cardinal do alvo
			anim_hands.change_dir(look_dir) # Sprite muda para a direção cardinal do alvo
			anim_hands.look_at(target_pos) # Gira na direção do alvo
			
			# Desconta a rotação base de cada sprite cardinal
			match anim_hands.cardinal:
				"down":
					anim_hands.rotation -= PI / 2.0 # -90 graus
				"left":
					anim_hands.rotation -= PI       # -180 graus
				"up":
					anim_hands.rotation += PI / 2.0 # +90 graus
	elif current_state != STATE.DEAD:
		anim_body.change_dir(move_dir)
		anim_hands.rotation = 0.0
		anim_hands.change_dir(move_dir)
	
	# Controla se as mãos ficam atrás do corpo ao olhar para cima
	if current_equipment.behind_if_up and anim_hands.cardinal == "up":
		anim_hands.z_index = -1
	else:
		anim_hands.z_index = 0
	
	match current_state: # FSM
		STATE.IDLE:
			if velocity != Vector2.ZERO:
				current_state = STATE.RUN
			anim_body.play_anim("idle")
			anim_hands.play_anim(current_equipment.get_anim_name("idle"), current_equipment.sprite_frames, current_equipment.sprite_offsets)
		STATE.RUN:
			if velocity == Vector2.ZERO and move_dir == Vector2.ZERO:
				current_state = STATE.IDLE
			anim_body.play_anim("run")
			anim_hands.play_anim(current_equipment.get_anim_name("run"), current_equipment.sprite_frames, current_equipment.sprite_offsets)
		STATE.PICKUP:
			pass
		STATE.DEAD:
			pass
	
	# Atualiza a posição do cano da arma
	muzzle.position = current_equipment.get_muzzle_pos(anim_hands.cardinal)

func _on_controller_component_dir_changed(input_dir: Vector2) -> void:
	if current_state == STATE.DEAD:
		return
	move_dir = input_dir
	mov_component.change_dir(input_dir)

func _on_controller_component_shoot_pressed() -> void:
	if current_state == STATE.DEAD:
		return
	if current_equipment.current_ammo > 0 and attack_timer.is_stopped() and (current_state == STATE.IDLE or current_state == STATE.RUN):
		controller_component.consume_buffer(controller_component.shoot_pressed)
		attack_component.shoot(current_equipment.damage, muzzle.global_position, controller_component.aim_target, current_equipment.projectile_scene)
		attack_timer.wait_time = current_equipment.attack_cd
		attack_timer.start()
		anim_hands.play_anim(current_equipment.get_anim_name("attack"), current_equipment.sprite_frames, current_equipment.sprite_offsets)
		current_equipment.current_ammo -= 1
	elif current_equipment.current_ammo == 0 and current_equipment.max_ammo > 0:
		print("sem munição")

func _on_controller_component_shoot_held() -> void:
	if current_state == STATE.DEAD:
		return
	if current_equipment.is_automatic and current_equipment.current_ammo > 0 and attack_timer.is_stopped() and (current_state == STATE.IDLE or current_state == STATE.RUN):
		attack_component.shoot(current_equipment.damage, muzzle.global_position, controller_component.aim_target, current_equipment.projectile_scene)
		attack_timer.wait_time = current_equipment.attack_cd
		attack_timer.start()
		anim_hands.play_anim(current_equipment.get_anim_name("attack"), current_equipment.sprite_frames, current_equipment.sprite_offsets)
		current_equipment.current_ammo -= 1

func _on_controller_component_reload_pressed() -> void:
	if current_state == STATE.DEAD:
		return
	if current_equipment.current_ammo < current_equipment.max_ammo:
		controller_component.consume_buffer(controller_component.reload_pressed)
		anim_hands.play_anim(current_equipment.get_anim_name("reload"), current_equipment.sprite_frames, current_equipment.sprite_offsets, current_equipment.reload_time)

func _on_controller_component_interact_pressed() -> void:
	if current_state == STATE.DEAD:
		return

func _on_health_component_health_changed(current_health: Variant) -> void:
	health_bar.change_value(current_health)

func _on_health_component_dead() -> void:
	current_state = STATE.DEAD

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if "damage" in area.get_parent():
		health_component.damage(area.get_parent().damage)
		controller_component.on_damaged()

func _on_anim_hands_animation_finished() -> void:
	var finished_action: String = anim_hands.animation.rsplit("_", true, 1)[0]
	if finished_action == current_equipment.get_anim_name("reload"):
		current_equipment.reload()
