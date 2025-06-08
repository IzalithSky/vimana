class_name RadarTarget extends Node3D


@export var rcs: float = 1.0


func _ready() -> void:
	add_to_group("radar_targets")


func get_magnitude_at(sensor: Node3D) -> float:
	return rcs / pow(get_distance(sensor), 2)


func get_distance(sensor: Node3D) -> float:
	return global_position.distance_to(sensor.global_position)
