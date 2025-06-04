class_name HeatSeekerTargetTracker extends Node3D


@export var seeker: HeatSeeker
@export var marker_scene: PackedScene
@export var lock_time_sec: float = 0.5
@export var show_markers: bool = true

var target: HeatSource = null
var _lock_candidate: HeatSource = null
var _lock_timer: float = 0.0
var _markers: Dictionary = {}


func _process(delta: float) -> void:
	var visible_sources: Array[HeatSource] = seeker.get_visible_sources()
	var best: HeatSource = seeker.get_best_target()
	
	if best == _lock_candidate:
		_lock_timer += delta
		if _lock_timer >= lock_time_sec:
			target = _lock_candidate
	else:
		_lock_candidate = best
		_lock_timer = 0.0
		target = null
	
	_update_visuals(visible_sources)


func _update_visuals(visible_sources: Array[HeatSource]) -> void:
	if show_markers:
		_update_markers(visible_sources)
	else:
		_clear_all_markers()


func _update_markers(visible_sources: Array[HeatSource]) -> void:
	var live: Array[int] = []
	for hs in visible_sources:
		var id: int = hs.get_instance_id()
		live.append(id)
		var m: TargetMarker = _markers.get(id, null)
		if m == null and marker_scene != null:
			m = marker_scene.instantiate() as TargetMarker
			add_child(m)
			_markers[id] = m
		if m != null:
			m.global_transform.origin = hs.global_transform.origin
			if hs == target:
				m.set_locked()
			else:
				m.clear()
	
	for id in _markers.keys():
		if id not in live:
			_markers[id].queue_free()
			_markers.erase(id)


func _clear_all_markers() -> void:
	for m in _markers.values():
		m.queue_free()
	_markers.clear()


func get_target() -> HeatSource:
	return target
