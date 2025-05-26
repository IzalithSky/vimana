class_name JetAI extends Node


@export var desired_range: float = 800.0
@export var range_tolerance: float = 100.0
@export var max_bank_deg: float = 60.0
@export var roll_gain: float = 2.0
@export var pitch_gain: float = 1.2
@export var avoid_pitch_gain: float = 1.0
@export var avoid_roll_gain: float = 1.0
@export var ray_length: float = 200.0
@export var missile_evade_distance: float = 600.0
@export var missile_beam_bank_deg: float = 60.0
@export var missile_pitch_input: float = 1.0
@export var missile_throttle: float = 1.0
@export var fire_cone_deg: float = 15.0
@export var fire_range: float = 1000.0
@export var missile_launcher: MissileLauncher

@onready var ray: RayCast3D = $RayCast3D

var vehicle: Jet
var player: Node3D


func _ready() -> void:
	vehicle = get_parent() as Jet
	if missile_launcher == null and has_node("MissileLauncher"):
		missile_launcher = $MissileLauncher
	ray.target_position = Vector3.FORWARD * ray_length
	vehicle.add_to_group("targets")


func move_towards(target: Vector3) -> void:
	var dir: Vector3 = (target - vehicle.global_transform.origin).normalized()
	var local: Vector3 = vehicle.global_transform.basis.inverse() * dir
	vehicle.roll_input  = clamp(-local.x * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = clamp(local.y  * pitch_gain, -1.0, 1.0)
	vehicle.yaw_input   = 0.0


func move_away(target: Vector3) -> void:
	var dir: Vector3 = (vehicle.global_transform.origin - target).normalized()
	var local: Vector3 = vehicle.global_transform.basis.inverse() * dir
	vehicle.roll_input  = clamp(-local.x * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = clamp(local.y  * pitch_gain, -1.0, 1.0)
	vehicle.yaw_input   = 0.0


func recover_from_stall() -> void:
	var vel: Vector3 = vehicle.linear_velocity
	if vel.length() < 0.1:
		return
	var local: Vector3 = vehicle.global_transform.basis.inverse() * vel.normalized()
	vehicle.roll_input  = clamp(local.x * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = clamp(local.y * pitch_gain, -1.0, 1.0)
	vehicle.yaw_input   = 0.0
	vehicle.throttle_input = 1.0


func avoid_obstacle() -> bool:
	ray.global_transform = vehicle.global_transform
	ray.force_raycast_update()
	if ray.is_colliding():
		move_away(ray.get_collision_point())
		vehicle.throttle_input = 1.0
		return true
	return false


func beam_evade(missile: Node3D) -> void:
	var dir: Vector3 = (missile.global_transform.origin - vehicle.global_transform.origin).normalized()
	var local: Vector3 = vehicle.global_transform.basis.inverse() * dir
	var bank_sign: float = -sign(local.x)
	var desired_bank_deg: float = bank_sign * missile_beam_bank_deg
	var current_bank_deg: float = rad_to_deg(asin(clamp(vehicle.transform.basis.x.dot(Vector3.UP), -1.0, 1.0)))
	var roll_error_deg: float = desired_bank_deg - current_bank_deg
	vehicle.roll_input  = clamp(roll_error_deg / missile_beam_bank_deg * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = missile_pitch_input
	vehicle.yaw_input   = 0.0
	vehicle.throttle_input = missile_throttle


func evade_missile() -> bool:
	var missiles: Array = get_tree().get_nodes_in_group("missiles")
	var threat: Node3D
	var threat_dist: float = missile_evade_distance
	for m in missiles:
		if m.get("target") == vehicle:
			var d: float = (m.global_transform.origin - vehicle.global_transform.origin).length()
			if d < threat_dist:
				threat_dist = d
				threat = m
	if threat:
		beam_evade(threat)
		return true
	return false


func try_fire() -> void:
	if missile_launcher == null or player == null:
		return
	var to_player: Vector3 = player.global_transform.origin - vehicle.global_transform.origin
	if to_player.length() > fire_range:
		return
	var forward: Vector3 = -vehicle.transform.basis.z
	var angle_deg: float = rad_to_deg(acos(clamp(forward.normalized().dot(to_player.normalized()), -1.0, 1.0)))
	if angle_deg <= fire_cone_deg:
		missile_launcher.target = player
		missile_launcher.launch_missile()


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
	
	if not vehicle.lift_ok:
		recover_from_stall()
		try_fire()
		return
	
	if avoid_obstacle():
		try_fire()
		return
	if evade_missile():
		try_fire()
		return
	
	var to_player: Vector3 = player.global_transform.origin - vehicle.global_transform.origin
	var dist: float = to_player.length()
	if dist > desired_range + range_tolerance:
		move_towards(player.global_transform.origin)
		vehicle.throttle_input = 1.0
	elif dist < desired_range - range_tolerance:
		move_away(player.global_transform.origin)
		vehicle.throttle_input = 0.3
	else:
		move_towards(player.global_transform.origin)
		vehicle.throttle_input = 0.6
	
	try_fire()
