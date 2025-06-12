class_name HeatSeekerTargetTracker extends Node3D


@export var seeker: HeatSeeker
@export var seeker_bg: HeatSeeker
@export var marker_scene: PackedScene
@export var lock_time_sec: float = 1.0
@export var show_markers: bool = true
@export var play_sounds: bool = false
@export var locking_sound: AudioStreamPlayer3D
@export var locked_sound: AudioStreamPlayer3D

var target: HeatSource = null
var _lock_candidate: HeatSource = null
var _lock_timer: float = 0.0
var _markers: Dictionary = {}


func _process(delta: float) -> void:
	var seeker_sources: Array[HeatSource] = seeker.get_visible_sources()
	var best: HeatSource = seeker.get_best_target()

	if seeker_sources.size() == 1 and best == _lock_candidate:
		_lock_timer += delta
		if _lock_timer >= lock_time_sec:
			target = _lock_candidate
	else:
		_lock_candidate = best if seeker_sources.size() == 1 else null
		_lock_timer = 0.0
		target = null

	var visible_sources: Array[HeatSource]
	if seeker_bg != null:
		visible_sources = seeker_bg.get_visible_sources()
	else:
		visible_sources = []
	_update_visuals(visible_sources)
	_update_sound_state(seeker_sources)


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
		var marker: TargetMarker = _markers.get(id, null)
		if marker == null and marker_scene != null:
			marker = marker_scene.instantiate() as TargetMarker
			if marker != null:
				add_child(marker)
				_markers[id] = marker
		if marker != null:
			marker.global_position = hs.global_position
			marker.heat()
			marker.clear()
	
	if target != null:
		var id: int = target.get_instance_id()
		var marker: TargetMarker = _markers.get(id, null)
		if marker == null and marker_scene != null:
			marker = marker_scene.instantiate() as TargetMarker
			if marker != null:
				add_child(marker)
				_markers[id] = marker
		if marker != null:
			marker.global_position = target.global_position
			marker.heat()
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


func _update_sound_state(visible_sources: Array[HeatSource]) -> void:
	if not play_sounds:
		if locking_sound: locking_sound.stop()
		if locked_sound: locked_sound.stop()
		return
	
	if target != null:
		if locking_sound: locking_sound.stop()
		if locked_sound and not locked_sound.playing: locked_sound.play()
	elif visible_sources.size() == 1:
		if locked_sound: locked_sound.stop()
		if locking_sound and not locking_sound.playing: locking_sound.play()
	else:
		if locking_sound: locking_sound.stop()
		if locked_sound: locked_sound.stop()


func get_target() -> HeatSource:
	return target
