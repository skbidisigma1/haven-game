extends StaticBody2D
class_name Platform

signal platform_moved
static var active_dragged_platform: Platform
var kind: String = "mirror"
var fixed: bool = false
# A pivot is small, stays where the level puts it, and can only be turned (8 directions).
var pivot: bool = false
var can_interact: bool = true
var is_dragging := false
var is_hovered := false
var blocked := false
var drag_offset := Vector2.ZERO
var footprint := RectangleShape2D.new()
var placement_area: Area2D
const GRID: float = 8.0
const ARENA := Rect2(18, 106, 1116, 500)

# Size of the housing used for placement and grabbing (the beam uses the CollisionShape2Ds).
@export var mirror_length: float = 104.0
@export var pivot_length: float = 56.0
const HOUSING_THICKNESS := 20.0

# Art and shapes are set up in platform.tscn in the 2D view.
@onready var mirror_sprite: Node2D = get_node_or_null("MirrorSprite")
@onready var splitter_sprite: Node2D = get_node_or_null("SplitterSprite")
@onready var pivot_sprite: Node2D = get_node_or_null("PivotSprite")
@onready var pivot_splitter_sprite: Node2D = get_node_or_null("PivotSplitterSprite")
# Art behind a pivot (a mount or bracket). Only shown on pivots, and it never turns.
@onready var pivot_base: Node2D = get_node_or_null("PivotBase")
@onready var splitter_grab: CollisionPolygon2D = get_node_or_null("SplitterGrab")
@onready var fixed_marker: Node2D = get_node_or_null("FixedMarker")
# The beam surfaces: the normal long one, and the short one used by pivots.
@onready var mirror_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var pivot_shape: CollisionShape2D = get_node_or_null("PivotShape")
# A Line2D styled in the editor. The script only moves its two ends:
# straight up from the platform to the ceiling, always vertical.
@onready var rope: Line2D = get_node_or_null("Rope")
# The arena's ceiling (top edge of the play area), in game coordinates.
@export var ceiling_y: float = 104.0

func _ready() -> void:
	add_to_group("reflectors")
	footprint.size = Vector2(_length(), HOUSING_THICKNESS)
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
	# Only one beam surface is active: the short one for pivots, the long one otherwise.
	if mirror_shape: mirror_shape.disabled = pivot
	if pivot_shape: pivot_shape.disabled = not pivot
	_update_look()

func _exit_tree() -> void:
	if active_dragged_platform == self: active_dragged_platform = null

func _length() -> float:
	return pivot_length if pivot else mirror_length

func stop_drag() -> void:
	is_dragging = false
	blocked = false
	if active_dragged_platform == self: active_dragged_platform = null
	_update_look()

func placement_is_clear(at: Vector2, angle: float) -> bool:
	var xform := Transform2D(angle, at)
	var half := Vector2(_length() / 2.0, HOUSING_THICKNESS / 2.0)
	for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
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
	if not can_interact or fixed or pivot:
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
		if pivot:
			# Pivots can't be dragged: left-click turns them one way, right-click the other.
			if event.button_index == MOUSE_BUTTON_LEFT:
				rotate_platform(45)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				rotate_platform(-45)
		elif event.button_index == MOUSE_BUTTON_RIGHT or (event.button_index == MOUSE_BUTTON_LEFT and event.double_click):
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
# Full-size splitters use the SplitterGrab triangle. Everything else uses a box sized to the platform.
func _is_under(global_point: Vector2) -> bool:
	if kind == "splitter" and not pivot and splitter_grab:
		return Geometry2D.is_point_in_polygon(splitter_grab.to_local(global_point), splitter_grab.polygon)
	var half := _length() / 2.0 + 4.0
	return Rect2(-half, -14, half * 2.0, 28).has_point(to_local(global_point))

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
	var is_splitter := kind == "splitter"
	if mirror_sprite: mirror_sprite.visible = not pivot and not is_splitter
	if splitter_sprite: splitter_sprite.visible = not pivot and is_splitter
	if pivot_sprite: pivot_sprite.visible = pivot and (not is_splitter or pivot_splitter_sprite == null)
	if pivot_splitter_sprite: pivot_splitter_sprite.visible = pivot and is_splitter
	if fixed_marker: fixed_marker.visible = fixed
	if pivot_base:
		pivot_base.visible = pivot
		# Cancel out the platform's rotation so the base always stays upright.
		pivot_base.global_rotation = 0.0
	# Pivots sit on their base instead of hanging from a rope.
	if rope: rope.visible = not pivot
	_update_rope()
	if blocked:
		modulate = Color("ed8a71")             # red-orange: can't turn/place here
	elif fixed:
		modulate = Color(0.7, 0.7, 0.7)         # dimmer: locked, can't be moved
	elif is_hovered:
		modulate = Color(1.3, 1.3, 1.3)         # brighter: under the mouse
	else:
		modulate = Color.WHITE
