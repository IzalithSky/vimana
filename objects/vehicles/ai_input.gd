class_name JetAI extends Node


@export var desired_range: float = 800.0
@export var range_tolerance: float = 100.0
@export var max_bank_deg: float = 60.0
@export var roll_gain: float = 2.0
@export var pitch_gain: float = 1.2
@export var avoid_pitch: float = 0.6
@export var avoid_roll: float = 0.7
@export var ray_length: float = 200.0

@onready var ray: RayCast3D = $RayCast3D

var vehicle: Jet
var player: Node3D


func _ready() -> void:
	vehicle = get_parent() as Jet
	ray.target_position = Vector3.FORWARD * ray_length
	add_to_group("targets")


func collect_inputs(delta: float) -> void:
	if vehicle == null:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		vehicle.roll_input = 0.0
		vehicle.pitch_input = 0.0
		vehicle.yaw_input = 0.0
		vehicle.throttle_input = 0.0
		return

	var to_player: Vector3 = player.global_transform.origin - vehicle.global_transform.origin
	var dist: float = to_player.length()
	var dir: Vector3 = to_player.normalized()

	var local_dir: Vector3 = vehicle.global_transform.basis.inverse() * dir

	vehicle.roll_input  = clamp(-local_dir.x * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = clamp(local_dir.y * pitch_gain,  -1.0, 1.0)
	vehicle.yaw_input   = 0.0

	if dist > desired_range + range_tolerance:
		vehicle.throttle_input = 1.0
	elif dist < desired_range - range_tolerance:
		vehicle.throttle_input = -0.5
	else:
		vehicle.throttle_input = 0.0

	ray.global_transform = vehicle.global_transform
	ray.force_raycast_update()
	if ray.is_colliding():
		vehicle.pitch_input = clamp(vehicle.pitch_input + avoid_pitch, -1.0, 1.0)
		vehicle.roll_input  = clamp(vehicle.roll_input  + avoid_roll * sign(randf() - 0.5), -1.0, 1.0)
