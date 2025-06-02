class_name Health
extends Node


@export var max_hp: float = 100
var current_hp: float = max_hp

signal died
signal damaged(amount: float)


func take_damage(amount: float) -> void:
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	emit_signal("damaged", amount)

	if current_hp <= 0:
		emit_signal("died")
