extends StaticBody2D
class_name ObstacleWall

var wall_size := Vector2(24, 200)

func _ready() -> void:
	add_to_group("walls")
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	$CollisionShape2D.shape = shape
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(-wall_size / 2, wall_size)
	draw_rect(rect.grow(3), Color("101b22"))
	draw_rect(rect, Color("536365"))
	draw_rect(rect.grow(-4), Color("35474b"))
	var along_y := wall_size.y > wall_size.x
	var length: float = wall_size.y if along_y else wall_size.x
	for i in range(12, int(length), 24):
		var point := Vector2(0, -length / 2 + i) if along_y else Vector2(-length / 2 + i, 0)
		draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), Color("9ca797"))
