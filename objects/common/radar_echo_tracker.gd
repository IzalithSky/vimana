class_name RadarEchoTracker extends Node3D


@export var radar: Radar
@export var marker_scene: PackedScene
@export var show_markers: bool = true
@export var min_draw_distance: float = 640.0


var _markers: Dictionary[int, Node3D] = {}
var _marker_ttls: Dictionary[int, int] = {}
var _last_scanned_bar: int = -1


func _process(_delta: float) -> void:
	if not show_markers:
		_clear_all_markers()
		return
	var echoes: Array[RadarEcho] = radar.get_echoes()
	_update_markers(echoes)
	if radar.current_bar != _last_scanned_bar:
		_decrement_ttls()
		_last_scanned_bar = radar.current_bar


func _update_markers(echoes: Array[RadarEcho]) -> void:
	var beam: RadarBeam = radar.beam
	var range_step: float = beam.range_bin_size
	var origin: Vector3 = beam.global_position
	var direction: Vector3 = -beam.global_transform.basis.z
	for echo in echoes:
		var center_distance: float = (echo.range_bin + 0.5) * range_step
		if center_distance < min_draw_distance:
			continue
		var key: int = hash((echo.range_bin << 8) | int(echo.radial_velocity_bin))
		if not _markers.has(key) and marker_scene:
			var m: Node3D = marker_scene.instantiate() as Node3D
			add_child(m)
			_markers[key] = m
		if _markers.has(key):
			var marker: Node3D = _markers[key]
			marker.global_position = origin + direction * center_distance
			_marker_ttls[key] = radar.bars


func _decrement_ttls() -> void:
	for key in _marker_ttls.keys():
		_marker_ttls[key] -= 1
		if _marker_ttls[key] <= 0:
			if _markers.has(key):
				_markers[key].queue_free()
				_markers.erase(key)
			_marker_ttls.erase(key)


func _clear_all_markers() -> void:
	for m in _markers.values():
		m.queue_free()
	_markers.clear()
	_marker_ttls.clear()
