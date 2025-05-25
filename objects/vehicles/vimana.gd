class_name Vimana extends RigidBody3D


@export var drag_forward: float = 0.01
@export var drag_up: float = 0.1
@export var drag_side: float = 0.05
@export var alignment_strength: float = 1.0

@export var warn_g_force: float = 6.0
@export var max_aoa_deg: float = 5.7
@export var control_effectiveness_speed: float = 50.0

@onready var speed_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer/SpeedLabel
@onready var throttle_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer/ThrottleLabel
@onready var aoa_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer2/AoALabel
@onready var gf_label: Label= $Display/SubViewport/HBoxContainer/VBoxContainer2/GForceLabel
@onready var horizon: MeshInstance3D = $Horizon
@onready var heading: Sprite3D = $HeadingSprite3D
@onready var camera: Camera3D = %Camera3D

const G_BUFFER_SIZE := 10
var _g_force_buffer: Array = []
var _prev_velocity: Vector3 = Vector3.ZERO
var smoothed_g: float = 0.0
var aoa_deg: float = 0.0
var control_effectiveness: float = 0.0
var throttle_percent: float = 0.0

func compute_control_state() -> void:
	var forward_speed: float = linear_velocity.dot(-transform.basis.z)
	control_effectiveness = clamp(forward_speed / control_effectiveness_speed, 0.0, 1.0)

	var forward: Vector3 = -transform.basis.z
	var up: Vector3 = transform.basis.y
	var velocity: Vector3 = linear_velocity

	if velocity.length() < 1e-3:
		aoa_deg = 0.0
		return

	var vel_proj: Vector3 = velocity - transform.basis.x * velocity.dot(transform.basis.x)
	var vel_dir: Vector3 = vel_proj.normalized()
	var aoa: float = forward.angle_to(vel_dir)
	var sign_factor: float = sign(up.dot(vel_dir.cross(forward)))
	aoa *= sign_factor
	aoa_deg = rad_to_deg(aoa)


func update_ui(delta: float) -> void:
	var speed: float = linear_velocity.length()
	var speed_knots = speed * 1.94384
	speed_label.text = "Speed: %.1f kn" % speed_knots

	throttle_label.text = "Throttle: %.0f%%" % throttle_percent
	aoa_label.text = "AoA: %.1f°" % aoa_deg

	var total_accel = (linear_velocity - _prev_velocity) / delta
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	var net_accel = total_accel - gravity
	var g_force = net_accel.length() / 9.80665

	_g_force_buffer.append(g_force)
	if _g_force_buffer.size() > G_BUFFER_SIZE:
		_g_force_buffer.pop_front()

	smoothed_g = _g_force_buffer.reduce(func(a, b): return a + b) / _g_force_buffer.size()
	gf_label.text = "Overload: %.2fG" % smoothed_g

	if smoothed_g >= warn_g_force:
		gf_label.add_theme_color_override("font_color", Color.RED)
	else:
		gf_label.add_theme_color_override("font_color", Color.LAWN_GREEN)

	_prev_velocity = linear_velocity

	if control_effectiveness < 1.0 or abs(aoa_deg) > max_aoa_deg:
		aoa_label.add_theme_color_override("font_color", Color.RED)
	else:
		aoa_label.add_theme_color_override("font_color", Color.LAWN_GREEN)

	var parent_yaw = horizon.get_parent().global_transform.basis.get_euler().y
	horizon.global_transform = Transform3D(
		Basis(Vector3.UP, parent_yaw),
		horizon.global_transform.origin)

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
		return

	var basis: Basis = transform.basis
	var drag_force: Vector3 = Vector3.ZERO
	drag_force += -basis.z * velocity.dot(basis.z) * abs(velocity.dot(basis.z)) * drag_forward
	drag_force += -basis.y * velocity.dot(basis.y) * abs(velocity.dot(basis.y)) * drag_up
	drag_force += -basis.x * velocity.dot(basis.x) * abs(velocity.dot(basis.x)) * drag_side

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
