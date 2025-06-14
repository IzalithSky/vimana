class_name MissileLauncher extends Node3D


@export var missile_scene: PackedScene
@export var missile_type: String = "heat"
@export var fire_interval: float = 2.0
@export var parent: RigidBody3D

var _timer: float = 0.0



func _ready() -> void:
	if parent == null:
		parent = get_parent() as RigidBody3D


func _process(delta: float) -> void:
	_timer += delta


func ready_to_fire() -> bool:
	return _timer >= fire_interval


func launch_missile() -> Missile:
	if not ready_to_fire():
		return null

	var missile: Missile = missile_scene.instantiate()
	missile.add_to_group("missiles")
	missile.global_transform = global_transform

	missile.linear_velocity = parent.linear_velocity
	missile.host = parent
	missile.add_collision_exception_with(parent)

	get_tree().current_scene.add_child(missile)
	_timer = 0.0
	return missile
