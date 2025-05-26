class_name LvD extends Heli


var camera: Node3D


func _ready() -> void:
	rig = get_node(rig_path)
	self.body_entered.connect(_on_body_entered)
	
	if rig is PlayerControls:
		camera = rig.camera


func apply_throttle(throttle_value: float) -> void:
	if camera:
		var forward_force = -camera.global_transform.basis.z * throttle_value * thrust_power
		apply_central_force(forward_force)


func _physics_process(delta: float) -> void:
	rig.collect_inputs(delta)
	
	stabilise_rotation(delta)
	apply_directional_alignment()
	apply_controls(delta)
	apply_air_drag()
	
	throttle_percent = throttle_input * 100.0
