extends CanvasLayer

# Each line has a portrait and text. Fill these in the Inspector.
@export var lines: Array[DialogueLine] = []
# How long each line stays on screen.
@export var seconds_per_line: float = 10.0
# Typewriter speed. Set to 0 to show each line instantly.
@export var letters_per_second: float = 40.0
# Start by itself when the scene loads. Off = start it from the AnimationPlayer.
@export var auto_start: bool = false

signal finished

@onready var panel: PanelContainer = $"Screen Margin/Panel"
@onready var portrait: TextureRect = $"Screen Margin/Panel/Margin/HBox/Portrait"
@onready var label: Label = $"Screen Margin/Panel/Margin/HBox/Label"

var index := -1
var playing := false

func _ready() -> void:
	panel.hide()
	if auto_start:
		play_all()

# Shows every line, one after another, then hides the box.
func play_all() -> void:
	if playing: return
	playing = true
	index = -1
	for i in lines.size():
		next_line()
		# Waiting with a tween on this node means the wait stops cleanly
		# if the scene ends partway through.
		await create_tween().tween_interval(seconds_per_line).finished
	panel.hide()
	playing = false
	finished.emit()

# Shows the next line. Can also be called from an AnimationPlayer key.
func next_line() -> void:
	index += 1
	if index >= lines.size():
		panel.hide()
		return
	var line := lines[index]
	if line == null:
		return   # an empty slot in the list; skip it
	panel.show()
	# Swap the face for this line, or hide the face box if there isn't one.
	portrait.texture = line.portrait
	portrait.visible = line.portrait != null
	label.text = line.text
	if letters_per_second > 0.0:
		# Typewriter effect: reveal the letters one by one.
		label.visible_ratio = 0.0
		var duration := line.text.length() / letters_per_second
		create_tween().tween_property(label, "visible_ratio", 1.0, duration)
	else:
		label.visible_ratio = 1.0	
