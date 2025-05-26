class_name PlayerControls extends Node


@export var rot_rate: float = 1.5
@export var rot_decay: float = 3.0
@export var thr_rate: float = 1.5
@export var thr_decay: float = 3.0
@export var vehicle_path: NodePath = NodePath("..")

@onready var v: Node = get_node(vehicle_path)

@onready var speed_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer/SpeedLabel
@onready var throttle_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer/ThrottleLabel
@onready var aoa_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer2/AoALabel
@onready var gf_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer2/GForceLabel
@onready var health: Node = v.get_node_or_null("Health")
@onready var hp_label: Label = $FPCameraHolder/Camera3D/CanvasLayer/HBoxContainer/VBoxContainer2/HpLabel
@onready var horizon: MeshInstance3D = $Horizon
@onready var heading_sprite: Sprite3D = $HeadingSprite3D
@onready var camera: Camera3D = %Camera3D


const G_BUFFER_SIZE: int = 10
var _buf: Array[float] = []


func collect_inputs(delta: float) -> void:
	var r: float = rot_rate * delta
	var d: float = rot_decay * delta
	if Input.is_action_pressed("roll_right"):
		v.roll_input -= r
	elif Input.is_action_pressed("roll_left"):
		v.roll_input += r
	else:
		v.roll_input = move_toward(v.roll_input, 0.0, d)
	if Input.is_action_pressed("pitch_up"):
		v.pitch_input += r
	elif Input.is_action_pressed("pitch_down"):
		v.pitch_input -= r
	else:
		v.pitch_input = move_toward(v.pitch_input, 0.0, d)
	if Input.is_action_pressed("yaw_right"):
		v.yaw_input -= r
	elif Input.is_action_pressed("yaw_left"):
		v.yaw_input += r
	else:
		v.yaw_input = move_toward(v.yaw_input, 0.0, d)
	v.roll_input  = clamp(v.roll_input,  -1.0, 1.0)
	v.pitch_input = clamp(v.pitch_input, -1.0, 1.0)
	v.yaw_input   = clamp(v.yaw_input,   -1.0, 1.0)

	var t_r: float = thr_rate * delta
	if Input.is_action_pressed("throttle_up"):
		v.throttle_input += t_r
	elif Input.is_action_pressed("throttle_down"):
		v.throttle_input -= t_r
	v.throttle_input = clamp(v.throttle_input, -1.0, 1.0)


func _process(delta: float) -> void:
	var speed_kn: float = v.linear_velocity.length() * 1.94384
	speed_label.text = "Speed: %.1f kn" % speed_kn
	throttle_label.text = "Throttle: %.0f%%" % v.throttle_percent
	aoa_label.text = "AoA: %.1f°" % v.aoa_deg
	
	var g_force: float = ((v.linear_velocity - v._prev_velocity) / delta -
						  ProjectSettings.get_setting("physics/3d/default_gravity_vector")
						 ).length() / 9.80665
	_buf.append(g_force)
	if _buf.size() > G_BUFFER_SIZE:
		_buf.pop_front()
	var smoothed: float = _buf.reduce(func(a, b): return a + b) / _buf.size()
	gf_label.text = "Overload: %.2fG" % smoothed
	gf_label.add_theme_color_override("font_color",
		Color.RED if smoothed >= v.warn_g_force else Color.LAWN_GREEN)
	v._prev_velocity = v.linear_velocity
	
	if v.control_effectiveness < 1.0 or abs(v.aoa_deg) > v.max_aoa_deg:
		aoa_label.add_theme_color_override("font_color", Color.RED)
	else:
		aoa_label.add_theme_color_override("font_color", Color.LAWN_GREEN)
	
	if health and hp_label:
		hp_label.text = "HP: %d / %d" % [health.current_hp, health.max_hp]
	else:
		hp_label.text = ""
	
	var parent_yaw: float = horizon.get_parent().global_transform.basis.get_euler().y
	horizon.global_transform = Transform3D(
		Basis(Vector3.UP, parent_yaw),
		horizon.global_transform.origin)
	
	var cam_pos: Vector3 = $FPCameraHolder.global_transform.origin
	var heading_dir: Vector3 = (
		v.linear_velocity.normalized() if v.linear_velocity.length() > 1e-3
		else ProjectSettings.get_setting("physics/3d/default_gravity_vector").normalized()
	)
	heading_sprite.global_transform.origin = cam_pos + heading_dir * 1.5
