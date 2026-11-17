extends Node
class_name InventoryComponent

@export var current_equipment: Equipment = preload("uid://x4bfj5wtdvg8") # free hands default

signal equipment_changed()

func _ready() -> void:
	# O equipamento atual precisa ser uma cópia para não alterar outros do mesmo tipo
	equip(current_equipment)

func equip(equipment: Equipment):
	current_equipment = equipment.duplicate()
	current_equipment.current_ammo = current_equipment.max_ammo
