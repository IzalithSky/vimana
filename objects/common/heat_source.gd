class_name HeatSource extends Node3D


@export var magnitude: float = 100.0
@export var multiplier: float = 1.0
@export var use_aspect: bool = true


func _ready() -> void:
	add_to_group("heat_sources")


func get_magnitude_at(sensor: Node3D) -> float:
	var distance: float = global_position.distance_to(sensor.global_position)
	var base: float = multiplier * magnitude / pow(distance, 2)
	if not use_aspect:
		return base
	
	var to_sensor: Vector3 = (sensor.global_position - global_position).normalized()
	var rear_dir: Vector3 = global_transform.basis.z
	var dot: float = (1 + rear_dir.dot(to_sensor)) / 2
	
	return base * dot
