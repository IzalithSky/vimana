class_name MissileHeatSeeker extends Missile


@export var max_turn_rate_deg: float = 90.0
@export var turn_fule_burn_rate: float = 4.0
@export var tracking_fov_deg: float = 60.0
@export var heat_sensitivity: float = 1e-8
@export var proximity_fuse_delay: float = 0.5

var target: HeatSource = null
var last_known_position: Vector3 = Vector3.ZERO
var last_target_position: Vector3 = Vector3.ZERO
var lifetime: float = 0.0


func _custom_physics(delta: float) -> void:
	lifetime += delta
	if lifetime < proximity_fuse_delay:
		return
	
	var new_target: HeatSource = HeatSeekUtils.best_heat_source(
		self, global_position, -global_transform.basis.z,
		tracking_fov_deg, heat_sensitivity)
	
	if new_target != target:
		target = new_target
		if target != null:
			last_target_position = target.global_position

	if target != null:
		var target_velocity: Vector3 = (target.global_position - last_target_position) / delta
		last_target_position = target.global_position
		last_known_position = target.global_transform.origin
	
	var steer_target: Vector3 = target.global_transform.origin if target != null else last_known_position
	
	if fuel > 0.0 and steer_target != Vector3.ZERO:
		var target_velocity: Vector3 = (steer_target - last_known_position) / delta
		var to_target: Vector3 = steer_target - global_transform.origin
		var speed: float = max(linear_velocity.length(), 0.1)
		var time_to_reach: float = to_target.length() / speed
		var predicted_pos: Vector3 = steer_target + target_velocity * time_to_reach
		var desired_dir: Vector3 = (predicted_pos - global_transform.origin).normalized()
		var current_dir: Vector3 = -global_transform.basis.z
		var angle: float = current_dir.angle_to(desired_dir)
		if angle > 0.001:
			var axis: Vector3 = current_dir.cross(desired_dir)
			if axis.length_squared() > 1e-5:
				axis = axis.normalized()
				var max_turn: float = deg_to_rad(max_turn_rate_deg) * delta
				var turn_angle: float = min(angle, max_turn)
				apply_torque(axis * torque_strength * turn_angle / delta)
				fuel -= turn_fule_burn_rate * (turn_angle / max_turn) * delta
	
	if target != null and global_transform.origin.distance_to(target.global_transform.origin) < proximity_radius:
		_die()
