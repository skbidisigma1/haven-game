extends Node

signal mute_changed(muted: bool)

const LEVELS = preload("res://scripts/levels.gd")
const SAVE_PATH = "user://progress.cfg"
var current_level_index: int = 0
var best_shots: Dictionary = {}
var muted: bool = false
var save_path: String = SAVE_PATH

func _ready() -> void:
	var save := ConfigFile.new()
	if save.load(save_path) == OK:
		best_shots = save.get_value("campaign", "best_shots", {})
		muted = save.get_value("audio", "muted", false)
	AudioServer.set_bus_mute(0, muted)

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
