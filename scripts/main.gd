extends Node2D
class_name GameManager

enum State { PLANNING, FIRING, RESULT }

var current_state: State = State.PLANNING
@export var current_level_index: int = 0
const MAX_TRIES: int = 3
var tries_left: int = 3

@onready var laser_gun: LaserGun = $LaserGun
@onready var level_container: Node2D = $LevelContainer
@onready var ui: GameUI = $UI

var platform_scene: PackedScene = preload("res://scenes/platform.tscn")
var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")
var humanoid_scene: PackedScene = preload("res://scenes/humanoid.tscn")
var wall_scene: PackedScene = preload("res://scenes/obstacle_wall.tscn")

var active_zombies: Array[Node] = []
var active_humanoids: Array[Node] = []
var active_platforms: Array[Node] = []
var initial_platform_states: Array[Dictionary] = []
var last_laser_data: Dictionary = {}

var levels: Array[Dictionary] = [
	# LEVEL 1
	{
		"name": "Level 1: Angle of Attack",
		"description": "Bounce the laser off the platform to eliminate the zombie behind the wall.",
		"gun_pos": Vector2(32, 160),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(360, 320), "rot": 0.0}
		],
		"zombies": [
			Vector2(862, 480)
		],
		"humanoids": [],
		"walls": [
			{"pos": Vector2(580, 460), "size": Vector2(24, 360)}
		]
	},
	# LEVEL 2
	{
		"name": "Level 2: Crossfire Avoidance",
		"description": "A civilian is in the direct line of fire! Route the laser around them to hit both zombies.",
		"gun_pos": Vector2(32, 160),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(240, 320), "rot": 0.0},
			{"pos": Vector2(600, 320), "rot": 0.0}
		],
		"zombies": [
			Vector2(480, 444),
			Vector2(960, 444)
		],
		"humanoids": [
			Vector2(480, 160)
		],
		"walls": [
			{"pos": Vector2(700, 300), "size": Vector2(24, 200)}
		]
	},
	# LEVEL 3
	{
		"name": "Level 3: Tactical Zig-Zag",
		"description": "Navigate a 3-turn zig-zag to eliminate all 3 zombies without harming the civilians.",
		"gun_pos": Vector2(32, 160),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(200, 320), "rot": 0.0},
			{"pos": Vector2(500, 320), "rot": 0.0},
			{"pos": Vector2(800, 320), "rot": 0.0}
		],
		"zombies": [
			Vector2(262, 280),
			Vector2(500, 364),
			Vector2(682, 500)
		],
		"humanoids": [
			Vector2(480, 160),
			Vector2(262, 480)
		],
		"walls": [
			{"pos": Vector2(400, 240), "size": Vector2(24, 180)},
			{"pos": Vector2(760, 440), "size": Vector2(24, 200)}
		]
	},
	# LEVEL 4
	{
		"name": "Level 4: The Corridor Sweep",
		"description": "Loop the laser down and back across the lower floor.",
		"gun_pos": Vector2(32, 160),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(300, 340), "rot": 0.0},
			{"pos": Vector2(650, 340), "rot": 0.0}
		],
		"zombies": [
			Vector2(752, 280),
			Vector2(752, 400),
			Vector2(320, 520)
		],
		"humanoids": [
			Vector2(920, 160),
			Vector2(540, 520)
		],
		"walls": [
			{"pos": Vector2(540, 300), "size": Vector2(24, 240)},
			{"pos": Vector2(860, 360), "size": Vector2(24, 260)}
		]
	},
	# LEVEL 5
	{
		"name": "Level 5: Splitter Alley",
		"description": "Direct the beam around double barricades into fortified targets.",
		"gun_pos": Vector2(32, 160),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(240, 320), "rot": 0.0},
			{"pos": Vector2(500, 320), "rot": 0.0},
			{"pos": Vector2(760, 320), "rot": 0.0}
		],
		"zombies": [
			Vector2(262, 340),
			Vector2(520, 444),
			Vector2(880, 260)
		],
		"humanoids": [
			Vector2(580, 160),
			Vector2(520, 220)
		],
		"walls": [
			{"pos": Vector2(420, 300), "size": Vector2(24, 240)},
			{"pos": Vector2(700, 420), "size": Vector2(24, 260)}
		]
	},
	# LEVEL 6
	{
		"name": "Level 6: The Bunker",
		"description": "Bounce through the central opening to strike the bunker chamber.",
		"gun_pos": Vector2(32, 140),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(240, 260), "rot": 0.0},
			{"pos": Vector2(540, 460), "rot": 0.0},
			{"pos": Vector2(780, 260), "rot": 0.0}
		],
		"zombies": [
			Vector2(400, 260),
			Vector2(682, 380),
			Vector2(920, 380)
		],
		"humanoids": [
			Vector2(650, 140),
			Vector2(400, 480)
		],
		"walls": [
			{"pos": Vector2(520, 180), "size": Vector2(24, 200)},
			{"pos": Vector2(520, 500), "size": Vector2(24, 180)},
			{"pos": Vector2(800, 500), "size": Vector2(24, 180)}
		]
	},
	# LEVEL 7
	{
		"name": "Level 7: Perimeter Sweep",
		"description": "4 platforms! Navigate around all 4 sides of the central civilian zone.",
		"gun_pos": Vector2(32, 140),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(200, 300), "rot": 0.0},
			{"pos": Vector2(450, 300), "rot": 0.0},
			{"pos": Vector2(700, 300), "rot": 0.0},
			{"pos": Vector2(950, 300), "rot": 0.0}
		],
		"zombies": [
			Vector2(880, 140),
			Vector2(862, 320),
			Vector2(540, 500),
			Vector2(262, 500)
		],
		"humanoids": [
			Vector2(550, 280),
			Vector2(550, 380)
		],
		"walls": [
			{"pos": Vector2(400, 330), "size": Vector2(24, 200)},
			{"pos": Vector2(700, 330), "size": Vector2(24, 200)},
			{"pos": Vector2(550, 440), "size": Vector2(280, 24)}
		]
	},
	# LEVEL 8
	{
		"name": "Level 8: The Fortress",
		"description": "Thread between 3 civilians guarding the fortress corridors.",
		"gun_pos": Vector2(32, 160),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(220, 280), "rot": 0.0},
			{"pos": Vector2(480, 400), "rot": 0.0},
			{"pos": Vector2(720, 280), "rot": 0.0},
			{"pos": Vector2(920, 400), "rot": 0.0}
		],
		"zombies": [
			Vector2(262, 300),
			Vector2(520, 444),
			Vector2(740, 260),
			Vector2(960, 444)
		],
		"humanoids": [
			Vector2(480, 160),
			Vector2(740, 444),
			Vector2(262, 480)
		],
		"walls": [
			{"pos": Vector2(380, 260), "size": Vector2(24, 200)},
			{"pos": Vector2(620, 460), "size": Vector2(24, 200)},
			{"pos": Vector2(840, 260), "size": Vector2(24, 200)}
		]
	},
	# LEVEL 9
	{
		"name": "Level 9: Precision Optics",
		"description": "High precision required. Weave through narrow cross-sections.",
		"gun_pos": Vector2(32, 140),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(220, 320), "rot": 0.0},
			{"pos": Vector2(480, 320), "rot": 0.0},
			{"pos": Vector2(720, 320), "rot": 0.0},
			{"pos": Vector2(940, 320), "rot": 0.0}
		],
		"zombies": [
			Vector2(262, 260),
			Vector2(480, 420),
			Vector2(750, 220),
			Vector2(950, 480)
		],
		"humanoids": [
			Vector2(550, 140),
			Vector2(262, 440),
			Vector2(750, 480)
		],
		"walls": [
			{"pos": Vector2(360, 360), "size": Vector2(24, 240)},
			{"pos": Vector2(640, 220), "size": Vector2(24, 200)},
			{"pos": Vector2(850, 380), "size": Vector2(24, 240)}
		]
	},
	# LEVEL 10
	{
		"name": "Level 10: Grand Circuit",
		"description": "The Master Circuit. 5 movable platforms, 5 zombies, 3 civilians. Full perimeter mastery.",
		"gun_pos": Vector2(32, 140),
		"gun_rot": 0.0,
		"platforms": [
			{"pos": Vector2(180, 340), "rot": 0.0},
			{"pos": Vector2(380, 340), "rot": 0.0},
			{"pos": Vector2(580, 340), "rot": 0.0},
			{"pos": Vector2(780, 340), "rot": 0.0},
			{"pos": Vector2(980, 340), "rot": 0.0}
		],
		"zombies": [
			Vector2(262, 280),
			Vector2(460, 480),
			Vector2(700, 240),
			Vector2(880, 480),
			Vector2(1000, 240)
		],
		"humanoids": [
			Vector2(460, 140),
			Vector2(700, 480),
			Vector2(262, 500)
		],
		"walls": [
			{"pos": Vector2(360, 240), "size": Vector2(24, 200)},
			{"pos": Vector2(580, 440), "size": Vector2(24, 220)},
			{"pos": Vector2(800, 240), "size": Vector2(24, 200)},
			{"pos": Vector2(920, 440), "size": Vector2(24, 220)}
		]
	}
]

