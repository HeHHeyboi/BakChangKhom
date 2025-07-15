extends Node2D
@export var _CharacterMap: Dictionary


func getCharacterTexture(t_name: String):
	return _CharacterMap[t_name]
