extends Control

@onready var grid: GridContainer = $VBoxContainer/CenterContainer/GridContainer
@onready var btn_back: Button = $VBoxContainer/BtnBack

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	
	# Connect level buttons
	for i in range(1, 11):
		var btn := grid.get_node_or_null("BtnLevel%d" % i) as Button
		if btn:
			var idx := i - 1
			btn.pressed.connect(func(): _on_level_selected(idx))

func _on_level_selected(level_idx: int) -> void:
	GameState.current_level_index = level_idx
	get_tree().change_scene_to_file("res://main.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
