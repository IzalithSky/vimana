class_name HeatSeekerTargetTracker extends Node3D


@export var holder: Node3D
@export var marker_scene: PackedScene
@export var tracking_fov_deg: float = 60.0
@export var heat_sensitivity: float = 1e-8

var target: HeatSource = null
var _markers: Dictionary = {}


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		target = null
	if holder == null:
		return
	
	var origin: Vector3 = holder.global_transform.origin
	var forward: Vector3 = -holder.global_transform.basis.z
	target = HeatSeekUtils.best_heat_source(self, origin, forward, tracking_fov_deg, heat_sensitivity)
	_update_markers()


func _update_markers() -> void:
	var live: Array[int] = []
	for hs in get_tree().get_nodes_in_group("heat_sources"):
		if not hs is HeatSource or not is_instance_valid(hs):
			continue
		var id: int = hs.get_instance_id()
		live.append(id)
		var m: TargetMarker = _markers.get(id, null)
		if m == null and marker_scene != null:
			m = marker_scene.instantiate() as TargetMarker
			add_child(m)
			_markers[id] = m
		if m != null:
			m.global_transform.origin = hs.global_transform.origin
			if hs == target:
				m.set_locked()
			else:
				m.clear()
	for id in _markers.keys():
		if id not in live:
			_markers[id].queue_free()
			_markers.erase(id)
