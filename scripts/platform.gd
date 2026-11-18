extends StaticBody2D
class_name Platform

signal platform_moved
static var active_dragged_platform: Platform
var kind: String = "mirror"
var fixed: bool = false
var can_interact: bool = true
var is_dragging := false
var is_hovered := false
var blocked := false
var drag_offset := Vector2.ZERO
var footprint := RectangleShape2D.new()
var placement_area: Area2D
const GRID: float = 8.0
const ARENA := Rect2(18, 106, 1116, 500)

func _ready() -> void:
	add_to_group("reflectors")
	footprint.size = Vector2(104, 20)
	# Beam geometry is a thin optical surface; placement uses its full housing.
	placement_area = Area2D.new()
	placement_area.collision_layer = 2
	placement_area.collision_mask = 0
	placement_area.input_pickable = false
	var shape := CollisionShape2D.new()
	shape.shape = footprint
	placement_area.add_child(shape)
	add_child(placement_area)
	input_pickable = false
	queue_redraw()

func _exit_tree() -> void:
	if active_dragged_platform == self: active_dragged_platform = null

func stop_drag() -> void:
	is_dragging = false
	blocked = false
	if active_dragged_platform == self: active_dragged_platform = null
	queue_redraw()

func placement_is_clear(at: Vector2, angle: float) -> bool:
	var transform := Transform2D(angle, at)
	for corner in [Vector2(-52, -10), Vector2(52, -10), Vector2(52, 10), Vector2(-52, 10)]:
		if not ARENA.has_point(transform * corner): return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = footprint
	query.transform = transform
	query.exclude = [get_rid(), placement_area.get_rid()]
	query.collide_with_areas = true
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func rotate_platform(angle: float) -> void:
	if fixed or not can_interact: return
	var proposed := snappedf(rotation_degrees + angle, 45.0)
	blocked = not placement_is_clear(global_position, deg_to_rad(proposed))
	if not blocked:
		rotation_degrees = fposmod(proposed, 360.0)
		platform_moved.emit()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	var hovered := Rect2(-56, -14, 112, 28).has_point(to_local(get_global_mouse_position()))
	if hovered != is_hovered:
		is_hovered = hovered
		queue_redraw()
	if not can_interact or fixed:
		if is_dragging: stop_drag()
		return
	if not is_dragging: return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		stop_drag()
		return

func _move_to(pointer: Vector2) -> void:
	var wanted := (pointer + drag_offset).snapped(Vector2(GRID, GRID))
	var start := global_position
	var steps := maxi(1, ceili(start.distance_to(wanted) / GRID))
	blocked = false
	for step in range(1, steps + 1):
		var candidate := start.lerp(wanted, float(step) / steps).snapped(Vector2(GRID, GRID))
		if not placement_is_clear(candidate, rotation):
			blocked = true
			break
		global_position = candidate
	if global_position != start: platform_moved.emit()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if fixed or not can_interact: return
	var pointer := get_global_mouse_position()
	if event is InputEventMouse:
		pointer = get_canvas_transform().affine_inverse() * event.position
	var under_pointer := Rect2(-56, -14, 112, 28).has_point(to_local(pointer))
	if is_dragging and event is InputEventMouseMotion:
		_move_to(pointer)
		get_viewport().set_input_as_handled()
		return
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_move_to(pointer)
		stop_drag()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and under_pointer:
		if event.button_index == MOUSE_BUTTON_RIGHT or (event.button_index == MOUSE_BUTTON_LEFT and event.double_click):
			stop_drag()
			rotate_platform(45)
		elif event.button_index == MOUSE_BUTTON_LEFT and active_dragged_platform == null:
			active_dragged_platform = self
			is_dragging = true
			drag_offset = global_position - pointer
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R and (under_pointer or is_dragging):
		rotate_platform(-45 if event.shift_pressed else 45)
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var accent := Color("8cddd6")
	if kind == "splitter": accent = Color("c09aee")
	if blocked: accent = Color("ed8a71")
	if is_hovered and not fixed:
		draw_rect(Rect2(-56, -14, 112, 28), Color(accent, 0.2))
	draw_rect(Rect2(-52, -8, 104, 16), Color("111e27"))
	draw_rect(Rect2(-48, -5, 96, 10), Color("3c555d"))
	draw_line(Vector2(-48, -5), Vector2(48, -5), accent, 3)
	if kind == "splitter":
		draw_line(Vector2(-36, 4), Vector2(36, 4), accent, 2)
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(0, -7), Vector2(7, 0), Vector2(0, 7)]), accent)
	else:
		draw_line(Vector2(-32, 1), Vector2(-12, 1), accent.darkened(0.4), 2)
		draw_line(Vector2(12, 1), Vector2(32, 1), accent.darkened(0.4), 2)
	for x in [-52, 48]:
		draw_rect(Rect2(x, -10, 4, 20), Color("c9a568") if fixed else Color("748a8b"))
