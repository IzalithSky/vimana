class_name MissileHeatSeeker extends Missile


@export var target: Node3D
@export var max_turn_rate_deg: float = 90.0
@export var turn_fule_burn_rate: float = 4.0
@export var tracking_fov_deg: float = 60.0
@export var tracking_grace_time: float = 0.3

var _target_lost_time: float = 0.0


func _custom_physics(delta: float) -> void:
	if target != null:
		if not is_instance_valid(target):
			target = null
		elif _is_target_in_fov():
			_target_lost_time = 0.0
		else:
			_target_lost_time += delta
			if _target_lost_time >= tracking_grace_time:
				target = null
	
	if target != null and fuel > 0.0:
		var to: Vector3 = target.global_transform.origin - global_transform.origin
		var tv: Vector3 = target.linear_velocity if target is RigidBody3D else Vector3.ZERO
		var spd: float = max(linear_velocity.length(), 0.1)
		var ttr: float = to.length() / spd
		var pred: Vector3 = target.global_transform.origin + tv * ttr
		var des: Vector3 = (pred - global_transform.origin).normalized()
		var cur: Vector3 = -global_transform.basis.z
		var ang: float = cur.angle_to(des)
		if ang > 0.001:
			var ax: Vector3 = cur.cross(des)
			if ax.length_squared() > 1e-5:
				ax = ax.normalized()
				var max_turn: float = deg_to_rad(max_turn_rate_deg) * delta
				var turn_angle: float = min(ang, max_turn)
				apply_torque(ax * torque_strength * turn_angle / delta)
				fuel -= turn_fule_burn_rate * (turn_angle / max_turn) * delta
	
	if target != null and global_transform.origin.distance_to(target.global_transform.origin) < proximity_radius:
		_spawn_explosion()
		queue_free()


func _is_target_in_fov() -> bool:
	var fwd: Vector3 = -global_transform.basis.z
	var dir: Vector3 = (target.global_transform.origin - global_transform.origin).normalized()
	var dot: float = fwd.dot(dir)
	var limit: float = cos(deg_to_rad(tracking_fov_deg))
	return dot >= limit
