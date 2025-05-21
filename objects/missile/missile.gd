class_name Missile
extends RigidBody3D

@export var speed: float = 300.0
@export var lifetime: float = 10.0
@export var explosion_scene: PackedScene
@export var target: Node3D
@export var max_turn_rate_deg: float = 90.0  # degrees per second
@export var max_fuel: float = 30.0  # fuel in seconds

var time_alive: float = 0.0
var fuel: float = max_fuel


func _ready() -> void:
	self.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if target and fuel > 0.0:
		# Predict target future position
		var to_target = target.global_transform.origin - global_transform.origin
		var target_velocity = target.linear_velocity if target is RigidBody3D else Vector3.ZERO
		var time_to_reach = to_target.length() / speed
		var predicted_position = target.global_transform.origin + target_velocity * time_to_reach

		var desired_dir: Vector3 = (predicted_position - global_transform.origin).normalized()
		var current_dir: Vector3 = -global_transform.basis.z
		var angle_diff: float = current_dir.angle_to(desired_dir)
		var max_turn_rad: float = deg_to_rad(max_turn_rate_deg) * delta

		if angle_diff > 0.001:
			var axis: Vector3 = current_dir.cross(desired_dir).normalized()
			var turn_angle: float = min(angle_diff, max_turn_rad)
			var rotation_delta = Basis(axis, turn_angle)
			global_transform.basis = rotation_delta * global_transform.basis
			fuel -= turn_angle / max_turn_rad * delta
		else:
			fuel -= delta * 0.1  # minimal drain

		fuel = max(fuel, 0.0)

	# Constant forward velocity
	linear_velocity = -global_transform.basis.z * speed

	# Lifetime check
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
