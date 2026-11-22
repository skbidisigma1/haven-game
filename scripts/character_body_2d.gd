extends CharacterBody2D


const SPEED = 1500
const JUMP_VELOCITY = -900.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var time := 0.0
var base_y := 0.0
func pause_animation():
	animated_sprite_2d.pause()

func resume_animation():
	animated_sprite_2d.play()
	
func _ready():
	base_y = animated_sprite_2d.position.y

func _process(delta):
	if is_on_floor():
		time += delta
		animated_sprite_2d.position.y = base_y + sin(time * 3) * 10

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = SPEED

	move_and_slide()
