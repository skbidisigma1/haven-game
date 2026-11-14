extends Area2D
class_name Target

enum Type { ZOMBIE, HUMANOID }

@export var target_type: Type = Type.ZOMBIE
@export var target_size: Vector2 = Vector2(46, 46)

var is_hit: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	add_to_group("targets")
	if target_type == Type.ZOMBIE:
		add_to_group("zombies")
	else:
		add_to_group("humanoids")
	
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect := collision_shape.shape as RectangleShape2D
		rect.size = target_size
	
	if color_rect:
		color_rect.offset_left = -target_size.x / 2.0
		color_rect.offset_top = -target_size.y / 2.0
		color_rect.offset_right = target_size.x / 2.0
		color_rect.offset_bottom = target_size.y / 2.0
	
	set_hit(false)

func set_hit(hit: bool) -> void:
	is_hit = hit
	if not color_rect:
		return
	
	if target_type == Type.ZOMBIE:
		if is_hit:
			color_rect.color = Color(0.9, 0.15, 0.15, 1.0) # Hit zombie turns red
		else:
			color_rect.color = Color(0.2, 0.8, 0.2, 1.0) # Unhit zombie is green
	else:
		if is_hit:
			color_rect.color = Color(0.9, 0.15, 0.15, 1.0) # Hit civilian turns red
		else:
			color_rect.color = Color(0.2, 0.5, 0.9, 1.0) # Safe civilian is blue
