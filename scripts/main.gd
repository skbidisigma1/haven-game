extends Node2D
class_name GameManager

enum State { SPAWNING, PLANNING, FIRING, RESULT }
const MAX_TRIES := 3
# Where the laser gun sits, and which way it fires (90 = straight down).
const GUN_POSITION := Vector2(576, 120)
const GUN_ROTATION_DEGREES := 90.0
# Seconds the laser waits after the last zombie is out before it fires.
const ZOMBIE_REVEAL_DELAY := 1.0
const LEVEL_DATA = preload("res://scripts/levels.gd")
const PLATFORM = preload("res://scenes/platform.tscn")
const ZOMBIE = preload("res://scenes/zombie.tscn")
const HUMAN = preload("res://scenes/humanoid.tscn")
const WALL = preload("res://scenes/obstacle_wall.tscn")
var levels: Array[Dictionary] = LEVEL_DATA.all()
var current_level_index := 0
var current_state := State.SPAWNING
var tries_left := MAX_TRIES
var active_zombies: Array[Target] = []
var active_humanoids: Array[Target] = []
var active_platforms: Array[Platform] = []
var last_laser_data: Dictionary = {}
var generation := 0
var test_mode := false
@onready var laser_gun: LaserGun = $LaserGun
@onready var level_container: Node2D = $LevelContainer
@onready var ui: GameUI = $UI

func _ready() -> void:
	ui.go_pressed.connect(_on_go_pressed)
	ui.reset_requested.connect(_on_reset_requested)
	ui.edit_placements_requested.connect(_on_edit_placements_requested)
	ui.next_level_requested.connect(_on_next_level_requested)
	ui.replay_requested.connect(_on_reset_requested)
	ui.level_select_requested.connect(_on_level_select_requested)
	ui.pause_requested.connect(_toggle_pause)
	laser_gun.shooting_finished.connect(_on_shooting_finished)
	laser_gun.target_struck.connect(func(_target: Node): _update_targets())
	load_level(GameState.current_level_index)

func load_level(index: int) -> void:
	generation += 1
	get_tree().paused = false
	ui.paused = false
	ui.hide_menus()
	current_level_index = clampi(index, 0, levels.size() - 1)
	GameState.current_level_index = current_level_index
	current_state = State.SPAWNING
	tries_left = MAX_TRIES
	Platform.active_dragged_platform = null
	laser_gun.clear_laser()
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()
	active_zombies.clear()
	active_humanoids.clear()
	active_platforms.clear()
	last_laser_data.clear()
	var data: Dictionary = levels[current_level_index]
	laser_gun.position = GUN_POSITION
	laser_gun.rotation_degrees = GUN_ROTATION_DEGREES
	for info in data["walls"]:
		var wall: ObstacleWall = WALL.instantiate()
		wall.position = info["pos"]
		wall.wall_size = info["size"]
		level_container.add_child(wall)
	for info in data["optics"]:
		var optic: Platform = PLATFORM.instantiate()
		optic.position = info["pos"]
		optic.rotation_degrees = info["rot"]
		optic.kind = info["kind"]
		optic.fixed = info["fixed"]
		optic.pivot = info.get("pivot", false)
		optic.can_interact = false
		level_container.add_child(optic)
		active_platforms.append(optic)
	# Zombies start hidden inside their wall cracks (Target handles that itself).
	for pos in data["zombies"]:
		var target: Target = ZOMBIE.instantiate()
		target.position = pos
		level_container.add_child(target)
		active_zombies.append(target)
	for pos in data["humans"]:
		var target: Target = HUMAN.instantiate()
		target.position = pos
		level_container.add_child(target)
		active_humanoids.append(target)
	ui.set_level(current_level_index, data)
	ui.update_tries(tries_left)
	ui.update_targets(0, active_zombies.size())
	ui.set_go_enabled(false)
	MusicPlayer.play_build()
	_enter_planning()

func _enter_planning() -> void:
	current_state = State.PLANNING
	for optic in active_platforms: optic.can_interact = true
	ui.set_go_enabled(true)

