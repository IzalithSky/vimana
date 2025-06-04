class_name HeatSeekerTargetTracker
extends Node3D


enum _SoundState {
	SILENT,
	LOCKING,
	LOCKED
}

@export var seeker: HeatSeeker
@export var marker_scene: PackedScene
@export var lock_time_sec: float = 1.0
@export var show_markers: bool = true
@export var locking_sound: AudioStreamPlayer3D
@export var locked_sound: AudioStreamPlayer3D

var target: HeatSource = null
var _lock_candidate: HeatSource = null
var _lock_timer: float = 0.0
var _markers: Dictionary = {}
var _sound_state: _SoundState = _SoundState.SILENT


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
	_update_sound_state(visible_sources)


func _update_sound_state(visible_sources: Array[HeatSource]) -> void:
	var new_state: _SoundState = _SoundState.SILENT
	
	if show_markers:
		if target != null:
			new_state = _SoundState.LOCKED
		elif visible_sources.size() > 0:
			new_state = _SoundState.LOCKING
	else:
		if locking_sound != null:
			locking_sound.stop()
		if locking_sound != null:
			locked_sound.stop()
		return
	
	if new_state != _sound_state:
		_sound_state = new_state
		match _sound_state:
			_SoundState.SILENT:
				if locking_sound != null:
					locking_sound.stop()
				if locked_sound != null:
					locked_sound.stop()
			_SoundState.LOCKING:
				if locking_sound != null:
					locking_sound.play()
				if locked_sound != null:
					locked_sound.stop()
			_SoundState.LOCKED:
				if locking_sound != null:
					locking_sound.stop()
				if locked_sound != null:
					locked_sound.play()


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
