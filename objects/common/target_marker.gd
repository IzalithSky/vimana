class_name TargetMarker extends Node3D


@onready var lock: TextureRect = %Lock
@onready var target_r: TextureRect = %TargetR
@onready var target_h: TextureRect = %TargetH
@onready var description_label: Label = %NameLabel
@onready var data_label: Label = %DataLabel
@onready var tag_label: Label = %TagLabel


func _ready() -> void:
	clear()


func set_next() -> void:
	lock.visible = false

func set_locked() -> void:
	lock.visible = true

func radar() -> void:
	target_r.visible = true
	target_h.visible = false


func heat() -> void:
	target_r.visible = false
	target_h.visible = true


func clear() -> void:
	lock.visible = false

func set_distance(distance: float) -> void:
	data_label.text = "%.0f m" % distance
