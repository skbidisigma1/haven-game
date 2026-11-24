extends Area2D
class_name Target

enum Type { ZOMBIE, HUMANOID }
@export var target_type: Type = Type.ZOMBIE
# Zombies use ONE AnimatedSprite2D with three animations:
# "crack" (before firing), "out" (climbing out, plays once), then "zombie" (loops).
@export var crack_animation: StringName = &"crack"
@export var out_animation: StringName = &"out"
@export var zombie_animation: StringName = &"zombie"
var is_hit := false
var popped_out := false

# Art is set up in zombie.tscn / humanoid.tscn in the 2D view.
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var hit_marker: Node2D = get_node_or_null("HitMarker")
# Whatever animation the sprite was set to in the editor (used by researchers).
@onready var idle_animation: StringName = sprite.animation if sprite else &"default"

func _ready() -> void:
	add_to_group("targets")
	add_to_group("zombies" if target_type == Type.ZOMBIE else "humanoids")
	# Only make a default hitbox if none was set in the editor.
	if $CollisionShape2D.shape == null:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(40, 40)
		$CollisionShape2D.shape = shape
	if target_type == Type.ZOMBIE:
		hide_in_crack()
	else:
		popped_out = true
		_update_look()

# Plays "out" once, then switches to "zombie".
# Use `await zombie.pop_out()` to wait until the zombie is fully out.
func pop_out() -> void:
	if popped_out: return
	popped_out = true
	_update_look()
	if _has_animation(out_animation):
		sprite.play(out_animation)
		# Wait exactly one run of "out" (works even if Loop is left on).
		# A tween on this node is used so the wait is cancelled if the zombie is deleted.
		await create_tween().tween_interval(_animation_length(out_animation)).finished
		if not popped_out: return  # sent back into the crack meanwhile
	elif sprite and sprite.sprite_frames:
		push_warning("Zombie has no \"%s\" animation. Its animations are: %s" % [out_animation, sprite.sprite_frames.get_animation_names()])
	_play(zombie_animation)

# How long one run of an animation takes, in seconds.
func _animation_length(anim: StringName) -> float:
	var frames := sprite.sprite_frames
	var fps := frames.get_animation_speed(anim) * absf(sprite.speed_scale)
	if fps <= 0.0: return 0.0
	var total := 0.0
	for i in frames.get_frame_count(anim):
		total += frames.get_frame_duration(anim, i)
	return total / fps

# Back to just the crack (used when the player edits placements again).
func hide_in_crack() -> void:
	if target_type != Type.ZOMBIE: return
	popped_out = false
	_play(crack_animation)
	_update_look()

func set_hit(hit: bool) -> void:
	is_hit = hit
	_update_look()

# The animation this target should show when it isn't hit.
func _normal_animation() -> StringName:
	if target_type == Type.HUMANOID: return idle_animation
	return zombie_animation if popped_out else crack_animation

func _play(anim: StringName) -> void:
	if _has_animation(anim): sprite.play(anim)

func _has_animation(anim: StringName) -> bool:
	return sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim)

# Picks the animation and tint. Draws nothing itself.
func _update_look() -> void:
	if sprite:
		if is_hit:
			# Zombies fade to a ghostly teal, researchers flush red.
			sprite.modulate = Color(0.44, 0.88, 0.8, 0.28) if target_type == Type.ZOMBIE else Color("ef8c73")
		else:
			sprite.modulate = Color.WHITE
		# Optional "hit" animation; otherwise go back to the normal one.
		if is_hit and _has_animation(&"hit"):
			sprite.play(&"hit")
		elif not is_hit and sprite.animation == &"hit":
			_play(_normal_animation())
	if hit_marker:
		hit_marker.visible = is_hit
