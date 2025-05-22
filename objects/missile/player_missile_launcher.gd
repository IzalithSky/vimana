extends MissileLauncher
class_name PlayerMissileLauncher

@export var fire_action: String = "fire_missile"
@export var select_target_action: String = "select_target"
@export var camera: Camera3D
@export var targeting_fov_deg: float = 45.0
@export var targeting_max_distance: float = 4000.0
@export var marker_orbit_distance: float = 1.5

@onready var marker_scene: PackedScene = preload("res://objects/common/target_marker.tscn")

var target_next: Node3D = null
var markers: Dictionary = {}  # instance_id -> marker


func _process(_delta: float) -> void:
	if is_instance_valid(target) == false:
		target = null
	if is_instance_valid(target_next) == false:
		target_next = null
	
	if Input.is_action_just_pressed(fire_action):
		launch_missile()
	
	if Input.is_action_just_pressed(select_target_action):
		select_next_target()
	
	update_next_target()
	update_target_markers()


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
			var score: float = 1.0 - angle_cos  # smaller is better
			if score < best_score:
				best_score = score
				best_target = candidate
	
	return best_target


func update_target_markers() -> void:
	var active_ids: Array[int] = []
	
	for obj in get_tree().get_nodes_in_group("targets"):
		if not obj is Node3D:
			continue
	
		var target: Node3D = obj
		if not is_instance_valid(target):
			continue
		
		var target_id: int = target.get_instance_id()
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
			marker.global_transform.origin = target.global_transform.origin
			marker.look_at(global_transform.origin)
	
			if target == self.target:
				marker.call("set_locked")
			elif target == target_next:
				marker.call("set_next")
			else:
				marker.call("clear")
	
	# Remove markers for targets no longer valid
	for id in markers.keys():
		if id not in active_ids:
			markers[id].queue_free()
			markers.erase(id)
