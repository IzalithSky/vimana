class_name Echo extends Node3D


var distance:      float
var azimuth_rad:   float
var elevation_rad: float
var radial_speed:  float


func _init(distance: float = 0.0, azimuth_rad: float = 0.0, elevation_rad: float = 0.0, radial_speed: float = 0.0) -> void:
	distance       = distance
	azimuth_rad    = azimuth_rad
	elevation_rad  = elevation_rad
	radial_speed   = radial_speed
