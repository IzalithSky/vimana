class_name Vimana extends RigidBody3D


@export var rig_path: NodePath

@export var drag_forward: float = 0.005
@export var drag_up: float = 0.05
@export var drag_side: float = 0.025
@export var alignment_strength: float = 4.0

@export var warn_g_force: float = 8.0
@export var control_effectiveness_speed: float = 50.0

@export var explosion_scene: PackedScene
@export var explosive_speed: float = 3.0
@export var collsion_damage_mult: float = 20.0

@export var aoa_limiter: bool = true

@onready var heat_source: HeatSource = $HeatSource


var rig: Node
var roll_input: float = 0.0
var pitch_input: float = 0.0
var yaw_input: float = 0.0
var throttle_input: float = 0.0

const G_BUFFER_SIZE: int = 10
var _g_force_buffer: Array[float] = []
var _prev_velocity: Vector3 = Vector3.ZERO
var smoothed_g: float = 0.0
var aoa_deg: float = 0.0
var horizontal_aoa_deg: float = 0.0
var throttle_percent: float = 0.0
var lift_ok: bool = true


func _on_body_entered(body: Node) -> void:
	var speed: float = linear_velocity.length()
	
	if speed >= explosive_speed and explosion_scene:
		var explosion: Node3D = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_transform.origin = global_transform.origin
	
	if speed >= explosive_speed:
		for child in get_children():
			if child is Health:
				child.take_damage(speed * collsion_damage_mult)
				break


func update_g_force(delta: float) -> void:
	var g_force: float = ((linear_velocity - _prev_velocity) / delta -
		ProjectSettings.get_setting("physics/3d/default_gravity_vector")).length() / 9.80665
	_g_force_buffer.append(g_force)
	if _g_force_buffer.size() > G_BUFFER_SIZE:
		_g_force_buffer.pop_front()
	smoothed_g = _g_force_buffer.reduce(func(a, b): return a + b) / _g_force_buffer.size()
	_prev_velocity = linear_velocity


func compute_aoa() -> void:
	var v: Vector3 = linear_velocity
	if v.length() < 0.001:
		aoa_deg = 0.0
		horizontal_aoa_deg = 0.0
		return
	
	var fwd: Vector3 = -transform.basis.z
	var up: Vector3 = transform.basis.y
	var right: Vector3 = transform.basis.x
	var vel_dir: Vector3 = v.normalized()
	
	aoa_deg = rad_to_deg(-atan2(vel_dir.dot(up), vel_dir.dot(fwd)))
	horizontal_aoa_deg = rad_to_deg(atan2(vel_dir.dot(right), vel_dir.dot(fwd)))


func compute_control_state(delta: float) -> void:
	var forward_speed: float = linear_velocity.dot(-transform.basis.z)
	compute_aoa()
	update_g_force(delta)


func apply_air_drag() -> void:
	var velocity: Vector3 = linear_velocity
	if velocity.length_squared() < 0.0001:
		return
	var b: Basis = transform.basis
	var drag: Vector3 = Vector3.ZERO
	drag += -b.z * velocity.dot(b.z) * abs(velocity.dot(b.z)) * drag_forward
	drag += -b.y * velocity.dot(b.y) * abs(velocity.dot(b.y)) * drag_up
	drag += -b.x * velocity.dot(b.x) * abs(velocity.dot(b.x)) * drag_side
	if drag.is_finite():
		apply_central_force(drag)


func apply_directional_alignment() -> void:
	var velocity: Vector3 = linear_velocity
	if velocity.length() < 0.001:
		return
	var forward: Vector3 = -transform.basis.z
	var vel_dir: Vector3 = velocity.normalized()
	var axis: Vector3 = forward.cross(vel_dir)
	var angle: float = forward.angle_to(vel_dir)
	if angle > 0.01:
		var torque: Vector3 = axis.normalized() * angle * alignment_strength * velocity.length()
		apply_torque(torque)
