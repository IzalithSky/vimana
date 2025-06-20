class_name Radar extends Node3D


@export var cone_half_angle_deg: float = 60.0
@export var detection_sensitivity_db: float = 8.0
@export var range_bin_size: float = 320.0
@export var radial_bin_size: float = 20.0
@export var angular_bin_size_deg: float = 2.0
@export var max_detection_range: float = 40_000.0
@export_flags_3d_physics var terrain_collision_mask: int = 8
@export var raycast_count: int = 16
@export var ignored_targets: Array[NodePath] = []
@export var active: bool = true

var cone_half_angle_rad: float
var detection_threshold: float
var terrain_rays: Array[RayCast3D] = []
var visible_targets: Array[RadarTarget] = []
var own_velocity: Vector3 = Vector3.ZERO
var previous_position: Vector3
var echo_nodes: Dictionary[int, Echo] = {}


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
	if not active:
		_clear_echoes()
		return
	own_velocity = (global_position - previous_position) / delta
	previous_position = global_position
	perform_scan()


func _clear_echoes() -> void:
	for e in echo_nodes.values():
		if is_instance_valid(e):
			e.queue_free()
	echo_nodes.clear()
	visible_targets.clear()


func perform_scan() -> void:
	visible_targets.clear()
	var forward: Vector3 = -global_transform.basis.z
	var up: Vector3 = global_transform.basis.y
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bins := {}
	var ray_index: int = 0
	for node in get_tree().get_nodes_in_group("radar_targets"):
		var t: RadarTarget = node
		if _is_ignored(t):
			continue
		var off: Vector3 = t.global_position - global_position
		var fwd_proj: float = off.dot(forward)
		if fwd_proj <= 0.0:
			continue
		var dist: float = off.length()
		if dist > max_detection_range:
			continue
		var ang_off: float = (off - forward * fwd_proj).length()
		if ang_off > fwd_proj * tan(cone_half_angle_rad):
			continue
		if t.get_magnitude_at(self) < detection_threshold:
			continue
		var range_bin: int = round(dist / range_bin_size)
		var rel_rad: float = (t.velocity - own_velocity).dot(forward)
		var radial_bin: int = round(rel_rad / radial_bin_size)
		var right: Vector3 = forward.cross(up).normalized()
		var dir: Vector3 = off.normalized()
		var az: float = atan2(dir.dot(right), dir.dot(forward))
		var el: float = atan2(dir.dot(up),    dir.dot(forward))
		var bs: float = deg_to_rad(angular_bin_size_deg)
		var az_bin: int = round(az / bs)
		var el_bin: int = round(el / bs)
		var ray: RayCast3D = terrain_rays[ray_index]
		ray_index += 1
		ray.position = Vector3.ZERO
		ray.target_position = global_transform.basis.inverse() * dir * max_detection_range
		ray.enabled = true
		ray.force_raycast_update()
		if ray.is_colliding():
			var terr: float = global_position.distance_to(ray.get_collision_point())
			if terr <= dist:
				continue
			if radial_bin == 0 and terr - dist <= range_bin_size:
				continue
		var key := Vector4i(range_bin, radial_bin, az_bin, el_bin)
		bins[key] = (bins.get(key, []) + [t])
	for tl in bins.values():
		visible_targets.append(tl[rng.randi_range(0, tl.size() - 1)])
	for i in range(ray_index, raycast_count):
		terrain_rays[i].enabled = false
	_update_echo_nodes()


func _update_echo_nodes() -> void:
	var live: Array[int] = []
	var f: Vector3 = -global_transform.basis.z
	var u: Vector3 = global_transform.basis.y
	var r: Vector3 = f.cross(u).normalized()
	for t in visible_targets:
		var id: int = t.get_instance_id()
		live.append(id)
		var e: Echo = echo_nodes.get(id, null)
		if e == null:
			e = Echo.new()
			add_child(e)
			e.add_to_group("radar_echoes")
			echo_nodes[id] = e
		var off: Vector3 = t.global_position - global_position
		var dist: float = off.length()
		var dir: Vector3 = off.normalized()
		e.distance       = dist
		e.azimuth_rad    = atan2(dir.dot(r), dir.dot(f))
		e.elevation_rad  = atan2(dir.dot(u), dir.dot(f))
		e.radial_speed   = (t.velocity - own_velocity).dot(f)
		e.global_position = t.global_position
	for id in echo_nodes.keys():
		if id not in live:
			if is_instance_valid(echo_nodes[id]):
				echo_nodes[id].queue_free()
			echo_nodes.erase(id)


func get_echoes() -> Array[Echo]:
	return echo_nodes.values()


func _is_ignored(n: Node) -> bool:
	return n.get_path() in ignored_targets
