class_name HeatSeeker extends Node3D


@export var tracking_fov_deg: float = 10.0
@export var heat_sensitivity: float = 0.0


func get_best_target() -> HeatSource:
	var best: HeatSource = null
	var best_heat: float = heat_sensitivity
	for hs in get_tree().get_nodes_in_group("heat_sources"):
		if not (hs is HeatSource and is_instance_valid(hs)):
			continue
		var dir: Vector3 = (hs.global_position - global_position).normalized()
		var forward: Vector3 = -global_transform.basis.z
		if forward.dot(dir) >= cos(deg_to_rad(tracking_fov_deg)):
			var heat: float = hs.get_magnitude_at(self)
			if heat >= best_heat:
				best = hs
				best_heat = heat
	return best


func get_visible_sources() -> Array[HeatSource]:
	var result: Array[HeatSource] = []
	for hs in get_tree().get_nodes_in_group("heat_sources"):
		if not (hs is HeatSource and is_instance_valid(hs)):
			continue
		var dir: Vector3 = (hs.global_position - global_position).normalized()
		var forward: Vector3 = -global_transform.basis.z
		if forward.dot(dir) >= cos(deg_to_rad(tracking_fov_deg)):
			if hs.get_magnitude_at(self) >= heat_sensitivity:
				result.append(hs)
	return result
