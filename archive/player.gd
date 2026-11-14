extends CharacterBody2D

@export var speed: float = 300.0
@export var bullet_scene: PackedScene # Drag bullet.tscn here in the Inspector!

func _physics_process(_delta: float) -> void:
	# 1. Movement (WASD / Arrow keys work out of the box with ui_ actions, or map your own)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

	# 2. Aiming at the mouse
	look_at(get_global_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
	# 3. Shooting (Left Click)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()

func shoot() -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	bullet.global_position = $Gun.global_position
	bullet.rotation = rotation
	# Add to the main level so bullets don't move with the player
	get_tree().current_scene.add_child(bullet)
	
