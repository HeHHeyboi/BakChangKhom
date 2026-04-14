extends Node
signal showDialogEvent(arg1: StringName, arg2: String, arg3: Array)
signal next_period
signal next_day
signal next_mounth
signal hide_time
signal show_time

signal sendUpdatedEvent

# enum MainEvent { GRANDMA, CLEAN_RAM, MAIN_FINISH }
# enum SubEvent { TASK_1, TASK_2 }
#
# var eventSeq = [MainEvent.GRANDMA, MainEvent.CLEAN_RAM, MainEvent.MAIN_FINISH]
@export var eventList: Array[Event]
var currentEvent: Event


func _ready() -> void:
	if eventList.size() <= 0:
		return
	currentEvent = eventList[0]


func update_event():
	if currentEvent == null:
		return
	currentEvent.next_step()
	sendUpdatedEvent.emit()


func event_finished(event: Event):
	if currentEvent == event:
		currentEvent = null


func show_dialog(title: String, file_path: StringName, bg_name: String, chars: Array = []):
	showDialogEvent.emit(file_path, bg_name, chars)
	DialogScene.set_title(title)


func hideTimeUI(isHide: bool) -> void:
	if isHide:
		hide_time.emit()
	else:
		show_time.emit()
