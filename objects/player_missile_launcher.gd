class_name PlayerMissileLauncher extends MissileLauncher

@export var fire_action: String = "fire_missile"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(fire_action):
		launch_missile()
