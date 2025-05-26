class_name Jet extends Vimana


@export var max_thrust: float = 4000.0

@export var max_pitch: float = 640.0
@export var max_yaw: float = 320.0
@export var max_roll: float = 120.0

@export var lift_coefficient: float = 0.1

@export var stall_aoa_deg: float = 15.0


func _ready() -> void:
	rig = get_node(rig_path)
	self.body_entered.connect(_on_body_entered)
	throttle_input = -1.0


func apply_thrust() -> void:
	apply_central_force(-transform.basis.z * ((throttle_input + 1.0) / 2.0) * max_thrust)


func apply_jet_torque(delta: float) -> void:
	apply_torque(transform.basis.x * pitch_input * control_effectiveness * max_pitch)
	apply_torque(transform.basis.y * yaw_input * control_effectiveness * max_yaw)
	apply_torque(transform.basis.z * roll_input * control_effectiveness * max_roll)


func apply_lift() -> void:
	var velocity: Vector3 = linear_velocity
	if velocity.length() < 1e-3:
		return
	
	var aoa: float = deg_to_rad(aoa_deg)
	var cl: float = lift_coefficient + (2.0 * PI * aoa)
	
	lift_ok = abs(aoa_deg) < stall_aoa_deg and cl > 0.0
	if not lift_ok:
		return  # stalled – no usable lift
	
	var lift: float = 0.5 * velocity.length_squared() * cl
	apply_central_force(transform.basis.y * lift)


func _physics_process(delta: float) -> void:
	rig.collect_inputs(delta)
	compute_control_state()
	apply_thrust()
	apply_jet_torque(delta)
	apply_lift()
	apply_air_drag()
	apply_directional_alignment()
	throttle_percent = ((throttle_input + 1.0) / 2.0) * 100.0
