class_name MissileHeatSeeker extends Missile


@export var maxTurnRateDegrees: float = 90.0
@export var turnFuelBurnRate: float = 4.0
@export var trackingFovDegrees: float = 60.0
@export var proximityFuseActivationDelay: float = 0.5
@export var slowdownTriggerDistance: float = 100.0
@export var minimumThrustFactor: float = 0.5
@export var heatSeeker: HeatSeeker

var timeSinceLaunch: float = 0.0
var baseThrust: float = 0.0
var lockedTargetDirection: Vector3
var previousTargetDirection: Vector3


func _ready() -> void:
	super._ready()
	lockedTargetDirection = -global_transform.basis.z
	previousTargetDirection = lockedTargetDirection
	baseThrust = thrust


func _custom_physics(delta: float) -> void:
	timeSinceLaunch += delta
	
	update_seeker_orientation(lockedTargetDirection)
	
	var target: HeatSource = heatSeeker.get_best_target()
	if target != null:
		var directionToTarget: Vector3 = (target.global_position - global_position).normalized()
		lockedTargetDirection = directionToTarget
		update_seeker_orientation(lockedTargetDirection)
	else:
		return
	
	if timeSinceLaunch < proximityFuseActivationDelay:
		return
	
	var distanceToTarget: float = global_position.distance_to(target.global_position)
	var thrustMultiplier: float = clamp(distanceToTarget / slowdownTriggerDistance, minimumThrustFactor, 1.0)
	thrust = baseThrust * thrustMultiplier
	
	var targetDirectionDelta: Vector3 = (lockedTargetDirection - previousTargetDirection) / delta
	previousTargetDirection = lockedTargetDirection
	
	var missileSpeed: float = max(linear_velocity.length(), 0.1)
	var predictedDirection: Vector3 = calculate_intercept_direction(-global_transform.basis.z, missileSpeed, lockedTargetDirection, targetDirectionDelta)
	var currentDirection: Vector3 = -global_transform.basis.z
	var angleToTurn: float = currentDirection.angle_to(predictedDirection)
	
	if angleToTurn > 1e-3:
		var turnAxis: Vector3 = currentDirection.cross(predictedDirection)
		if turnAxis.length_squared() > 1e-5:
			turnAxis = turnAxis.normalized()
			var maxTurnAngle: float = deg_to_rad(maxTurnRateDegrees) * delta
			var clampedTurnAngle: float = min(angleToTurn, maxTurnAngle)
			apply_torque(turnAxis * torque_strength * clampedTurnAngle / delta)
			fuel -= turnFuelBurnRate * (clampedTurnAngle / maxTurnAngle) * delta
	
	if distanceToTarget < proximity_radius:
		_spawn_explosion()
		_die()


func calculate_intercept_direction(missileDirection: Vector3, missileSpeed: float, targetDirection: Vector3, targetAngularVelocity: Vector3) -> Vector3:
	var relativeDirection: Vector3 = targetDirection - missileDirection
	var a: float = targetAngularVelocity.length_squared() - missileSpeed * missileSpeed
	var b: float = 2.0 * relativeDirection.dot(targetAngularVelocity)
	var c: float = relativeDirection.length_squared()
	var interceptTime: float
	if abs(a) < 1e-3:
		interceptTime = c / max(b, 1e-3)
	else:
		var discriminant: float = b * b - 4.0 * a * c
		interceptTime = (-b + sqrt(max(discriminant, 0.0))) / (2.0 * a)
	interceptTime = max(interceptTime, 0.0)
	var interceptDirection: Vector3 = (targetDirection + targetAngularVelocity * interceptTime).normalized()
	return interceptDirection


func update_seeker_orientation(direction: Vector3) -> void:
	if heatSeeker == null:
		return
	
	var normalizedDirection: Vector3 = direction.normalized()
	var missileForward: Vector3 = -global_transform.basis.z
	var angleToTarget: float = missileForward.angle_to(normalizedDirection)
	var maxTrackingAngle: float = deg_to_rad(trackingFovDegrees)
	
	var seekerDirection: Vector3 = normalizedDirection
	if angleToTarget > maxTrackingAngle:
		var rotationAxis: Vector3 = missileForward.cross(normalizedDirection).normalized()
		seekerDirection = missileForward.rotated(rotationAxis, maxTrackingAngle).normalized()
	
	var seekerBasis: Basis = Basis().looking_at(seekerDirection, Vector3.UP)
	heatSeeker.global_transform = Transform3D(seekerBasis, heatSeeker.global_position)


func lock_target(target: HeatSource) -> void:
	lockedTargetDirection = (target.global_position - global_position).normalized()
	update_seeker_orientation(lockedTargetDirection)
	previousTargetDirection = lockedTargetDirection
