class_name HeatSeekUtils extends Node


static func best_heat_source(
	context: Node,
	origin: Vector3,
	forward: Vector3,
	fov_deg: float,
	heat_sensitivity: float) -> HeatSource:
	
	var cos_limit: float = cos(deg_to_rad(fov_deg))
	var best: HeatSource = null
	var best_heat: float = 0.0
	
	for hs in context.get_tree().get_nodes_in_group("heat_sources"):
		if not hs is HeatSource:
			continue
		var h := hs as HeatSource
		var dir: Vector3 = (h.global_position - origin).normalized()
		if forward.dot(dir) < cos_limit:
			continue
		var heat: float = h.get_magnitude_at(context as Node3D)
		if heat >= heat_sensitivity and heat > best_heat:
			best = h
			best_heat = heat
	
	return best
