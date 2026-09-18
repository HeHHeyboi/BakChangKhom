extends Node2D
@export var _CharacterMap: Dictionary

var dialogShown = false
var in_minigame = false
var on_start = true


func getCharacterTexture(t_name: String):
	return _CharacterMap[t_name]


func getCharacterSprite(char_name: String) -> CharacterSprite:
	var texture = _CharacterMap[char_name]
	var new_char = CharacterSprite.new(texture, char_name)
	return new_char


func isDialogShown() -> bool:
	return dialogShown


func isInMinigame() -> bool:
	return in_minigame


func hideDialog():
	dialogShown = false


func showDialog():
	dialogShown = true