func _ready() -> void:
	MusicPlayer.play_build()
	if GameState:
		current_level_index = GameState.current_level_index
	
	laser_gun.shooting_finished.connect(_on_shooting_finished)
	ui.go_pressed.connect(_on_go_pressed)
	ui.reset_requested.connect(_on_reset_requested)
	ui.edit_placements_requested.connect(_on_edit_placements_requested)
	ui.next_level_requested.connect(_on_next_level_requested)
	ui.replay_requested.connect(_on_reset_requested)
	ui.level_select_requested.connect(_on_level_select_requested)
	
	load_level(current_level_index)

func load_level(index: int) -> void:
	current_level_index = clampi(index, 0, levels.size() - 1)
	if GameState:
		GameState.current_level_index = current_level_index
	
	tries_left = MAX_TRIES
	current_state = State.PLANNING
	Platform.active_dragged_platform = null
	
	laser_gun.clear_laser()
	
	for child in level_container.get_children():
		child.queue_free()
	
	active_zombies.clear()
	active_humanoids.clear()
	active_platforms.clear()
	initial_platform_states.clear()
	last_laser_data.clear()
	
	var data: Dictionary = levels[current_level_index]
	
	laser_gun.global_position = data.get("gun_pos", Vector2(32, 160))
	laser_gun.global_rotation = data.get("gun_rot", 0.0)
	
	# Spawn walls
	for wall_info in data.get("walls", []):
		var wall: ObstacleWall = wall_scene.instantiate()
		level_container.add_child(wall)
		wall.position = wall_info["pos"]
		wall.wall_size = wall_info.get("size", Vector2(24, 200))
	
	# Spawn platforms
	for plat_info in data.get("platforms", []):
		var plat: Platform = platform_scene.instantiate()
		plat.position = plat_info["pos"]
		plat.rotation_degrees = plat_info.get("rot", 0.0)
		plat.can_interact = true
		level_container.add_child(plat)
		active_platforms.append(plat)
		initial_platform_states.append({
			"pos": plat.position,
			"rot": plat.rotation_degrees
		})
	
	# Spawn zombies
	for z_pos in data.get("zombies", []):
		var zombie: Target = zombie_scene.instantiate()
		zombie.position = z_pos
		level_container.add_child(zombie)
		active_zombies.append(zombie)
	
	# Spawn humanoids
	for h_pos in data.get("humanoids", []):
		var human: Target = humanoid_scene.instantiate()
		human.position = h_pos
		level_container.add_child(human)
		active_humanoids.append(human)
	
	ui.hide_menus()
	ui.update_tries(tries_left, MAX_TRIES)
	ui.set_go_enabled(true)

