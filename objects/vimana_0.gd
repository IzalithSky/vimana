extends RigidBody3D


@onready var _camera := %Camera3D as Camera3D
@onready var _camera_pivot := %CameraPivot as Node3D
@onready var thrust_point_l = $ThrustPointL
@onready var thrust_point_r = $ThrustPointR

@export_range(0.0, 0.01) var mouse_sensitivity = 0.005
@export var tilt_limit = deg_to_rad(75)
@export var max_engine_thrust_force: float = 100

var thrust_force_l: float = 0
var thrust_force_r: float = 0
var thrust_direction_l: Vector3 = Vector3.UP
var thrust_direction_r: Vector3 = Vector3.UP


func _process(delta: float) -> void:
	if Input.is_action_pressed("thrust_up"):
		thrust_force_l = max_engine_thrust_force
		thrust_force_r = max_engine_thrust_force
	elif Input.is_action_pressed("thrust_down"):
		thrust_force_l = -max_engine_thrust_force
		thrust_force_r = -max_engine_thrust_force
	else:
		thrust_force_l = 0
		thrust_force_r = 0


func _physics_process(delta: float) -> void:
	apply_central_force(global_transform.basis.y * (thrust_force_l + thrust_force_r))
	
	#apply_constant_force(thrust_direction_l * thrust_force_l, thrust_point_l.position)
	#apply_constant_force(thrust_direction_r * thrust_force_r, thrust_point_r.position)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		# Prevent the camera from rotating too far up or down.
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -tilt_limit, tilt_limit)
		_camera_pivot.rotation.y += -event.relative.x * mouse_sensitivity
