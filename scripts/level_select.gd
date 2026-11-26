extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIStyle.theme()
	UIStyle.backdrop(self)
	UIStyle.place(UIStyle.label(self, "Level select", 48), 72, 78, 900, 70)
	UIStyle.place(UIStyle.label(self, "Hit all zombies in a single shot without hitting a researcher.", 18, UIStyle.MUTED), 72, 158, 1000, 32)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 18)
	add_child(grid)
	UIStyle.place(grid, 72, 230, 1008, 256)
	var levels := GameState.LEVELS.all()
	for i in levels.size():
		var record := "Not cleared"
		if GameState.best_shots.has(i): record = "Clear / %d shot%s" % [GameState.best_shots[i], "" if GameState.best_shots[i] == 1 else "s"]
		var button := UIStyle.button(grid, "%02d
%s

%s" % [i + 1, levels[i]["name"], record], _select.bind(i), Vector2(190, 120))
		button.add_theme_font_size_override("font_size", 15)
		if GameState.best_shots.has(i): button.add_theme_color_override("font_color", UIStyle.MINT)
		if i == 0: button.grab_focus()
	var back := UIStyle.button(self, "← Back to title", func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	UIStyle.place(back, 72, 548, 200, 44)
	UIStyle.place(UIStyle.label(self, "%d / %d levels complete" % [GameState.best_shots.size(), levels.size()], 18, UIStyle.MINT), 800, 554, 280, 32)
	MusicPlayer.play_menu()

func _select(index: int) -> void:
	GameState.current_level_index = index
	GameState.story_mode = false
	GameState.go_to_level(index)
