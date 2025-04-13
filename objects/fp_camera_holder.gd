class_name FPCameraHolder
extends Node3D


@export var sensitivity : float = 0.003
@export var pitch_limit : float = 80

@onready var camera : Camera3D = $Camera3D

var current_pitch : float = 0.0
var current_yaw : float = 0.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_pitch = camera.rotation.x
	current_yaw = camera.rotation.y


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		current_yaw -= event.relative.x * sensitivity
		current_pitch -= event.relative.y * sensitivity
		var pitch_limit_rad: float = deg_to_rad(pitch_limit)
		current_pitch = clamp(current_pitch, -pitch_limit_rad, pitch_limit_rad)
		camera.rotation = Vector3(current_pitch, current_yaw, 0)
