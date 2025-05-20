class_name Missile extends RigidBody3D

@export var speed: float = 300.0
@export var lifetime: float = 5.0
@export var explosion_scene: PackedScene

var time_alive: float = 0.0


func _ready() -> void:
	self.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# Move missile forward
	linear_velocity = -global_transform.basis.z * speed

	# Timeout check
	time_alive += delta
	if time_alive >= lifetime:
		_spawn_explosion()
		queue_free()


func _on_body_entered(body: Node) -> void:
	_spawn_explosion()
	queue_free()


func _spawn_explosion() -> void:
	if explosion_scene:
		var explosion: Node3D = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_transform.origin = global_transform.origin
