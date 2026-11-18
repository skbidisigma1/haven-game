extends Control

var sound_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIStyle.theme()
	UIStyle.backdrop(self)
	var title := UIStyle.label(self, "Z-BEAM", 96)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyle.place(title, 176, 144, 800, 120)
	var objective := UIStyle.label(self, "Hit every zombie. Avoid the researchers.", 20, UIStyle.MUTED)
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyle.place(objective, 176, 272, 800, 36)
	var has_progress := not GameState.best_shots.is_empty() and GameState.best_shots.size() < GameState.LEVELS.all().size()
	var play := UIStyle.button(self, "Continue" if has_progress else "Play", _play, Vector2(240, 48))
	UIStyle.place(play, 456, 344, 240, 48)
	var levels := UIStyle.button(self, "Level select", _levels, Vector2(240, 48))
	UIStyle.place(levels, 456, 408, 240, 48)
	sound_button = UIStyle.button(self, "", GameState.toggle_mute, Vector2(240, 48))
	_on_mute_changed(GameState.muted)
	GameState.mute_changed.connect(_on_mute_changed)
	UIStyle.place(sound_button, 456, 472, 240, 48)
	MusicPlayer.play_menu()
	play.grab_focus()

func _play() -> void:
	GameState.current_level_index = 0
	for i in GameState.LEVELS.all().size():
		if not GameState.best_shots.has(i):
			GameState.current_level_index = i
			break
	get_tree().change_scene_to_file("res://main.tscn")

func _levels() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_mute_changed(muted: bool) -> void:
	sound_button.text = "Sound: off" if muted else "Sound: on"
