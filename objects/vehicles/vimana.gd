class_name Vimana extends RigidBody3D


@export var rig_path: NodePath

@export var drag_forward: float = 0.005
@export var drag_up: float = 0.05
@export var drag_side: float = 0.025
@export var alignment_strength: float = 10.0

@export var warn_g_force: float = 6.0
@export var control_effectiveness_speed: float = 50.0

@export var explosion_scene: PackedScene
@export var explosive_speed: float = 15.0

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
				var dmg: int = int(round(speed))
				child.take_damage(dmg)
				break



func compute_aoa() -> void:
	var v: Vector3 = linear_velocity
	if v.length() < 0.001:
		aoa_deg = 0.0
		return
	
	var forward: Vector3 = -transform.basis.z
	var up: Vector3 = transform.basis.y
	var vel_dir: Vector3 = v.normalized()
	
	var aoa: float = -atan2(vel_dir.dot(up), vel_dir.dot(forward))
	aoa_deg = rad_to_deg(aoa)


func compute_control_state() -> void:
	var forward_speed: float = linear_velocity.dot(-transform.basis.z)
	control_effectiveness = clamp(forward_speed / control_effectiveness_speed, 0.0, 1.0)
	compute_aoa()


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
