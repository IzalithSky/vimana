class_name Trail extends MeshInstance3D


var points: Array[Vector3] = []
var widths: Array = []
var life_points: Array[float] = []
var old_pos: Vector3
var node_ttl: float = -1.0

@export var permanent: bool = true
@export var trail_enabled: bool = true
@export var from_width: float = 0.5
@export var to_width: float = 0.0
@export_range(0.5, 1.5) var scale_acceleration: float = 1.0
@export var motion_delta: float = 8.0
@export var lifespan: float = 1.0
@export var scale_texture: bool = true
@export var start_color: Color = Color(1, 1, 1, 1)
@export var end_color: Color = Color(1, 1, 1, 0)


func _ready() -> void:
	add_to_group("trails")
	old_pos = global_transform.origin
	mesh = ImmediateMesh.new()


func _process(delta: float) -> void:
	if not permanent and node_ttl >= 0.0:
		node_ttl -= delta
		if node_ttl <= 0.0:
			queue_free()
			return
	
	var moved: bool = (old_pos - global_transform.origin).length() > motion_delta
	if trail_enabled and moved:
		_append_point()
		old_pos = global_transform.origin
	
	var i: int = 0
	while i < points.size():
		life_points[i] += delta
		if life_points[i] > lifespan:
			_remove_point(i)
			continue
		i += 1
	
	mesh.clear_surfaces()
	if points.size() < 2:
		return
	
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var count: int = points.size()
	for j in range(count):
		var t: float = float(j) / float(count - 1)
		mesh.surface_set_color(start_color.lerp(end_color, 1.0 - t))
		
		var scale: float = pow(1.0 - t, scale_acceleration)
		var w_from: Vector3 = widths[j][0] as Vector3
		var w_to: Vector3 = widths[j][1] as Vector3
		var w: Vector3 = w_from - scale * w_to
		
		if scale_texture:
			mesh.surface_set_uv(Vector2(motion_delta * j, 0.0))
			mesh.surface_add_vertex(to_local(points[j] + w))
			mesh.surface_set_uv(Vector2(motion_delta * (j + 1), 1.0))
			mesh.surface_add_vertex(to_local(points[j] - w))
		else:
			mesh.surface_set_uv(Vector2(t, 0.0))
			mesh.surface_add_vertex(to_local(points[j] + w))
			mesh.surface_set_uv(Vector2(t, 1.0))
			mesh.surface_add_vertex(to_local(points[j] - w))
	mesh.surface_end()


func _append_point() -> void:
	var direction: Vector3 = (global_transform.origin - old_pos).normalized()
	rotation.y = atan2(direction.x, direction.z)
	points.append(global_transform.origin)
	var width_from: Vector3 = global_transform.basis.x * from_width
	var width_to: Vector3 = global_transform.basis.x * to_width
	widths.append([width_from, width_from - width_to])
	life_points.append(0.0)


func _remove_point(index: int) -> void:
	points.remove_at(index)
	widths.remove_at(index)
	life_points.remove_at(index)


func _build_surface() -> void:
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var count: int = points.size()
	for i in count:
		var t: float = float(i) / float(count - 1)
		var curr_color: Color = start_color.lerp(end_color, 1.0 - t)
		mesh.surface_set_color(curr_color)
		var curr_width: Vector3 = widths[i][0] - pow(1.0 - t, scale_acceleration) * widths[i][1]
		if scale_texture:
			var t0: float = motion_delta * float(i)
			var t1: float = motion_delta * float(i + 1)
			mesh.surface_set_uv(Vector2(t0, 0.0))
			mesh.surface_add_vertex(to_local(points[i] + curr_width))
			mesh.surface_set_uv(Vector2(t1, 1.0))
			mesh.surface_add_vertex(to_local(points[i] - curr_width))
		else:
			var t0: float = float(i) / float(count)
			mesh.surface_set_uv(Vector2(t0, 0.0))
			mesh.surface_add_vertex(to_local(points[i] + curr_width))
			mesh.surface_set_uv(Vector2(t, 1.0))
			mesh.surface_add_vertex(to_local(points[i] - curr_width))
	mesh.surface_end()
