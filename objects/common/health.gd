class_name Health extends Node


enum DeathCause { COLLISION, OTHER }


@export var max_hp: float = 100.0
var current_hp: float = max_hp

signal died(cause: DeathCause)
signal damaged(amount: float)


func take_damage(amount: float, cause: DeathCause = DeathCause.OTHER) -> void:
	current_hp -= amount
	current_hp = clamp(current_hp, 0.0, max_hp)
	emit_signal("damaged", amount)
	if current_hp <= 0.0:
		emit_signal("died", cause)
