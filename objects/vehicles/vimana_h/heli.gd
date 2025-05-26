class_name Heli extends Vimana


@export var input_sensitivity = 1.5
@export var input_decay = 3.0
@export var thrust_power = 600.0
@export var torque_power = 20.0
@export var spin_threshold = 1


func _ready() -> void:
	rig = get_node(rig_path)
	self.body_entered.connect(_on_body_entered)


func apply_throttle(throttle_value: float) -> void:
	var up_force = transform.basis.y * throttle_value * thrust_power
	apply_central_force(up_force)


func apply_roll(roll_value: float) -> void:
	var roll_torque = transform.basis.z * roll_value * torque_power
	apply_torque(roll_torque)


func apply_pitch(pitch_value: float) -> void:
	var pitch_torque = transform.basis.x * pitch_value * torque_power
	apply_torque(pitch_torque)


func apply_yaw(yaw_value: float) -> void:
	var yaw_torque = transform.basis.y * yaw_value * torque_power
	apply_torque(yaw_torque)


func get_effective_pitch_and_roll() -> Vector2:
	var combined = Vector2(roll_input, pitch_input)
	if combined.length() > 1:
		combined = combined.normalized()
	return combined


func apply_controls(delta: float) -> void:
	apply_throttle(throttle_input)
	
	var effective = get_effective_pitch_and_roll()
	apply_roll(effective.x)
	apply_pitch(effective.y)
	
	apply_yaw(yaw_input)


func apply_stabilization_torque(correction_torque: Vector3) -> void:
	var roll_corr = correction_torque.dot(transform.basis.z) / torque_power
	var pitch_corr = correction_torque.dot(transform.basis.x) / torque_power
	var yaw_corr = correction_torque.dot(transform.basis.y) / torque_power
	
	apply_roll(roll_corr)
	apply_pitch(pitch_corr)
	apply_yaw(yaw_corr)


func stabilise_rotation(delta: float) -> void:
	if not (Input.is_action_pressed("roll_right") or Input.is_action_pressed("roll_left") or
			Input.is_action_pressed("pitch_up") or Input.is_action_pressed("pitch_down") or
			Input.is_action_pressed("yaw_right") or Input.is_action_pressed("yaw_left")):
		var ang_vel = get_angular_velocity()
		var spin = ang_vel.length()
		if spin > 0:
			var scale = clamp(spin / spin_threshold, 0, 1)
			var correction_torque = -ang_vel * scale * torque_power
			apply_stabilization_torque(correction_torque)


func _physics_process(delta: float) -> void:
	rig.collect_inputs(delta)
	
	stabilise_rotation(delta)
	
	apply_controls(delta)
	apply_air_drag()
	
	throttle_percent = throttle_input * 100.0
