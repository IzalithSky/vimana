class_name RadarEchoTracker extends Node3D


@export var radar: RadarBeam
@export var marker_scene: PackedScene
@export var show_markers: bool = true
@export var min_draw_distance: float = 640.0

var _markers: Dictionary = {}


func _process(_delta: float) -> void:
	var echoes: Array[RadarEcho] = radar.get_echoes()
	if show_markers:
		_update_markers(echoes)
	else:
		_clear_all_markers()


func _update_markers(echoes: Array[RadarEcho]) -> void:
	var live_ids: Array[int] = []
	for echo in echoes:
		var center_range: float = (float(echo.range_bin) + 0.5) * radar.range_resolution
		if center_range < min_draw_distance:
			continue
	
		var id: int = hash(int(echo.range_bin) << 8 | int(echo.radial_velocity_bin))
		live_ids.append(id)
	
		var marker: Node3D = _markers.get(id, null)
		if marker == null:
			if marker_scene == null:
				continue
			marker = marker_scene.instantiate()
			if marker == null:
				continue
			add_child(marker)
			_markers[id] = marker
	
		var direction: Vector3 = -radar.global_transform.basis.z.normalized()
		var position: Vector3 = radar.global_position + direction * center_range
		marker.global_position = position
	
	for id in _markers.keys():
		if id not in live_ids:
			var marker: Node3D = _markers[id]
			if marker != null:
				marker.queue_free()
			_markers.erase(id)


func _clear_all_markers() -> void:
	for marker in _markers.values():
		if marker != null:
			marker.queue_free()
	_markers.clear()
