extends AnimatableBody2D
class_name Platform

signal platform_moved

static var active_dragged_platform: Node = null

@export var platform_size: Vector2 = Vector2(130, 24)
@export var min_bounds: Vector2 = Vector2(80, 100)
@export var max_bounds: Vector2 = Vector2(1072, 600)

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var is_hovered: bool = false
var can_interact: bool = true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	add_to_group("reflectors")
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	sync_to_physics = false
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_setup_visuals()

func _on_mouse_entered() -> void:
	is_hovered = true

func _on_mouse_exited() -> void:
	is_hovered = false

func _setup_visuals() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape := collision_shape.shape as RectangleShape2D
		rect_shape.size = platform_size
	
	if color_rect:
		color_rect.offset_left = -platform_size.x / 2.0
		color_rect.offset_top = -platform_size.y / 2.0
		color_rect.offset_right = platform_size.x / 2.0
		color_rect.offset_bottom = platform_size.y / 2.0

func rotate_platform(angle_deg: float) -> void:
	rotation_degrees = fmod(round(rotation_degrees + angle_deg), 360.0)
	platform_moved.emit()

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not can_interact:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.double_click:
					# Double click rotates 45 degrees
					rotate_platform(45.0)
					is_dragging = false
					if active_dragged_platform == self:
						active_dragged_platform = null
					get_viewport().set_input_as_handled()
				else:
					if active_dragged_platform == null:
						active_dragged_platform = self
						is_dragging = true
						drag_offset = global_position - get_global_mouse_position()
						get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			rotate_platform(45.0)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not can_interact:
		is_dragging = false
		if active_dragged_platform == self:
			active_dragged_platform = null
		return
	
	if is_dragging:
		if event is InputEventMouseMotion:
			var target_pos := get_global_mouse_position() + drag_offset
			target_pos.x = clampf(target_pos.x, min_bounds.x, max_bounds.x)
			target_pos.y = clampf(target_pos.y, min_bounds.y, max_bounds.y)
			global_position = target_pos
			platform_moved.emit()
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				is_dragging = false
				if active_dragged_platform == self:
					active_dragged_platform = null
	
	if can_interact and (is_hovered or is_dragging):
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_R:
				rotate_platform(45.0)
				get_viewport().set_input_as_handled()
