extends CharacterBody2D

# Turn the bounce on or off. Keyframe this in the AnimationPlayer.

const SPEED = 1500
const JUMP_VELOCITY = -900.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var time := 0.0
var base_y := 0.0
# How quickly the truck turns to match the slope (higher = snappier).
@export var tilt_speed: float = 10.0
# The most the truck tips nose-up or nose-down in the air, in degrees.
@export var max_air_tilt_degrees: float = 35.0

func pause_animation():
	animated_sprite_2d.pause()

func resume_animation():
	animated_sprite_2d.play()
	
func _ready():
	base_y = animated_sprite_2d.position.y

func _process(delta):
	if is_on_floor():
		time += delta
		animated_sprite_2d.position.y = base_y + sin(time * 3.0) * 3.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var _direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = SPEED

	move_and_slide()
