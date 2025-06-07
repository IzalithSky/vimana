class_name PlayerControls extends Node


@export var rot_rate: float = 1.5
@export var rot_decay: float = 3.0
@export var thr_rate: float = 1.5
@export var thr_decay: float = 3.0
@export var vehicle_path: NodePath = NodePath("..")
@export var g_overload_damage: bool = true
@export var g_overload_damage_threshold: float = 16.0
@export var g_overload_damage_per_sec: float = 1.0
@export var damage_flash_alpha: float = 0.64
@export var damage_flash_fade_speed: float = 1.0

@onready var v: Node = get_node(vehicle_path)
@onready var speed_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer/SpeedLabel
@onready var throttle_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer/ThrottleLabel
@onready var aoa_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer2/AoALabel
@onready var gf_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer2/GForceLabel
@onready var limiter_label: Label = $Display/SubViewport/HBoxContainer/VBoxContainer2/LimiterLabel
@onready var throttle_progress_bar: ProgressBar = $FPCameraHolder/Camera3D/CanvasLayer2/HBoxContainer/VBoxContainerT/ThrottleProgressBar
@onready var vl_progress_bar: ProgressBar = $FPCameraHolder/Camera3D/CanvasLayer2/HBoxContainer/VBoxContainerV/HBoxContainer1/VLProgressBar
@onready var va_progress_bar: ProgressBar = $FPCameraHolder/Camera3D/CanvasLayer2/HBoxContainer/VBoxContainerV/HBoxContainer1/VAProgressBar
@onready var health: Health = v.get_node_or_null("Health")
@onready var hp_label: Label = $FPCameraHolder/Camera3D/CanvasLayer1/HBoxContainer/VBoxContainer2/HpLabel
@onready var horizon: MeshInstance3D = $Horizon
@onready var heading_sprite: Sprite3D = $HeadingSprite3D
@onready var camera: Camera3D = %Camera3D
@onready var missile_camera: Camera3D = $MissileCamera
@onready var damage_color_rect: ColorRect = $FPCameraHolder/Camera3D/CanvasLayer1/DamageColorRect
@onready var audio_listener_3d: AudioListener3D = $FPCameraHolder/Camera3D/AudioListener3D
@onready var aoa_limiter_warning: AudioStreamPlayer3D = $AoALimiterWarning
@onready var heat_seeker_target_tracker: HeatSeekerTargetTracker = $FPCameraHolder/Camera3D/HeatSeekerTargetTracker
#@onready var player_gun: PlayerGun = $FPCameraHolder/Camera3D/PlayerGun
#@onready var player_gun: PlayerGun = $PlayerGun

const HEADING_BUFFER_SIZE: int = 10
var _heading_buf: Array[float] = []
var _prev_heading: Vector3

#var missile_launcher: PlayerMissileLauncher = null
@onready var missile_launcher: PlayerMissileLauncher = $FPCameraHolder/Camera3D/PlayerMissileLauncher


func _ready() -> void:
	if health and health.has_signal("damaged"):
		health.damaged.connect(_on_damaged)
	audio_listener_3d.add_to_group("audio_listener")
	
	#for child in v.get_children():
		#if child is PlayerMissileLauncher:
			#missile_launcher = child
			#break
	#if missile_launcher != null:
		#missile_launcher.tracker = heat_seeker_target_tracker
		
	missile_launcher.parent = v
		
	#player_gun.holder = v


func _on_damaged(amount: float) -> void:
	damage_color_rect.color.a = damage_flash_alpha


func collect_inputs(delta: float) -> void:
	var r: float = rot_rate * delta
	var d: float = rot_decay * delta
	if Input.is_action_pressed("roll_right"):
		v.roll_input -= r
	elif Input.is_action_pressed("roll_left"):
		v.roll_input += r
	else:
		v.roll_input = move_toward(v.roll_input, 0.0, d)
	if Input.is_action_pressed("pitch_up"):
		v.pitch_input += r
	elif Input.is_action_pressed("pitch_down"):
		v.pitch_input -= r
	else:
		v.pitch_input = move_toward(v.pitch_input, 0.0, d)
	if Input.is_action_pressed("yaw_right"):
		v.yaw_input -= r
	elif Input.is_action_pressed("yaw_left"):
		v.yaw_input += r
	else:
		v.yaw_input = move_toward(v.yaw_input, 0.0, d)
	v.roll_input  = clamp(v.roll_input,  -1.0, 1.0)
	v.pitch_input = clamp(v.pitch_input, -1.0, 1.0)
	v.yaw_input   = clamp(v.yaw_input,   -1.0, 1.0)
	
	var t_r: float = thr_rate * delta
	if Input.is_action_pressed("throttle_up"):
		v.throttle_input += t_r
	elif Input.is_action_pressed("throttle_down"):
		v.throttle_input -= t_r
	v.throttle_input = clamp(v.throttle_input, -1.0, 1.0)


