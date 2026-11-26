extends Resource
class_name CutsceneData

# Everything that changes between pre-level cutscenes.
# One of these per level, kept in the cutscene's Pre Level Table.

@export_group("Dialogue")
# The lines for this cutscene, each with its own portrait.
@export var lines: Array[DialogueLine] = []

@export_group("Zombies")
# How many road zombies spawn.
@export var zombie_count: int = 10
# How far ahead of the truck they can appear (random between these).
@export var zombie_distance_min: float = 1500.0
@export var zombie_distance_max: float = 3000.0

@export_group("Background")
# One picture per background layer, in the same order as the cutscene's
# Background Layers list. Leave a slot empty to keep that layer's current picture.
@export var background_textures: Array[Texture2D] = []
