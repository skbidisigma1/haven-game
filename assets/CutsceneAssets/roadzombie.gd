extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var moreparticles: CPUParticles2D = $CPUParticles2D2
var exploded := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)
	# Pop up out of the road, then switch to idle.
	if sprite.sprite_frames.has_animation("pop"):
		sprite.play("pop")
	else:
		sprite.play("idle")

func _on_animation_finished() -> void:
	if sprite.animation == &"pop":
		sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	# Only the truck sets it off, and only once.
	if exploded or not body is CharacterBody2D:
		return
	exploded = true
	sprite.hide()
	set_deferred("monitoring", false)   # stop detecting while we explode
	particles.emitting = true
	moreparticles.emitting = true
	# Wait for the particles to finish, then remove the zombie.
	await get_tree().create_timer(particles.lifetime + 0.2).timeout
	queue_free()
