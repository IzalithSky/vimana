class_name Bullet extends CharacterBody3D


@export var damage: float = 20.0
@export var time_to_live: float = 5.0
@export var explosion_scene: PackedScene

@onready var area_3d: Area3D = $Area3D


func _ready() -> void:
	area_3d.body_entered.connect(try_hit)
	await get_tree().create_timer(time_to_live).timeout
	if is_instance_valid(self):
		queue_free()


func _physics_process(delta: float) -> void:
	move_and_slide()
	#print(global_position)


func try_hit(body: Node) -> void:
	_spawn_explosion()
	var health_node := body.find_child("Health", true, false)
	if health_node and health_node is Health:
		health_node.take_damage(damage)
	queue_free()


func _spawn_explosion() -> void:
	if explosion_scene != null:
		var explosion: Node3D = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_transform.origin = global_transform.origin
