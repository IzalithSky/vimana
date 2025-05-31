class_name PlayerMissileLauncher extends MissileLauncher


@export var fire_action: String = "fire_missile"
@export var camera: Camera3D
@export var target_tracker: TargetTracker
@export var fire_attach_threshold: float = 0.3
@export var follow_distance: float = 4.0

@onready var missile_cam: Camera3D = $"../MissileCamera"

var _followed_missile: Node3D = null
var _pending_attach_missile: Node3D = null
var _fire_hold_time: float = 0.0


func _process(delta: float) -> void:
	super._process(delta)
	
	if Input.is_action_just_pressed(fire_action):
		var m: Node3D = launch_missile()
		_pending_attach_missile = m
		_fire_hold_time = 0.0
	
	if Input.is_action_pressed(fire_action):
		_fire_hold_time += delta
		if _pending_attach_missile != null and _fire_hold_time >= fire_attach_threshold and _followed_missile == null:
			_attach_camera_to(_pending_attach_missile)
			_pending_attach_missile = null
	else:
		_fire_hold_time = 0.0
		_pending_attach_missile = null
		if _followed_missile != null:
			_detach_camera()
	
	if _followed_missile != null and is_instance_valid(_followed_missile):
		var behind: Vector3 = _followed_missile.global_transform.basis.z * -follow_distance
		missile_cam.global_transform.origin = _followed_missile.global_transform.origin + behind
		if is_instance_valid(_followed_missile.target):
			missile_cam.look_at(_followed_missile.target.global_transform.origin)


func launch_missile() -> MissileHeatSeeker:
	var m: MissileHeatSeeker = super.launch_missile()
	if m != null and target_tracker != null and target_tracker.target != null:
		m.target = target_tracker.target
	return m


func _attach_camera_to(missile: Node3D) -> void:
	if missile_cam == null:
		return
	_followed_missile = missile
	missile_cam.current = true
	if camera != null:
		camera.current = false
	missile.connect("tree_exited", Callable(self, "_on_missile_gone"))


func _detach_camera() -> void:
	if missile_cam != null:
		missile_cam.current = false
	if camera != null:
		camera.current = true
	_followed_missile = null


func _on_missile_gone() -> void:
	_detach_camera()
