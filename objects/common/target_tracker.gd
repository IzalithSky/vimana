class_name TargetTracker extends Node3D


@export var radar: Radar
@export var camera: Camera3D
@export var seeker: HeatSeeker
@export var seeker_bg: HeatSeeker
@export var marker_scene: PackedScene
@export var lock_time_sec: float = 1.0
@export var show_markers: bool = true
@export var play_sounds: bool = false
@export var locking_sound: AudioStreamPlayer3D
@export var locked_sound: AudioStreamPlayer3D

@export var enable_heat_locking: bool = false
@export var enable_radar_locking: bool = false
@export var enable_heat_markers: bool = false
@export var enable_radar_markers: bool = false

var heat_locked: HeatSource = null
var heat_candidate: HeatSource = null
var heat_timer: float = 0.0

var radar_locked: TargetMarker = null
var radar_candidate: TargetMarker = null
var radar_timer: float = 0.0

var _markers: Dictionary[int, TargetMarker] = {}
var _heat_live_ids: Array[int] = []
var _radar_live_ids: Array[int] = []


func _process(delta: float) -> void:
	radar.active = enable_radar_markers if radar != null else false
	_heat_live_ids = _handle_heat_logic(delta)
	_radar_live_ids = _handle_radar_logic(delta)
	var all_live_ids: Array[int] = _heat_live_ids + _radar_live_ids
	_mark_unused(all_live_ids)
	_update_sound_state()
	_purge_unused_markers()
	_rotate_seeker_to_best_target()


func _handle_heat_logic(delta: float) -> Array[int]:
	if seeker == null and not enable_heat_markers:
		return []
	
	if enable_heat_locking:
		var seeker_sources: Array[HeatSource] = seeker.get_visible_sources()
		var best: HeatSource = seeker.get_best_target()
		if seeker_sources.size() == 1 and best == heat_candidate:
			heat_timer += delta
			if heat_timer >= lock_time_sec:
				heat_locked = heat_candidate
		else:
			heat_candidate = best if seeker_sources.size() == 1 else null
			heat_timer = 0.0
			heat_locked = null
	else:
		heat_locked = null
		heat_candidate = null
		heat_timer = 0.0
	
	var visible_sources: Array[HeatSource] = []
	if enable_heat_markers and seeker_bg != null:
		visible_sources = seeker_bg.get_visible_sources()
	
	if enable_heat_markers:
		return _update_heat_markers(visible_sources)
	return []


func _handle_radar_logic(delta: float) -> Array[int]:
	if radar == null:
		return []
	
	var live_ids := _update_radar_markers_from_echoes(radar.get_echoes())
	
	if not enable_radar_locking or camera == null:
		radar_locked = null
		radar_candidate = null
		radar_timer = 0.0
		return live_ids
	
	var cam_dir: Vector3 = -camera.global_transform.basis.z
	var best: TargetMarker = null
	var best_angle: float = INF
	for id in live_ids:
		var m: TargetMarker = _markers.get(id, null)
		if m == null:
			continue
		var dir: Vector3 = (m.global_position - camera.global_position).normalized()
		var ang: float = acos(clamp(cam_dir.dot(dir), -1.0, 1.0))
		if ang < best_angle:
			best_angle = ang
			best = m
	
	if best == radar_candidate:
		radar_timer += delta
		if radar_timer >= lock_time_sec:
			radar_locked = radar_candidate
	else:
		radar_candidate = best
		radar_timer = 0.0
		radar_locked = null
	
	if radar_locked != null:
		radar_locked.set_locked()
	
	return live_ids


func _update_radar_markers_from_echoes(echoes: Array[Echo]) -> Array[int]:
	var live_ids: Array[int] = []
	for echo in echoes:
		var id: int = echo.get_instance_id()
		live_ids.append(id)
		var marker: TargetMarker = _get_or_create_marker(id)
		if marker != null:
			var dir_local: Vector3 = Vector3(
				sin(echo.azimuth_rad) * cos(echo.elevation_rad),
				sin(echo.elevation_rad),
				-cos(echo.azimuth_rad) * cos(echo.elevation_rad))
			var dir_world: Vector3 = radar.global_transform.basis * dir_local
			marker.global_position = radar.global_position + dir_world * echo.distance
			marker.set_distance(echo.distance)
			marker.radar()
			marker.clear()
			marker.add_to_group("radar_echoes")
	return live_ids


