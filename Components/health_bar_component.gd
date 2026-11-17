extends TextureProgressBar
class_name BarComponent

@export var sub_health_bar: ProgressBar
@export var health_timer: float = 0.25

var health_tween: Tween
var _current_duration: float = 0.0

func _ready() -> void:
	change_value(max_value)

func change_max(new_max: float, add_difference: bool = true) -> void:
	var old_max: float = max_value
	max_value = new_max
	if add_difference:
		value += new_max - old_max
	if sub_health_bar:
		sub_health_bar.max_value = new_max
		sub_health_bar.value = value

func change_value(new_value: float) -> void:
	var time: float = health_timer
	if health_tween and health_tween.is_running():
		var remaining: float = max(0.0, _current_duration - health_tween.get_total_elapsed_time())
		time += remaining
		health_tween.kill()
	value = new_value
	if not sub_health_bar:
		return
	# Se curou (novo valor maior que a barra de fundo), sobe a barra de fundo na hora
	if new_value >= sub_health_bar.value:
		sub_health_bar.value = new_value
		return
	_current_duration = time
	health_tween = create_tween()
	health_tween.tween_property(sub_health_bar, "value", new_value, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
