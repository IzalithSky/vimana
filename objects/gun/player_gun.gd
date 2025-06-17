class_name PlayerGun extends Gun


@export var marker_scene: PackedScene

var _marker: Node3D = null
var _previous_target: Node3D = null
var _previous_target_position: Vector3


func _ready() -> void:
	if marker_scene:
		_marker = marker_scene.instantiate() as Node3D
		add_child(_marker)


func _process(delta: float) -> void:
	if Input.is_action_pressed("fire_gun"):
		shoot()
	_update_target_marker(delta)


func _update_target_marker(delta: float) -> void:
	if _marker == null or bullet_speed.length() < 0.01:
		return
	
	var origin: Vector3 = global_transform.origin
	var closest_target: Node3D = null
	var closest_distance: float = INF
	
	for node in get_tree().get_nodes_in_group("targets"):
		if node is Node3D:
			var distance: float = origin.distance_to(node.global_position)
			if distance < closest_distance:
				closest_target = node
				closest_distance = distance
	
	if closest_target == null:
		return
	
	if closest_target != _previous_target:
		_previous_target = closest_target
		_previous_target_position = closest_target.global_position
		return
	
	var target_velocity: Vector3 = (closest_target.global_position - _previous_target_position) / delta
	_previous_target_position = closest_target.global_position
	
	var to_target: Vector3 = closest_target.global_position - origin
	var bullet_speed_magnitude: float = bullet_speed.length()
	
	var a: float = target_velocity.length_squared() - bullet_speed_magnitude * bullet_speed_magnitude
	var b: float = 2.0 * to_target.dot(target_velocity)
	var c: float = to_target.length_squared()
	var discriminant: float = b * b - 4.0 * a * c
	
	if discriminant < 0.0:
		return
	
	var intercept_time: float = (-b - sqrt(discriminant)) / (2.0 * a) if a != 0.0 else -c / b
	if intercept_time <= 0.0:
		return
	
	var predicted_position: Vector3 = closest_target.global_position + target_velocity * intercept_time
	_marker.global_position = predicted_position
