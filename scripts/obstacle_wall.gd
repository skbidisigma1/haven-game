extends StaticBody2D
class_name ObstacleWall

@export var wall_size: Vector2 = Vector2(24, 200):
	set(value):
		wall_size = value
		if is_node_ready():
			_update_size()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	add_to_group("walls")
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	_update_size()

func _update_size() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect := collision_shape.shape as RectangleShape2D
		rect.size = wall_size
	
	if color_rect:
		color_rect.offset_left = -wall_size.x / 2.0
		color_rect.offset_top = -wall_size.y / 2.0
		color_rect.offset_right = wall_size.x / 2.0
		color_rect.offset_bottom = wall_size.y / 2.0
