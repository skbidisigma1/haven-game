extends CanvasLayer
class_name GameUI

signal go_pressed
signal reset_requested
signal edit_placements_requested
signal next_level_requested
signal replay_requested
signal level_select_requested
signal pause_requested

var root: Control
var level_label: Label
var hint_label: Label
var tries_label: Label
var status_label: Label
var btn_go: Button
var btn_reset: Button
var btn_menu: Button
var overlay: Control
var modal := false
var paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = UIStyle.root(self)
	var bar := ColorRect.new()
	bar.color = UIStyle.INK
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	UIStyle.place(bar, 0, 0, 1152, 96)
	level_label = UIStyle.label(root, "", 23)
	UIStyle.place(level_label, 24, 12, 680, 32)
	hint_label = UIStyle.label(root, "", 14, UIStyle.MUTED)
	UIStyle.place(hint_label, 24, 52, 700, 36)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tries_label = UIStyle.label(root, "", 16, UIStyle.GOLD)
	UIStyle.place(tries_label, 760, 12, 160, 28)
	btn_go = UIStyle.button(root, "Fire / Space", func(): go_pressed.emit())
	UIStyle.place(btn_go, 760, 48, 160, 36)
	btn_go.add_theme_color_override("font_color", UIStyle.MINT)
	btn_reset = UIStyle.button(root, "Reset", func(): reset_requested.emit(), Vector2(90, 36))
	UIStyle.place(btn_reset, 932, 48, 90, 36)
	btn_reset.tooltip_text = "Restore starting positions and all three shots."
	btn_menu = UIStyle.button(root, "Pause", func(): pause_requested.emit(), Vector2(90, 36))
	UIStyle.place(btn_menu, 1034, 48, 90, 36)
	status_label = UIStyle.label(root, "", 14, UIStyle.MINT)
	UIStyle.place(status_label, 932, 12, 200, 28)
	var controls := UIStyle.label(root, "DRAG to place   /   R or right-click to turn   /   Shift+R to turn back   /   Esc pause   /   M sound", 13, UIStyle.MUTED)
	UIStyle.place(controls, 24, 626, 1100, 20)

func set_level(index: int, data: Dictionary) -> void:
	level_label.text = "%02d  /  %s" % [index + 1, data["name"]]
	hint_label.text = data["hint"]

func update_tries(left: int, total: int = 3) -> void:
	tries_label.text = "%d / %d shots left" % [left, total]
	tries_label.modulate = Color("ed9870") if left <= 1 else Color.WHITE

func update_targets(hit: int, total: int) -> void:
	status_label.text = "%d / %d zombies hit" % [hit, total]

func set_go_enabled(enabled: bool) -> void:
	btn_go.disabled = not enabled
	btn_reset.disabled = not enabled

func hide_menus() -> void:
	if is_instance_valid(overlay):
		root.remove_child(overlay)
		overlay.queue_free()
	overlay = null
	modal = false

func _dialog(kicker: String, title: String, message: String) -> VBoxContainer:
	hide_menus()
	modal = true
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.01, 0.03, 0.05, 0.8)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dimmer)
	var panel := PanelContainer.new()
	overlay.add_child(panel)
	UIStyle.place(panel, 288, 152, 576, 360)
	var col := UIStyle.column(panel, 16)
	UIStyle.label(col, kicker, 14, UIStyle.GOLD)
	UIStyle.label(col, title, 32)
	var text := UIStyle.label(col, message, 18, UIStyle.MUTED)
	text.custom_minimum_size = Vector2(540, 110)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.modulate.a = 0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.2)
	return col

func show_victory(last: bool, shots: int, targets: int) -> void:
	var col := _dialog("CLEARED IN %d SHOT%s" % [shots, "" if shots == 1 else "S"], "All levels complete" if last else "Level complete", "All %d zombies hit. No researchers hit." % targets)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var next := UIStyle.button(row, "Level select" if last else "Next level", func(): next_level_requested.emit(), Vector2(270, 44))
	UIStyle.button(row, "Replay level", func(): replay_requested.emit(), Vector2(260, 44))
	if not last:
		UIStyle.button(col, "Level select", func(): level_select_requested.emit())
	next.grab_focus()

func show_failure(reason: String, left: int) -> void:
	var col := _dialog("SHOT SPENT  /  %d LEFT" % left, "Shot missed" if left > 0 else "Out of shots", reason)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var focus: Button
	if left > 0:
		focus = UIStyle.button(row, "Adjust mirrors", func(): edit_placements_requested.emit(), Vector2(270, 44))
	var restart := UIStyle.button(row, "Start over", func(): reset_requested.emit(), Vector2(260, 44))
	if not focus: focus = restart
	UIStyle.button(col, "Level select", func(): level_select_requested.emit())
	focus.grab_focus()

func show_pause() -> void:
	paused = true
	var col := _dialog("", "Paused", "Resume, restart this level, or choose another level.")
	var resume := UIStyle.button(col, "Resume", func(): pause_requested.emit())
	UIStyle.button(col, "Restart level", func(): reset_requested.emit())
	UIStyle.button(col, "Level select", func(): level_select_requested.emit())
	resume.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if event.keycode == KEY_ESCAPE and (not modal or paused):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_SPACE and not modal and not btn_go.disabled:
		go_pressed.emit()
		get_viewport().set_input_as_handled()
