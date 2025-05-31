class_name MissileHeatSeeker extends Missile


@export var max_turn_rate_deg: float = 90.0
@export var turn_fule_burn_rate: float = 4.0
@export var tracking_fov_deg: float = 60.0
@export var heat_sensitivity: float = 1e-8
@export var proximity_fuse_delay: float = 0.8

var target: HeatSource
var last_known_position: Vector3
var lifetime: float = 0.0


func _custom_physics(delta: float) -> void:
	lifetime += delta
	if lifetime < proximity_fuse_delay:
		return
	
	target = HeatSeekUtils.best_heat_source(
		self, global_position, -global_transform.basis.z,
		tracking_fov_deg, heat_sensitivity)
	
	if target != null:
		last_known_position = target.global_transform.origin
	
	var steer_target: Vector3 = target.global_transform.origin if target != null else last_known_position
	
	if fuel > 0.0 and steer_target != Vector3.ZERO:
		var des: Vector3 = (steer_target - global_transform.origin).normalized()
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
