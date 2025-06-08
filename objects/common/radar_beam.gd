class_name RadarBeam extends Node3D


@export var radius: float = 200.0
@export var sensitivity: float = 8.0
@export var range_resolution: float = 320.0
@export var radial_resolution: float = 20.0
@export var max_range: float = 40_000.0
@export_flags_3d_physics var terrain_mask: int = 8
@export var update_cycle_total: int = 4
@export var update_cycle_offset: int = 0
@export var ray_pool_size: int = 16

var sensitivity_threshold: float = 0.0
var beam_visualizer: RayCast3D
var ray_pool: Array[RayCast3D] = []
var previous_positions: Dictionary = {}
var current_echoes: Array[RadarEcho] = []
var targets_per_bin: Dictionary = {}
var frame_count: int = 0
var accumulated_time: float = 0.0


func _ready() -> void:
	sensitivity_threshold = pow(10.0, -sensitivity)
	
	beam_visualizer = RayCast3D.new()
	beam_visualizer.position = Vector3(0, 0, -1)
	beam_visualizer.target_position = Vector3(0, 0, -1000)
	beam_visualizer.collision_mask = 0
	beam_visualizer.collide_with_areas = false
	beam_visualizer.collide_with_bodies = false
	beam_visualizer.debug_shape_custom_color = Color.WHITE
	add_child(beam_visualizer)
	
	for i: int in range(ray_pool_size):
		var rc: RayCast3D = RayCast3D.new()
		rc.collision_mask = terrain_mask
		rc.collide_with_bodies = false
		rc.collide_with_areas = true
		rc.enabled = false
		add_child(rc)
		ray_pool.append(rc)


func _physics_process(delta: float) -> void:
	frame_count += 1
	accumulated_time += delta
	if frame_count % update_cycle_total != update_cycle_offset:
		return
	
	var elapsed_time: float = max(accumulated_time, 0.001)
	accumulated_time = 0.0
	
	var forward_axis: Vector3 = -global_transform.basis.z
	var echo_map: Dictionary = {}
	targets_per_bin.clear()
	var valid_targets: Array[RadarTarget] = []
	var ray_index: int = 0
	
	for target in get_tree().get_nodes_in_group("radar_targets"):
		if ray_index >= ray_pool_size:
			break
		if not (target is RadarTarget) or not is_instance_valid(target):
			continue
	
		var tgt: RadarTarget = target
		valid_targets.append(tgt)
	
		var offset: Vector3 = tgt.global_position - global_position
		var forward_distance: float = offset.dot(forward_axis)
		if forward_distance <= 0.0:
			continue
	
		var distance: float = offset.length()
		if distance > max_range:
			continue
	
		var lateral: Vector3 = offset - forward_axis * forward_distance
		if lateral.length() > radius:
			continue
	
		var energy: float = tgt.get_magnitude_at(self)
		if energy < sensitivity_threshold:
			continue
	
		var range_bin: int = round(distance / range_resolution)
		var prev_pos: Vector3 = previous_positions.get(tgt, tgt.global_position)
		var velocity: Vector3 = (tgt.global_position - prev_pos) / elapsed_time
		var radial_velocity: float = velocity.dot(forward_axis)
		var radial_bin: int = round(radial_velocity / radial_resolution)
		previous_positions[tgt] = tgt.global_position
	
		var rc: RayCast3D = ray_pool[ray_index]
		ray_index += 1
		rc.position = Vector3.ZERO
		var local_dir: Vector3 = global_transform.basis.inverse() * offset.normalized() * max_range
		rc.target_position = local_dir
		rc.enabled = true
		rc.force_raycast_update()
	
		if rc.is_colliding():
			var terrain_distance: float = global_position.distance_to(rc.get_collision_point())
			if terrain_distance <= distance:
				continue
			var gap: float = terrain_distance - distance
			if radial_bin == 0 and gap <= range_resolution:
				continue
	
		var key: Vector2i = Vector2i(range_bin, radial_bin)
		if echo_map.has(key):
			var existing_echo: RadarEcho = echo_map[key]
			existing_echo.energy += energy
			(targets_per_bin[key] as Array).append(tgt)
		else:
			var echo: RadarEcho = RadarEcho.new()
			echo.range_bin = range_bin
			echo.radial_velocity_bin = radial_bin
			echo.energy = energy
			echo_map[key] = echo
			targets_per_bin[key] = [tgt]
	
	for j: int in range(ray_index, ray_pool_size):
		ray_pool[j].enabled = false
	
	for stored in previous_positions.keys():
		if not is_instance_valid(stored) or stored not in valid_targets:
			previous_positions.erase(stored)
	
	current_echoes.clear()
	for e in echo_map.values():
		current_echoes.append(e)


func get_echoes() -> Array[RadarEcho]:
	return current_echoes


func get_targets() -> Array[RadarTarget]:
	var result: Array[RadarTarget] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for key in targets_per_bin.keys():
		var list: Array[RadarTarget] = targets_per_bin[key]
		if list.is_empty():
			continue
		result.append(list[rng.randi_range(0, list.size() - 1)])
	return result


func get_target_for_echo(echo: RadarEcho) -> RadarTarget:
	var key: Vector2i = Vector2i(echo.range_bin, echo.radial_velocity_bin)
	if not targets_per_bin.has(key):
		return null
	var candidates: Array = targets_per_bin[key]
	if candidates.is_empty():
		return null
	if candidates.size() == 1:
		return candidates[0]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return candidates[rng.randi_range(0, candidates.size() - 1)]
