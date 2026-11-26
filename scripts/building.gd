extends Node2D

# Sent when the truck reaches the end of the path (on the roof).
signal truck_landed

# How fast the truck travels along the path, in pixels per second.
@export var ride_speed: float = 1500.0

@onready var ramp_start: Area2D = $RampStart
@onready var path: Path2D = $JumpPath
@onready var follow: PathFollow2D = $JumpPath/Follow
@onready var mover: RemoteTransform2D = $JumpPath/Follow/Mover
var triggered := false

func _ready() -> void:
	follow.loop = false
	follow.rotates = true
	mover.update_scale = false
	ramp_start.body_entered.connect(_on_ramp_start_body_entered)

func _on_ramp_start_body_entered(body: Node2D) -> void:
	if triggered or not body is CharacterBody2D:
		return
	triggered = true
	ride(body)

# Carries the truck along the path from start to end.
func ride(truck: CharacterBody2D) -> void:
	truck.set_physics_process(false)   # the path moves it now, not physics
	follow.progress = 0.0
	mover.remote_path = mover.get_path_to(truck)
	var length := path.curve.get_baked_length()
	var tween := create_tween()
	tween.tween_property(follow, "progress", length, length / ride_speed)
	await tween.finished
	truck_landed.emit()
