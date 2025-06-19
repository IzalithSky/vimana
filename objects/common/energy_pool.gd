class_name EnergyPool extends Node


@export var max_energy: float = 100.0
@export var recharge_rate: float = 1.5
var current_energy: float = max_energy

signal energy_changed(current: float, max: float)


func _ready() -> void:
	current_energy = clamp(current_energy, 0.0, max_energy)
	emit_signal("energy_changed", current_energy, max_energy)


func _process(delta: float) -> void:
	if current_energy < max_energy:
		current_energy = min(max_energy, current_energy + recharge_rate * delta)
		emit_signal("energy_changed", current_energy, max_energy)


func consume(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current_energy >= amount:
		current_energy -= amount
		emit_signal("energy_changed", current_energy, max_energy)
		return true
	return false


func charge(amount: float) -> void:
	if amount <= 0.0:
		return
	var prev: float = current_energy
	current_energy = min(max_energy, current_energy + amount)
	if current_energy != prev:
		emit_signal("energy_changed", current_energy, max_energy)
