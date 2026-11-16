extends CanvasLayer
class_name GameUI

signal go_pressed
signal reset_requested
signal edit_placements_requested
signal next_level_requested
signal replay_requested
signal level_select_requested

@onready var tries_label: Label = $ControlsBar/TriesLabel
@onready var btn_go: Button = $ControlsBar/BtnGo
@onready var btn_reset: Button = $ControlsBar/BtnReset
@onready var btn_menu: Button = $ControlsBar/BtnMenu

@onready var victory_panel: Control = $VictoryPanel
@onready var victory_title: Label = $VictoryPanel/Panel/VBoxContainer/VictoryTitle
@onready var btn_next: Button = $VictoryPanel/Panel/VBoxContainer/HBoxContainer/BtnNext
@onready var btn_replay: Button = $VictoryPanel/Panel/VBoxContainer/HBoxContainer/BtnReplay
@onready var btn_victory_select: Button = $VictoryPanel/Panel/VBoxContainer/BtnSelect

@onready var failure_panel: Control = $FailurePanel
@onready var failure_title: Label = $FailurePanel/Panel/VBoxContainer/FailureTitle
@onready var failure_reason: Label = $FailurePanel/Panel/VBoxContainer/FailureReason
@onready var failure_tries_info: Label = $FailurePanel/Panel/VBoxContainer/TriesInfo
@onready var btn_edit: Button = $FailurePanel/Panel/VBoxContainer/HBoxContainer/BtnEdit
@onready var btn_restart: Button = $FailurePanel/Panel/VBoxContainer/HBoxContainer/BtnRestart
@onready var btn_failure_select: Button = $FailurePanel/Panel/VBoxContainer/BtnSelect

func _ready() -> void:
	MusicPlayer.play_go()
	hide_menus()
	btn_go.pressed.connect(func(): go_pressed.emit())
	btn_reset.pressed.connect(func(): reset_requested.emit())
	btn_menu.pressed.connect(func(): level_select_requested.emit())
	
	btn_next.pressed.connect(func():
		hide_menus()
		next_level_requested.emit()
	)
	btn_replay.pressed.connect(func():
		hide_menus()
		replay_requested.emit()
	)
	btn_victory_select.pressed.connect(func():
		hide_menus()
		level_select_requested.emit()
	)
	
	btn_edit.pressed.connect(func():
		hide_menus()
		edit_placements_requested.emit()
	)
	btn_restart.pressed.connect(func():
		hide_menus()
		reset_requested.emit()
	)
	btn_failure_select.pressed.connect(func():
		hide_menus()
		level_select_requested.emit()
	)

func update_tries(tries_left: int, max_tries: int = 3) -> void:
	tries_label.text = "Tries: %d/%d" % [tries_left, max_tries]
	if tries_left <= 1:
		tries_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	else:
		tries_label.modulate = Color(0.9, 0.9, 0.9, 1.0)

func set_go_enabled(enabled: bool) -> void:
	btn_go.disabled = not enabled

func show_victory(is_last_level: bool) -> void:
	hide_menus()
	victory_panel.visible = true
	if is_last_level:
		victory_title.text = "ALL LEVELS CLEARED!"
		btn_next.text = "Level 1"
	else:
		victory_title.text = "VICTORY!"
		btn_next.text = "Next Level"

func show_failure(reason: String, tries_left: int) -> void:
	hide_menus()
	failure_panel.visible = true
	failure_reason.text = reason
	
	if tries_left > 0:
		failure_title.text = "ATTEMPT FAILED"
		failure_tries_info.text = "Tries remaining: %d" % tries_left
		btn_edit.visible = true
		btn_restart.text = "Start Over"
	else:
		failure_title.text = "OUT OF TRIES!"
		failure_tries_info.text = "All 3 attempts used."
		btn_edit.visible = false
		btn_restart.text = "Try Again"

func hide_menus() -> void:
	victory_panel.visible = false
	failure_panel.visible = false
