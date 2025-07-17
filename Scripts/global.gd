extends Node2D
@export var _CharacterMap: Dictionary

var dialogShown = false


func getCharacterTexture(t_name: String):
	return _CharacterMap[t_name]


func isDialogShown() -> bool:
	return dialogShown


func hideDialog():
	dialogShown = false


func showDialog():
	dialogShown = true
