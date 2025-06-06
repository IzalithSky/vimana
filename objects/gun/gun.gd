class_name Gun extends Node3D


@export var bullet_scene: PackedScene
@export var bullet_count: int = 1300
@export var attack_speed: float = 0.015
@export var shot_force: float = 105.0
@export var holder: RigidBody3D

var _can_shoot: bool = true


func shoot():
	if not _can_shoot or bullet_count <= 0:
		return
	
	bullet_count -= 1
	_can_shoot = false
	await get_tree().create_timer(attack_speed).timeout
	_can_shoot = true
	
	var bullet = bullet_scene.instantiate() as RigidBody3D
	bullet.global_transform = global_transform
	bullet.add_collision_exception_with(holder)
	get_tree().current_scene.add_child(bullet)
	
	bullet.linear_velocity = holder.linear_velocity
	bullet.apply_impulse(global_transform.basis.z * -shot_force)
