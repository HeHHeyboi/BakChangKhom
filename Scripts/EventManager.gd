extends Node2D

enum MainEvent { GRANDMA, CLEAN_RAM, MAIN_FINISH }

var currentEvent: MainEvent = MainEvent.GRANDMA

@export var showDialogEvent: Event


func show_dialog(title: String, file_path: StringName, bg_name: String, chars: Array = []):
	showDialogEvent.emit(file_path, bg_name, chars)
	DialogScene.set_title(title)
