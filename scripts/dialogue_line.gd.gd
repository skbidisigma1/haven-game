extends Resource
class_name DialogueLine

# The face shown next to this line. Leave empty for no portrait.
@export var portrait: Texture2D
# What this line says.
@export_multiline var text: String = ""
