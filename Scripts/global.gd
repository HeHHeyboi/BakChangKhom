extends Node2D
@export var _CharacterMap: Dictionary
@export var MiniGames: Dictionary
signal show_map(m: Global.Map)

var dialogShown = false

enum Map { HOME, MARKET }


func showmap(m: Global.Map) -> void:
	emit_signal("show_map", m)
	self.hide()


func ReturnMiniGame(minigame_name: String) -> Variant:
	return MiniGames[minigame_name].instantiate()


func getCharacterTexture(t_name: String):
	return _CharacterMap[t_name]


func getCharacterSprite(char_name: String) -> CharacterSprite:
	var texture = _CharacterMap[char_name]
	var new_char = CharacterSprite.new(texture, char_name)
	return new_char


func isDialogShown() -> bool:
	return dialogShown


func hideDialog():
	dialogShown = false


func showDialog():
	dialogShown = true
