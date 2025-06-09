class_name Radar extends Node3D


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
var azimuth_dir: int = 1
var current_bar: int = 0
var half_sweep_rad: float
var last_scan_azimuth: float = INF
var last_scan_bar: int = -1


func _ready() -> void:
	var full_bw_deg := beam.beam_half_angle_deg * 2.0
	bar_spacing_deg = full_bw_deg * (1.0 - vertical_overlap)
	horizontal_step_rad = deg_to_rad(full_bw_deg * (1.0 - horizontal_overlap))
	base_pitch_rad = deg_to_rad(center_pitch_deg)
	half_sweep_rad = deg_to_rad(sweep_width_deg) * 0.5


func _physics_process(delta: float) -> void:
	azimuth_rad += azimuth_dir * deg_to_rad(sweep_rate_deg) * delta
	if abs(azimuth_rad) >= half_sweep_rad:
		azimuth_rad = sign(azimuth_rad) * half_sweep_rad
		azimuth_dir *= -1
		current_bar = (current_bar + 1) % bars
	
	var pitch_rad := base_pitch_rad + deg_to_rad(bar_spacing_deg) * current_bar
	beam.rotation = Vector3(pitch_rad, azimuth_rad, 0.0)
	var need_scan := false
	if current_bar != last_scan_bar:
		need_scan = true
	elif abs(azimuth_rad - last_scan_azimuth) >= horizontal_step_rad:
		need_scan = true
	
	if need_scan:
		_perform_scan()


func _perform_scan() -> void:
	beam.scan()
	last_scan_azimuth = azimuth_rad
	last_scan_bar = current_bar


func get_echoes() -> Array[RadarEcho]:
	return beam.get_echoes()


func get_targets() -> Array[RadarTarget]:
	return beam.get_targets()


func get_target_for_echo(echo: RadarEcho) -> RadarTarget:
	return beam.get_target_for_echo(echo)
