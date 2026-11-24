extends Node2D

const ROAD_ZOMBIE = preload("res://assets/CutsceneAssets/Zombie.tscn")

@onready var truck: CharacterBody2D = $CharacterBody2D

# Height of the road surface, where zombies stand.
@export var road_y: float = -114.0
# How far ahead of the truck a zombie can appear (random between these).
@export var spawn_distance_min: float = 1500.0
@export var spawn_distance_max: float = 30000.0
@export var legion: int = 100

func spawn_road_zombie() -> void:
	for i in legion:
		var zombie := ROAD_ZOMBIE.instantiate()
		var ahead := randf_range(spawn_distance_min, spawn_distance_max)
		zombie.position = Vector2(truck.global_position.x + ahead, road_y + randf_range(-25, 60))
		add_child(zombie)
	print("Spawning road zombies")
