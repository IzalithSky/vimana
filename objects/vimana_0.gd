class_name Vimana_0
extends RigidBody3D


@export var input_sensitivity = 1.5
@export var input_decay = 3.0
@export var thrust_power = 200.0
@export var torque_power = 20.0
@export var spin_threshold = 1

@onready var camera_holder: FPCameraHolder = $FPCameraHolder
@onready var camera: Camera3D = $FPCameraHolder.camera
@onready var rc_vel: RayCast3D = $rc_vel
@onready var rc_tilt: RayCast3D = $rc_tilt

var roll_input = 0.0
var pitch_input = 0.0
var yaw_input = 0.0
var throttle_input = 0.0


func read_vehicle_inputs(delta: float) -> void:
	if Input.is_action_pressed("roll_right"):
		roll_input -= input_sensitivity * delta
	elif Input.is_action_pressed("roll_left"):
		roll_input += input_sensitivity * delta
	else:
		roll_input = move_toward(roll_input, 0, input_decay * delta)
	
	if Input.is_action_pressed("pitch_down"):
		pitch_input -= input_sensitivity * delta
	elif Input.is_action_pressed("pitch_up"):
		pitch_input += input_sensitivity * delta
	else:
		pitch_input = move_toward(pitch_input, 0, input_decay * delta)
	
	if Input.is_action_pressed("yaw_right"):
		yaw_input -= input_sensitivity * delta
	elif Input.is_action_pressed("yaw_left"):
		yaw_input += input_sensitivity * delta
	else:
		yaw_input = move_toward(yaw_input, 0, input_decay * delta)
		
	if Input.is_action_pressed("throttle_up"):
		throttle_input += input_sensitivity * delta
	elif Input.is_action_pressed("throttle_down"):
		throttle_input -= input_sensitivity * delta
	else:
		throttle_input = move_toward(throttle_input, 0, input_decay * delta)
	
	roll_input = clamp(roll_input, -1, 1)
	pitch_input = clamp(pitch_input, -1, 1)
	yaw_input = clamp(yaw_input, -1, 1)
	throttle_input = clamp(throttle_input, -1, 1)


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


#func apply_controls(delta: float) -> void:
	#apply_throttle(throttle_input)
	#apply_roll(roll_input)
	#apply_pitch(pitch_input)
	#apply_yaw(yaw_input)


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


func stabilise_yaw(delta: float) -> void:
	if not (Input.is_action_pressed("yaw_right") or Input.is_action_pressed("yaw_left")):
		var ang_vel = get_angular_velocity()
		var spin = ang_vel.length()
		if spin > 0:
			var scale = clamp(spin / spin_threshold, 0, 1)
			var correction_torque = -ang_vel * scale * torque_power
			var yaw_corr = correction_torque.dot(transform.basis.y) / torque_power
			apply_yaw(yaw_corr)


@export var Kp = 0.5
@export var Ki = 0.1
@export var Kd = 0.1

var pitch_integral: float = 0.0
var pitch_last_error: float = 0.0
var roll_integral: float = 0.0
var roll_last_error: float = 0.0

func align_with_camera_plane(delta: float) -> void:
	var A = camera_holder.pointA.global_transform.origin
	var B = camera_holder.pointB.global_transform.origin
	var C = camera.global_transform.origin
	
	var plane_normal = (B - A).cross(C - A).normalized()
	
	var normal_local = transform.basis.inverse() * plane_normal

	var roll_error = -normal_local.x
	var pitch_error = normal_local.z
	
	#print("%+.2f %+.2f" % [pitch_error, roll_error])
	
	pitch_integral += pitch_error * delta
	var pitch_derivative = (pitch_error - pitch_last_error) / delta
	pitch_last_error = pitch_error

	roll_integral += roll_error * delta
	var roll_derivative = (roll_error - roll_last_error) / delta
	roll_last_error = roll_error

	var pitch_output = Kp * pitch_error + Ki * pitch_integral + Kd * pitch_derivative
	var roll_output = Kp * roll_error + Ki * roll_integral + Kd * roll_derivative

	apply_pitch(pitch_output)
	apply_roll(roll_output)


func update_rcs() -> void:	
	rc_vel.target_position = global_transform.basis.inverse() * linear_velocity


func _physics_process(delta: float) -> void:
	read_vehicle_inputs(delta)

	#stabilise_yaw(delta)
	align_with_camera_plane(delta)

	#stabilise_rotation(delta)
	apply_controls(delta)
	
	update_rcs()
