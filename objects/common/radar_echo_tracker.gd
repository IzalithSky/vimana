class_name RadarEchoTracker
extends Node3D

@export var radar: Radar
@export var camera: Camera3D
@export var marker_scene: PackedScene
@export var lock_time_sec: float = 1.0
@export var show_markers: bool = true

var locked_target: RadarTarget = null
var _lock_candidate: RadarTarget = null
var _lock_timer: float = 0.0
var _markers: Dictionary = {}

func _process(delta: float) -> void:
	var radar_targets: Array[RadarTarget] = radar.get_targets()

	var best: RadarTarget = null
	var best_angle: float = INF
	if camera != null:
		var cam_dir: Vector3 = -camera.global_transform.basis.z
		for t in radar_targets:
			if not is_instance_valid(t):
				continue
			var to_target: Vector3 = (t.global_position - camera.global_position).normalized()
			var angle: float = acos(cam_dir.dot(to_target))
			if angle < best_angle:
				best_angle = angle
				best = t

	if best == _lock_candidate:
		_lock_timer += delta
		if _lock_timer >= lock_time_sec:
			locked_target = _lock_candidate
	else:
		_lock_candidate = best
		_lock_timer = 0.0
		locked_target = null

	_update_visuals(radar_targets)

func _update_visuals(visible_targets: Array[RadarTarget]) -> void:
	if show_markers:
		_update_markers(visible_targets)
	else:
		_clear_all_markers()

func _update_markers(visible_targets: Array[RadarTarget]) -> void:
	var live: Array[int] = []

	for t in visible_targets:
		if not is_instance_valid(t):
			continue
		var id: int = t.get_instance_id()
		live.append(id)

		var marker = _markers.get(id, null)
		if marker == null and marker_scene != null:
			marker = marker_scene.instantiate()
			if marker != null:
				add_child(marker)
				_markers[id] = marker
		if marker != null:
			marker.global_position = t.global_position
			marker.radar()
			marker.clear()

	if locked_target != null:
		var id: int = locked_target.get_instance_id()
		var marker = _markers.get(id, null)
		if marker == null and marker_scene != null:
			marker = marker_scene.instantiate()
			if marker != null:
				add_child(marker)
				_markers[id] = marker
		if marker != null:
			marker.global_position = locked_target.global_position
			marker.radar()
			marker.set_locked()
		if id not in live:
			live.append(id)

	for id in _markers.keys():
		if id not in live:
			if is_instance_valid(_markers[id]):
				_markers[id].queue_free()
			_markers.erase(id)


func _clear_all_markers() -> void:
	for m in _markers.values():
		m.queue_free()
	_markers.clear()
