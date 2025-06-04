class_name TargetTracker extends Node3D


@export var camera: Camera3D
@export var marker_scene: PackedScene
@export var select_target_action: String = "select_target"
@export var target_group: String = "bravo"
@export var fov_deg: float = 45.0
@export var max_distance: float = 4000.0

var target: Node3D = null
var target_next: Node3D = null
var _markers: Dictionary = {}


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		target = null
	if not is_instance_valid(target_next):
		target_next = null
	target_next = _get_best_target(target)
	if Input.is_action_just_pressed(select_target_action):
		var nt: Node3D = _get_best_target(target)
		if nt != null:
			target = nt
	_update_markers()


func _get_best_target(exclude: Node3D) -> Node3D:
	if camera == null:
		return null
	var cam_pos: Vector3 = camera.global_transform.origin
	var cam_dir: Vector3 = -camera.global_transform.basis.z
	var cos_limit: float = cos(deg_to_rad(fov_deg))
	var best: Node3D = null
	var best_score: float = INF
	for n in get_tree().get_nodes_in_group(target_group):
		if not n is Node3D or n == exclude:
			continue
		var to_vec: Vector3 = n.global_transform.origin - cam_pos
		var dist: float = to_vec.length()
		if dist > max_distance:
			continue
		var ang_cos: float = cam_dir.dot(to_vec.normalized())
		if ang_cos >= cos_limit:
			var score: float = 1.0 - ang_cos
			if score < best_score:
				best_score = score
				best = n
	return best


func _update_markers() -> void:
	var live: Array[int] = []
	for n in get_tree().get_nodes_in_group(target_group):
		if not n is Node3D or not is_instance_valid(n):
			continue
		var id: int = n.get_instance_id()
		live.append(id)
		var m: Node3D = _markers.get(id, null)
		if m == null and marker_scene != null:
			m = marker_scene.instantiate() as Node3D
			add_child(m)
			_markers[id] = m
		if m != null:
			m.global_transform.origin = n.global_transform.origin
			m.look_at(global_transform.origin)
			if n == target:
				m.call("set_locked")
			elif n == target_next:
				m.call("set_next")
			else:
				m.call("clear")
	for id in _markers.keys():
		if id not in live:
			_markers[id].queue_free()
			_markers.erase(id)
