class_name MissileHeatSeeker extends GuidedMissile


@export var tracking_fov_degrees: float = 40.0
@export var heat_seeker: HeatSeeker


func _ready() -> void:
	super._ready()
	heat_seeker.global_transform = global_transform


func _update_target(delta: float) -> void:
	var new_target: HeatSource = heat_seeker.get_best_target()
	if new_target != null:
		target = new_target
	else:
		target = null
		_disable_guidance()


func _update_seeker_orientation(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	
	var direction_to_target: Vector3 = (target.global_position - global_position).normalized()
	var forward: Vector3 = -global_transform.basis.z
	var max_tracking_angle: float = deg_to_rad(tracking_fov_degrees)
	var seeker_direction: Vector3 = direction_to_target
	
	if forward.angle_to(direction_to_target) > max_tracking_angle:
		var rotation_axis: Vector3 = forward.cross(direction_to_target).normalized()
		seeker_direction = forward.rotated(rotation_axis, max_tracking_angle).normalized()
	
	var seeker_basis: Basis = Basis().looking_at(seeker_direction, Vector3.UP)
	heat_seeker.global_transform = Transform3D(seeker_basis, heat_seeker.global_position)


func lock_target(new_target: Node3D) -> void:
	super.lock_target(new_target)
	_update_seeker_orientation(0.0)
