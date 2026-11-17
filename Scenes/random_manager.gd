extends Node2D

@onready var tile_map: TileMapLayer = $"../TileMap"
const AIRDROP = preload("uid://dko2pnlp7itrg")
const PISTOL_EQUIPMENT = preload("uid://sidwlaxgjc1w")
const GUN_EQUIPMENT = preload("uid://b0m8e7b1qdaai")
const SHOTGUN_EQUIPMENT = preload("uid://ddhgh3mwa0d3f")

# gun stuff
var guns: Dictionary[Equipment, int] = {PISTOL_EQUIPMENT : 60, GUN_EQUIPMENT : 40, SHOTGUN_EQUIPMENT : 20}

# name stuff
var size: int = 2
var start: String = "^"
var end: String = "$"
var databaseNames: Array[String] = [
	# Clássicos de uma palavra só
	"abrams", "bebop", "dynamo", "haze", 
	"infernus", "ivy", "kelvin", "lash", 
	"mcginnis", "mirage", "paradox", "pocket", "seven", 
	"shiv", "vindicta", "viscous", "warden", "wraith", "yamato",
	
	# Novos heróis recentes
	"apollo", "baba", "billy", "calico", "celeste", 
	"drifter", "graves", "holliday", "mina", "paige", 
	"rem", "silver", "sinclair", "solomon", "venator", 
	"victor", "violet", "vyper"
]
var table: Dictionary[String, Array] = {}

func _ready() -> void:
	#seed(12345)
	
	train_name()
	
	for enemy in $"../Enemies".get_children():
		enemy.get_node("name").text = get_valid_name()
	try_air_drop()

func getRandomGun() -> Equipment:
	var total: int = 0
	for gun in guns:
		total += guns[gun]
	var r: int = randi_range(0, total)
	var biggest : int = 0
	var biggestGun: Equipment
	for gun in guns:
		if guns[gun] > biggest:
			biggest = guns[gun]
			biggestGun = gun
		r -= guns[gun] # r = r - peso
		if r < 0:
			return gun
	return biggestGun

func train_name() -> void:
	var startSized: String = ""
	for num in size:
		startSized = startSized + start
	for nome in databaseNames:
		var text = (startSized) + nome + end
		for i in text.length():
			if i < size:
				continue
			var context: String = text.substr(i - size, size) # letras depois de 
			var proxima: String = text[i] # proximo
			if not table.has(context):
				table[context] = []
			table[context].append(proxima)

func make_name() -> String:
	var context: String = ""
	var randName: String = ""
	for num in size:
		context = context + start
	while not randName.length() > 12:
		var letter: String = table[context].pick_random()
		if letter == end:
			break
		randName = randName + letter
		context = context.substr(context.length() - size + 1) + letter
	return randName

func get_valid_name():
	var randName: String = make_name()
	while true:
		if (randName.length() > 4 and randName.length() < 9) and databaseNames.find(randName) == - 1:
			break
		else:
			randName = make_name()
	if randName.length() > 0:
		randName = randName.substr(0, 1).to_upper() + randName.substr(1)
	return randName

func get_air_drop_pos():
	var cells: Array[Vector2i] = tile_map.get_used_cells()
	var target_cell: Vector2i = cells[randi_range(0, cells.size() - 1)]
	var cell_data: TileData = tile_map.get_cell_tile_data(target_cell)
	var counter: int = 0
	while not cell_data.get_custom_data("free"):
		target_cell = cells[randi_range(0, cells.size() - 1)]
		cell_data = tile_map.get_cell_tile_data(target_cell)
		counter += 1
		if counter > 10:
			print("air drop failed")
			return
	return tile_map.map_to_local(target_cell)

func try_air_drop():
	var target_pos = get_air_drop_pos()
	var airdrop = AIRDROP.instantiate()
	$"..".add_child.call_deferred(airdrop)
	airdrop.equipment = getRandomGun()
	airdrop.spawn_at(target_pos)
	
	print("air drop at ", target_pos)


func _on_timer_timeout() -> void:
	try_air_drop()