func _on_go_pressed() -> void:
	$LaserSound.play()
	MusicPlayer.play_go()
	if current_state != State.PLANNING:
		return
	
	current_state = State.FIRING
	tries_left -= 1
	ui.update_tries(tries_left, MAX_TRIES)
	ui.set_go_enabled(false)
	
	# Lock platform interactions during laser shoot
	for plat in active_platforms:
		if is_instance_valid(plat):
			plat.can_interact = false
	
	# Reset target hit colors before laser sweeps
	for z in active_zombies:
		if is_instance_valid(z) and z.has_method("set_hit"):
			z.set_hit(false)
	for h in active_humanoids:
		if is_instance_valid(h) and h.has_method("set_hit"):
			h.set_hit(false)
	
	# Gradually shoot laser over ~0.25s
	last_laser_data = laser_gun.fire_laser(0.25)

func _on_shooting_finished(laser_data: Dictionary) -> void:
	last_laser_data = laser_data
	
	# Wait 0.4s for player to clearly see full trajectory outcome
	await get_tree().create_timer(0.4).timeout
	
	_evaluate_result()

func _evaluate_result() -> void:
	if current_state != State.FIRING:
		return
	current_state = State.RESULT
	
	var hit_zombies: Array = last_laser_data.get("hit_zombies", [])
	var hit_humanoids: Array = last_laser_data.get("hit_humanoids", [])
	
	var total_zombies := active_zombies.size()
	var z_hit_count := hit_zombies.size()
	var h_hit_count := hit_humanoids.size()
	
	if h_hit_count > 0:
		ui.show_failure("Civilian in line of fire!", tries_left)
	elif z_hit_count >= total_zombies:
		var is_last := (current_level_index >= levels.size() - 1)
		ui.show_victory(is_last)
	else:
		ui.show_failure("Not all zombies were eliminated!", tries_left)

func _on_edit_placements_requested() -> void:
	MusicPlayer.play_build()
	# Keep platform positions as-is, reset laser and target colors
	laser_gun.clear_laser()
	for z in active_zombies:
		if is_instance_valid(z) and z.has_method("set_hit"):
			z.set_hit(false)
	for h in active_humanoids:
		if is_instance_valid(h) and h.has_method("set_hit"):
			h.set_hit(false)
	for plat in active_platforms:
		if is_instance_valid(plat):
			plat.can_interact = true
	
	current_state = State.PLANNING
	ui.hide_menus()
	ui.set_go_enabled(true)

func _on_reset_requested() -> void:
	MusicPlayer.play_build()
	# Reset platforms to initial default positions
	tries_left = MAX_TRIES
	ui.update_tries(tries_left, MAX_TRIES)
	
	for i in range(mini(active_platforms.size(), initial_platform_states.size())):
		var plat: Platform = active_platforms[i]
		if is_instance_valid(plat):
			plat.position = initial_platform_states[i]["pos"]
			plat.rotation_degrees = initial_platform_states[i]["rot"]
			plat.can_interact = true
	
	_on_edit_placements_requested()

func _on_next_level_requested() -> void:
	MusicPlayer.play_build()
	if current_level_index < levels.size() - 1:
		current_level_index += 1
		load_level(current_level_index)
	else:
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_level_select_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")
