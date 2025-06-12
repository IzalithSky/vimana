class_name TargetMarker extends Node3D


@onready var next: Sprite3D = $Next
@onready var lock: Sprite3D = $Lock
@onready var target_r: Sprite3D = $TargetR
@onready var target_h: Sprite3D = $TargetH


func _ready() -> void:
	clear()


func set_next() -> void:
	next.visible = true
	lock.visible = false


func set_locked() -> void:
	lock.visible = true
	next.visible = false


func radar() -> void:
	target_r.visible = true
	target_h.visible = false


func heat() -> void:
	target_r.visible = false
	target_h.visible = true

func clear() -> void:
	lock.visible = false
	next.visible = false
