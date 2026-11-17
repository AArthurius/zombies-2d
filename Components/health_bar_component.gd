extends TextureProgressBar
class_name BarComponent

@export var sub_health_bar: ProgressBar
@export var health_timer: float = 0.25

var health_tween: Tween
var _current_duration: float = 0.0

func _ready() -> void:
	value = max_value
	if sub_health_bar:
		sub_health_bar.max_value = max_value
		sub_health_bar.value = value

func change_max(new_max: float, add_difference: bool = true) -> void:
	if health_tween and health_tween.is_running():
		health_tween.kill()
	var old_max: float = max_value
	max_value = new_max
	if add_difference:
		value = clamp(value + (new_max - old_max), 0.0, new_max)
	if sub_health_bar:
		sub_health_bar.max_value = new_max
		sub_health_bar.value = value

func change_value(new_value: float) -> void:
	var time: float = health_timer
	if health_tween and health_tween.is_running():
		var remaining: float = max(0.0, _current_duration - health_tween.get_total_elapsed_time())
		time += remaining
		health_tween.kill()
	if not sub_health_bar:
		value = new_value
		return
	_current_duration = time
	health_tween = create_tween()
	if new_value > value:
		# Cura: barra de fundo sobe na hora e a principal desliza até ela
		sub_health_bar.value = new_value
		health_tween.tween_property(self, "value", new_value, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		# Dano: barra principal cai na hora e a de fundo desliza até ela
		value = new_value
		health_tween.tween_property(sub_health_bar, "value", new_value, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
