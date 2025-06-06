class_name PlayerGun extends Gun


func _process(delta: float) -> void:
	if Input.is_action_pressed("fire_gun"):
		shoot()
