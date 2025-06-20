class_name EchoSeeker extends Node3D


@export var sensor_fov_degrees: float = 10.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func get_best_target() -> Node3D:
	var fwd: Vector3 = -global_transform.basis.z
	var cos_lim: float = cos(deg_to_rad(sensor_fov_degrees))
	var best: Echo = null
	var best_speed: float = -INF
	rng.randomize()
	for n in get_tree().get_nodes_in_group("radar_echoes"):
		if not (n is Echo):
			continue
		var dir: Vector3 = (n.global_position - global_position).normalized()
		if fwd.dot(dir) < cos_lim:
			continue
		var s: float = n.radial_speed
		if s > best_speed:
			best_speed = s
			best = n
		elif s == best_speed and rng.randi_range(0, 1) == 0:
			best = n
	return best
