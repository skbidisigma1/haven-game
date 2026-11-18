extends Area2D
class_name Target

enum Type { ZOMBIE, HUMANOID }
@export var target_type: Type = Type.ZOMBIE
var is_hit := false
var emergence: float = 0.0
var appearance: Tween
const ZOMBIE = preload("res://assets/sprites/zombie.png")
var idle_time := 0.0

func _ready() -> void:
	add_to_group("targets")
	add_to_group("zombies" if target_type == Type.ZOMBIE else "humanoids")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 40)
	$CollisionShape2D.shape = shape
	if target_type == Type.HUMANOID:
		emergence = 1.0

func emerge(delay: float) -> void:
	emergence = 0.0
	if appearance: appearance.kill()
	appearance = create_tween()
	appearance.tween_interval(delay)
	appearance.tween_property(self, "emergence", 1.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	idle_time += delta
	queue_redraw()

func set_hit(hit: bool) -> void:
	is_hit = hit
	queue_redraw()

func _draw() -> void:
	if target_type == Type.ZOMBIE:
		draw_colored_polygon(PackedVector2Array([Vector2(-26, 17), Vector2(-12, 10), Vector2(-4, 16), Vector2(8, 9), Vector2(26, 17), Vector2(10, 24), Vector2(-10, 22)]), Color("080e13"))
		draw_polyline(PackedVector2Array([Vector2(-24, 18), Vector2(-10, 14), Vector2(0, 19), Vector2(12, 13), Vector2(24, 17)]), Color("df8052") if not is_hit else Color("72cabb"), 2)
		if emergence < 0.05: return
		var frame := int(idle_time * 4) % 3
		var source := Rect2(Vector2((frame % 2) * 64, (frame / 2) * 64), Vector2(64, 64))
		var height := 64.0 * clampf(emergence, 0, 1)
		source.size.y = height
		var tint := Color("70e1cb") if is_hit else Color.WHITE
		if is_hit: tint.a = 0.28
		draw_texture_rect_region(ZOMBIE, Rect2(-32, 22 - height, 64, height), source, tint)
		if is_hit:
			draw_line(Vector2(-12, -12), Vector2(-3, -3), Color("83f1d0"), 3)
			draw_line(Vector2(-3, -3), Vector2(16, -22), Color("83f1d0"), 3)
	else:
		# A lab coat, badge, and square safety glasses, all on the same 2px grid.
		var coat := Color("e5dfc8") if not is_hit else Color("ef8c73")
		draw_rect(Rect2(-14, 18, 28, 5), Color("10232b"))
		draw_rect(Rect2(-8, 8, 6, 14), Color("587e8c"))
		draw_rect(Rect2(4, 8, 6, 14), Color("587e8c"))
		draw_rect(Rect2(-12, -10, 26, 24), coat)
		draw_rect(Rect2(-4, -12, 8, 20), Color("559d9b"))
		draw_rect(Rect2(-18, -6, 6, 18), coat)
		draw_rect(Rect2(14, -6, 6, 18), coat)
		draw_rect(Rect2(-8, -28, 18, 18), Color("c49170"))
		draw_rect(Rect2(-10, -30, 22, 6), Color("433d3c"))
		draw_rect(Rect2(-10, -22, 22, 6), Color("9edfdc"))
		draw_rect(Rect2(0, -22, 2, 6), Color("433d3c"))
		draw_rect(Rect2(6, -4, 6, 6), Color("d9b56c"))
		if is_hit:
			draw_line(Vector2(-22, -32), Vector2(22, 24), Color("ffac8c"), 3)
			draw_line(Vector2(22, -32), Vector2(-22, 24), Color("ffac8c"), 3)
