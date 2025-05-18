class_name HUD
extends Control


@export var jet: NodePath
@onready var aircraft: RigidBody3D = get_node(jet)

const PITCH_LADDER_SPACING: float = 10.0  # degrees between pitch lines
const MAX_PITCH: int = 90
const SCALE: float = 4.0  # pixels per degree


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if aircraft == null:
		return

	var screen_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = screen_size / 2.0

	var basis: Basis = aircraft.global_transform.basis
	var up: Vector3 = basis.y
	var forward: Vector3 = -basis.z

	# Pitch angle
	var pitch_angle: float = rad_to_deg(Vector3.FORWARD.angle_to(forward)) * sign(up.y)

	# Roll angle
	var roll_angle: float = atan2(basis.x.y, basis.y.y)

	# Apply rotation around center
	draw_set_transform(center, roll_angle, Vector2.ONE)

	for angle in range(-MAX_PITCH, MAX_PITCH + 1, int(PITCH_LADDER_SPACING)):
		var offset: float = (angle - pitch_angle) * SCALE
		var y: float = offset

		if center.y + y < 0.0 or center.y + y > screen_size.y:
			continue

		var line_len: float = 200.0 if angle == 0 else 100.0
		var start: Vector2 = Vector2(-line_len / 2.0, y)
		var end: Vector2 = Vector2(line_len / 2.0, y)

		draw_line(start, end, Color.GREEN, 2.0)

		if angle != 0:
			var label_pos: Vector2 = Vector2(line_len / 2.0 + 10.0, y + 4.0)
			var font: Font = get_theme_default_font()
			draw_string(font, label_pos, "%+d" % angle, HORIZONTAL_ALIGNMENT_LEFT, -1, 1.0, Color.GREEN)

	# Reset transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
