extends Resource
class_name Equipment

@export_group("Identificação & Visual")
@export var equipment_name: String = "free"
@export var icon: Texture = Texture.new()
@export var pellet_icon: Texture = Texture.new()
@export var sprite_frames: SpriteFrames = SpriteFrames.new()
@export var behind_if_up: bool = true ## algumas animações tem q ficar com visibility layer -1 na animação up pra ficar atrás do player
@export var run_equals_idle: bool = true
@export var follow_mouse: bool = true

@export_group("Combate & Disparo")
@export var is_automatic: bool = false
@export var attack_cd: float = 1.0 ## cooldown total pra atirar, coloca isso em um timer se maior que 1
@export var damage: int = 5
@export var pellets: int = 1 ## quantas balas atiram de uma vez
@export var spread_angle: float = 0.0 ## angulo do spread de tiro
@export var projectile_texture: Texture ## a prefab de bala

@export_group("Munição & Recarga")
@export var reload_one_by_one: bool = false ## true para shotgun (reload_start -> reload -> reload_end)
@export var reload_time: float = -1.0 ## quantos segundos leva pra recarregar
@export var reload_start_time: float = -1.0 ## tempo para levantar a arma
@export var reload_end_time: float = -1.0 ## tempo para engatilhar/empunhar ao finalizar
@export var max_ammo: int = -1 : ## se ammo for menor que zero não precisa de munição
	set(value):
		max_ammo = value
		current_ammo = value

var current_ammo: int = 0

@export_group("Offsets & Posicionamento")
@export var sprite_offsets: Dictionary[String, Vector2] = {
	"idle_down": Vector2(0, 0),
	"idle_left": Vector2(0, 0),
	"idle_right": Vector2(0, 0),
	"idle_up": Vector2(0, 0),
	"attack_down": Vector2(0, 0),
	"attack_left": Vector2(0, 0),
	"attack_right": Vector2(0, 0),
	"attack_up": Vector2(0, 0),
	"reload_down": Vector2(0, 0),
	"reload_left": Vector2(0, 0),
	"reload_right": Vector2(0, 0),
	"reload_up": Vector2(0, 0)
}

@export var muzzle_positions: Dictionary[String, Vector2] = {
	"down": Vector2.ZERO,  # do jeito que fiz é dificil achar o boca do cano da arma
	"left": Vector2.ZERO,  # já que a arma gira e tem um offset no sprite pra cada direção que ela aponta
	"right": Vector2.ZERO, # então se define direto no equipamento onde fica o cano pra cada offset
	"up": Vector2.ZERO,    # se fizesse sem trocar o sprite e só girar a arma não precisaria
}

func _init() -> void:
	current_ammo = max_ammo

# retorna o nome de uma animação baseado no equipment
# ex: se anim_suffix = idle_down e equipment = free retorna free_idle_down
func get_anim_name(anim_suffix: String) -> String:
	if anim_suffix == "run" and run_equals_idle: # se as animações de equipamento idle e run são as mesmas
		anim_suffix = "idle"
	return anim_suffix

# retorna o offset de uma direção
# ex: se anim_suffix = idle_down retorna o offset de free_idle_down
func get_offset(anim_suffix: String) -> Vector2:
	if anim_suffix.substr(0, 4) == "run_" and run_equals_idle: # se as animações de equipamento idle e run são as mesmas
		# checa se as primeiras quatro letras são run_
		anim_suffix = "idle_" + anim_suffix.substr(4, -1) # troca por idle_ + o resto da string
	return sprite_offsets.get(anim_suffix, Vector2.ZERO)

func get_muzzle_pos(cardinal: String) -> Vector2:
	return muzzle_positions.get(cardinal, Vector2.ZERO)

func reload(amount: int) -> void:
	if max_ammo > 0:
		current_ammo = min(current_ammo + amount, max_ammo)
