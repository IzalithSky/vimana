class_name HeatSeeker extends Node3D


@export var tracking_fov_deg: float = 10.0
@export var heat_sensitivity: float = 5
@export var ignored_targets: Array[NodePath] = []

var sens: float
var _debug_ray: RayCast3D


func _ready() -> void:
	sens = pow(10, -1 * heat_sensitivity)
	
	_debug_ray = RayCast3D.new()
	_debug_ray.position = Vector3(0, 0, -1)
	_debug_ray.target_position = Vector3(0, 0, -1000.0)
	_debug_ray.collision_mask = 0
	_debug_ray.collide_with_areas = false
	_debug_ray.collide_with_bodies = false
	_debug_ray.debug_shape_custom_color = Color.ORANGE
	add_child(_debug_ray)


func get_best_target() -> HeatSource:
	var best: HeatSource = null
	var best_heat: float = sens
	for hs in get_tree().get_nodes_in_group("heat_sources"):
		if not (hs is HeatSource and is_instance_valid(hs)):
			continue
		if _is_ignored(hs):
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
		if _is_ignored(hs):
			continue
		var dir: Vector3 = (hs.global_position - global_position).normalized()
		var forward: Vector3 = -global_transform.basis.z
		if forward.dot(dir) >= cos(deg_to_rad(tracking_fov_deg)):
			if hs.get_magnitude_at(self) >= sens:
				result.append(hs)
	return result


func _is_ignored(target: Node) -> bool:
	return target.get_path() in ignored_targets
