class_name GuidedMissile extends Missile


@export var turn_fuel_burn_rate: float = 4.0
@export var proximity_fuse_delay: float = 0.5
@export var slowdown_trigger_distance: float = 120.0
@export var minimum_thrust_factor: float = 1.0
@export var target_loss_grace_period: float = 1.0

var target: Node3D = null
var base_thrust: float = 0.0
var time_since_launch: float = 0.0
var previous_target_position: Vector3 = Vector3.ZERO
var time_since_target_lost: float = 0.0
var previous_deviation: Vector3 = Vector3.ZERO


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
	var where_it_is: Vector3 = global_position
	var where_it_isnt: Vector3 = target.global_position
	var deviation: Vector3 = where_it_isnt - where_it_is
	var variation: Vector3 = deviation - previous_deviation
	previous_deviation = deviation
	
	var corrective_direction: Vector3 = (deviation + variation).normalized()
	var current_forward: Vector3 = -global_transform.basis.z
	var angle: float = current_forward.angle_to(corrective_direction)
	
	var distance: float = deviation.length()
	thrust = base_thrust * clamp(distance / slowdown_trigger_distance, minimum_thrust_factor, 1.0)
	
	if distance < proximity_radius:
		_spawn_explosion()
		_die()
		return
	
	if angle > 1e-3:
		var axis: Vector3 = current_forward.cross(corrective_direction).normalized()
		var max_turn: float = deg_to_rad(max_ang_vel_deg) * delta
		var turn_angle: float = min(angle, max_turn)
		apply_torque(axis * torque_strength * (turn_angle / delta))
		fuel -= turn_fuel_burn_rate * (turn_angle / max_turn) * delta


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
