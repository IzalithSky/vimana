class_name Jet extends Vimana

@export var min_thrust: float = 0.0
@export var max_thrust: float = 1000.0
@export var idle_thrust_percent: float = 0.5

@export var input_rate: float = 128.0
@export var input_decay: float = 2048.0

@export var max_pitch: float = 64
@export var max_yaw: float = 32
@export var max_roll: float = 2

@export var max_lift: float = 20.0
@export var lift_zero_aoa_deg: float = -5.0

@export var lift_coefficient: float = 0.1
@export var angular_damping_strength: float = 8.0

@export var max_speed: float = 500.0  # throttle disabled above this

@export var g_limit_pitch_enabled: bool = true
@export var g_limit_throttle_enabled: bool = true
@export var max_g_force: float = 11.0

@export var explosion_scene: PackedScene
@export var explosive_speed: float = 50.0

var current_thrust: float = 0.0
var aoa: float = 0.0

var pitch_input: float = 0.0
var yaw_input: float = 0.0
var roll_input: float = 0.0

var pitch_rate: float = 0.0
var yaw_rate: float = 0.0
var roll_rate: float = 0.0

var pitch_active: bool = false
var yaw_active: bool = false
var roll_active: bool = false


func _ready() -> void:
	self.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if linear_velocity.length() >= explosive_speed:
		var explosion: Node3D = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_transform.origin = global_transform.origin
		


func _physics_process(delta: float) -> void:
	compute_control_state()
	handle_throttle(delta)
	apply_thrust()
	apply_lift()
	apply_air_drag()
	apply_jet_torque(delta)
	apply_directional_alignment()
	apply_trim_torque()
	
	throttle_percent = (current_thrust / max_thrust) * 100.0
	update_ui(delta)
	


func handle_throttle(delta: float) -> void:
	if g_limit_throttle_enabled and smoothed_g >= max_g_force:
		current_thrust = move_toward(current_thrust, 0.0, input_rate * 10.0 * delta)
		return

	if linear_velocity.length() >= max_speed:
		return

	var mult: float = 5
	if Input.is_action_pressed("throttle_up"):
		current_thrust = min(current_thrust + input_rate * mult * delta, max_thrust)
	elif Input.is_action_pressed("throttle_down"):
		current_thrust = max(current_thrust - input_rate * mult * delta, min_thrust)


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


func apply_jet_torque(delta: float) -> void:
	pitch_active = false
	yaw_active = false
	roll_active = false
	
	# --- Pitch input ---
	if Input.is_action_pressed("pitch_up"):
		if not (g_limit_pitch_enabled and smoothed_g >= max_g_force):
			pitch_input += input_rate * delta
			pitch_active = true
	elif Input.is_action_pressed("pitch_down"):
		if not (g_limit_pitch_enabled and smoothed_g >= max_g_force):
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
