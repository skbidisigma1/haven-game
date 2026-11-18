extends Node2D

const LAB = preload("res://assets/sprites/lab.png")

func _ready() -> void:
	var boundary := StaticBody2D.new()
	add_child(boundary)
	for rect in [Rect2(0, 92, 1152, 12), Rect2(0, 608, 1152, 12), Rect2(0, 104, 16, 504), Rect2(1136, 104, 16, 504)]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		boundary.add_child(shape)

func _draw() -> void:
	draw_texture_rect(LAB, Rect2(16, 104, 1120, 504), false, Color(0.16, 0.21, 0.23))
	for x in range(32, 1136, 32):
		for y in range(112, 608, 32):
			draw_rect(Rect2(x, y, 2, 2), Color(0.28, 0.37, 0.39, 0.35))
	draw_rect(Rect2(16, 104, 1120, 504), Color(0.28, 0.39, 0.41), false, 2)
	for x in range(16, 1136, 32):
		draw_line(Vector2(x, 610), Vector2(x + 12, 622), Color("c8a469"), 4)
