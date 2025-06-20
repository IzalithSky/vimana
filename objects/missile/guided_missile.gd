class_name GuidedMissile extends Missile


@export var turn_fuel_burn_rate: float = 4.0
@export var proximity_fuse_delay: float = 0.5
@export var slowdown_trigger_distance: float = 120.0
@export var minimum_thrust_factor: float = 0.8
@export var target_loss_grace_period: float = 1.0

var target: Node3D = null
var base_thrust: float = 0.0
var time_since_launch: float = 0.0
var previous_target_position: Vector3 = Vector3.ZERO
var time_since_target_lost: float = 0.0


func _ready() -> void:
	super._ready()
	base_thrust = thrust


func _custom_physics(delta: float) -> void:
	time_since_launch += delta
	if not is_guidance_active:
		return
	
	if time_since_launch >= proximity_fuse_delay:
		_update_target(delta)
	
	if target == null or not is_instance_valid(target):
		time_since_target_lost += delta
		if time_since_target_lost >= target_loss_grace_period:
			_disable_guidance()
		return
	else:
		time_since_target_lost = 0.0
	
	_update_seeker_orientation(delta)
	_apply_guidance(delta)


func _update_target(delta: float) -> void:
	pass


func _update_seeker_orientation(delta: float) -> void:
	pass


func _apply_guidance(delta: float) -> void:
	var distance_to_target: float = global_position.distance_to(target.global_position)
	thrust = base_thrust * clamp(distance_to_target / slowdown_trigger_distance, minimum_thrust_factor, 1.0)
	
	if distance_to_target < proximity_radius:
		_spawn_explosion()
		_die()
	
	var target_velocity: Vector3 = (target.global_position - previous_target_position) / delta
	previous_target_position = target.global_position
	
	var direction_to_target: Vector3 = target.global_position - global_position
	var missile_speed: float = linear_velocity.length()
	
	var a: float = target_velocity.length_squared() - missile_speed * missile_speed
	var b: float = 2.0 * direction_to_target.dot(target_velocity)
	var c: float = direction_to_target.length_squared()
	var discriminant: float = b * b - 4.0 * a * c
	
	var intercept_time: float = 0.0
	if discriminant >= 0.0:
		intercept_time = (-b - sqrt(discriminant)) / (2.0 * a) if a != 0.0 else -c / b
	
	var predicted_position: Vector3 = target.global_position
	if intercept_time > 0.0:
		predicted_position += target_velocity * intercept_time
	
	var desired_direction: Vector3 = (predicted_position - global_position).normalized()
	var current_direction: Vector3 = -global_transform.basis.z
	var angle_to_target: float = current_direction.angle_to(desired_direction)
	
	if angle_to_target > 1e-3:
		var turn_axis: Vector3 = current_direction.cross(desired_direction).normalized()
		var max_turn_angle: float = deg_to_rad(max_ang_vel_deg) * delta
		var turn_angle: float = min(angle_to_target, max_turn_angle)
		apply_torque(turn_axis * torque_strength * (turn_angle / delta))
		fuel -= turn_fuel_burn_rate * (turn_angle / max_turn_angle) * delta


func lock_target(new_target: Node3D) -> void:
	if new_target == null or not is_instance_valid(new_target):
		_disable_guidance()
		return
	target = new_target
	previous_target_position = new_target.global_position
	is_guidance_active = true
	time_since_target_lost = 0.0


func _disable_guidance() -> void:
	is_guidance_active = false
	target = null
