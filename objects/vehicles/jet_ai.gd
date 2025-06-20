class_name JetAI extends Node


@export var desired_range: float = 500.0
@export var range_tolerance: float = 100.0
@export var roll_gain: float = 2.0
@export var pitch_gain: float = 1.2
@export var yaw_gain: float = 1.0
@export var missile_evade_distance: float = 600.0
@export var missile_beam_bank_deg: float = 60.0
@export var missile_pitch_input: float = 1.0
@export var missile_throttle: float = 1.0
@export var fire_cone_deg: float = 30.0
@export var fire_range: float = 1000.0
@export var missile_launcher: MissileLauncher
@export var target_group: String = "alpha"
@export var ally_group: String = "bravo"
@export var anchor_group: String = "anchors"
@export var is_hostile: bool = true
@export var is_expert: bool = false
@export var max_pursuit_time: float = 35.0
@export var obstacle_prediction_horizon: float = 5.0
@export var attack_range: float = 2000.0

@onready var ray: RayCast3D = $RayCast3D

var vehicle: Jet
var target: Node3D
var anchor: Node3D
var pursuit_timer: float = 0.0
var missile_fired_recently: bool = false
var tracker: HeatSeekerTargetTracker


func _ready() -> void:
	vehicle = get_parent() as Jet
	if missile_launcher == null and has_node("MissileLauncher"):
		missile_launcher = $MissileLauncher
		missile_launcher.energy_pool = vehicle.energy_pool
	if tracker == null and vehicle.has_node("HeatSeekerTargetTracker"):
		tracker = vehicle.get_node("HeatSeekerTargetTracker") as HeatSeekerTargetTracker
	
	vehicle.add_to_group(ally_group)
	
	var health: Health = vehicle.get_node("Health") as Health
	health.died.connect(_on_vehicle_died)
	
	randomize()


func _on_vehicle_died(cause: Health.DeathCause) -> void:
	if cause == Health.DeathCause.COLLISION:
		vehicle.queue_free()


func _health_alive(n: Node3D) -> bool:
	var h: Health = n.get_node("Health") as Health
	return h.current_hp > 0.0


func find_nearest(group_name: String) -> Node3D:
	var best: Node3D = null
	var best_d: float = INF
	for n: Node in get_tree().get_nodes_in_group(group_name):
		if n is Node3D and n != vehicle:
			if not _health_alive(n):
				continue
			var d: float = (n as Node3D).global_transform.origin.distance_to(vehicle.global_transform.origin)
			if d < best_d:
				best_d = d
				best = n as Node3D
	return best