func _on_go_pressed() -> void:
	if current_state != State.PLANNING or get_tree().paused: return
	current_state = State.FIRING
	tries_left -= 1
	ui.update_tries(tries_left)
	ui.set_go_enabled(false)
	for optic in active_platforms:
		optic.stop_drag()
		optic.can_interact = false
	MusicPlayer.play_go()
	var this_generation := generation
	# Zombies climb out of their cracks one at a time, each waiting for the one before.
	for zombie in active_zombies:
		if test_mode: zombie.pop_out()
		else: await zombie.pop_out()
		if this_generation != generation or current_state != State.FIRING: return
	# Then the laser waits a beat before firing.
	if not test_mode:
		await get_tree().create_timer(ZOMBIE_REVEAL_DELAY, false).timeout
	if this_generation != generation or current_state != State.FIRING: return
	# Wait for the physics server to see a mirror moved on this input frame.
	await get_tree().physics_frame
	if this_generation != generation or current_state != State.FIRING: return
	$LaserSound.play()
	last_laser_data = laser_gun.fire_laser()

func _on_shooting_finished(data: Dictionary) -> void:
	last_laser_data = data
	var this_generation := generation
	await get_tree().create_timer(0.5, false).timeout
	if this_generation == generation: _evaluate_result()

func _update_targets() -> void:
	var count := 0
	for target in active_zombies:
		if target.is_hit: count += 1
	ui.update_targets(count, active_zombies.size())

func _evaluate_result() -> void:
	if current_state != State.FIRING: return
	current_state = State.RESULT
	var hits: Array = last_laser_data.get("hit_zombies", [])
	var civilians: Array = last_laser_data.get("hit_humanoids", [])
	if not civilians.is_empty():
		MusicPlayer.play_build()
		ui.show_failure("A researcher was hit. Keep every beam branch clear of researchers.", tries_left)
	elif hits.size() == active_zombies.size():
		GameState.complete_level(current_level_index, MAX_TRIES - tries_left)
		MusicPlayer.play_victory()
		ui.show_victory(current_level_index == levels.size() - 1, MAX_TRIES - tries_left, active_zombies.size())
	else:
		MusicPlayer.play_build()
		var missing := active_zombies.size() - hits.size()
		ui.show_failure("%d zombie%s missed. The beam stays on screen so you can see where it stopped." % [missing, "" if missing == 1 else "s"], tries_left)

func _on_edit_placements_requested() -> void:
	if current_state != State.RESULT or tries_left <= 0: return
	ui.hide_menus()
	laser_gun.clear_laser()
	for target in active_zombies + active_humanoids: target.set_hit(false)
	# Zombies duck back into their cracks until the next shot.
	for target in active_zombies: target.hide_in_crack()
	_update_targets()
	MusicPlayer.play_build()
	_enter_planning()

func _on_reset_requested() -> void:
	get_tree().paused = false
	ui.paused = false
	# Reload the same level behind the line wipe.
	SceneTransition.cover(func(): load_level(current_level_index))

func _on_next_level_requested() -> void:
	if current_level_index < levels.size() - 1:
		if GameState.story_mode:
			# Playing through from the start: show the next level's cutscene first.
			generation += 1
			GameState.go_to_level(current_level_index + 1)
		else:
			var next := current_level_index + 1
			SceneTransition.cover(func(): load_level(next))
	else:
		_on_level_select_requested()

func _toggle_pause() -> void:
	if current_state == State.RESULT and not ui.paused: return
	if current_state == State.SPAWNING: return
	if get_tree().paused:
		get_tree().paused = false
		ui.paused = false
		ui.hide_menus()
	else:
		for optic in active_platforms: optic.stop_drag()
		get_tree().paused = true
		ui.show_pause()

func _on_level_select_requested() -> void:
	generation += 1
	# Leaving for Level Select ends the play-through.
	GameState.story_mode = false
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/level_select.tscn")
