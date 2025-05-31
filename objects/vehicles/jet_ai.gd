class_name JetAI extends Node

@export var desired_range: float = 1000.0
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
@export var target_group: String = "player"
@export var anchor_group: String = "anchors"
@export var is_hostile: bool = true
@export var is_expert: bool = false
@export var max_pursuit_time: float = 15.0

@onready var ray: RayCast3D = $RayCast3D

var vehicle: Jet
var target: Node3D
var anchor: Node3D
var pursuit_timer: float = 0.0
var missile_fired_recently: bool = false


func _ready() -> void:
	vehicle = get_parent() as Jet
	if missile_launcher == null and has_node("MissileLauncher"):
		missile_launcher = $MissileLauncher
	ray.target_position = Vector3.FORWARD * ray_length
	var group: String = "targets" if is_hostile else "ally"
	vehicle.add_to_group(group)
	var health: Health = vehicle.get_node("Health") as Health
	health.died.connect(_on_vehicle_died)
	randomize()


func _on_vehicle_died() -> void:
	vehicle.queue_free()


func find_nearest(g: String) -> Node3D:
	var best: Node3D
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group(g):
		if n is Node3D and n != vehicle:
			var d: float = (n.global_transform.origin - vehicle.global_transform.origin).length()
			if d < best_d:
				best_d = d
				best = n
	return best


func move_towards(p: Vector3) -> void:
	var dir: Vector3 = (p - vehicle.global_transform.origin).normalized()
	var local: Vector3 = vehicle.global_transform.basis.inverse() * dir
	vehicle.roll_input  = clamp(-local.x * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = clamp(local.y  * pitch_gain, -1.0, 1.0)
	vehicle.yaw_input   = 0.0


func move_away(p: Vector3) -> void:
	var dir: Vector3 = (vehicle.global_transform.origin - p).normalized()
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


func beam_evade(m: Node3D) -> void:
	var dir: Vector3 = (m.global_transform.origin - vehicle.global_transform.origin).normalized()
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
	var best: Node3D
	var best_d: float = missile_evade_distance
	for m in get_tree().get_nodes_in_group("missiles"):
		if m.get("target") == vehicle:
			var d: float = (m.global_transform.origin - vehicle.global_transform.origin).length()
			if d < best_d:
				best_d = d
				best = m
	if best:
		if is_expert:
			beam_evade(best)
		else:
			move_away(best.global_transform.origin)
			vehicle.throttle_input = 1.0
		return true
	return false


func try_fire() -> void:
	if missile_launcher == null or target == null:
		return
	var to_t: Vector3 = target.global_transform.origin - vehicle.global_transform.origin
	if to_t.length() > fire_range:
		return
	var angle: float = rad_to_deg(acos(clamp((-vehicle.transform.basis.z).normalized().dot(to_t.normalized()), -1.0, 1.0)))
	if angle <= fire_cone_deg:
		missile_launcher.target = target
		missile_launcher.launch_missile()
		pursuit_timer = 0.0
		missile_fired_recently = true


func act_on_point(p: Vector3) -> void:
	var d: float = (p - vehicle.global_transform.origin).length()
	if d > desired_range + range_tolerance:
		move_towards(p)
		vehicle.throttle_input = 1.0
	elif d < desired_range - range_tolerance:
		move_away(p)
		vehicle.throttle_input = 0.3
	else:
		move_towards(p)
		vehicle.throttle_input = 0.6


func collect_inputs(_delta: float) -> void:
	if vehicle == null:
		return

	pursuit_timer += _delta
	if target and pursuit_timer > max_pursuit_time and not missile_fired_recently:
		var prev_target := target
		var candidates := []
		for candidate in get_tree().get_nodes_in_group(target_group):
			if candidate != vehicle and candidate != prev_target and candidate is Node3D:
				candidates.append(candidate)
		if candidates.size() > 0:
			target = candidates[randi() % candidates.size()]
			pursuit_timer = 0.0
	missile_fired_recently = false

	if target == null or not is_instance_valid(target):
		target = find_nearest(target_group)
	if target == null or not is_instance_valid(target):
		anchor = find_nearest(anchor_group)
	else:
		anchor = null

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

	if target != null:
		act_on_point(target.global_transform.origin)
		try_fire()
	elif anchor != null:
		act_on_point(anchor.global_transform.origin)
	else:
		vehicle.roll_input = 0.0
		vehicle.pitch_input = 0.0
		vehicle.yaw_input = 0.0
		vehicle.throttle_input = 0.0
