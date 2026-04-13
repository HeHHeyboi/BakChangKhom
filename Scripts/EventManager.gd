extends Node

enum MainEvent { GRANDMA, CLEAN_RAM, MAIN_FINISH }

var eventSeq = [MainEvent.GRANDMA, MainEvent.CLEAN_RAM, MainEvent.MAIN_FINISH]
var currentEvent: MainEvent = eventSeq.pop_front()
signal showDialogEvent(arg1: StringName, arg2: String, arg3: Array)
signal next_period
signal next_day
signal next_mounth
signal hide_time
signal show_time

signal sendUpdatedEvent


func update_event():
	currentEvent = eventSeq.pop_front()
	sendUpdatedEvent.emit()


func show_dialog(title: String, file_path: StringName, bg_name: String, chars: Array = []):
	showDialogEvent.emit(file_path, bg_name, chars)
	DialogScene.set_title(title)


func hideTimeUI(isHide: bool) -> void:
	if isHide:
		hide_time.emit()
	else:
		show_time.emit()
