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

# Art and grab shapes are set up in platform.tscn in the 2D view.
@onready var mirror_sprite: Node2D = get_node_or_null("MirrorSprite")
@onready var splitter_sprite: Node2D = get_node_or_null("SplitterSprite")
@onready var splitter_grab: CollisionPolygon2D = get_node_or_null("SplitterGrab")
@onready var fixed_marker: Node2D = get_node_or_null("FixedMarker")
# A Line2D styled in the editor. The script only moves its two ends:
# straight up from the platform to the ceiling, always vertical.
@onready var rope: Line2D = get_node_or_null("Rope")
# The arena's ceiling (top edge of the play area), in game coordinates.
@export var ceiling_y: float = 104.0

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
	# The grab triangle is only for the mouse. It must never block the laser.
	if splitter_grab: splitter_grab.disabled = true
	_update_look()

func _exit_tree() -> void:
	if active_dragged_platform == self: active_dragged_platform = null

func stop_drag() -> void:
	is_dragging = false
	blocked = false
	if active_dragged_platform == self: active_dragged_platform = null
	_update_look()

func placement_is_clear(at: Vector2, angle: float) -> bool:
	var xform := Transform2D(angle, at)
	for corner in [Vector2(-52, -10), Vector2(52, -10), Vector2(52, 10), Vector2(-52, 10)]:
		if not ARENA.has_point(xform * corner): return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = footprint
	query.transform = xform
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
	_update_look()

func _physics_process(_delta: float) -> void:
	var hovered := _is_under(get_global_mouse_position())
	if hovered != is_hovered:
		is_hovered = hovered
		_update_look()
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
	_update_look()

func _unhandled_input(event: InputEvent) -> void:
	if fixed or not can_interact: return
	var pointer := get_global_mouse_position()
	if event is InputEventMouse:
		pointer = get_canvas_transform().affine_inverse() * event.position
	var under_pointer := _is_under(pointer)
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

# True if the point is over the part you can grab.
# Splitters use the SplitterGrab triangle. Mirrors use a box.
func _is_under(global_point: Vector2) -> bool:
	if kind == "splitter" and splitter_grab:
		return Geometry2D.is_point_in_polygon(splitter_grab.to_local(global_point), splitter_grab.polygon)
	return Rect2(-56, -14, 112, 28).has_point(to_local(global_point))

# Stretches the rope from the ceiling down to the middle of the platform.
# Rounded to whole pixels so a pixel-art rope stays crisp.
func _update_rope() -> void:
	if not rope: return
	var x := roundf(global_position.x)
	var top := Vector2(x, ceiling_y)
	var bottom := Vector2(x, roundf(global_position.y))
	# Points are worked out on screen, then converted into the rotated platform's
	# own space, so the rope stays straight up and down whatever the rotation.
	rope.points = PackedVector2Array([rope.to_local(top), rope.to_local(bottom)])

# Shows the right sprite and tints it. Draws nothing itself.
func _update_look() -> void:
	if mirror_sprite: mirror_sprite.visible = kind != "splitter"
	if splitter_sprite: splitter_sprite.visible = kind == "splitter"
	if fixed_marker: fixed_marker.visible = fixed
	_update_rope()
	if blocked:
		modulate = Color("ed8a71")             # red-orange: can't place here
	elif fixed:
		modulate = Color(0.7, 0.7, 0.7)         # dimmer: locked, can't be moved
	elif is_hovered:
		modulate = Color(1.3, 1.3, 1.3)         # brighter: under the mouse
	else:
		modulate = Color.WHITE
