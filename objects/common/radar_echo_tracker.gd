class_name RadarEchoTracker
extends Node3D

@export var radar: Radar
@export var marker_scene: PackedScene
@export var show_markers: bool = true
@export var min_draw_distance: float = 640.0

var _markers: Dictionary[int, Node3D] = {}
var _marker_expiry: Dictionary[int, float] = {}

func _process(delta: float) -> void:
	if radar == null or not show_markers:
		_clear_all_markers()
		return
	var now := Time.get_ticks_msec() / 1000.0
	var echoes: Array[RadarEcho] = radar.get_echoes()
	_update_markers(echoes, now)
	_expire_old_markers(now)

func _update_markers(echoes: Array[RadarEcho], now: float) -> void:
	var beam := radar.beam
	var range_step := beam.range_bin_size
	var speed_step := beam.radial_velocity_bin_size
	var origin := beam.global_position
	var forward := -beam.global_transform.basis.z

	var sweep_angle_deg := radar.sweep_width_deg
	var sweep_rate_deg := radar.sweep_rate_deg
	var total_bars := radar.bars
	var sweep_time := (sweep_angle_deg * 2.0 / sweep_rate_deg) * total_bars

	for echo in echoes:
		var range := (echo.range_bin + 0.5) * range_step
		if range < min_draw_distance:
			continue
		var velocity := (echo.radial_velocity_bin + 0.5) * speed_step
		var id := hash((echo.range_bin << 8) | int(echo.radial_velocity_bin))
		if not _markers.has(id) and marker_scene:
			var marker := marker_scene.instantiate() as Node3D
			add_child(marker)
			_markers[id] = marker
		if _markers.has(id):
			var marker := _markers[id]
			marker.global_position = origin + forward * range
			var label := marker.get_node("Label3D") as Label3D
			label.text = "D: %.0f\nV: %.1f" % [range, velocity]
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
