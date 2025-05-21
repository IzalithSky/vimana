class_name MissileDisplay extends Node3D


@export var orbit_distance: float = 0.5
@export var update_interval_frames: int = 3

@onready var marker_scene: PackedScene = preload("res://objects/missile/missile_marker.tscn")

var _frame_counter := 0
var markers := {}


func _process(_delta: float) -> void:
	_frame_counter += 1
	if _frame_counter % update_interval_frames != 0:
		return
	
	var my_pos = global_transform.origin
	var missiles = get_tree().get_nodes_in_group("missiles")
	var updated_ids = []
	
	for missile in missiles:
		if not missile is RigidBody3D:
			continue
	
		var to_me = my_pos - missile.global_transform.origin
		var missile_dir = missile.linear_velocity.normalized()
		if missile_dir.dot(to_me.normalized()) > 0.7:
			var id = missile.get_instance_id()
			updated_ids.append(id)
	
			if not markers.has(id):
				var marker = marker_scene.instantiate()
				add_child(marker)
				markers[id] = marker
	
			var marker = markers[id]
			var offset = -to_me.normalized() * orbit_distance
			marker.global_transform.origin = my_pos + offset
			marker.look_at(my_pos)
	
	# Clean up unused markers
	for id in markers.keys():
		if id not in updated_ids:
			markers[id].queue_free()
			markers.erase(id)
