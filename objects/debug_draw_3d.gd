extends Control

@export var vimana: Vimana

var camera: Camera3D


func _ready():
	camera = vimana._camera

func _draw():
	if not vimana or not camera:
		return

	var motors = vimana.motors
	var up_dir = vimana.global_transform.basis.y

	# Draw motor thrust directions
	for motor_pos in motors:
		var global_motor_pos = vimana.global_transform.origin + motor_pos
		var thrust_tip = global_motor_pos + up_dir * 2.0
		var screen_start = camera.unproject_position(global_motor_pos)
		var screen_end = camera.unproject_position(thrust_tip)
		draw_line(screen_start, screen_end, Color.GREEN, 2)

	var desired_vector = Vector3(vimana.roll_input, 0, vimana.pitch_input)
	if desired_vector.length() > 0.01:
		desired_vector = desired_vector.normalized()
		var global_input_pos = vimana.global_transform.origin
		var input_tip = global_input_pos + vimana.global_transform.basis * desired_vector * 3.0
		var screen_start = camera.unproject_position(global_input_pos)
		var screen_end = camera.unproject_position(input_tip)
		draw_line(screen_start, screen_end, Color.YELLOW, 3)

func draw_triangle(pos, dir, size, color):
	var perpendicular = Vector2(-dir.y, dir.x)
	var point1 = pos + dir * size
	var point2 = pos + perpendicular * (size * 0.5)
	var point3 = pos - perpendicular * (size * 0.5)
	draw_polygon(PackedVector2Array([point1, point2, point3]), PackedColorArray([color]))
