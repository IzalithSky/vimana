class_name AIInput extends Node


func collect_inputs(delta: float, vehicle: Node) -> void:
	vehicle.roll_input = 0.0
	vehicle.pitch_input = 0.0
	vehicle.yaw_input = 0.0
	vehicle.throttle_input = 0.6
