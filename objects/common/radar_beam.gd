class_name RadarBeam extends Node3D


@export var beam_half_angle_deg: float = 2.0
@export var sensitivity_db: float = 8.0
@export var range_bin_size: float = 320.0
@export var radial_velocity_bin_size: float = 20.0
@export var maximum_range: float = 40_000.0
@export_flags_3d_physics var terrain_collision_mask: int = 8
@export var raycast_pool_size: int = 16

var sensitivity_threshold: float
var half_angle_rad: float
var visualizer: RayCast3D
var ray_pool: Array[RayCast3D] = []
var current_echoes: Array[RadarEcho] = []
var targets_per_bin: Dictionary = {}
var frame_count: int = 0


func _ready() -> void:
	half_angle_rad = deg_to_rad(beam_half_angle_deg)

	sensitivity_threshold = pow(10.0, -sensitivity_db)
	visualizer = RayCast3D.new()
	visualizer.position = Vector3(0, 0, -1)
	visualizer.target_position = Vector3(0, 0, -1000)
	visualizer.collision_mask = 0
	visualizer.collide_with_areas = false
	visualizer.collide_with_bodies = false
	visualizer.debug_shape_custom_color = Color.WHITE
	add_child(visualizer)
	for i in range(raycast_pool_size):
		var rc := RayCast3D.new()
		rc.collision_mask = terrain_collision_mask
		rc.collide_with_bodies = false
		rc.collide_with_areas = true
		rc.enabled = false
		add_child(rc)
		ray_pool.append(rc)


func scan() -> void:
	var forward_axis: Vector3 = -global_transform.basis.z
	var echo_map: Dictionary = {}
	targets_per_bin.clear()
	current_echoes.clear()
	var ray_index: int = 0
	
	for target in get_tree().get_nodes_in_group("radar_targets"):
		if ray_index >= raycast_pool_size:
			break
		
		if not (target is RadarTarget) or not is_instance_valid(target):
			continue
		
		var tgt: RadarTarget = target
		var offset: Vector3 = tgt.global_position - global_position
		var forward_distance: float = offset.dot(forward_axis)
		if forward_distance <= 0.0:
			continue
		
		var distance: float = offset.length()
		if distance > maximum_range:
			continue
		
		var lateral: Vector3 = offset - forward_axis * forward_distance
		var max_lateral: float = forward_distance * tan(half_angle_rad)
		if lateral.length() > max_lateral:
			continue
		
		var energy: float = tgt.get_magnitude_at(self)
		if energy < sensitivity_threshold:
			continue
		
		var range_bin: int = round(distance / range_bin_size)
		var radial_velocity: float = tgt.velocity.dot(forward_axis)
		var radial_bin: int = round(radial_velocity / radial_velocity_bin_size)
		var rc: RayCast3D = ray_pool[ray_index]
		ray_index += 1
		rc.position = Vector3.ZERO
		var local_dir: Vector3 = global_transform.basis.inverse() * offset.normalized() * maximum_range
		rc.target_position = local_dir
		rc.enabled = true
		rc.force_raycast_update()
		if rc.is_colliding():
			var terrain_distance: float = global_position.distance_to(rc.get_collision_point())
			if terrain_distance <= distance or (radial_bin == 0 and terrain_distance - distance <= range_bin_size):
				continue
		
		var key: Vector2i = Vector2i(range_bin, radial_bin)
		if echo_map.has(key):
			var existing_echo: RadarEcho = echo_map[key]
			existing_echo.energy += energy
			(targets_per_bin[key] as Array).append(tgt)
		else:
			var echo := RadarEcho.new()
			echo.range_bin = range_bin
			echo.radial_velocity_bin = radial_bin
			echo.energy = energy
			echo_map[key] = echo
			targets_per_bin[key] = [tgt]
	
	for j in range(ray_index, raycast_pool_size):
		ray_pool[j].enabled = false
	for echo in echo_map.values():
		current_echoes.append(echo)


func get_echoes() -> Array[RadarEcho]:
	return current_echoes


func get_targets() -> Array[RadarTarget]:
	var result: Array[RadarTarget] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for list in targets_per_bin.values():
		if list.size() > 0:
			result.append(list[rng.randi_range(0, list.size() - 1)])
	return result


func get_target_for_echo(echo: RadarEcho) -> RadarTarget:
	var key := Vector2i(echo.range_bin, echo.radial_velocity_bin)
	var candidates: Array = targets_per_bin.get(key, [])
	if candidates.size() == 0:
		return null
	if candidates.size() == 1:
		return candidates[0]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return candidates[rng.randi_range(0, candidates.size() - 1)]
