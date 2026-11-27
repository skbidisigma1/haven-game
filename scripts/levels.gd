extends RefCounted

# Rotations describe the mirror's surface, not its normal.
# The laser drops straight down from the top-left at x = 64.
static func optic(x: float, y: float, angle: float, kind: String = "mirror", fixed: bool = false, is_pivot: bool = false) -> Dictionary:
	return {"pos": Vector2(x, y), "rot": angle, "kind": kind, "fixed": fixed, "pivot": is_pivot}

# A small mirror that stays put but can be turned. Use kind = "splitter" for a pivot splitter.
static func pivot(x: float, y: float, angle: float, kind: String = "mirror") -> Dictionary:
	return optic(x, y, angle, kind, false, true)
		
static func wall(x: float, y: float, w: float, h: float) -> Dictionary:
	return {"pos": Vector2(x, y), "size": Vector2(w, h)}

static func all() -> Array[Dictionary]:
	return [
		{
			"name": "Drop zone", "hint": "The beam falls from the top-left. One mirror turns it across the room.",
			"optics": [optic(960, 400, 0)],
			"solution": [optic(64, 448, 45)],
			"zombies": [Vector2(400, 300)],
			"humans": [Vector2(576, 544)], "walls": [],
		},
		{
			"name": "Shaft blocked", "hint": "A researcher is standing in the shaft. Turn early, then turn again.",
			"optics": [optic(832, 576, 0), optic(960, 576, 0)],
			"solution": [optic(64, 288, 45), optic(1088, 288, 45)],
			"zombies": [Vector2(64, 192), Vector2(608, 288), Vector2(1088, 480)],
			"humans": [Vector2(608, 480)], "walls": [],
		},
		{
			"name": "Long way up", "hint": "Go low first, then climb. Mind which way you turn at the top.",
			"optics": [optic(816, 576, 0), optic(944, 576, 0), optic(1072, 576, 0)],
			"solution": [optic(64, 512, 45), optic(704, 512, 135), optic(704, 192, 135)],
			"zombies": [Vector2(384, 512), Vector2(704, 320), Vector2(960, 192)],
			"humans": [Vector2(192, 192), Vector2(1088, 512)], "walls": [],
		},
		{
			"name": "Back side", "hint": "Mirrors work on both faces. Hit the bolted one from the other side.",
			"optics": [optic(576, 320, 45, "mirror", true), optic(816, 576, 0), optic(944, 576, 0), optic(1072, 576, 0)],
			"solution": [optic(64, 480, 45), optic(1024, 480, 135), optic(1024, 320, 45)],
			"zombies": [Vector2(576, 192), Vector2(864, 320), Vector2(1024, 400)],
			"humans": [Vector2(576, 448)], "walls": [],
		},
		{
			"name": "Fork", "hint": "The splitter sends one beam on and turns another. Both have to count.",
			"optics": [optic(816, 576, 0, "splitter"), optic(944, 576, 0)],
			"solution": [optic(64, 320, 45), optic(960, 320, 45)],
			"zombies": [Vector2(64, 224), Vector2(64, 512), Vector2(640, 320), Vector2(960, 528)],
			"humans": [Vector2(1088, 320)], "walls": [],
		},
		{
			"name": "Two-faced", "hint": "Split the beam on its way across. One half climbs, the other needs a final turn.",
			"optics": [optic(688, 576, 0), optic(816, 576, 0, "splitter"), optic(944, 576, 0)],
			"solution": [optic(64, 448, 45), optic(512, 448, 135), optic(960, 448, 45)],
			"zombies": [Vector2(512, 224), Vector2(832, 448), Vector2(960, 560)],
			"humans": [Vector2(1088, 448), Vector2(960, 256), Vector2(64, 560)], "walls": [],
		},
		{
			"name": "Switchback", "hint": "Walls cut the room into lanes. Four turns, and every lane has a zombie.",
			"optics": [optic(608, 144, 0), optic(720, 144, 0), optic(944, 144, 0), optic(1056, 144, 0)],
			"solution": [optic(64, 560, 45), optic(448, 560, 135), optic(448, 224, 135), optic(832, 224, 45)],
			"zombies": [Vector2(256, 560), Vector2(448, 400), Vector2(640, 224), Vector2(832, 448)],
			"humans": [Vector2(1088, 224), Vector2(448, 160)],
			"walls": [wall(640, 464, 24, 288), wall(256, 352, 288, 24)],
		},
		{
			"name": "Crossfire", "hint": "The bolted splitter sends beams both ways. Catch each one before it reaches a researcher.",
			"optics": [optic(576, 320, 45, "splitter", true), optic(816, 144, 0), optic(944, 144, 0), optic(1056, 144, 0)],
			"solution": [optic(64, 320, 45), optic(576, 512, 135), optic(960, 320, 135)],
			"zombies": [Vector2(576, 432), Vector2(320, 512), Vector2(832, 320), Vector2(960, 192)],
			"humans": [Vector2(576, 584), Vector2(1088, 320), Vector2(64, 448)], "walls": [],
		},
		{
			"name": "Double trouble", "hint": "Two splitters, six zombies. Some beams have to share the work.",
			"optics": [optic(688, 576, 0, "splitter"), optic(816, 576, 0, "splitter"), optic(944, 576, 0)],
			"solution": [optic(64, 256, 45), optic(640, 256, 45), optic(64, 544, 45)],
			"zombies": [Vector2(64, 400), Vector2(320, 256), Vector2(960, 256), Vector2(640, 416), Vector2(448, 544), Vector2(864, 544)],
			"humans": [Vector2(320, 400), Vector2(1088, 400)], "walls": [],
		},
		{
			"name": "Last stand", "hint": "The shaft is already split. Keep every branch off the researchers.",
			"optics": [optic(64, 384, 45, "splitter", true), optic(560, 144, 0, "splitter"), optic(688, 144, 0), optic(944, 144, 0), optic(1056, 144, 0)],
			"solution": [optic(768, 384, 135), optic(64, 560, 45), optic(1024, 560, 135), optic(960, 384, 45)],
			"zombies": [Vector2(320, 384), Vector2(768, 224), Vector2(960, 480), Vector2(64, 480), Vector2(448, 560), Vector2(1024, 448)],
			"humans": [Vector2(1088, 384), Vector2(1088, 560), Vector2(768, 480), Vector2(256, 224)], "walls": [],
		},
	]
