class_name MissileLauncher extends Node3D

@export var missile_scene: PackedScene
@export var fire_action: String = "fire_missile"


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(fire_action):
		launch_missile()


func launch_missile() -> void:
	if missile_scene:
		var missile: RigidBody3D = missile_scene.instantiate()
		get_tree().current_scene.add_child(missile)
		missile.global_transform = global_transform
		
		# Ignore collision with parent (e.g., the jet)
		if missile is RigidBody3D and owner is CollisionObject3D:
			missile.add_collision_exception_with(owner)
