class_name MissileLauncher extends Node3D

@export var missile_scene: PackedScene
@export var target: Node3D  # Optional

func launch_missile() -> void:
	if missile_scene:
		var missile: RigidBody3D = missile_scene.instantiate()
		get_tree().current_scene.add_child(missile)
		missile.global_transform = global_transform

		if missile is Missile and target:
			missile.target = target

		# Ignore collision with parent
		if missile is RigidBody3D and owner is CollisionObject3D:
			missile.add_collision_exception_with(owner)
