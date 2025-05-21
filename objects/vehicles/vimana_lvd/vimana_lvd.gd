class_name LvD extends Heli


func read_vehicle_inputs(delta: float) -> void:
	if Input.is_action_pressed("yaw_right"):
		roll_input -= input_sensitivity * delta
	elif Input.is_action_pressed("yaw_left"):
		roll_input += input_sensitivity * delta
	else:
		roll_input = move_toward(roll_input, 0, input_decay * delta)
	
	if Input.is_action_pressed("throttle_up"):
		pitch_input -= input_sensitivity * delta
	elif Input.is_action_pressed("throttle_down"):
		pitch_input += input_sensitivity * delta
	else:
		pitch_input = move_toward(pitch_input, 0, input_decay * delta)
	
	if Input.is_action_pressed("roll_right"):
		yaw_input -= input_sensitivity * delta
	elif Input.is_action_pressed("roll_left"):
		yaw_input += input_sensitivity * delta
	else:
		yaw_input = move_toward(yaw_input, 0, input_decay * delta)
		
	if Input.is_action_pressed("pitch_down"):
		throttle_input += input_sensitivity * delta / 6
	elif Input.is_action_pressed("pitch_up"):
		throttle_input -= input_sensitivity * delta / 6
	else:
		throttle_input = move_toward(throttle_input, 0, input_decay * 10 * delta)
	
	roll_input = clamp(roll_input, -1, 1)
	pitch_input = clamp(pitch_input, -1, 1)
	yaw_input = clamp(yaw_input, -1, 1)
	throttle_input = clamp(throttle_input, -1, 1)


func apply_throttle(throttle_value: float) -> void:
	var forward_force = -camera.global_transform.basis.z * throttle_value * thrust_power
	apply_central_force(forward_force)


func _physics_process(delta: float) -> void:
	read_vehicle_inputs(delta)
	stabilise_rotation(delta)
	apply_directional_alignment()
	apply_controls(delta)
	apply_air_drag()
	
	throttle_percent = throttle_input * 100.0
	update_ui(delta)
