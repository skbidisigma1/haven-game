extends RefCounted

# Rotations describe the mirror's surface, not its normal.
static func optic(x: float, y: float, angle: float, kind: String = "mirror", fixed: bool = false) -> Dictionary:
	return {"pos": Vector2(x, y), "rot": angle, "kind": kind, "fixed": fixed}

static func wall(x: float, y: float, w: float, h: float) -> Dictionary:
	return {"pos": Vector2(x, y), "size": Vector2(w, h)}

static func all() -> Array[Dictionary]:
	return [
		{
			"name": "First light", "hint": "One mirror. Catch the beam and turn it down the hall.",
			"optics": [optic(240, 552, 0)], "solution": [optic(320, 160, 45)],
			"zombies": [Vector2(320, 432)], "humans": [], "walls": [],
		},
		{
			"name": "Occupied corridor", "hint": "The researcher is in the firing lane. Take the long way around.",
			"optics": [optic(208, 552, 0), optic(384, 552, 0)],
			"solution": [optic(256, 160, 45), optic(256, 432, 45)],
			"zombies": [Vector2(640, 432), Vector2(960, 432)], "humans": [Vector2(640, 160)],
			"walls": [wall(600, 280, 24, 160)],
		},
		{
			"name": "Dogleg", "hint": "Three turns. Check the far end of the beam before you fire.",
			"optics": [optic(176, 552, 0), optic(352, 552, 0), optic(528, 552, 0)],
			"solution": [optic(256, 160, 45), optic(256, 432, 45), optic(832, 432, 135)],
			"zombies": [Vector2(256, 304), Vector2(600, 432), Vector2(832, 256)],
			"humans": [Vector2(600, 160), Vector2(832, 560)],
			"walls": [wall(560, 280, 24, 160)],
		},
		{
			"name": "Bolted down", "hint": "Amber brackets mark fixed mirrors. Work with the turn that's already there.",
			"optics": [optic(864, 160, 45, "mirror", true), optic(192, 552, 0)],
			"solution": [optic(864, 496, 135)],
			"zombies": [Vector2(864, 320), Vector2(560, 496), Vector2(240, 496)],
			"humans": [Vector2(1040, 160), Vector2(560, 336)],
			"walls": [wall(528, 288, 24, 208)],
		},
		{
			"name": "Around the wall", "hint": "The fixed mirror turns the beam down. Use two mirrors to get around the lower wall.",
			"optics": [optic(880, 160, 45, "mirror", true), optic(208, 552, 0), optic(400, 552, 0)],
			"solution": [optic(880, 432, 135), optic(320, 432, 45)],
			"zombies": [Vector2(880, 304), Vector2(608, 432), Vector2(320, 256)],
			"humans": [Vector2(1040, 160), Vector2(880, 568)],
			"walls": [wall(608, 280, 160, 24)],
		},
		{
			"name": "Two places at once", "hint": "A violet splitter keeps one beam going and turns a second. Both beams count.",
			"optics": [optic(240, 552, 0, "splitter")], "solution": [optic(400, 160, 45)],
			"zombies": [Vector2(880, 160), Vector2(400, 432)],
			"humans": [Vector2(880, 432)], "walls": [wall(640, 336, 24, 176)],
		},
		{
			"name": "Double shift", "hint": "Route both branches around the researchers in the center.",
			"optics": [optic(320, 160, 45, "splitter", true), optic(896, 160, 45, "mirror", true), optic(176, 552, 0), optic(368, 552, 0)],
			"solution": [optic(320, 480, 45), optic(896, 480, 135)],
			"zombies": [Vector2(640, 160), Vector2(320, 320), Vector2(896, 320), Vector2(640, 480)],
			"humans": [Vector2(608, 304), Vector2(736, 304)],
			"walls": [wall(608, 240, 240, 24), wall(608, 384, 240, 24)],
		},
		{
			"name": "Three directions", "hint": "Place the splitter below the right-hand targets. Send one branch down and the other left.",
			"optics": [optic(896, 160, 45, "mirror", true), optic(320, 432, 45, "mirror", true), optic(208, 552, 0, "splitter")],
			"solution": [optic(896, 432, 135)],
			"zombies": [Vector2(896, 304), Vector2(896, 552), Vector2(640, 432), Vector2(320, 304)],
			"humans": [Vector2(608, 304), Vector2(1056, 160)],
			"walls": [wall(608, 304, 160, 24)],
		},
		{
			"name": "Separate lanes", "hint": "Turn the left branch across at the middle targets. Turn the right branch across the bottom targets.",
			"optics": [optic(384, 160, 45, "splitter", true), optic(960, 160, 45, "mirror", true), optic(384, 488, 0), optic(880, 480, 0)],
			"solution": [optic(384, 400, 45), optic(960, 480, 135)],
			"placement_paths": [[Vector2(384, 400)], [Vector2(960, 480)]],
			"zombies": [Vector2(720, 160), Vector2(384, 304), Vector2(640, 400), Vector2(960, 320), Vector2(720, 480)],
			"humans": [Vector2(640, 304), Vector2(384, 560), Vector2(960, 568)],
			"walls": [wall(544, 496, 24, 128)],
		},
		{
			"name": "Double split", "hint": "Use the movable splitter below the left targets: one beam down, one right. Turn the far-right beam left.",
			"optics": [optic(288, 160, 45, "splitter", true), optic(928, 160, 45, "mirror", true), optic(848, 512, 0), optic(208, 512, 0, "splitter")],
			"solution": [optic(928, 432, 135), optic(288, 432, 45)],
			"placement_paths": [[Vector2(848, 432), Vector2(928, 432)], [Vector2(208, 432), Vector2(288, 432)]],
			"zombies": [Vector2(528, 160), Vector2(928, 304), Vector2(720, 432), Vector2(288, 288), Vector2(464, 432), Vector2(288, 552)],
			"humans": [Vector2(704, 304), Vector2(1056, 160), Vector2(928, 560)],
			"walls": [wall(512, 432, 24, 112)],
		},
	]
