class_name MissileSemiActiveRadar extends GuidedMissile


@export var gimbal_fov_degrees: float = 60.0
@export var sensor_fov_degrees: float = 10.0
@export var seeker_node: Node3D


func _update_target(delta: float) -> void:
	var visible_targets: Array[Node3D] = _get_visible_targets()
	var best_target: Node3D = _pick_best_target(visible_targets)

	if best_target != null:
		target = best_target
	else:
		target = null
		_disable_guidance()


func _update_seeker_orientation(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	
	var forward: Vector3 = -global_transform.basis.z
	var desired_direction: Vector3 = (target.global_position - global_position).normalized()
	var angle_to_target: float = forward.angle_to(desired_direction)
	var max_angle: float = deg_to_rad(gimbal_fov_degrees)
	
	var clamped_direction: Vector3 = desired_direction
	if angle_to_target > max_angle:
		var axis: Vector3 = forward.cross(desired_direction).normalized()
		clamped_direction = forward.rotated(axis, max_angle).normalized()
	
	var seeker_basis: Basis = Basis().looking_at(clamped_direction, Vector3.UP)
	seeker_node.global_transform = Transform3D(seeker_basis, global_position)


func _get_visible_targets() -> Array[Node3D]:
	var results: Array[Node3D] = []
	var seeker_forward: Vector3 = -seeker_node.global_transform.basis.z
	var cos_sensor: float = cos(deg_to_rad(sensor_fov_degrees))
	
	for node in get_tree().get_nodes_in_group("radar_echoes"):
		if not is_instance_valid(node):
			continue
		var direction: Vector3 = (node.global_position - global_position).normalized()
		if seeker_forward.dot(direction) >= cos_sensor:
			results.append(node)
	return results


func _pick_best_target(candidates: Array[Node3D]) -> Node3D:
	var best: Node3D = null
	var smallest_angle: float = INF
	var seeker_forward: Vector3 = -seeker_node.global_transform.basis.z
	
	for candidate in candidates:
		var direction: Vector3 = (candidate.global_position - global_position).normalized()
		var angle: float = seeker_forward.angle_to(direction)
		if angle < smallest_angle:
			smallest_angle = angle
			best = candidate
	
	return best


func lock_target(new_target: Node3D) -> void:
	super.lock_target(new_target)
	_update_seeker_orientation(0.0)
