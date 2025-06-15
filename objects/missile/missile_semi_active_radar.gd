class_name MissileSemiActiveRadar extends GuidedMissile


@export var gimbal_fov_degrees: float = 60.0
@export var echo_seeker: EchoSeeker


func _ready() -> void:
	super._ready()
	echo_seeker.global_transform = global_transform


func _update_target(delta: float) -> void:
	var new_target: Node3D = echo_seeker.get_best_target()
	if new_target != null:
		target = new_target
	else:
		target = null
		_disable_guidance()


func _update_seeker_orientation(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	
	var forward: Vector3 = -global_transform.basis.z
	var to_target: Vector3 = (target.global_position - global_position).normalized()
	var max_angle: float = deg_to_rad(gimbal_fov_degrees)
	var seeker_direction: Vector3 = to_target
	
	if forward.angle_to(to_target) > max_angle:
		var axis: Vector3 = forward.cross(to_target).normalized()
		seeker_direction = forward.rotated(axis, max_angle).normalized()
	
	var seeker_basis: Basis = Basis().looking_at(seeker_direction, Vector3.UP)
	echo_seeker.global_transform = Transform3D(seeker_basis, echo_seeker.global_position)


func lock_target(new_target: Node3D) -> void:
	super.lock_target(new_target)
	_update_seeker_orientation(0.0)
