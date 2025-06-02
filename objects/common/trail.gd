class_name Trail extends MeshInstance3D


var points: Array[Vector3] = []
var widths: Array = []
var life_points: Array[float] = []
var _dirty: bool = false
var old_pos: Vector3
var node_ttl: float = -1.0

@export var trail_enabled: bool = true
@export var from_width: float = 0.5
@export var to_width: float = 0.0
@export_range(0.5, 1.5) var scale_acceleration: float = 1.0
@export var motion_delta: float = 0.1
@export var lifespan: float = 1.0
@export var scale_texture: bool = true
@export var start_color: Color = Color(1, 1, 1, 1)
@export var end_color: Color = Color(1, 1, 1, 0)


func _ready() -> void:
	old_pos = global_transform.origin
	mesh = ImmediateMesh.new()


func _process(delta: float) -> void:
	var moved: bool = (old_pos - global_transform.origin).length() > motion_delta
	if trail_enabled and moved:
		_append_point()
		old_pos = global_transform.origin
		_dirty = true
	
	var p: int = 0
	var max_points: int = points.size()
	while p < max_points:
		life_points[p] += delta
		if life_points[p] > lifespan:
			_remove_point(p)
			p -= 1
			if p < 0:
				p = 0
			max_points = points.size()
			_dirty = true
		p += 1
	
	if points.size() == 1 and life_points[0] > lifespan:
		_remove_point(0)
		_dirty = true
	
	if points.size() >= 2:
		_dirty = true
	
	if node_ttl > 0.0:
		node_ttl -= delta
		_dirty = true
		if node_ttl <= 0.0 and points.is_empty():
			queue_free()
	
	if not _dirty or points.size() < 2:
		return
	
	_dirty = false
	mesh.clear_surfaces()
	_build_surface()


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
