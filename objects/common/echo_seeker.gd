class_name EchoSeeker extends Node3D


@export var sensor_fov_degrees: float = 10.0

var _debug_ray: RayCast3D


func _ready() -> void:
	_debug_ray = RayCast3D.new()
	_debug_ray.position = Vector3(0, 0, -1)
	_debug_ray.target_position = Vector3(0, 0, -1000.0)
	_debug_ray.collision_mask = 0
	_debug_ray.collide_with_areas = false
	_debug_ray.collide_with_bodies = false
	_debug_ray.debug_shape_custom_color = Color.ORANGE
	add_child(_debug_ray)


func get_best_target() -> Node3D:
	var best: Node3D = null
	var smallest_angle: float = INF
	var forward: Vector3 = -global_transform.basis.z
	var cos_limit: float = cos(deg_to_rad(sensor_fov_degrees))
	
	for node in get_tree().get_nodes_in_group("radar_echoes"):
		if not is_instance_valid(node):
			continue
		var dir: Vector3 = (node.global_position - global_position).normalized()
		if forward.dot(dir) >= cos_limit:
			var angle: float = forward.angle_to(dir)
			if angle < smallest_angle:
				smallest_angle = angle
				best = node
	return best