func move_towards(p: Vector3) -> void:
	var dir: Vector3 = (p - vehicle.global_transform.origin).normalized()
	var local: Vector3 = vehicle.global_transform.basis.inverse() * dir
	vehicle.roll_input = clamp(-local.x * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = clamp(local.y * pitch_gain, -1.0, 1.0)
	vehicle.yaw_input = clamp(local.x * yaw_gain, -1.0, 1.0)


func move_away(p: Vector3) -> void:
	var dir: Vector3 = (vehicle.global_transform.origin - p).normalized()
	var local: Vector3 = vehicle.global_transform.basis.inverse() * dir
	vehicle.roll_input = clamp(-local.x * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = clamp(local.y * pitch_gain, -1.0, 1.0)
	vehicle.yaw_input = clamp(local.x * yaw_gain, -1.0, 1.0)


func recover_from_stall() -> void:
	var vel: Vector3 = vehicle.linear_velocity
	if vel.length() < 0.1:
		return
	var local: Vector3 = vehicle.global_transform.basis.inverse() * vel.normalized()
	vehicle.roll_input = clamp(local.x * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = clamp(local.y * pitch_gain, -1.0, 1.0)
	vehicle.yaw_input = 0.0
	vehicle.throttle_input = 1.0


func avoid_obstacle() -> bool:
	var velocity: Vector3 = vehicle.linear_velocity
	if velocity.length_squared() < 1e-4:
		return false
	
	var look_dir: Vector3 = velocity.normalized()
	var cast_distance: float = velocity.length() * obstacle_prediction_horizon
	var cast_target: Vector3 = vehicle.global_transform.origin + look_dir * cast_distance
	
	ray.global_position = vehicle.global_transform.origin
	ray.target_position = vehicle.linear_velocity.normalized() * cast_distance
	ray.force_raycast_update()
	
	if ray.is_colliding():
		move_away(ray.get_collision_point())
		vehicle.throttle_input = 0.0
		return true
	return false


func beam_evade(m: Node3D) -> void:
	var dir: Vector3 = (m.global_transform.origin - vehicle.global_transform.origin).normalized()
	var local: Vector3 = vehicle.global_transform.basis.inverse() * dir
	var bank_sign: float = -sign(local.x)
	var desired_bank_deg: float = bank_sign * missile_beam_bank_deg
	var current_bank_deg: float = rad_to_deg(asin(clamp(vehicle.global_transform.basis.x.dot(Vector3.UP), -1.0, 1.0)))
	var roll_error_deg: float = desired_bank_deg - current_bank_deg
	vehicle.roll_input = clamp(roll_error_deg / missile_beam_bank_deg * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = missile_pitch_input
	vehicle.yaw_input = 0.0
	vehicle.throttle_input = missile_throttle


func evade_missile() -> bool:
	var threat: Node3D = null
	var threat_d: float = INF
	var threat_t: float = INF
	
	for n: Node in get_tree().get_nodes_in_group("missiles"):
		if not (n is RigidBody3D):
			continue
		if n.host == vehicle:
			continue
	
		var m: RigidBody3D = n
		
		var rel_pos: Vector3 = m.global_transform.origin - vehicle.global_transform.origin
		var rel_vel: Vector3 = m.linear_velocity - vehicle.linear_velocity
		var vel_sq: float = rel_vel.length_squared()
		if vel_sq < 1e-3:
			continue
		
		var t_ca: float = -rel_pos.dot(rel_vel) / vel_sq
		if t_ca < 0.0 or t_ca > 3.0:
			continue
		
		var closest_vec: Vector3 = rel_pos + rel_vel * t_ca
		var d_ca: float = closest_vec.length()
		
		if d_ca < threat_d:
			threat_d = d_ca
			threat_t = t_ca
			threat = m
	
	if threat != null and threat_d < missile_evade_distance:
		for child in vehicle.get_children():
			if child is FlareLauncher and child.ready_to_fire():
				child.launch_flares()
				return true
		
		if is_expert:
			beam_evade(threat)
		else:
			move_away(threat.global_transform.origin)
			vehicle.throttle_input = 0.0
		return true
	
	return false


func try_fire() -> void:
	if missile_launcher == null or tracker == null:
		return
	
	var heat_target: HeatSource = tracker.get_target()
	if heat_target == null:
		return
	
	var missile: Missile = missile_launcher.launch_missile()
	if missile is MissileHeatSeeker:
		var seeker_missile: MissileHeatSeeker = missile as MissileHeatSeeker
		seeker_missile.lock_target(heat_target)
	
	pursuit_timer = 0.0
	missile_fired_recently = true


func _attack_target() -> void:
	if target == null or not is_instance_valid(target) or not _health_alive(target):
		return
	
	var p: Vector3 = target.global_transform.origin
	var dir: Vector3 = (p - vehicle.global_transform.origin).normalized()
	var local: Vector3 = vehicle.global_transform.basis.inverse() * dir
	vehicle.roll_input = clamp(-local.x * roll_gain, -1.0, 1.0)
	vehicle.pitch_input = clamp(local.y * pitch_gain, -1.0, 1.0)
	vehicle.yaw_input = clamp(local.x * yaw_gain, -1.0, 1.0)
	vehicle.throttle_input = 0.0
	
	if tracker != null:
		var seeker_pos: Vector3 = tracker.global_position
		var to_target: Vector3 = (target.global_position - seeker_pos).normalized()
		var new_basis: Basis = Basis().looking_at(to_target, Vector3.UP)
		var new_transform: Transform3D = Transform3D(new_basis, seeker_pos)
		tracker.global_transform = new_transform
		if missile_launcher != null:
			missile_launcher.global_transform = new_transform
		
	try_fire()


func collect_inputs(delta: float) -> void:
	if vehicle == null:
		return
	pursuit_timer += delta
	if target != null and pursuit_timer > max_pursuit_time and not missile_fired_recently:
		var prev_target: Node3D = target
		var candidates: Array[Node3D] = []
		for c: Node in get_tree().get_nodes_in_group(target_group):
			if c is Node3D and c != vehicle and c != prev_target and _health_alive(c):
				candidates.append(c as Node3D)
		if candidates.size() > 0:
			target = candidates[randi() % candidates.size()]
			pursuit_timer = 0.0
	missile_fired_recently = false
	if target == null or not is_instance_valid(target) or not _health_alive(target):
		target = find_nearest(target_group)
	if target == null:
		anchor = find_nearest(anchor_group)
	else:
		anchor = null
	if not vehicle.lift_ok:
		recover_from_stall()
		return
	if evade_missile():
		try_fire()
		return
	if avoid_obstacle():
		return
	if target != null:
		var d: float = vehicle.global_transform.origin.distance_to(target.global_transform.origin)
		if d <= attack_range:
			_attack_target()
		else:
			act_on_point(target.global_transform.origin)
			try_fire()
	elif anchor != null:
		act_on_point(anchor.global_transform.origin)
	else:
		vehicle.roll_input = 0.0
		vehicle.pitch_input = 0.0
		vehicle.yaw_input = 0.0
		vehicle.throttle_input = 0.0


func act_on_point(p: Vector3) -> void:
	var d: float = vehicle.global_transform.origin.distance_to(p)
	if d > desired_range + range_tolerance:
		move_towards(p)
		vehicle.throttle_input = 1.0
	elif d < desired_range - range_tolerance:
		move_away(p)
		vehicle.throttle_input = -0.5
	else:
		move_towards(p)
		vehicle.throttle_input = 0.0
