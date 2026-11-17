extends CharacterBody2D
class_name Character

@export var current_equipment: Equipment 
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
	attack_timer.one_shot = true

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
			if not _is_hands_busy():
				anim_hands.play_anim(current_equipment.get_anim_name("idle"), current_equipment.sprite_frames, current_equipment.sprite_offsets)
		STATE.RUN:
			if velocity == Vector2.ZERO and move_dir == Vector2.ZERO:
				current_state = STATE.IDLE
			anim_body.play_anim("run")
			if not _is_hands_busy():
				anim_hands.play_anim(current_equipment.get_anim_name("run"), current_equipment.sprite_frames, current_equipment.sprite_offsets)
		STATE.PICKUP:
			pass
		STATE.DEAD:
			pass
	
	# Atualiza a posição do cano da arma
	muzzle.position = current_equipment.get_muzzle_pos(anim_hands.cardinal)

# Retorna true enquanto uma animação pontual (attack ou reload) ainda estiver rodando
func _is_hands_busy() -> bool:
	if not anim_hands.is_playing() or anim_hands.animation == "":
		return false
	var current_action: String = anim_hands.animation.rsplit("_", true, 1)[0] # nome da atuão ação(animação)
	return current_action in [ # se estiver no array retorna true e mãos estão ocupadas
		current_equipment.get_anim_name("attack"),
		current_equipment.get_anim_name("reload"),
		"reload_start",
		"reload_end"
	]

func _try_shoot() -> bool:
	if current_state == STATE.DEAD:
		return false
	var current_action: String = anim_hands.animation.rsplit("_", true, 1)[0] if anim_hands.is_playing() else ""
	var can_interrupt_reload: bool = current_equipment.reload_one_by_one and current_equipment.current_ammo > 0 and current_action in ["reload_start", current_equipment.get_anim_name("reload")]
	
	if _is_hands_busy() and not can_interrupt_reload:
		return false
	
	if current_equipment.current_ammo > 0 and attack_timer.is_stopped() and (current_state == STATE.IDLE or current_state == STATE.RUN):
		attack_component.shoot(current_equipment.damage, muzzle.global_position, controller_component.aim_target, current_equipment.projectile_texture, current_equipment.pellets, current_equipment.spread_angle)
		attack_timer.wait_time = current_equipment.attack_cd
		attack_timer.start()
		anim_hands.play_anim(current_equipment.get_anim_name("attack"), current_equipment.sprite_frames, current_equipment.sprite_offsets)
		current_equipment.current_ammo -= 1
		return true
	elif current_equipment.current_ammo == 0 and current_equipment.max_ammo > 0:
		print("sem munição")
		return true
	return false

func _on_controller_component_dir_changed(input_dir: Vector2) -> void:
	if current_state == STATE.DEAD:
		return
	move_dir = input_dir
	mov_component.change_dir(input_dir)

func _on_controller_component_shoot_pressed() -> void:
	if _try_shoot():
		controller_component.consume_buffer(controller_component.shoot_pressed)

func _on_controller_component_shoot_held() -> void:
	if current_equipment.is_automatic:
		_try_shoot()


func _on_controller_component_reload_pressed() -> void:
	if current_state == STATE.DEAD or _is_hands_busy():
		return
	if current_equipment.current_ammo < current_equipment.max_ammo:
		controller_component.consume_buffer(controller_component.reload_pressed)
		var reload_type: String = "reload"
		if current_equipment.reload_one_by_one:
			reload_type = "reload_start"
		anim_hands.play_anim(current_equipment.get_anim_name(reload_type), current_equipment.sprite_frames, current_equipment.sprite_offsets, current_equipment.reload_time)

func _on_controller_component_interact_pressed() -> void:
	if current_state == STATE.DEAD:
		return

func _on_health_component_health_changed(current_health: Variant) -> void:
	health_bar.change_value(current_health)

func _on_health_component_dead() -> void:
	current_state = STATE.DEAD
	if anim_body.cardinal == "up":
		anim_body.cardinal = "left"
		anim_hands.cardinal = "left"
	elif anim_body.cardinal == "down":
		anim_body.cardinal = "right"
		anim_hands.cardinal = "right"
	
	if anim_hands.cardinal == "left":
		anim_hands.rotation = deg_to_rad(360)
	else:
		anim_hands.rotation = 0.0
	
	anim_body.play_anim("die")
	anim_hands.play_anim("die")

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if "damage" in area.get_parent():
		health_component.damage(area.get_parent().damage)
		controller_component.on_damaged()

# 4. Encadeia: reload_start -> reload (1 bala por vez) -> reload_end
func _on_anim_hands_animation_finished() -> void:
	var finished_action: String = anim_hands.animation.rsplit("_", true, 1)[0]
	if finished_action == "reload_start":
		anim_hands.play_anim(current_equipment.get_anim_name("reload"), current_equipment.sprite_frames, current_equipment.sprite_offsets, current_equipment.reload_time)
	elif finished_action == current_equipment.get_anim_name("reload"):
		if current_equipment.reload_one_by_one:
			current_equipment.reload(1)
			if current_equipment.current_ammo < current_equipment.max_ammo and current_state != STATE.DEAD:
				anim_hands.play_anim(current_equipment.get_anim_name("reload"), current_equipment.sprite_frames, current_equipment.sprite_offsets, current_equipment.reload_time)
			else:
				anim_hands.play_anim("reload_end", current_equipment.sprite_frames, current_equipment.sprite_offsets, current_equipment.reload_end_time)
		else:
			current_equipment.reload(current_equipment.max_ammo)

func change_equipment(new_equipment: Equipment):
	current_equipment = new_equipment

func _on_mov_component_move(new_velocity: Vector2) -> void:
	if current_state == STATE.DEAD:
		return
	velocity = new_velocity
	move_and_slide()
