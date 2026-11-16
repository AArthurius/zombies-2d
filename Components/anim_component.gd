extends AnimatedSprite2D
class_name AnimComponent

var dir: Vector2 = Vector2.ZERO
var cardinal: String = "down" # Guarda a última direção válida
var offsets: Dictionary[String, Vector2] = {}

func _process(_delta: float) -> void:
	# Usa .get() com fallback para Vector2.ZERO para não quebrar no 1º frame ("") ou no anim_body ("run_*")
	offset = offsets.get(animation, Vector2.ZERO)

func play_anim(anim_name: String, anim: SpriteFrames = sprite_frames, anim_offsets: Dictionary[String, Vector2] = offsets, anim_time: float = -1) -> void:
	if sprite_frames != anim:
		sprite_frames = anim
	offsets = anim_offsets
	var target_anim: String = anim_name + "_" + cardinal
	if animation != target_anim or not is_playing():
		play(target_anim)
	change_anim_speed(anim_time)

func change_dir(new_dir: Vector2) -> void:
	dir = new_dir
	# Só atualiza para onde o boneco olha se houver movimento/mira
	if dir != Vector2.ZERO:
		var prev_cardinal: String = cardinal
		if abs(dir.x) > abs(dir.y):
			cardinal = "right" if dir.x > 0 else "left"
		else:
			cardinal = "down" if dir.y > 0 else "up"
		
		# Se mudou de quadrante no meio de uma animação, troca a direção preservando o frame atual
		if cardinal != prev_cardinal and animation != "":
			var current_frame: int = frame
			var current_progress: float = frame_progress
			play(animation.rsplit("_", true, 1)[0] + "_" + cardinal)
			set_frame_and_progress(current_frame, current_progress)

func change_anim_speed(anim_time: float):
	if anim_time == -1:
		speed_scale = 1
		return
	var frames:int = sprite_frames.get_frame_count(animation)
	var fps: float = sprite_frames.get_animation_speed(animation)
	var original_duration = frames/fps
	speed_scale = original_duration/anim_time
