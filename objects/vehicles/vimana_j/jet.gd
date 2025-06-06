class_name Jet extends Vimana


@export var max_thrust: float = 3000.0
@export var max_pitch: float = 800.0
@export var max_yaw: float = 800.0
@export var max_roll: float = 400.0
@export var lift_coefficient: float = 0.4
@export var stall_aoa_deg: float = 45.0
@export var trail_ttl_after_stop: float = 1.0
@export var trail_pitch_threshold: float = 0.2
@export var trail_speed_thr: float = 100.0
@export var trail_pitch_thr: float = 15.0
@export var base_pitch_scale: float = 0.6

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
	if aoa_limiter:
		if smoothed_g > warn_g_force:
			var scale: float = warn_g_force / smoothed_g
			pitch_input = clamp(pitch_input, -scale, scale)
		if not lift_ok:
			var aoa_frac: float = clamp(1.0 - abs(aoa_deg) / stall_aoa_deg, 0.0, 1.0)
			pitch_input *= aoa_frac
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
		return
	var lift: float = 0.5 * velocity.length_squared() * cl
	apply_central_force(transform.basis.y * lift)


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
