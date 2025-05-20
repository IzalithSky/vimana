class_name Heli extends RigidBody3D


@export var input_sensitivity = 1.5
@export var input_decay = 3.0
@export var thrust_power = 300.0
@export var torque_power = 20.0
@export var spin_threshold = 1

@export var drag_forward: float = 0.01
@export var drag_up: float = 0.1
@export var drag_side: float = 0.05
@export var alignment_strength: float = 1.0

@onready var camera_holder: FPCameraHolder = $FPCameraHolder
@onready var camera: Camera3D = $FPCameraHolder.camera

@export var speed_label: Label
@export var throttle_label: Label
@export var aoa_label: Label
@export var gf_label: Label
@export var horizon: MeshInstance3D
@export var heading: Sprite3D


@export var warn_g_force: float = 6.0

var roll_input = 0.0
var pitch_input = 0.0
var yaw_input = 0.0
var throttle_input = 0.0

const G_BUFFER_SIZE := 10
var _g_force_buffer: Array = []
var _prev_velocity: Vector3 = Vector3.ZERO
var smoothed_g: float = 0.0


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


func update_ui(delta: float) -> void:	
	var speed: float = linear_velocity.length()
	var speed_knots = speed * 1.94384
	speed_label.text = "Speed: %.1f kn" % speed_knots

	var throttle_percent: float = (throttle_input) * 100.0
	throttle_label.text = "Throttle: %.0f%%" % throttle_percent
	
	aoa_label.text = "AoA: NaN"
	
	var total_accel = (linear_velocity - _prev_velocity) / delta
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	var net_accel = total_accel - gravity
	var g_force = net_accel.length() / 9.80665

	# Update buffer
	_g_force_buffer.append(g_force)
	if _g_force_buffer.size() > G_BUFFER_SIZE:
		_g_force_buffer.pop_front()

	# Smoothed G-force
	smoothed_g = _g_force_buffer.reduce(func(a, b): return a + b) / _g_force_buffer.size()
	gf_label.text = "Overload: %.2fG" % smoothed_g

	if smoothed_g >= warn_g_force:
		gf_label.add_theme_color_override("font_color", Color.RED)
	else:
		gf_label.add_theme_color_override("font_color", Color.LAWN_GREEN)

	_prev_velocity = linear_velocity
		
	var parent_yaw = horizon.get_parent().global_transform.basis.get_euler().y
	horizon.global_transform = Transform3D(
		Basis(Vector3.UP, parent_yaw),
		horizon.global_transform.origin)
		
	# Update heading sprite position
	var cam_pos: Vector3 = $FPCameraHolder.global_transform.origin
	var heading_dir: Vector3

	if linear_velocity.length() > 1e-3:
		heading_dir = linear_velocity.normalized()
	else:
		heading_dir = gravity.normalized()

	var offset: Vector3 = heading_dir * 1.5
	heading.global_transform.origin = cam_pos + offset


func apply_air_drag() -> void:
	var velocity: Vector3 = linear_velocity
	var speed_squared: float = velocity.length_squared()
	if speed_squared < 1e-4:
		return  # avoid tiny/invalid values

	var basis: Basis = transform.basis

	var forward_vel: float = velocity.dot(basis.z)
	var up_vel: float = velocity.dot(basis.y)
	var side_vel: float = velocity.dot(basis.x)

	var drag_force: Vector3 = Vector3.ZERO
	drag_force += -basis.z * forward_vel * abs(forward_vel) * drag_forward
	drag_force += -basis.y * up_vel * abs(up_vel) * drag_up
	drag_force += -basis.x * side_vel * abs(side_vel) * drag_side

	if drag_force.is_finite():
		apply_central_force(drag_force)


func apply_directional_alignment() -> void:
	var velocity: Vector3 = linear_velocity
	if velocity.length() < 1e-3:
		return

	var forward: Vector3 = -transform.basis.z
	var vel_dir: Vector3 = velocity.normalized()
	var axis: Vector3 = forward.cross(vel_dir)
	var angle: float = forward.angle_to(vel_dir)

	if angle > 0.01:
		var torque: Vector3 = axis.normalized() * angle * alignment_strength * velocity.length()
		apply_torque(torque)

func _physics_process(delta: float) -> void:
	read_vehicle_inputs(delta)
	stabilise_rotation(delta)
	#apply_directional_alignment()
	apply_controls(delta)
	apply_air_drag()
	update_ui(delta)
