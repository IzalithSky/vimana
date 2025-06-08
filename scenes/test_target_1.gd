class_name TestTargetMovement
extends Node3D

@export var amplitude: float = 200.0
@export var speed: float = 50.0     # metres per second

var origin: Vector3
var displacement: float = 0.0
var direction: float = 1.0          # +1 forward, -1 back

func _ready() -> void:
	origin = global_position

func _physics_process(delta: float) -> void:
	displacement += speed * direction * delta

	if displacement > amplitude:
		displacement = amplitude
		direction = -1.0
	elif displacement < -amplitude:
		displacement = -amplitude
		direction = 1.0

	global_position.z = origin.z + displacement
	global_position.x = origin.x + displacement
