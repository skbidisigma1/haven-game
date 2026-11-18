extends RefCounted
class_name UIStyle

const INK := Color("101e28")
const PAPER := Color("e9e3d0")
const MUTED := Color("99b0af")
const MINT := Color("8cddd0")
const GOLD := Color("d5af6c")

static func box(color: Color, border: Color = Color.TRANSPARENT, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(3)
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_color("font_color", "Label", PAPER)
	result.set_color("font_color", "Button", PAPER)
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_focus_color", "Button", Color.WHITE)
	result.set_color("font_disabled_color", "Button", Color("647877"))
	result.set_stylebox("normal", "Button", box(Color("203640"), Color("526c70")))
	result.set_stylebox("hover", "Button", box(Color("31545a"), MINT))
	result.set_stylebox("pressed", "Button", box(Color("172b34"), GOLD))
	result.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), GOLD, 2))
	result.set_stylebox("disabled", "Button", box(Color("17272f"), Color("2c4046")))
	result.set_stylebox("panel", "PanelContainer", box(INK, Color("647d7c")))
	return result

static func root(parent: Node) -> Control:
	var control := Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.theme = theme()
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	return control

static func label(parent: Node, text: String, size: int = 16, color: Color = PAPER) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, callback: Callable, minimum := Vector2(120, 42)) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = minimum
	node.pressed.connect(callback)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(node)
	return node

static func place(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)

static func backdrop(parent: Control) -> void:
	var background := ColorRect.new()
	background.color = Color("0c1821")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(background)
	var texture := TextureRect.new()
	texture.texture = preload("res://assets/sprites/lab.png")
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.modulate = Color(0.15, 0.23, 0.25)
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture)

static func column(parent: Node, separation: int = 12) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node
