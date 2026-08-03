extends Node
signal showDialogEvent(arg1: StringName, arg2: String, arg3: Array)
signal next_period
signal next_day
signal next_mounth
signal hide_time
signal show_time

signal sendUpdatedEvent

@export var eventList: Array[Event]
var currentEvent: Event


func _ready() -> void:
	if eventList.size() <= 0:
		return
	currentEvent = eventList[0]
	QuestBoard.update_task(currentEvent.get_task(), currentEvent)


func update_event():
	if currentEvent == null:
		return
	var text = currentEvent.next_step()
	QuestBoard.update_task(text, currentEvent)

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
