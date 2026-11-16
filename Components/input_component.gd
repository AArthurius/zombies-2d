extends Node
class_name InputComponent

var buffered_inputs: Dictionary[Signal, float] = {}
@export var buffer_time: float = 0.25

signal dir_changed(dir: Vector2)
signal shoot_pressed()
signal shoot_held()
signal interact_pressed()
signal reload_pressed()

func _process(delta: float) -> void:
	var move_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	dir_changed.emit(move_dir)
	
	# Para armas automáticas: emite continuamente enquanto segurar, sem sujar o buffer
	if Input.is_action_pressed("shoot") and buffered_inputs.is_empty():
		shoot_held.emit()
	
	for input: Signal in buffered_inputs.keys():
		input.emit()
		if buffered_inputs.has(input):
			buffered_inputs[input] -= delta
			if buffered_inputs[input] <= 0.0:
				buffered_inputs.erase(input)

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("shoot"):
		buffer_input(shoot_pressed)
	if event.is_action_pressed("interact"):
		buffer_input(interact_pressed)
	if event.is_action_pressed("reload"):
		buffer_input(reload_pressed)

func buffer_input(input: Signal) -> void:
	buffered_inputs.clear()
	buffered_inputs[input] = buffer_time

func consume_buffer(input: Signal) -> void:
	buffered_inputs.erase(input)
