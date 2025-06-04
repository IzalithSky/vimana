class_name MissileHeatSeeker extends Missile


@export var max_turn_rate_deg: float = 90.0
@export var turn_fule_burn_rate: float = 4.0
@export var tracking_fov_deg: float = 60.0
@export var proximity_fuse_delay: float = 0.5
@export var slowdown_distance: float = 100.0
@export var slowdown_factor: float = 0.5
@export var seeker: HeatSeeker

var lifetime: float = 0.0
var original_thrust: float = 0.0
var locked_pos: Vector3
var last_target_position: Vector3


func _ready() -> void:
	super._ready()
	
	locked_pos = global_position
	last_target_position = global_position
	
	original_thrust = thrust


func _custom_physics(delta: float) -> void:
	lifetime += delta
	
	point_seeker_at(locked_pos)
	
	var t: HeatSource = seeker.get_best_target()
	if t != null:
		locked_pos = t.global_position
		point_seeker_at(locked_pos)
	else:
		return
	
	if lifetime < proximity_fuse_delay:
		return
	
	var dist: float = global_position.distance_to(locked_pos)
	var thrust_scale: float = clamp(dist / slowdown_distance, slowdown_factor, 1.0)
	thrust = original_thrust * thrust_scale
	
	var target_velocity: Vector3 = (locked_pos - last_target_position) / delta
	last_target_position = locked_pos
	
	var speed: float = max(linear_velocity.length(), 0.1)
	var desired_dir: Vector3 = _intercept_dir(global_transform.origin, speed, locked_pos, target_velocity)
	var current_dir: Vector3 = -global_transform.basis.z
	var angle: float = current_dir.angle_to(desired_dir)
	
	if angle > 1e-3:
		var axis: Vector3 = current_dir.cross(desired_dir)
		if axis.length_squared() > 1e-5:
			axis = axis.normalized()
			var max_turn: float = deg_to_rad(max_turn_rate_deg) * delta
			var turn_angle: float = min(angle, max_turn)
			apply_torque(axis * torque_strength * turn_angle / delta)
			fuel -= turn_fule_burn_rate * (turn_angle / max_turn) * delta
	
	if global_transform.origin.distance_to(locked_pos) < proximity_radius:
		_spawn_explosion()
		_die()


func _intercept_dir(m_pos: Vector3, m_speed: float, t_pos: Vector3, t_vel: Vector3) -> Vector3:
	var rel: Vector3 = t_pos - m_pos
	var a: float = t_vel.length_squared() - m_speed * m_speed
	var b: float = 2.0 * rel.dot(t_vel)
	var c: float = rel.length_squared()
	var t: float
	if abs(a) < 1e-3:
		t = c / max(b, 1e-3)
	else:
		var disc: float = b * b - 4.0 * a * c
		t = (-b + sqrt(max(disc, 0.0))) / (2.0 * a)
	t = max(t, 0.0)
	var intercept: Vector3 = t_pos + t_vel * t
	return (intercept - m_pos).normalized()


func point_seeker_at(target: Vector3) -> void:
	if seeker == null:
		return
	
	var to_target: Vector3 = (target - seeker.global_position).normalized()
	var missile_forward: Vector3 = -global_transform.basis.z
	var angle_to_target: float = missile_forward.angle_to(to_target)
	
	var max_angle_rad: float = deg_to_rad(tracking_fov_deg)
	
	var final_dir: Vector3 = to_target
	if angle_to_target > max_angle_rad:
		var axis: Vector3 = missile_forward.cross(to_target).normalized()
		final_dir = missile_forward.rotated(axis, max_angle_rad).normalized()
	
	var new_basis: Basis = Basis().looking_at(final_dir, Vector3.UP)
	seeker.global_transform = Transform3D(new_basis, seeker.global_position)


func lock_target(t: HeatSource) -> void:
	locked_pos = t.global_position
	point_seeker_at(locked_pos)
	last_target_position = locked_pos
