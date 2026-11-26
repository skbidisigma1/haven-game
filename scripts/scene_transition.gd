extends CanvasLayer

# Autoload: Project Settings -> Globals -> Autoload, name it "SceneTransition".
# Black lines close over the screen, the change happens while it's black, then they open again.

const SHADER_PATH = "res://shaders/transition_lines.gdshader"
# Seconds for the lines to close (and again to open).
const CLOSE_TIME := 0.45
const OPEN_TIME := 0.45
# How long to stay fully black in the middle.
const HOLD_TIME := 0.1

var _rect: ColorRect
var _material: ShaderMaterial
var busy := false

func _ready() -> void:
	layer = 100                                # above every other UI
	process_mode = Node.PROCESS_MODE_ALWAYS    # still works while the game is paused
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH)
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_set_progress(0.0)

# Swap to another scene file behind the transition.
func change_scene(path: String) -> void:
	await cover(func(): get_tree().change_scene_to_file(path))

# Close the lines, run `action` while the screen is black, then open them.
# Use it for anything that isn't a scene change, like reloading a level in place.
func cover(action: Callable) -> void:
	if busy:
		return
	busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP   # block clicks during the wipe
	_material.set_shader_parameter("opening", false)
	await _animate(0.0, 1.0, 0.0, 1.0, CLOSE_TIME)
	action.call()
	# A scene change finishes at the end of the frame; give the new scene a moment to set up.
	await get_tree().process_frame
	await get_tree().process_frame
	if HOLD_TIME > 0.0:
		await get_tree().create_timer(HOLD_TIME, true, false, true).timeout
	# Scroll keeps going (1 -> 2) so the lines carry on sliding left as they thin out.
	_material.set_shader_parameter("opening", true)
	await _animate(1.0, 0.0, 1.0, 2.0, OPEN_TIME)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false

func _animate(from: float, to: float, scroll_from: float, scroll_to: float, time: float) -> void:
	var tween := create_tween()
	tween.tween_method(func(t: float):
		_set_progress(lerpf(from, to, t))
		_material.set_shader_parameter("scroll", lerpf(scroll_from, scroll_to, t))
	, 0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _set_progress(value: float) -> void:
	_material.set_shader_parameter("progress", value)
	_rect.visible = value > 0.0
