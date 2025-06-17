class_name Gun extends Node3D


@export var bullet_scene: PackedScene
@export var bullet_count: int = 1300
@export var attack_speed: float = 0.015
@export var shot_force: float = 1000.0
@export var energy_cost: float = 0.2
@export var holder: RigidBody3D

var energy_pool: EnergyPool

var _can_shoot: bool = true
var bullet_speed: Vector3 = Vector3.ZERO


func _ready() -> void:
	var p: Node = holder if holder != null else get_parent()
	if p != null:
		energy_pool = p.get_node_or_null("Energy")


func shoot():
	if not _can_shoot or bullet_count <= 0:
		return
	
	if energy_pool != null and not energy_pool.consume(energy_cost):
		return
	
	bullet_count -= 1
	_can_shoot = false
	
	var bullet = bullet_scene.instantiate() as CharacterBody3D
	bullet.global_transform = global_transform
	bullet.add_collision_exception_with(holder)
	get_tree().current_scene.add_child(bullet)
	
	var velocity = holder.linear_velocity + global_transform.basis.z * -shot_force
	bullet.velocity = velocity
	bullet_speed = velocity
	
	await get_tree().create_timer(attack_speed).timeout
	_can_shoot = true
