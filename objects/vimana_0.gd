class_name Vimana
extends RigidBody3D


@export var input_sensitivity = 1.5
@export var input_decay = 3.0

var roll_input = 0.0
var pitch_input = 0.0
var yaw_input = 0.0
var throttle_input = 0.0

@onready var _camera = %Camera3D
@onready var _camera_pivot = %CameraPivot
@export_range(0.0, 1.0) var mouse_sensitivity = 0.01
@export var tilt_limit = deg_to_rad(75)

@export var thrust_power = 200.0
@export var torque_power = 20.0
@export var spin_threshold = 1

@export var pitch_gain = 0.1
@export var roll_gain = 0.1
@export var vertical_gain = 0.1
@export var hover_throttle = 0.5
@export var autohover_enabled = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -tilt_limit, tilt_limit)
		_camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_autohover"):
		autohover_enabled = !autohover_enabled
		print("Autohover toggled: ", autohover_enabled)


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


func apply_thrust_and_torque(delta: float) -> void:
	var up_force = transform.basis.y * throttle_input * thrust_power
	apply_central_force(up_force)
	
	var torque = Vector3.ZERO
	torque += transform.basis.z * roll_input * torque_power  # Roll around local Z
	torque += transform.basis.x * pitch_input * torque_power # Pitch around local X
	torque += transform.basis.y * yaw_input * torque_power   # Yaw around local Y
	apply_torque(torque)


func stabilise_rotation(delta: float) -> void:
	if not (Input.is_action_pressed("roll_right") or Input.is_action_pressed("roll_left") or
			Input.is_action_pressed("pitch_up") or Input.is_action_pressed("pitch_down") or
			Input.is_action_pressed("yaw_right") or Input.is_action_pressed("yaw_left")):
		var ang_vel = get_angular_velocity()
		var spin = ang_vel.length()
		if spin > 0:
			var scale = clamp(spin / spin_threshold, 0, 1)
			var correction_torque = -ang_vel * scale * torque_power
			apply_torque(correction_torque)


func _physics_process(delta: float) -> void:
	read_vehicle_inputs(delta)
	
	stabilise_rotation(delta)
	
	#print("R=%+0.2f P=%+0.2f Y=%+0.2f T=%+0.2f" % [
		#roll_input,
		#pitch_input,
		#yaw_input,
		#throttle_input
	#])
	
	apply_thrust_and_torque(delta)
