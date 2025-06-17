class_name LvD extends Heli


var camera: Node3D


func on_ready_enabled() -> void:
	if rig is PlayerControls:
		camera = rig.camera


func apply_throttle(throttle_value: float, delta: float) -> void:
	var cost: float = 0.0
	if abs(throttle_value) > 0.0:
		cost = throttle_value * throttle_energy_rate * delta
		if energy_pool != null and not energy_pool.consume(cost):
			return
	var forward_force: Vector3
	if Input.is_action_pressed("pitch_up"):
		forward_force = camera.global_transform.basis.y * throttle_value * thrust_power
	else:
		forward_force = -camera.global_transform.basis.z * throttle_value * thrust_power
	apply_central_force(forward_force)


func apply_directional_alignment() -> void:
	var velocity: Vector3 = linear_velocity
	if velocity.length() < 0.001:
		return
	var forward: Vector3 = -transform.basis.z
	var vel_dir: Vector3 = velocity.normalized()
	var axis: Vector3 = forward.cross(vel_dir)
	var angle: float = forward.angle_to(vel_dir)
	if angle > 0.01:
		var torque: Vector3 = axis.normalized() * angle * alignment_strength * velocity.length()
		apply_torque(torque)
