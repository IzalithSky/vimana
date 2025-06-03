class_name TimeSkipLoader extends Node


@export var next_scene_path: String
@export var progress_bar: ProgressBar
@export var pause_duration: float = 2.0
@export var time_scale: float = 4.0
@export var time_scale_duration: float = 22.0
@export var update_interval: float = 0.1

var _original_bus_volume: float = 0.0


func _ready() -> void:
	_original_bus_volume = AudioServer.get_bus_volume_db(0)
	AudioServer.set_bus_volume_db(0, -80.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_start_sequence()


func _start_sequence() -> void:
	await get_tree().create_timer(pause_duration).timeout
	get_tree().paused = false
	Engine.time_scale = time_scale
	_update_progress_bar(0.0)
	
	var timer: Timer = Timer.new()
	timer.wait_time = update_interval
	timer.one_shot = false
	add_child(timer)
	timer.start()
	
	var elapsed: float = 0.0
	while elapsed < time_scale_duration:
		await timer.timeout
		elapsed += update_interval
		_update_progress_bar(elapsed / time_scale_duration)
	
	timer.stop()
	timer.queue_free()
	Engine.time_scale = 1.0
	_update_progress_bar(1.0)
	_unmute_and_load()


func _unmute_and_load() -> void:
	AudioServer.set_bus_volume_db(0, _original_bus_volume)
	_load_next_scene()


func _update_progress_bar(value: float) -> void:
	if progress_bar:
		progress_bar.value = clamp(value * progress_bar.max_value, 0.0, progress_bar.max_value)


func _load_next_scene() -> void:
	if next_scene_path.is_empty():
		return
	get_tree().change_scene_to_file(next_scene_path)