func _update_heat_markers(sources: Array[HeatSource]) -> Array[int]:
	var live_ids: Array[int] = []
	for hs in sources:
		if not is_instance_valid(hs):
			continue
		var id: int = hs.get_instance_id()
		live_ids.append(id)
		var marker: TargetMarker = _get_or_create_marker(id)
		if marker != null:
			marker.global_position = hs.global_position
			marker.heat()
			marker.clear()
	if heat_locked != null and is_instance_valid(heat_locked):
		var id: int = heat_locked.get_instance_id()
		var marker: TargetMarker = _get_or_create_marker(id)
		if marker != null:
			marker.global_position = heat_locked.global_position
			marker.heat()
			marker.set_locked()
		if id not in live_ids:
			live_ids.append(id)
	return live_ids


func _get_or_create_marker(id: int) -> TargetMarker:
	var marker: TargetMarker = _markers.get(id, null)
	if marker == null and marker_scene != null:
		marker = marker_scene.instantiate() as TargetMarker
		if marker != null:
			add_child(marker)
			_markers[id] = marker
	return marker


func _mark_unused(live_ids: Array[int]) -> void:
	for id in _markers.keys():
		if id not in live_ids:
			if is_instance_valid(_markers[id]):
				_markers[id].queue_free()
			_markers.erase(id)


func _purge_unused_markers() -> void:
	for id in _markers.keys():
		if not is_instance_valid(_markers[id]):
			_markers.erase(id)


func _clear_all_markers() -> void:
	for marker in _markers.values():
		if is_instance_valid(marker):
			marker.queue_free()
	_markers.clear()


func _update_sound_state() -> void:
	if not play_sounds:
		if locking_sound: locking_sound.stop()
		if locked_sound: locked_sound.stop()
		return
	
	var playing_locking := false
	var playing_locked := false
	
	if enable_heat_locking and seeker != null:
		var seeker_sources: Array[HeatSource] = seeker.get_visible_sources()
		if heat_locked != null:
			playing_locked = true
		elif seeker_sources.size() == 1 and heat_candidate != null:
			playing_locking = true
	
	if enable_radar_locking:
		if radar_locked != null:
			playing_locked = true
		elif radar_candidate != null:
			playing_locking = true
	
	if playing_locked:
		if locking_sound: locking_sound.stop()
		if locked_sound and not locked_sound.playing:
			locked_sound.play()
	elif playing_locking:
		if locked_sound: locked_sound.stop()
		if locking_sound and not locking_sound.playing:
			locking_sound.play()
	else:
		if locking_sound: locking_sound.stop()
		if locked_sound: locked_sound.stop()


func _rotate_seeker_to_best_target() -> void:
	if camera == null or seeker == null or seeker_bg == null:
		return
	
	var camera_forward: Vector3 = -camera.global_transform.basis.z
	var camera_position: Vector3 = camera.global_transform.origin
	var best_dot: float = -1.0
	var best_target: Node3D = null
	
	for target in seeker_bg.get_visible_sources():
		if not target is Node3D:
			continue
		var to_target: Vector3 = (target.global_transform.origin - camera_position).normalized()
		var dot: float = camera_forward.dot(to_target)
		if dot > best_dot:
			best_dot = dot
			best_target = target
	
	if best_target:
		var seeker_transform: Transform3D = seeker.global_transform
		seeker_transform.basis = Basis().looking_at(
			best_target.global_transform.origin - seeker.global_transform.origin,
			Vector3.UP)
		seeker.global_transform = seeker_transform


func get_heat_target() -> HeatSource:
	return heat_locked


func get_radar_target() -> TargetMarker:
	return radar_locked
