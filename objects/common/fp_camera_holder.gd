class_name FPCameraHolder extends Node3D


@export var sensitivity: float = 0.002
@export var pitch_limit: float = 120.0
@export var yaw_limit: float = 120.0
@export var yaw_limit_enabled: bool = true
@export var fps_label: Label
@export var normal_fov: float = 90.0
@export var zoomed_fov: float = 32.0
@export var zoom_as_toggle: bool = false

@onready var camera: Camera3D = $Camera3D

var current_pitch: float = 0.0
var current_yaw: float = 0.0
var is_zooming: bool = false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_pitch = camera.rotation.x
	current_yaw = camera.rotation.y


func _process(delta: float) -> void:
	var fps: int = int(Engine.get_frames_per_second())
	fps_label.text = "FPS: %d" % fps
	camera.fov = zoomed_fov if is_zooming else normal_fov


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		current_yaw -= motion.relative.x * sensitivity
		current_pitch -= motion.relative.y * sensitivity
		
		var pitch_limit_rad: float = deg_to_rad(pitch_limit)
		current_pitch = clamp(current_pitch, -pitch_limit_rad, pitch_limit_rad)
		
		if yaw_limit_enabled:
			var yaw_limit_rad: float = deg_to_rad(yaw_limit)
			current_yaw = clamp(current_yaw, -yaw_limit_rad, yaw_limit_rad)
		
		camera.rotation = Vector3(current_pitch, current_yaw, 0.0)
	
	if zoom_as_toggle and event.is_action_pressed("zoom"):
		is_zooming = not is_zooming
	elif not zoom_as_toggle:
		is_zooming = Input.is_action_pressed("zoom")
	
	if event.is_action_pressed("center_camera"):
		current_pitch = 0.0
		current_yaw = 0.0
		camera.rotation = Vector3(current_pitch, current_yaw, 0.0)
