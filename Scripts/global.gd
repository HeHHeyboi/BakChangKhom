extends Node2D
@export var _CharacterMap: Dictionary
@export var MiniGames: Dictionary

var dialogShown = false


func ReturnMiniGame(minigame_name: String) -> Variant:
	return MiniGames[minigame_name].instantiate()


func getCharacterTexture(t_name: String):
	return _CharacterMap[t_name]


func isDialogShown() -> bool:
	return dialogShown


func hideDialog():
	dialogShown = false


func showDialog():
	dialogShown = true
