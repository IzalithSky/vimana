class_name Jet
extends RigidBody3D

@export var min_thrust: float = 0.0
@export var max_thrust: float = 800.0
@export var idle_thrust_percent: float = 0.5

@export var input_rate: float = 128.0
@export var input_decay: float = 512.0

@export var max_pitch: float = 64
@export var max_yaw: float = 32
@export var max_roll: float = 2

@export var max_lift: float = 10.0
@export var lift_zero_aoa_deg: float = -5.0

@export var lift_coefficient: float = 0.1
@export var angular_damping_strength: float = 8.0
@export var max_aoa_deg: float = 5.7

@export var drag_forward: float = 0.005
@export var drag_up: float = 0.1
@export var drag_side: float = 0.05
@export var alignment_strength: float = 1.0

@export var max_speed: float = 500.0  # throttle disabled above this
@export var control_effectiveness_speed: float = 20.0  # full control above this

@onready var speed_label: Label = $CanvasLayer/VBoxContainer/SpeedLabel
@onready var throttle_label: Label = $CanvasLayer/VBoxContainer/ThrottleLabel
@onready var aoa_label: Label = $CanvasLayer/VBoxContainer/AoALabel
@onready var rc_vel: RayCast3D = $rc_vel
@onready var rc_tilt: RayCast3D = $rc_tilt

var current_thrust: float = 0.0
var aoa: float = 0.0
var aoa_deg: float = 0.0

var pitch_input: float = 0.0
var yaw_input: float = 0.0
var roll_input: float = 0.0

var control_effectiveness: float = 0.0
var pitch_rate: float = 0.0
var yaw_rate: float = 0.0
var roll_rate: float = 0.0

var pitch_active: bool = false
var yaw_active: bool = false
var roll_active: bool = false


func _physics_process(delta: float) -> void:
	compute_control_state()
	handle_throttle(delta)
	apply_thrust()
	apply_lift()
	apply_air_drag()
	apply_jet_torque(delta)
	apply_directional_alignment()
	apply_trim_torque()
	update_ui()


func update_ui() -> void:
	rc_vel.target_position = global_transform.basis.inverse() * linear_velocity
	
	var gravity_dir: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector").normalized()
	rc_tilt.target_position = global_transform.basis.inverse() * gravity_dir
	
	var speed: float = linear_velocity.length()
	speed_label.text = "Speed: %.1f m/s" % speed

	var throttle_percent: float = (current_thrust / max_thrust) * 100.0
	throttle_label.text = "Throttle: %.0f%%" % throttle_percent
	
	aoa_label.text = "AoA: %.1f°" % aoa_deg
	
	if control_effectiveness < 1.0 or abs(aoa_deg) > max_aoa_deg:
		aoa_label.add_theme_color_override("font_color", Color.RED)
	else:
		aoa_label.remove_theme_color_override("font_color")


func compute_control_state() -> void:
	var forward_speed: float = linear_velocity.dot(-transform.basis.z)
	control_effectiveness = clamp(forward_speed / control_effectiveness_speed, 0.0, 1.0)

	var ang_vel: Vector3 = get_angular_velocity()
	pitch_rate = ang_vel.dot(transform.basis.x)
	yaw_rate = ang_vel.dot(transform.basis.y)
	roll_rate = ang_vel.dot(transform.basis.z)


func handle_throttle(delta: float) -> void:
	var target_thrust: float = max_thrust * idle_thrust_percent

	if linear_velocity.length() >= max_speed:
		return

	var mult: float = 5
	if Input.is_action_pressed("throttle_up"):
		current_thrust = min(current_thrust + input_rate * mult * delta, max_thrust)
	elif Input.is_action_pressed("throttle_down"):
		current_thrust = max(current_thrust - input_rate * mult * delta, min_thrust)
	else:
		# Decay toward idle thrust
		current_thrust = move_toward(current_thrust, target_thrust, input_rate * mult * delta)



func apply_thrust() -> void:
	var forward_force: Vector3 = -transform.basis.z * current_thrust
	apply_central_force(forward_force)


func apply_lift() -> void:
	var forward: Vector3 = -transform.basis.z
	var up: Vector3 = transform.basis.y
	var velocity: Vector3 = linear_velocity

	if velocity.length() < 1e-3:
		return

	var vel_proj: Vector3 = velocity - transform.basis.x * velocity.dot(transform.basis.x)  # remove side (yaw) component
	var vel_dir: Vector3 = vel_proj.normalized()
	var aoa: float = forward.angle_to(vel_dir)
	var sign_factor: float = sign(up.dot(vel_dir.cross(forward)))
	aoa *= sign_factor

	aoa_deg = rad_to_deg(aoa)
	var max_aoa: float = max_aoa_deg
	var zero_lift_aoa: float = lift_zero_aoa_deg
	var aoa_range: float = max_aoa - zero_lift_aoa

	if abs(aoa_range) < 1e-3:
		return  # avoid division by zero or near-zero

	var lift_ratio: float = clamp((aoa_deg - zero_lift_aoa) / aoa_range, 0.0, 1.0)
	var lift_strength: float = clamp(velocity.length_squared() * lift_ratio * lift_coefficient, -max_lift, max_lift)

	var lift_force: Vector3 = transform.basis.y * lift_strength
	apply_central_force(lift_force)


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


func apply_jet_torque(delta: float) -> void:
	pitch_active = false
	yaw_active = false
	roll_active = false

	# --- Pitch input ---
	if Input.is_action_pressed("pitch_up"):
		pitch_input += input_rate * delta
		pitch_active = true
	elif Input.is_action_pressed("pitch_down"):
		pitch_input -= input_rate * delta
		pitch_active = true
	else:
		pitch_input = move_toward(pitch_input, 0.0, input_decay * delta)

	pitch_input = clamp(pitch_input, -max_pitch, max_pitch)

	# --- Yaw input ---
	if Input.is_action_pressed("yaw_left"):
		yaw_input += input_rate * delta
		yaw_active = true
	elif Input.is_action_pressed("yaw_right"):
		yaw_input -= input_rate * delta
		yaw_active = true
	else:
		yaw_input = move_toward(yaw_input, 0.0, input_decay * delta)

	yaw_input = clamp(yaw_input, -max_yaw, max_yaw)

	# --- Roll input ---
	if Input.is_action_pressed("roll_left"):
		roll_input += input_rate * delta
		roll_active = true
	elif Input.is_action_pressed("roll_right"):
		roll_input -= input_rate * delta
		roll_active = true
	else:
		roll_input = move_toward(roll_input, 0.0, input_decay * delta)

	roll_input = clamp(roll_input, -max_roll, max_roll)

	# --- Apply torque ---
	apply_torque(transform.basis.x * pitch_input * control_effectiveness)
	apply_torque(transform.basis.y * yaw_input * control_effectiveness)
	apply_torque(transform.basis.z * roll_input * control_effectiveness)


func apply_trim_torque() -> void:
	if control_effectiveness < 1e-3:
		return

	if not pitch_active:
		var pitch_trim: float = clamp(-pitch_rate * angular_damping_strength, -max_pitch, max_pitch)
		apply_torque(transform.basis.x * pitch_trim * control_effectiveness)

	if not yaw_active:
		var yaw_trim: float = clamp(-yaw_rate * angular_damping_strength, -max_yaw, max_yaw)
		apply_torque(transform.basis.y * yaw_trim * control_effectiveness)

	if not roll_active:
		var roll_trim: float = clamp(-roll_rate * angular_damping_strength, -max_roll, max_roll)
		apply_torque(transform.basis.z * roll_trim * control_effectiveness)


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
