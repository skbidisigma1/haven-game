extends Node2D

const ROAD_ZOMBIE = preload("res://assets/CutsceneAssets/Zombie.tscn")

@onready var truck: CharacterBody2D = $CharacterBody2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var dialogue_box: CanvasLayer = $DialogueBox

const CUTSCENE_SCENE = "res://scenes/StartingCutscene.tscn"
const GAME_SCENE = "res://main.tscn"

# Height of the road surface, where zombies stand.
@export var road_y: float = -114.0
# How far ahead of the truck a zombie can appear (random between these).
@export var spawn_distance_min: float = 1500.0
@export var spawn_distance_max: float = 30000.0
@export var legion: int = 100

# The table: one entry per level. Entry 0 plays before level 1, entry 1 before level 2, and so on.
@export var pre_level_table: Array[CutsceneData] = []
# The Parallax2D layers that the table's background pictures go onto, in order.
# Each Parallax2D needs a Sprite2D child; that's where the picture is put.
@export var background_layers: Array[Parallax2D] = []
# For testing this scene on its own (F6): set a number to force that pre-level. -1 = use the real level.
@export var test_pre_level: int = -1

# Which pre-level cutscene this is (0 = before level 1).
var pre_level: int = 0

func _ready() -> void:
	# When the last line of dialogue is done, start the jump animation.
	dialogue_box.finished.connect(_on_dialogue_finished)
	pre_level = test_pre_level if test_pre_level >= 0 else GameState.current_level_index
	_apply_pre_level()

func _on_dialogue_finished() -> void:
	animation_player.play("Finale")
	
# How far ahead of the truck the building appears.
@export var building_ahead: float = 2000.0
# The building's height (Y position). Usually the road level.
@export var building_y: float = -60.0
@onready var building = $Building

func spawn_road_zombie() -> void:
	for i in legion:
		var zombie := ROAD_ZOMBIE.instantiate()
		var ahead := randf_range(spawn_distance_min, spawn_distance_max)
		zombie.position = Vector2(truck.global_position.x + ahead, road_y + randf_range(-25, 60))
		add_child(zombie)
	print("Spawning road zombies")

# Call this from a key in the Finale animation.
func bring_in_building() -> void:
	# Put the building a set distance ahead of the truck, at a set height.
	building.global_position = Vector2(truck.global_position.x + building_ahead, building_y)
	# The building carries the truck over the jump. Wait for the landing.
	await building.truck_landed
	# The truck is on the roof now. Add anything that happens next here.
	
	# Ends the cutscene and starts the level. Call from the last key of the Finale animation.
func finish_cutscene() -> void:
	GameState.cutscene_finished()
	
# Loads this pre-level's dialogue, zombies and background from the table.
func _apply_pre_level() -> void:
	if pre_level_table.is_empty():
		push_warning("Pre Level Table is empty, so the cutscene uses its default settings.")
		return
	# If there are more levels than table entries, reuse the last entry.
	var data := pre_level_table[mini(pre_level, pre_level_table.size() - 1)]
	if data == null:
		push_warning("Pre Level Table entry %d is empty." % pre_level)
		return

	# Zombies
	legion = data.zombie_count
	spawn_distance_min = data.zombie_distance_min
	spawn_distance_max = data.zombie_distance_max

	# Dialogue
	dialogue_box.lines = data.lines

	# Background: put each picture on its Parallax2D layer, skipping empty slots.
	for i in mini(data.background_textures.size(), background_layers.size()):
		_set_layer_picture(background_layers[i], data.background_textures[i])


# Puts a picture on a Parallax2D layer's Sprite2D, and fixes the repeat
# spacing so the new picture tiles seamlessly even if it's a different width.
func _set_layer_picture(layer: Parallax2D, picture: Texture2D) -> void:
	if layer == null or picture == null:
		return
	var sprite: Sprite2D = null
	for child in layer.get_children():
		if child is Sprite2D:
			sprite = child
			break
	if sprite == null:
		push_warning("Parallax layer \"%s\" has no Sprite2D child to put a picture on." % layer.name)
		return
	sprite.texture = picture
	if layer.repeat_size.x > 0.0:
		layer.repeat_size.x = picture.get_width() * absf(sprite.scale.x)
