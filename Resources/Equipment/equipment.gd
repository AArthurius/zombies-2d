extends Resource
class_name Equipment

@export var behind_if_up: bool = true # algumas animações tem q ficar com visibility layer -1 na animação up pra ficar atrás do player
@export var run_equals_idle: bool = true
@export var follow_mouse: bool = true
@export var equipment_name: String = "free"

@export var sprite_offsets: Dictionary[String, Vector2] = {
	"idle_down" : Vector2(0, 0),
	"idle_left" : Vector2(0, 0),
	"idle_right" : Vector2(0, 0),
	"idle_up" : Vector2(0, 0),
	"attack_down" : Vector2(0, 0),
	"attack_left" : Vector2(0, 0),
	"attack_right" : Vector2(0, 0),
	"attack_up" : Vector2(0, 0),
	}

@export var muzzle_positions: Dictionary[String, Vector2] = { 
	"down": Vector2.ZERO, # do jeito que fiz é dificil achar o boca do cano da arma
	"left": Vector2.ZERO, # já que a arma gira e tem um offset no sprite pra cada direção que ela aponta
	"right": Vector2.ZERO,# então se define direto no equipamento onde fica o cano pra cada offset
	"up": Vector2.ZERO,   # se fizesse sem trocar o sprite e só girar a arma não precisaria
}

#retorna o nome de uma animação baseado no equipment
#ex: se anim_suffix = idle_down e equipment = free retorna free_idle_down
func get_full_anim_name(anim_suffix: String) -> String:
	if anim_suffix == "run" and run_equals_idle: # se as animações de equipamento idle e run são as mesmas
		anim_suffix = "idle"
	return equipment_name + "_" + anim_suffix

# retorna o offset de uma direção
# ex: se anim_suffix = idle_down retorna o offset de free_idle_down
func get_offset(anim_suffix: String) -> Vector2:
	if anim_suffix.substr(0, 4) == "run_" and run_equals_idle: # se as animações de equipamento idle e run são as mesmas
		#checa se as primeiras quatro letras são run_
		anim_suffix = "idle_" + anim_suffix.substr(4, -1) # troca por idle_ + o resto da string
	return sprite_offsets.get(anim_suffix, Vector2.ZERO) 

func get_muzzle_pos(cardinal: String) -> Vector2:
	return muzzle_positions.get(cardinal, Vector2.ZERO)
