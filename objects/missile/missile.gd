class_name Missile
extends RigidBody3D

@export var thrust: float = 1200.0
@export var drag_coeff: float = 0.005
@export var torque_strength: float = 20.0
@export var max_turn_rate_deg: float = 90.0
@export var max_ang_vel_deg: float = 160.0
@export var max_fuel: float = 20.0
@export var turn_fule_burn_rate: float = 4.0
@export var proximity_radius: float = 10.0
@export var explosion_radius: float = 25.0
@export var explosion_min_damage: int = 10
@export var explosion_max_damage: int = 80
@export var explosion_collision_mask: int = 1
@export var explosion_scene: PackedScene
@export var target: Node3D

var fuel: float = 0.0

func _ready() -> void:
	fuel = max_fuel
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if fuel > 0.0:
		apply_force(-global_transform.basis.z * thrust)
		fuel -= delta
	var drag: Vector3 = -linear_velocity * drag_coeff * linear_velocity.length()
	apply_force(drag)
	if target and fuel > 0.0:
		var to_target: Vector3 = target.global_transform.origin - global_transform.origin
		var target_velocity: Vector3 = target.linear_velocity if target is RigidBody3D else Vector3.ZERO
		var speed: float = max(linear_velocity.length(), 0.1)
		var time_to_reach: float = to_target.length() / speed
		var predicted_position: Vector3 = target.global_transform.origin + target_velocity * time_to_reach
		var desired_dir: Vector3 = (predicted_position - global_transform.origin).normalized()
		var current_dir: Vector3 = -global_transform.basis.z
		var angle_diff: float = current_dir.angle_to(desired_dir)
		if angle_diff > 0.001:
			var axis: Vector3 = current_dir.cross(desired_dir)
			if axis.length_squared() > 1e-5 and angle_diff > 1e-3:
				axis = axis.normalized()
				var max_turn_rad: float = deg_to_rad(max_turn_rate_deg) * delta
				var turn_angle: float = min(angle_diff, max_turn_rad)
				apply_torque(axis * torque_strength * turn_angle / delta)
				fuel -= turn_fule_burn_rate * (turn_angle / max_turn_rad) * delta
	fuel = max(fuel, 0.0)
	if target and global_transform.origin.distance_to(target.global_transform.origin) < proximity_radius:
		_spawn_explosion()
		queue_free()
	if fuel <= 0.0:
		_spawn_explosion()
		queue_free()
	var max_ang_vel: float = deg_to_rad(max_ang_vel_deg)
	if angular_velocity.length_squared() > max_ang_vel * max_ang_vel:
		angular_velocity = angular_velocity.normalized() * max_ang_vel

func _on_body_entered(body: Node) -> void:
	_spawn_explosion()
	queue_free()

func _spawn_explosion() -> void:
	if explosion_scene:
		var explosion: Node3D = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_transform.origin = global_transform.origin
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = explosion_radius
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = explosion_collision_mask
	query.collide_with_bodies = true
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var results: Array = space_state.intersect_shape(query, 32)
	for result in results:
		var node: Node = result["collider"]
		if node.has_node("Health"):
			var health_node: Node = node.get_node("Health")
			if "take_damage" in health_node:
				var distance: float = global_transform.origin.distance_to(node.global_transform.origin)
				var t: float = clamp(1.0 - (distance / explosion_radius), 0.0, 1.0)
				var damage: float = lerp(float(explosion_min_damage), float(explosion_max_damage), t)
				health_node.call("take_damage", int(round(damage)))
