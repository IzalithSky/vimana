class_name Bullet extends RigidBody3D


@export var damage: float = 20.0
@export var time_to_live: float = 5.0


func _ready() -> void:
	body_entered.connect(try_hit)
	await get_tree().create_timer(time_to_live).timeout
	if is_instance_valid(self):
		queue_free()


func try_hit(body: Node) -> void:
	#var health_node := body.find_child("Health", true, false)
	#if health_node and health_node is Health:
		#health_node.apply_damage(damage)
	queue_free()
