class_name RadarEchoTracker
extends Node3D

@export var radar: Radar
@export var marker_scene: PackedScene
@export var show_markers: bool = true
@export var min_draw_distance: float = 640.0
@export var camera: Camera3D

var _markers: Dictionary[int, Node3D] = {}
var _marker_expiry: Dictionary[int, float] = {}

func _process(_delta: float) -> void:
	if radar == null:
		return

	if Input.is_action_just_pressed("select_target"):
		if radar.tracking:
			radar.stop_tracking()
		else:
			_lock_nearest_target()
		_clear_all_markers()
		return

	if radar.tracking:
		return

	if not show_markers:
		_clear_all_markers()
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	_update_markers(radar.get_echoes(), now)
	_expire_old_markers(now)


func _lock_nearest_target() -> void:
	var echoes: Array = radar.get_echoes()
	if echoes.is_empty():
		return
	var cam_pos: Vector3 = camera.global_position
	var cam_forward: Vector3 = -camera.global_transform.basis.z
	var best_echo: RadarEcho = null
	var best_angle: float = INF
	for echo in echoes:
		var dir: Vector3 = (echo.world_position - cam_pos).normalized()
		var angle: float = cam_forward.angle_to(dir)
		if angle < best_angle:
			best_angle = angle
			best_echo = echo
	if best_echo != null:
		radar.start_tracking_position(best_echo.world_position)


func _update_markers(echoes: Array, now: float) -> void:
	var beam := radar.beam
	var range_step := beam.range_bin_size
	var origin: Vector3 = beam.global_position
	var sweep_time: float = (radar.sweep_width_deg * 2.0 / radar.sweep_rate_deg) * radar.bars
	for e in echoes:
		var pos: Vector3 = e.world_position
		var rng: float = (pos - radar.beam.global_position).length()
		if rng < min_draw_distance:
			continue

		var id: int = e.get_instance_id()
		if not _markers.has(id) and marker_scene:
			_markers[id] = marker_scene.instantiate()
			add_child(_markers[id])

		if _markers.has(id):
			var m: Node3D = _markers[id]
			m.global_position = pos
			var lbl := m.get_node("Label3D") as Label3D
			lbl.text = "D: %.0f" % rng
			_marker_expiry[id] = now + sweep_time

func _expire_old_markers(now: float) -> void:
	for id in _marker_expiry.keys():
		if _marker_expiry[id] < now:
			if _markers.has(id):
				_markers[id].queue_free()
				_markers.erase(id)
			_marker_expiry.erase(id)

func _clear_all_markers() -> void:
	for m in _markers.values():
		m.queue_free()
	_markers.clear()
	_marker_expiry.clear()
