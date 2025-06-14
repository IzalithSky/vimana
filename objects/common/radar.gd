class_name Radar extends Node3D


@export var cone_half_angle_deg: float = 60.0
@export var detection_sensitivity_db: float = 8.0
@export var range_bin_size: float = 320.0
@export var radial_bin_size: float = 20.0
@export var angular_bin_size_deg: float = 2.0
@export var max_detection_range: float = 40_000.0
@export_flags_3d_physics var terrain_collision_mask: int = 8
@export var raycast_count: int = 16

var cone_half_angle_rad: float
var detection_threshold: float
var terrain_rays: Array[RayCast3D] = []
var visible_targets: Array[RadarTarget] = []
var own_velocity: Vector3 = Vector3.ZERO
var previous_position: Vector3


func _ready() -> void:
	previous_position = global_position
	cone_half_angle_rad = deg_to_rad(cone_half_angle_deg)
	detection_threshold = pow(10.0, -detection_sensitivity_db)
	
	for i in raycast_count:
		var ray := RayCast3D.new()
		ray.collision_mask = terrain_collision_mask
		ray.collide_with_areas = true
		ray.collide_with_bodies = false
		add_child(ray)
		terrain_rays.append(ray)


func _physics_process(delta: float) -> void:
	own_velocity = (global_position - previous_position) / delta
	previous_position = global_position
	perform_scan()


func perform_scan() -> void:
	visible_targets.clear()
	var forward: Vector3 = -global_transform.basis.z
	var up: Vector3 = global_transform.basis.y
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bins := {}
	var ray_index: int = 0
	
	for node in get_tree().get_nodes_in_group("radar_targets"):
		var target: RadarTarget = node
		var offset: Vector3 = target.global_position - global_position
		var forward_projection: float = offset.dot(forward)
		if forward_projection <= 0.0:
			continue
	
		var distance: float = offset.length()
		if distance > max_detection_range:
			continue
	
		var angle_offset: float = (offset - forward * forward_projection).length()
		if angle_offset > forward_projection * tan(cone_half_angle_rad):
			continue
	
		if target.get_magnitude_at(self) < detection_threshold:
			continue
	
		var range_bin: int = round(distance / range_bin_size)
		var relative_radial_velocity: float = (target.velocity - own_velocity).dot(forward)
		var radial_bin: int = round(relative_radial_velocity / radial_bin_size)
	
		var right: Vector3 = forward.cross(up).normalized()
		var offset_dir: Vector3 = offset.normalized()
		var x: float = offset_dir.dot(right)
		var y: float = offset_dir.dot(up)
		var z: float = offset_dir.dot(forward)
	
		var azimuth_angle: float = atan2(x, z)
		var elevation_angle: float = atan2(y, z)
		var bin_size_rad: float = deg_to_rad(angular_bin_size_deg)
		var azimuth_bin: int = round(azimuth_angle / bin_size_rad)
		var elevation_bin: int = round(elevation_angle / bin_size_rad)
	
		var ray: RayCast3D = terrain_rays[ray_index]
		ray_index += 1
		ray.position = Vector3.ZERO
		ray.target_position = global_transform.basis.inverse() * offset.normalized() * max_detection_range
		ray.enabled = true
		ray.force_raycast_update()
	
		if ray.is_colliding():
			var terrain_distance: float = global_position.distance_to(ray.get_collision_point())
			if terrain_distance <= distance:
				continue
			if radial_bin == 0 and terrain_distance - distance <= range_bin_size:
				continue
	
		var bin_key := Vector4i(range_bin, radial_bin, azimuth_bin, elevation_bin)
		bins[bin_key] = (bins.get(bin_key, []) + [target])
	
	for target_list in bins.values():
		visible_targets.append(target_list[rng.randi_range(0, target_list.size() - 1)])
	
	for i in range(ray_index, raycast_count):
		terrain_rays[i].enabled = false


func get_targets() -> Array[RadarTarget]:
	return visible_targets
