class_name FlareLauncher extends Node3D


@export var flare_scene: PackedScene
@export var fire_interval: float = 3.0
@export var flares_per_burst: int = 6
@export var spread_angle_deg: float = 70.0

var _timer: float = 0.0


func _process(delta: float) -> void:
	_timer += delta


func ready_to_fire() -> bool:
	return _timer >= fire_interval


func launch_flares() -> void:
	if not ready_to_fire():
		return
	
	var parent: Node3D = get_parent()
	var base_dir: Vector3 = -global_transform.basis.y
	var axis: Vector3 = global_transform.basis.z
	
	for i in flares_per_burst:
		var flare: RigidBody3D = flare_scene.instantiate()
		get_tree().current_scene.add_child(flare)
	
		var angle_deg: float = 0.0
		if flares_per_burst == 1:
			angle_deg = 0.0
		else:
			angle_deg = -90.0 + i * 180.0 / float(flares_per_burst - 1)
		var dir: Vector3 = base_dir.rotated(axis, deg_to_rad(angle_deg)).normalized()
		var origin: Vector3 = global_transform.origin
	
		flare.global_transform = Transform3D(Basis(), origin)
		flare.look_at_from_position(origin, origin + dir, Vector3.UP)
	
		if parent is RigidBody3D:
			flare.linear_velocity = parent.linear_velocity
			flare.angular_velocity = parent.angular_velocity
		if parent is CollisionObject3D:
			flare.add_collision_exception_with(parent)
	
		flare.add_to_group("flares")
	
	_timer = 0.0
