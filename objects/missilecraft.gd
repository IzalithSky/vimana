extends RigidBody3D
class_name MissileLikeAircraft

@export var min_thrust: float = 0.0
@export var max_thrust: float = 200.0
@export var throttle_speed: float = 20.0
@export var max_forward_speed: float = 250.0

@export var pitch_torque: float = 8.0
@export var yaw_torque: float = 2.0
@export var roll_torque: float = 4.0

@export var angular_damping_strength: float = 5.0
@export var lateral_damping_strength: float = 3.0

@onready var speed_label: Label = $CanvasLayer/VBoxContainer/SpeedLabel
@onready var throttle_label: Label = $CanvasLayer/VBoxContainer/ThrottleLabel
@onready var aoa_label: Label = $CanvasLayer/VBoxContainer/AoALabel

var current_thrust: float = 0.0

func _physics_process(_delta: float) -> void:
	handle_throttle(_delta)
	handle_input()
	apply_thrust()
	apply_damping()
	update_ui()


func update_ui() -> void:
	var speed: float = linear_velocity.length()
	speed_label.text = "Speed: %.1f m/s" % speed

	var throttle_percent: float = (current_thrust / max_thrust) * 100.0
	throttle_label.text = "Throttle: %.0f%%" % throttle_percent

	var velocity: Vector3 = linear_velocity
	var aoa: float = 0.0
	if velocity.length() > 0.001:
		var forward: Vector3 = -transform.basis.z
		var vel_dir: Vector3 = velocity.normalized()
		aoa = forward.angle_to(vel_dir)
	aoa_label.text = "AoA: %.1f°" % rad_to_deg(aoa)
		

func handle_throttle(delta: float) -> void:
	if Input.is_action_pressed("throttle_up"):
		current_thrust = min(current_thrust + throttle_speed * delta, max_thrust)
	elif Input.is_action_pressed("throttle_down"):
		current_thrust = max(current_thrust - throttle_speed * delta, min_thrust)


func apply_thrust() -> void:
	var forward: Vector3 = -transform.basis.z
	var forward_speed: float = linear_velocity.dot(forward)
	
	if forward_speed >= max_forward_speed:
		return  # Stop applying thrust when at or above max speed
	
	var forward_force: Vector3 = forward * current_thrust
	apply_central_force(forward_force)


func handle_input() -> void:
	var input_active: bool = false

	if Input.is_action_pressed("pitch_up"):
		apply_torque(transform.basis.x * pitch_torque)
		input_active = true
	elif Input.is_action_pressed("pitch_down"):
		apply_torque(-transform.basis.x * pitch_torque)
		input_active = true

	if Input.is_action_pressed("yaw_left"):
		apply_torque(transform.basis.y * yaw_torque)
		input_active = true
	elif Input.is_action_pressed("yaw_right"):
		apply_torque(-transform.basis.y * yaw_torque)
		input_active = true

	if Input.is_action_pressed("roll_left"):
		apply_torque(transform.basis.z * roll_torque)
		input_active = true
	elif Input.is_action_pressed("roll_right"):
		apply_torque(-transform.basis.z * roll_torque)
		input_active = true

	# Angular damping when no control input
	if not input_active:
		var ang_vel: Vector3 = get_angular_velocity()
		var correction_torque: Vector3 = -ang_vel * angular_damping_strength
		apply_torque(correction_torque)


func apply_damping() -> void:
	var velocity: Vector3 = linear_velocity
	var forward: Vector3 = -transform.basis.z

	var lateral_velocity: Vector3 = velocity - forward * velocity.dot(forward)
	var lateral_correction: Vector3 = -lateral_velocity * lateral_damping_strength
	apply_central_force(lateral_correction)
