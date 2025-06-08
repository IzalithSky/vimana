class_name MissileHeatSeeker extends Missile


@export var turnFuelBurnRate: float = 4.0
@export var trackingFovDegrees: float = 60.0
@export var proximityFuseActivationDelay: float = 0.5
@export var slowdownTriggerDistance: float = 100.0
@export var minimumThrustFactor: float = 0.8
@export var heatSeeker: HeatSeeker

var target: HeatSource = null
var baseThrust: float = 0.0
var timeSinceLaunch: float = 0.0
var _previous_target_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	super._ready()
	baseThrust = thrust
	heatSeeker.global_transform = global_transform


func _custom_physics(delta: float) -> void:
	timeSinceLaunch += delta
	
	if target != null and is_instance_valid(target):
		update_seeker_orientation(target)
	
	if timeSinceLaunch < proximityFuseActivationDelay:
		return
	
	var new_target: HeatSource = heatSeeker.get_best_target()
	if new_target != null:
		target = new_target
	elif target == null:
		return
	
	update_seeker_orientation(target)
	
	var distance: float = global_position.distance_to(target.global_position)
	thrust = baseThrust * clamp(distance / slowdownTriggerDistance, minimumThrustFactor, 1.0)
	
	if distance < proximity_radius:
		_spawn_explosion()
		_die()
	
	if target == null or not is_instance_valid(target):
		return
	
	var target_velocity: Vector3 = (target.global_position - _previous_target_position) / delta
	_previous_target_position = target.global_position
	
	var to_target: Vector3 = target.global_position - global_position
	var missile_speed: float = linear_velocity.length()
	
	var a: float = target_velocity.length_squared() - missile_speed * missile_speed
	var b: float = 2.0 * to_target.dot(target_velocity)
	var c: float = to_target.length_squared()
	var discriminant: float = b * b - 4.0 * a * c
	
	var intercept_time: float = 0.0
	if discriminant >= 0.0:
		intercept_time = (-b - sqrt(discriminant)) / (2.0 * a) if a != 0.0 else -c / b
	
	var predicted_position: Vector3 = target.global_position
	if intercept_time > 0.0:
		predicted_position += target_velocity * intercept_time
	
	var direction_to_target: Vector3 = (predicted_position - global_position).normalized()
	var current_dir: Vector3 = -global_transform.basis.z
	var angle: float = current_dir.angle_to(direction_to_target)
	if angle > 1e-3:
		var axis: Vector3 = current_dir.cross(direction_to_target).normalized()
		var max_turn: float = deg_to_rad(max_ang_vel_deg) * delta
		var turn_angle: float = min(angle, max_turn)
		apply_torque(axis * torque_strength * (turn_angle / delta))
		fuel -= turnFuelBurnRate * (turn_angle / max_turn) * delta


func update_seeker_orientation(t: HeatSource) -> void:
	if t == null or not is_instance_valid(t):
		return
	
	var direction: Vector3 = (t.global_position - global_position).normalized()
	var forward: Vector3 = -global_transform.basis.z
	var angle_to_target: float = forward.angle_to(direction)
	var max_tracking_angle: float = deg_to_rad(trackingFovDegrees)
	
	var seeker_direction: Vector3 = direction
	if angle_to_target > max_tracking_angle:
		var axis: Vector3 = forward.cross(direction).normalized()
		seeker_direction = forward.rotated(axis, max_tracking_angle).normalized()
	
	var seeker_basis: Basis = Basis().looking_at(seeker_direction, Vector3.UP)
	heatSeeker.global_transform = Transform3D(seeker_basis, heatSeeker.global_position)


func lock_target(new_target: HeatSource) -> void:
	target = new_target
	_previous_target_position = new_target.global_position
	update_seeker_orientation(target)
