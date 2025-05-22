class_name Health
extends Node


@export var max_hp: int = 1000
@export var health_label: Label  # optional
var current_hp: int = max_hp

signal died
signal damaged(amount: int)


func _ready() -> void:
	_update_label()


func take_damage(amount: int) -> void:
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	emit_signal("damaged", amount)
	_update_label()

	if current_hp == 0:
		emit_signal("died")


func _update_label() -> void:
	if health_label:
		health_label.text = "HP: %d / %d" % [current_hp, max_hp]
