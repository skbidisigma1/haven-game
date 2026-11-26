extends Node

signal mute_changed(muted: bool)

const LEVELS = preload("res://scripts/levels.gd")
const SAVE_PATH = "user://progress.cfg"
# The pre-level cutscene and the gameplay scene.
const CUTSCENE_SCENE = "res://scenes/StartingCutscene.tscn"
const GAME_SCENE = "res://main.tscn"
var current_level_index: int = 0
var best_shots: Dictionary = {}
var muted: bool = false
var save_path: String = SAVE_PATH
# True when playing through from the Play button: every level gets its cutscene first.
# False when a level was picked from Level Select: levels lead straight into each other.
var story_mode: bool = false

func _ready() -> void:
	var save := ConfigFile.new()
	if save.load(save_path) == OK:
		best_shots = save.get_value("campaign", "best_shots", {})
		muted = save.get_value("audio", "muted", false)
	AudioServer.set_bus_mute(0, muted)

# Goes to the given level: through its cutscene in story mode, straight in otherwise.
func go_to_level(index: int) -> void:
	current_level_index = index
	get_tree().paused = false
	if story_mode:
		SceneTransition.change_scene(CUTSCENE_SCENE)
	else:
		SceneTransition.change_scene(GAME_SCENE)

# Called by the cutscene when it ends: start the level it was introducing.
func cutscene_finished() -> void:
	get_tree().paused = false
	SceneTransition.change_scene(GAME_SCENE)

func complete_level(index: int, shots: int) -> void:
	best_shots[index] = mini(shots, int(best_shots.get(index, 3)))
	save_progress()

func save_progress() -> void:
	var save := ConfigFile.new()
	save.set_value("campaign", "best_shots", best_shots)
	save.set_value("audio", "muted", muted)
	var error := save.save(save_path)
	if error != OK:
		push_warning("Couldn't save progress (%s)." % error_string(error))

func toggle_mute() -> void:
	muted = not muted
	mute_changed.emit(muted)
	AudioServer.set_bus_mute(0, muted)
	save_progress()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		toggle_mute()
		get_viewport().set_input_as_handled()
