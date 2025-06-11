class_name Radar
extends Node3D

@export var beam: RadarBeam
@export var bars: int = 4
@export var vertical_overlap: float = 0.1
@export var horizontal_overlap: float = 0.1
@export var sweep_width_deg: float = 60.0
@export var sweep_rate_deg: float = 60.0
@export var center_pitch_deg: float = 0.0

var bar_spacing_deg: float
var horizontal_step_rad: float
var base_pitch_rad: float
var azimuth_rad: float = 0.0
var azimuth_direction: int = 1
var current_bar: int = 0
var half_sweep_rad: float
var last_scan_azimuth: float = INF
var last_scan_bar: int = -1

var _echo_grid: Array = []

var tracking: bool = false
var tracked_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	var beam_width_deg: float = beam.beam_half_angle_deg * 2.0
	bar_spacing_deg = beam_width_deg * (1.0 - vertical_overlap)
	horizontal_step_rad = deg_to_rad(beam_width_deg * (1.0 - horizontal_overlap))
	base_pitch_rad = deg_to_rad(center_pitch_deg)
	half_sweep_rad = deg_to_rad(sweep_width_deg) * 0.5
	_echo_grid.resize(bars)
	for i in range(bars):
		_echo_grid[i] = []

func _physics_process(delta: float) -> void:
	if tracking:
		_track_position()
	else:
		_sweep_search(delta)

func _sweep_search(delta: float) -> void:
	azimuth_rad += azimuth_direction * deg_to_rad(sweep_rate_deg) * delta
	if abs(azimuth_rad) >= half_sweep_rad:
		azimuth_rad = sign(azimuth_rad) * half_sweep_rad
		azimuth_direction *= -1
		current_bar = (current_bar + 1) % bars
	var pitch_rad: float = base_pitch_rad + deg_to_rad(bar_spacing_deg) * current_bar
	beam.rotation = Vector3(pitch_rad, azimuth_rad, 0.0)
	var scan_needed: bool = false
	if current_bar != last_scan_bar:
		scan_needed = true
	elif abs(azimuth_rad - last_scan_azimuth) >= horizontal_step_rad:
		scan_needed = true
	if scan_needed:
		_perform_scan()

func _track_position() -> void:
	var local_pos: Vector3 = to_local(tracked_position)
	var dir: Vector3 = local_pos.normalized()
	var pitch_rad: float = asin(-dir.y)
	var yaw_rad: float = atan2(dir.x, -dir.z)
	beam.rotation = Vector3(pitch_rad, yaw_rad, 0.0)
	_perform_scan()

func _perform_scan() -> void:
	beam.scan()
	var new_echoes: Array = beam.get_echoes()
	var bar_index: int = current_bar
	var azimuth_deg: float = rad_to_deg(azimuth_rad) + sweep_width_deg * 0.5
	var az_index: int = int(round(azimuth_deg))
	var bar_echoes: Array = _echo_grid[bar_index]
	if bar_echoes.size() <= az_index:
		bar_echoes.resize(az_index + 1)
	bar_echoes[az_index] = null
	if new_echoes.size() > 0:
		var e: RadarEcho = new_echoes[0]
		var fwd: Vector3 = -beam.global_transform.basis.z
		var origin: Vector3 = beam.global_position
		var rng: float = (e.range_bin + 0.5) * beam.range_bin_size
		e.world_position = origin + fwd * rng
		bar_echoes[az_index] = e
	_echo_grid[bar_index] = bar_echoes
	last_scan_azimuth = azimuth_rad
	last_scan_bar = current_bar


func get_echoes() -> Array:
	var result: Array = []
	for bar_echoes in _echo_grid:
		for echo in bar_echoes:
			if echo != null:
				result.append(echo)
	return result

func get_targets() -> Array[RadarTarget]:
	return beam.get_targets()

func get_target_for_echo(echo: RadarEcho) -> RadarTarget:
	return beam.get_target_for_echo(echo)

func start_tracking_position(pos: Vector3) -> void:
	tracking = true
	tracked_position = pos

func stop_tracking() -> void:
	tracking = false
