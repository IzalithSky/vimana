class_name MissileLauncher extends Node3D


@export var missile_scene: PackedScene
@export var target: Node3D
@export var fire_interval: float = 2.0

var _timer: float = 0.0


func _process(delta: float) -> void:
	_timer += delta


func ready_to_fire() -> bool:
	return _timer >= fire_interval


func launch_missile() -> Node3D:
	if not ready_to_fire():
		return null
	var missile: Missile = missile_scene.instantiate()
	missile.add_to_group("missiles")
	missile.global_transform = global_transform
	missile.target = target
	if get_parent() is CollisionObject3D:
		missile.add_collision_exception_with(get_parent())
	get_tree().current_scene.add_child(missile)
	_timer = 0.0
	return missile
