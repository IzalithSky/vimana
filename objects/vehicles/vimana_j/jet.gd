class_name Jet extends Vimana


@export var max_thrust: float = 5000.0
@export var max_pitch: float = 0.8
@export var max_yaw: float = 0.1
@export var max_roll: float = 1.0
@export var lift_coefficient: float = 0.0
@export var stall_aoa_deg: float = 30.0
@export var trail_ttl_after_stop: float = 1.0
@export var trail_pitch_threshold: float = 0.2
@export var trail_speed_thr: float = 100.0
@export var trail_pitch_thr: float = 15.0
@export var base_pitch_scale: float = 0.6
@export var glimiter_scale: float = 0.3
@export var speed_assist: float = 1.4

@onready var trail_l: Trail = $WingL/Trail
@onready var trail_r: Trail = $WingR/Trail
@onready var propulsion_sound: AudioStreamPlayer3D = $PropulsionSound


func _ready() -> void:
	rig = get_node(rig_path)
	self.body_entered.connect(_on_body_entered)
	throttle_input = 0.0


func _physics_process(delta: float) -> void:
	rig.collect_inputs(delta)
	compute_control_state(delta)
	apply_thrust()
	apply_jet_torque(delta)
	apply_lift()
	apply_air_drag()
	apply_directional_alignment()
	
	heat_source.multiplier = throttle_input + 1.0
	throttle_percent = ((throttle_input + 1.0) / 2.0) * 100.0
	_update_wing_trails()
	_update_propulsion_sound()


func _update_propulsion_sound() -> void:
	var t: float = throttle_percent / 100.0
	propulsion_sound.pitch_scale = base_pitch_scale * lerp(1.0, 1.5, t)
	if not propulsion_sound.playing:
		propulsion_sound.play()


func apply_thrust() -> void:
	apply_central_force(-transform.basis.z * ((throttle_input + 1.0) / 2.0) * max_thrust)


func apply_jet_torque(delta: float) -> void:
	var forward_speed: float = linear_velocity.dot(-transform.basis.z)
	var q: float = 0.5 * forward_speed * forward_speed
	
	var speed_factor: float = 1.0
	var t: float = max(0.0, forward_speed) / control_effectiveness_speed
	if aoa_limiter:
		speed_factor = 1.0 / (1.0 + pow(t, 2.0 * speed_assist))
	else:
		speed_factor = 1.0 / (1.0 + pow(t, 2.0 * 0.8))
	
	var p_in: float = pitch_input
	var y_in: float = yaw_input
	var r_in: float = roll_input
	
	p_in *= speed_factor
	y_in *= speed_factor
	r_in *= speed_factor
	
	apply_torque(transform.basis.x * p_in * q * max_pitch)
	apply_torque(transform.basis.y * y_in * q * max_yaw)
	apply_torque(transform.basis.z * r_in * q * max_roll)


func apply_lift() -> void:
	var vel: Vector3 = linear_velocity
	if vel.length() < 1e-3:
		return
	var dynamic_pressure: float = 0.5 * vel.length_squared()
	var vertical_cl: float = lift_coefficient + (2.0 * PI * deg_to_rad(aoa_deg))
	var lateral_cl: float = -2.0 * PI * deg_to_rad(horizontal_aoa_deg)
	lift_ok = abs(aoa_deg) < stall_aoa_deg and abs(horizontal_aoa_deg) < stall_aoa_deg
	if not lift_ok:
		return
	var vertical_lift: float = dynamic_pressure * vertical_cl
	var lateral_lift: float = dynamic_pressure * lateral_cl
	apply_central_force(transform.basis.y * vertical_lift)
	apply_central_force(transform.basis.x * lateral_lift)


func _update_wing_trails() -> void:	
	var local_ang_vel: Vector3 = global_transform.basis.inverse() * angular_velocity
	var local_velocity: Vector3 = global_transform.basis.inverse() * linear_velocity
	var pitch_rate: float = abs(local_ang_vel.x)
	var forward_speed: float = -local_velocity.z
	
	var pitch_ok: bool = pitch_rate > deg_to_rad(trail_pitch_thr)
	var speed_ok: bool = forward_speed > trail_speed_thr
	
	var active: bool = pitch_ok and speed_ok
	
	trail_l.trail_enabled = active
	trail_r.trail_enabled = active
