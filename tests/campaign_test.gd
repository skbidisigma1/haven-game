extends SceneTree

var failures: Array[String] = []
var game
var state: Node

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame

func run() -> void:
	state = root.get_node("GameState")
	state.save_path = "user://campaign-test.cfg"
	state.best_shots = {}
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	await settle()
	for i in game.levels.size():
		game.load_level(i)
		await settle()
		var data: Dictionary = game.levels[i]
		var mobile: Array[Platform] = []
		for optic in game.active_platforms:
			if not optic.fixed:
				mobile.append(optic)
				check(optic.placement_is_clear(optic.global_position, optic.rotation), "Room %d starts with overlapping optics" % (i + 1))
		check(mobile.size() == data["solution"].size(), "Room %d has the wrong solution size" % (i + 1))
		for j in mobile.size():
			if data.has("placement_paths"):
				for waypoint in data["placement_paths"][j]:
					mobile[j]._move_to(waypoint)
					await settle()
					check(mobile[j].position == waypoint, "Level %d: a drag path is blocked" % (i + 1))
				for turn in int(data["solution"][j]["rot"] / 45):
					mobile[j].rotate_platform(45)
					await settle()
				check(is_equal_approx(mobile[j].rotation_degrees, data["solution"][j]["rot"]), "Level %d: a required rotation is blocked" % (i + 1))
			else:
				mobile[j].position = data["solution"][j]["pos"]
				mobile[j].rotation_degrees = data["solution"][j]["rot"]
		await settle()
		for optic in mobile:
			check(optic.placement_is_clear(optic.global_position, optic.rotation), "Room %d solution overlaps an obstacle" % (i + 1))
		var beam = game.laser_gun.cast_laser()
		check(beam["hit_zombies"].size() == game.active_zombies.size(), "Room %d: hit %d of %d zombies" % [i + 1, beam["hit_zombies"].size(), game.active_zombies.size()])
		check(beam["hit_humanoids"].is_empty(), "Room %d solution hits a researcher" % (i + 1))
		check(beam["segments"].size() <= 256, "Room %d circuit exceeded trace budget" % (i + 1))
		game._on_go_pressed()
		game._on_go_pressed()
		check(game.tries_left == 2, "Repeated fire consumed multiple shots")
		await create_timer(1.5).timeout
		check(game.current_state == game.State.RESULT, "Room %d did not finish its animated shot" % (i + 1))
		check(state.best_shots.get(i, 0) == 1, "Room %d victory was not saved" % (i + 1))
		print("Room %02d: %d targets, %d beam segments" % [i + 1, beam["hit_zombies"].size(), beam["segments"].size()])
	# Miss, preserve edits, spend the final shot, and refuse an extra edit.
	game.load_level(0)
	await settle()
	game.active_platforms[0].position = Vector2(192, 552)
	for remaining in [2, 1, 0]:
		game._on_go_pressed()
		await create_timer(1.5).timeout
		check(game.tries_left == remaining, "Wrong retry count")
		check(game.current_state == game.State.RESULT, "Miss did not show result")
		game._on_edit_placements_requested()
		if remaining > 0:
			check(game.current_state == game.State.PLANNING, "Retry did not return to planning")
			check(game.active_platforms[0].position == Vector2(192, 552), "Retry discarded a placement")
		else:
			check(game.current_state == game.State.RESULT, "Out-of-shots edit was accepted")
	game._on_reset_requested()
	await settle()
	check(game.tries_left == 3, "Restart did not restore shots")
	check(game.active_platforms[0].position == game.levels[0]["optics"][0]["pos"], "Restart did not restore mirrors")
	# Deliver an entire quick drag in one frame, like a fast mouse gesture.
	root.size = Vector2i(1152, 648)
	var press = InputEventMouseButton.new()
	press.position = Vector2(240, 552)
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	var move = InputEventMouseMotion.new()
	move.position = Vector2(160, 160)
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(move, true)
	var release = InputEventMouseButton.new()
	release.position = move.position
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release, true)
	check(game.active_platforms[0].position == Vector2(160, 160), "Fast drag discarded its movement")
	check(not game.active_platforms[0].is_dragging and Platform.active_dragged_platform == null, "Mouse release left a stuck drag")
	# Regular mirrors must reflect from either side; splitters also pass a branch.
	game.load_level(7)
	await settle()
	var splitter: Platform = game.active_platforms[-1]
	splitter.position = Vector2(896, 432)
	splitter.rotation_degrees = 135
	await settle()
	check(game.laser_gun.cast_laser()["hit_zombies"].size() == 4, "Splitter failed to cover both lower routes")
	splitter.kind = "mirror"
	check(game.laser_gun.cast_laser()["hit_zombies"].size() < 4, "A regular mirror unexpectedly emitted a straight branch")
	splitter.kind = "splitter"
	game.load_level(4)
	await settle()
	# Collision guards include people, walls, other optics, and all rotated corners.
	var mobile: Platform = game.active_platforms[-1]
	check(not mobile.placement_is_clear(Vector2(880, 568), 0), "Placement accepted a researcher overlap")
	check(not mobile.placement_is_clear(Vector2(608, 280), 0), "Placement accepted a wall overlap")
	check(not mobile.placement_is_clear(Vector2(880, 160), 0), "Placement accepted a fixed mirror overlap")
	check(not mobile.placement_is_clear(Vector2(32, 128), PI / 4), "Placement accepted a rotated boundary overlap")
	# Reset during a paused shot must cancel the old shot's pending result.
	game.load_level(0)
	await settle()
	game.active_platforms[0].position = Vector2(320, 160)
	game.active_platforms[0].rotation_degrees = 45
	await settle()
	game.laser_gun.max_bounces = 0
	var capped = game.laser_gun.cast_laser()
	check(capped["hit_zombies"].is_empty(), "Bounce limit invented an outgoing ray")
	check(capped["segments"][-1]["to"].distance_to(Vector2(320, 160)) < 0.1, "Capped beam did not stop at mirror")
	game.laser_gun.max_bounces = 16
	game._on_go_pressed()
	await settle()
	game._toggle_pause()
	check(paused, "Pause did not stop the game")
	game._on_reset_requested()
	await settle()
	await create_timer(1.5).timeout
	check(not paused and game.current_state == game.State.PLANNING and game.tries_left == 3, "Old shot leaked into restarted room")
	var saved = ConfigFile.new()
	check(saved.load(state.save_path) == OK, "Progress file missing")
	check(saved.get_value("campaign", "best_shots", {}).size() == game.levels.size(), "Campaign completion did not persist")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.save_path))
	game.queue_free()
	root.get_node("MusicPlayer").stop_music()
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("PASS: campaign solutions, animated shots, retries, fast mouse input, splitters, reachable late-level solutions, collisions, pause/reset, and save data")
	else:
		printerr("FAILED: %d checks" % failures.size())
	quit(0 if failures.is_empty() else 1)
