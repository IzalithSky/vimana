extends Control


@export var color: Color = Color.LAWN_GREEN


func _draw():
	var center = size / 2
	var spacing = size.y / 19.0
	var line_length = size.x * 0.05
	
	# Center full-width horizontal line
	draw_line(Vector2(0 + size.x / 3, center.y), Vector2(2 * size.x / 3, center.y), color)

	# Horizontal ticks (above and below center)
	for i in range(1, 10):
		var y_up = center.y - spacing * i
		var y_down = center.y + spacing * i

		# Solid tick above
		draw_line(
			Vector2(center.x - line_length / 2, y_up),
			Vector2(center.x + line_length / 2, y_up),
			color)

		# Dashed tick below
		var dash_len = line_length / 15.0
		for d in range(0, 15, 2):
			var x0 = center.x - line_length / 2 + d * dash_len
			var x1 = x0 + dash_len
			draw_line(Vector2(x0, y_down), Vector2(x1, y_down), color)


func _ready():
	queue_redraw()
