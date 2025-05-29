extends MissileLauncher
class_name PlayerMissileLauncher

@export var fire_action: String = "fire_missile"
@export var select_target_action: String = "select_target"
@export var camera: Camera3D
@export var targeting_fov_deg: float = 45.0
@export var targeting_max_distance: float = 4000.0
@export var marker_orbit_distance: float = 1.5
@export var fire_attach_threshold: float = 0.3
@export var follow_distance: float = 4.0

@onready var marker_scene: PackedScene = preload("res://objects/common/target_marker.tscn")
@onready var missile_cam: Camera3D = $"../MissileCamera"

var target_next: Node3D = null
var markers: Dictionary = {}

var _followed_missile: Node3D = null
var _pending_attach_missile: Node3D = null
var _fire_hold_time: float = 0.0


func _process(delta: float) -> void:
	super._process(delta)
	
	if not is_instance_valid(target):
		target = null
	if not is_instance_valid(target_next):
		target_next = null
	
	if Input.is_action_just_pressed(fire_action):
		var m: Node3D = launch_missile()
		_pending_attach_missile = m
		_fire_hold_time = 0.0
	
	if Input.is_action_pressed(fire_action):
		_fire_hold_time += delta
		if _pending_attach_missile != null and _fire_hold_time >= fire_attach_threshold and _followed_missile == null:
			_attach_camera_to(_pending_attach_missile)
			_pending_attach_missile = null
	else:
		_fire_hold_time = 0.0
		_pending_attach_missile = null
		if _followed_missile != null:
			_detach_camera()
	
	if _followed_missile != null and is_instance_valid(_followed_missile):
		var behind: Vector3 = _followed_missile.global_transform.basis.z * -follow_distance
		missile_cam.global_transform.origin = _followed_missile.global_transform.origin + behind
		if is_instance_valid(_followed_missile.target):
			missile_cam.look_at(_followed_missile.target.global_transform.origin)
	
	if Input.is_action_just_pressed(select_target_action):
		select_next_target()
	
	update_next_target()
	update_target_markers()


func launch_missile() -> Node3D:
	return super.launch_missile()


func _attach_camera_to(missile: Node3D) -> void:
	if missile_cam == null:
		return
	_followed_missile = missile
	missile_cam.current = true
	if camera != null:
		camera.current = false
	missile.connect("tree_exited", Callable(self, "_on_missile_gone"))


func _detach_camera() -> void:
	if missile_cam != null:
		missile_cam.current = false
	if camera != null:
		camera.current = true
	_followed_missile = null


func _on_missile_gone() -> void:
	_detach_camera()


func update_next_target() -> void:
	target_next = get_best_target(target)


func select_next_target() -> void:
	var new_target: Node3D = get_best_target(target)
	if new_target != null:
		target = new_target


func get_best_target(exclude: Node3D) -> Node3D:
	if camera == null:
		return null
	
	var cam_origin: Vector3 = camera.global_transform.origin
	var cam_dir: Vector3 = -camera.global_transform.basis.z
	var fov_cos: float = cos(deg_to_rad(targeting_fov_deg))
	
	var best_target: Node3D = null
	var best_score: float = INF
	
	for obj in get_tree().get_nodes_in_group("targets"):
		if not obj is Node3D:
			continue
	
		var candidate: Node3D = obj
		if candidate == exclude:
			continue
	
		var to_target: Vector3 = candidate.global_transform.origin - cam_origin
		var distance: float = to_target.length()
		if distance > targeting_max_distance:
			continue
	
		var dir_to_target: Vector3 = to_target.normalized()
		var angle_cos: float = cam_dir.dot(dir_to_target)
		if angle_cos >= fov_cos:
			var score: float = 1.0 - angle_cos
			if score < best_score:
				best_score = score
				best_target = candidate
	
	return best_target


func update_target_markers() -> void:
	var active_ids: Array[int] = []
	
	for obj in get_tree().get_nodes_in_group("targets"):
		if not obj is Node3D:
			continue
	
		var target_obj: Node3D = obj
		if not is_instance_valid(target_obj):
			continue
		
		var target_id: int = target_obj.get_instance_id()
		active_ids.append(target_id)
	
		var marker: Node3D
		if not markers.has(target_id):
			if marker_scene:
				marker = marker_scene.instantiate() as Node3D
				add_child(marker)
				markers[target_id] = marker
		else:
			marker = markers[target_id]
	
		if marker != null:
			marker.global_transform.origin = target_obj.global_transform.origin
			marker.look_at(global_transform.origin)
	
			if target_obj == self.target:
				marker.call("set_locked")
			elif target_obj == target_next:
				marker.call("set_next")
			else:
				marker.call("clear")
	
	for id in markers.keys():
		if id not in active_ids:
			markers[id].queue_free()
			markers.erase(id)
