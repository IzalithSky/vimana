class_name MissileDisplay extends Node3D


@export var orbit_distance: float = 0.5
@export var update_interval_frames: int = 3
@export var min_pause: float = 0.1
@export var max_pause: float = 1.5
@export var detection_range: float = 5000.0
@export var show_markers: bool = true

@onready var marker_scene: PackedScene = preload("res://objects/missile/missile_marker.tscn")
@onready var proximity_alarm_sound: AudioStreamPlayer3D = $"../ProximityAlarmSound"

var _frame_counter: int = 0
var markers: Dictionary = {}
var _alarm_timer: float = 0.0


func _process(delta: float) -> void:
	_frame_counter += 1
	if _frame_counter % update_interval_frames != 0:
		return
	
	var my_pos: Vector3 = global_transform.origin
	var missiles: Array = get_tree().get_nodes_in_group("missiles")
	var updated_ids: Array = []
	var nearest_missile: RigidBody3D = null
	var nearest_dist: float = detection_range
	
	for missile in missiles:
		if not missile is RigidBody3D:
			continue
	
		var to_me: Vector3 = my_pos - missile.global_transform.origin
		var dist: float = to_me.length()
		var missile_dir: Vector3 = missile.linear_velocity.normalized()
	
		if missile_dir.dot(to_me.normalized()) > 0.5:
			var id: int = missile.get_instance_id()
			updated_ids.append(id)
	
			if show_markers:
				if not markers.has(id):
					var marker: Node3D = marker_scene.instantiate()
					add_child(marker)
					markers[id] = marker
	
				var marker: Node3D = markers[id]
				var offset: Vector3 = -to_me.normalized() * orbit_distance
				marker.global_transform.origin = my_pos + offset
				marker.look_at(my_pos)
	
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_missile = missile
	
	for id in markers.keys():
		if id not in updated_ids:
			markers[id].queue_free()
			markers.erase(id)
	
	if nearest_missile:
		var t: float = clamp(nearest_dist / detection_range, 0.0, 1.0)
		var pause: float = lerp(min_pause, max_pause, t)
		_alarm_timer -= delta
		if _alarm_timer <= 0.0:
			proximity_alarm_sound.play()
			_alarm_timer = pause
