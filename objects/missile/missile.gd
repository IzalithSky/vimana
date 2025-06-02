class_name Missile extends RigidBody3D


@export var thrust: float = 1200.0
@export var drag_coeff: float = 0.005
@export var torque_strength: float = 20.0
@export var max_ang_vel_deg: float = 160.0
@export var max_fuel: float = 20.0
@export var proximity_radius: float = 15.0
@export var explosion_radius: float = 25.0
@export var explosion_min_damage: int = 10
@export var explosion_max_damage: int = 80
@export var explosion_collision_mask: int = 1
@export var explosion_scene: PackedScene
@export var trail_scene: PackedScene
@export var trail_ttl_after_death: float = 4.0
@export var stabilised = true

var fuel: float = 0.0
var trail: Trail
var host: RigidBody3D


func _ready() -> void:
	fuel = max_fuel
	body_entered.connect(_on_body_entered)
	if trail_scene:
		trail = trail_scene.instantiate() as Trail
		trail.permanent = false
		get_tree().current_scene.add_child(trail)
		trail.global_transform = global_transform


func _physics_process(delta: float) -> void:
	if fuel > 0.0:
		apply_force(-global_transform.basis.z * thrust)
		fuel -= delta
	_apply_drag()
	_custom_physics(delta)
	_apply_stabilisation()
	fuel = max(fuel, 0.0)
	var max_av: float = deg_to_rad(max_ang_vel_deg)
	if angular_velocity.length_squared() > max_av * max_av:
		angular_velocity = angular_velocity.normalized() * max_av
	if trail:
		trail.global_transform = global_transform
	if fuel <= 0.0:
		_die()


func _apply_drag() -> void:
	var drag: Vector3 = -linear_velocity * drag_coeff * linear_velocity.length()
	apply_force(drag)


func _apply_stabilisation() -> void:
	if not stabilised:
		return
	var av_len: float = angular_velocity.length()
	if av_len > 1e-4:
		var mag: float = min(av_len, torque_strength)
		apply_torque(-angular_velocity.normalized() * mag)


func _custom_physics(delta: float) -> void:
	pass


func _on_body_entered(body: Node) -> void:
	_die()


func _die() -> void:
	if trail:
		trail.node_ttl = trail_ttl_after_death
		trail = null
	queue_free()


func _spawn_explosion() -> void:
	if explosion_scene != null:
		var e: Node3D = explosion_scene.instantiate()
		get_tree().current_scene.add_child(e)
		e.global_transform.origin = global_transform.origin
	
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = explosion_radius
	
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = explosion_collision_mask
	query.collide_with_bodies = true
	
	var state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var results: Array = state.intersect_shape(query, 32)
	
	for result in results:
		var node: Node = result["collider"]
		for child in node.get_children():
			if child is Health:
				var health_node: Health = child
				var dist: float = global_transform.origin.distance_to(node.global_transform.origin)
				var t: float = clamp(1.0 - dist / explosion_radius, 0.0, 1.0)
				var dmg: float = lerp(float(explosion_min_damage), float(explosion_max_damage), t)
				health_node.take_damage(int(round(dmg)))
				break
