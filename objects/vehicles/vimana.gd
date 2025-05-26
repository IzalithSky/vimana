class_name Vimana extends RigidBody3D


@export var rig_path: NodePath

@export var drag_forward: float = 0.005
@export var drag_up: float = 0.05
@export var drag_side: float = 0.025
@export var alignment_strength: float = 1.0

@export var warn_g_force: float = 6.0
@export var max_aoa_deg: float = 5.7
@export var control_effectiveness_speed: float = 50.0

@export var explosion_scene: PackedScene
@export var explosive_speed: float = 50.0

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
var control_effectiveness: float = 0.0
var throttle_percent: float = 0.0


func _on_body_entered(body: Node) -> void:
	if linear_velocity.length() >= explosive_speed:
		var explosion: Node3D = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_transform.origin = global_transform.origin


func compute_control_state() -> void:
	var forward_speed: float = linear_velocity.dot(-transform.basis.z)
	control_effectiveness = clamp(forward_speed / control_effectiveness_speed, 0.0, 1.0)
	var forward: Vector3 = -transform.basis.z
	var up: Vector3 = transform.basis.y
	var velocity: Vector3 = linear_velocity
	if velocity.length() < 0.001:
		aoa_deg = 0.0
		return
	var vel_proj: Vector3 = velocity - transform.basis.x * velocity.dot(transform.basis.x)
	var vel_dir: Vector3 = vel_proj.normalized()
	var aoa: float = forward.angle_to(vel_dir)
	var sign_factor: float = sign(up.dot(vel_dir.cross(forward)))
	aoa *= sign_factor
	aoa_deg = rad_to_deg(aoa)


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
