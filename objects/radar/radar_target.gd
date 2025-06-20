class_name RadarTarget extends Node3D


@export var rcs: float = 1.0

var velocity: Vector3 = Vector3.ZERO
var _previous_position: Vector3


func _ready() -> void:
	add_to_group("radar_targets")
	_previous_position = global_position


func _physics_process(delta: float) -> void:
	velocity = (global_position - _previous_position) / delta
	_previous_position = global_position


func get_magnitude_at(sensor: Node3D) -> float:
	return rcs / pow(get_distance(sensor), 2)


func get_distance(sensor: Node3D) -> float:
	return global_position.distance_to(sensor.global_position)
