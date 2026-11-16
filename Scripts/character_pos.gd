class_name CharacterPos extends Node2D

@onready var marks = self.get_children()
var currentPos = 0
var posSet = [0, 1, 2, 3]


func addCharacterSprite(charSprite: CharacterSprite, pos: int = -1):
	var mark: Marker2D
	# [0.8.0] บทที่มีคนพูดเกินจำนวนจุดยืน (เช่น บท 10 มี 7 คน) — เดิม error index เกิน · คนที่เกินขึ้นตอนพูด (_show_speaker)
	if pos < 0 and currentPos >= marks.size():
		charSprite.queue_free()
		return
	if pos >= marks.size():
		pos = marks.size() - 1
	if pos < 0:
		mark = marks.get(currentPos) as Marker2D
		charSprite.position = mark.position
		posSet.erase(currentPos)
		currentPos += 1
	else:
		mark = marks.get(pos) as Marker2D
		posSet.erase(pos)
		charSprite.position = mark.position

	if mark.has_meta("flip"):
		charSprite.flip_h = mark.get_meta("flip")
	self.add_child(charSprite)


func reset():
	posSet = [0, 1, 2, 3]
	currentPos = 0
	for n in self.get_children():
		if n.has_meta("destroy"):
			# print_rich("Destroy ", n.name)
			n.queue_free()
	pass
