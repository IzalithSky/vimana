class_name Health
extends Node


@export var max_hp: int = 100
var current_hp: int = max_hp

signal died
signal damaged(amount: int)


func take_damage(amount: int) -> void:
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	emit_signal("damaged", amount)

	if current_hp <= 0:
		emit_signal("died")
