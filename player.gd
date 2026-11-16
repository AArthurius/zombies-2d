extends CharacterBody2D

@export var current_equipment: Equipment = Equipment.new()
@onready var input_component: InputComponent = $InputComponent
@onready var mov_component: MovComponent = $MovComponent
@onready var anim_body: AnimComponent = $AnimBody
@onready var anim_hands: AnimComponent = $AnimHands
@onready var muzzle: Marker2D = $AnimHands/Marker2D

enum STATE {IDLE, RUN, PICKUP, MELEE, DEAD} # estados

var current_state: STATE = STATE.IDLE
var dir: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if current_equipment.follow_mouse:
		var mouse_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
		anim_body.change_dir(mouse_dir) # faz o corpo olhar na direção cardinal do mouse
		anim_hands.change_dir(mouse_dir) # sprite muda pra direção cardinal do mouse
		anim_hands.look_at(get_global_mouse_position()) # gira na direção do mouse
		
		# Desconta a rotação base de cada sprite cardinal
		match anim_hands.cardinal:
			"down":
				anim_hands.rotation -= PI / 2.0 # -90 graus
			"left":
				anim_hands.rotation -= PI       # -180 graus
			"up":
				anim_hands.rotation += PI / 2.0 # +90 graus
	else:
		anim_hands.rotation = 0.0
		anim_hands.change_dir(dir)
	
	# Controla se as mãos ficam atrás do corpo ao olhar para cima
	if current_equipment.behind_if_up and anim_hands.cardinal == "up":
		anim_hands.z_index = -1
	else:
		anim_hands.z_index = 0
	
	match current_state:
		STATE.IDLE:
			if velocity != Vector2.ZERO:
				current_state = STATE.RUN
			anim_body.play_anim("idle")
			anim_hands.play_anim(current_equipment.get_full_anim_name("idle"), current_equipment.get_offset("idle_" + anim_hands.cardinal))
		STATE.RUN:
			if velocity == Vector2.ZERO and dir == Vector2.ZERO:
				current_state = STATE.IDLE
			anim_body.play_anim("run")
			anim_hands.play_anim(current_equipment.get_full_anim_name("run"), current_equipment.get_offset("run_" + anim_hands.cardinal))
		STATE.PICKUP:
			pass
		STATE.MELEE:
			pass
		STATE.DEAD:
			pass
	
	# Atualiza a posição do cano da arma (some "+ anim_hands.offset" aqui caso tenha medido com offset zerado)
	muzzle.position = current_equipment.get_muzzle_pos(anim_hands.cardinal)

func _on_input_component_dir_changed(input_dir: Vector2) -> void: # mudou a direção
	dir = input_dir
	mov_component.change_dir(input_dir)
	if not current_equipment.follow_mouse:
		anim_body.change_dir(input_dir)
		anim_hands.change_dir(input_dir)

func _on_input_component_shoot_pressed() -> void: # botão pra atirar
	pass # Replace with function body.

func _on_input_component_interact_pressed() -> void: # botão pra interagir
	pass # Replace with function body.
