class_name HeatSource extends Node3D


@export var magnitude: float = 100.0


func _ready() -> void:
	add_to_group("heat_sources")


func get_magnitude_at(sensor: Node3D) -> float:
	return magnitude / pow(global_position.distance_to(sensor.global_position), 2)
