class_name CharacterSprite extends Sprite2D

var hl = false


func _init(t, n: String):
	self.texture = t
	self.self_modulate = self.self_modulate.darkened(1)
	self.name = n
	self.set_meta("destroy", true)


func highlight():
	if !hl:
		self.self_modulate = self.self_modulate.lightened(1)
		hl = true


func fade():
	self.self_modulate = self.self_modulate.darkened(1)
	hl = false
