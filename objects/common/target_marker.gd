class_name TargetMarker extends Node3D


@onready var next: Sprite3D = $Next
@onready var lock: Sprite3D = $Lock


func _ready() -> void:
	clear()


func set_next() -> void:
	next.visible = true
	lock.visible = false


func set_locked() -> void:
	lock.visible = true
	next.visible = false


func clear() -> void:
	lock.visible = false
	next.visible = false
