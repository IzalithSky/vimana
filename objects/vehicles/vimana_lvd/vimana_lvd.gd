class_name LvD extends Heli


var camera: Node3D


func _ready() -> void:
	rig = get_node(rig_path)
	self.body_entered.connect(_on_body_entered)
	
	if rig is PlayerControls:
		camera = rig.camera


func apply_throttle(throttle_value: float) -> void:
	if camera:
		var forward_force = -camera.global_transform.basis.z * throttle_value * thrust_power
		apply_central_force(forward_force)


func apply_directional_alignment() -> void:
	var velocity: Vector3 = linear_velocity
	if velocity.length() < 0.0011:
		return
	var forward: Vector3 = -transform.basis.z
	var vel_dir: Vector3 = velocity.normalized()
	var axis: Vector3 = forward.cross(vel_dir)
	var angle: float = forward.angle_to(vel_dir)
	if angle > 0.01:
		var torque: Vector3 = axis.normalized() * angle * alignment_strength * velocity.length()
		apply_torque(torque)
