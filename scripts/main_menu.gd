extends Control

@onready var btn_play: Button = $VBoxContainer/BtnPlay

func _ready() -> void:
	MusicPlayer.play_menu()
	btn_play.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")
