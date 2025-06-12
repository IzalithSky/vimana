class_name PlayerMissileLauncher extends MissileLauncher


@export var fire_action: String = "fire_missile"
@export var camera: Camera3D
@export var missile_cam: Camera3D
@export var fire_attach_threshold: float = 0.3
@export var follow_distance: float = 4.0
@export var tracker: TargetTracker

var _followed_missile: Node3D = null
var _pending_attach_missile: Node3D = null
var _fire_hold_time: float = 0.0


func _process(delta: float) -> void:
	super._process(delta)
	
	if Input.is_action_just_pressed(fire_action):
		var heat_target: HeatSource = tracker.get_heat_target()
		if heat_target == null:
			return
	
		var missile: Missile = launch_missile()
		if missile is MissileHeatSeeker:
			var seeker_missile: MissileHeatSeeker = missile as MissileHeatSeeker
			seeker_missile.lock_target(heat_target)
	
		_pending_attach_missile = missile
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
		var fwd: Vector3 = -_followed_missile.global_transform.basis.z
		missile_cam.look_at(missile_cam.global_transform.origin + fwd)


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