func track_cgpu_offenders() -> void:
	var ts: Array = get_tree().get_nodes_in_group("trails")
	print("m: %d, f: %d, t: %d" % [
		get_tree().get_nodes_in_group("missiles").size(),
		get_tree().get_nodes_in_group("flares").size(),
		ts.size()])


func print_nearest_enemy_dist() -> void:
	var nearest_distance := INF
	for node in get_tree().get_nodes_in_group("bravo"):
		var dist: float = v.global_position.distance_to(node.global_position)
		if dist < nearest_distance:
			nearest_distance = dist
	print("nearest:", nearest_distance)


func _process(delta: float) -> void:
	#print_nearest_enemy_dist()
	#track_cgpu_offenders()
	#var speed_kn: float = v.linear_velocity.length() * 1.94384
	
	speed_label.text = "Speed: %.1f m/s" % v.linear_velocity.length()
	throttle_label.text = "Throttle: %.0f%%" % v.throttle_percent
	aoa_label.text = "AoA: %.1f°" % v.aoa_deg
	
	gf_label.text = "Overload: %.2fG" % v.smoothed_g
	gf_label.add_theme_color_override("font_color",
		Color.RED if v.smoothed_g >= v.warn_g_force else Color.LAWN_GREEN)
	
	if v.control_effectiveness < 1.0 or not v.lift_ok:
		aoa_label.add_theme_color_override("font_color", Color.RED)
	else:
		aoa_label.add_theme_color_override("font_color", Color.LAWN_GREEN)
		
	if v.aoa_limiter:
		limiter_label.text = "AoA Limiter: ON"
		limiter_label.add_theme_color_override("font_color", Color.LAWN_GREEN)
		if aoa_limiter_warning.playing:
			aoa_limiter_warning.stop()
	else:
		limiter_label.text = "AoA Limiter: OFF"
		limiter_label.add_theme_color_override("font_color", Color.RED)
		if not aoa_limiter_warning.playing:
			aoa_limiter_warning.play()
	
	if health and hp_label:
		hp_label.text = "HP: %d / %d" % [health.current_hp, health.max_hp]
	else:
		hp_label.text = ""
	
	var parent_yaw: float = horizon.get_parent().global_transform.basis.get_euler().y
	horizon.global_transform = Transform3D(
		Basis(Vector3.UP, parent_yaw),
		horizon.global_transform.origin)
	
	var cam_pos: Vector3 = $FPCameraHolder.global_transform.origin
	var heading_dir: Vector3 = (
		v.linear_velocity.normalized() if v.linear_velocity.length() > 1e-3
		else ProjectSettings.get_setting("physics/3d/default_gravity_vector").normalized())
	heading_sprite.global_transform.origin = cam_pos + heading_dir * 1.5
	
	throttle_progress_bar.value = v.throttle_percent
	vl_progress_bar.value = fmod(v.linear_velocity.length(), vl_progress_bar.max_value)
	var curr_heading: Vector3 = -v.global_transform.basis.z.normalized()
	var angle_diff_rad: float = _prev_heading.angle_to(curr_heading)
	var heading_deg_per_sec: float = rad_to_deg(angle_diff_rad) / delta
	_heading_buf.append(heading_deg_per_sec)
	if _heading_buf.size() > HEADING_BUFFER_SIZE:
		_heading_buf.pop_front()
	var smoothed_heading_rate: float = 0.0
	if _heading_buf.size() > 0:
		smoothed_heading_rate = _heading_buf.reduce(func(a, b): return a + b) / _heading_buf.size()
	va_progress_bar.value = fmod(smoothed_heading_rate, va_progress_bar.max_value)
	_prev_heading = curr_heading
	
	if Input.is_action_just_pressed("flares"):
		for child in v.get_children():
			if child is FlareLauncher:
				child.launch_flares()
				break
	
	if Input.is_action_just_pressed("aoa_limiter"):
		v.aoa_limiter = not v.aoa_limiter
	
	if g_overload_damage and health and v.smoothed_g > g_overload_damage_threshold:
		health.take_damage(g_overload_damage_per_sec * delta)
		
	damage_color_rect.color.a = move_toward(
		damage_color_rect.color.a, 0.0, delta * damage_flash_fade_speed)
