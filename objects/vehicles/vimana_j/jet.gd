class_name Jet extends Vimana


@export var max_thrust: float = 600.0

@export var max_pitch: float = 64
@export var max_yaw: float = 32
@export var max_roll: float = 2

@export var max_lift: float = 20.0
@export var lift_zero_aoa_deg: float = -5.0

@export var lift_coefficient: float = 0.1
@export var angular_damping_strength: float = 8.0


func _ready() -> void:
	rig = get_node(rig_path)
	self.body_entered.connect(_on_body_entered)
	throttle_input = -1.0


func apply_thrust() -> void:
	apply_central_force(-transform.basis.z * ((throttle_input + 1) / 2) * max_thrust)


func apply_jet_torque(delta: float) -> void:
	apply_torque(transform.basis.x * pitch_input * control_effectiveness * max_pitch)
	apply_torque(transform.basis.y * yaw_input * control_effectiveness * max_yaw)
	apply_torque(transform.basis.z * roll_input * control_effectiveness * max_roll)


func apply_lift() -> void:
	var forward: Vector3 = -transform.basis.z
	var up: Vector3 = transform.basis.y
	var velocity: Vector3 = linear_velocity
	
	if velocity.length() < 1e-3:
		return
	
	var vel_proj: Vector3 = velocity - transform.basis.x * velocity.dot(transform.basis.x)  # remove side (yaw) component
	var vel_dir: Vector3 = vel_proj.normalized()
	var aoa: float = forward.angle_to(vel_dir)
	var sign_factor: float = sign(up.dot(vel_dir.cross(forward)))
	aoa *= sign_factor
	
	aoa_deg = rad_to_deg(aoa)
	var max_aoa: float = max_aoa_deg
	var zero_lift_aoa: float = lift_zero_aoa_deg
	var aoa_range: float = max_aoa - zero_lift_aoa
	
	if abs(aoa_range) < 1e-3:
		return  # avoid division by zero or near-zero
	
	var lift_ratio: float = clamp((aoa_deg - zero_lift_aoa) / aoa_range, 0.0, 1.0)
	var lift_strength: float = clamp(velocity.length_squared() * lift_ratio * lift_coefficient, -max_lift, max_lift)
	
	var lift_force: Vector3 = transform.basis.y * lift_strength
	apply_central_force(lift_force)


func _physics_process(delta: float) -> void:
	rig.collect_inputs(delta)
	
	compute_control_state()
	apply_thrust()
	apply_jet_torque(delta)
	apply_lift()
	apply_air_drag()
	apply_directional_alignment()
	
	throttle_percent = ((throttle_input + 1) / 2) * 100.0
