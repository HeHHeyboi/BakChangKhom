class_name QuestStep extends Resource

enum Action {
	DIALOG,
	MINIGAME,
	TUTORIAL,
	SCENE_CHANGE,
}

enum EmitType {
	TRIGGER,
	DIALOG_END,
	MINIGAME_END,
	TUTORIAL_END,
}
@export var action: Action
## When trigger, does this step update event
@export var emitType: EmitType = EmitType.TRIGGER

## Title of the Dialog. Only Action is DIALOG
@export var title: String
## Path to .txt. Only Action is DIALOG
@export_file("*.txt") var dialog_file: String
## Path to background image. Only Action is DIALOG
@export_file("*.png", "*jpg") var bg_name: String
## List of character (will be change). Only Action is DIALOG
@export var chars: Array[String] = []

## change scene to minigame or another scene. Only Action is MINIGAME
@export_file("*.tscn") var scene_path: String
## Show HUD. Only Action is Minigame
@export var showHUD = false
@export var tutorial: Tutorial.TutorialState
# @export var tutorial_state: int = -1
## Text that need to show in QuestBoard.
@export_multiline var quest_text_th: String

var isDone = false


func set_done():
	isDone = true


func reset():
	isDone = false
