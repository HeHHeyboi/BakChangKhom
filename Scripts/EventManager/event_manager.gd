extends Node
signal next_period
signal next_day
signal next_mounth
signal hide_time
signal show_time

signal sendUpdatedEvent(Event)
signal showDialogEvent(arg1: StringName, arg2: String, arg3: Array)

enum EventID { NONE, MAIN }

@export var eventMap: Dictionary[EventID,Event]
var currentEvent: Event


func _ready() -> void:
	var root_tree = get_tree().root.get_tree()
	root_tree.node_added.connect(_on_node_added)
	if eventMap.size() <= 0:
		return
	var event = eventMap[EventID.MAIN]
	currentEvent = event
	QuestBoard.update_task(event.get_task(), event)
	sendUpdatedEvent.emit(event)


func _on_node_added(node: Node) -> void:
	if node is CautionMarker:
		sendUpdatedEvent.emit(currentEvent)


func init_manager() -> void:
	var event = eventMap[EventID.MAIN]
	currentEvent = event
	QuestBoard.update_task(event.get_task(), event)
	sendUpdatedEvent.emit(event)


func update_event(id: EventID):
	var event = eventMap[id]
	if event == null:
		return
	currentEvent = event
	var text = event.next_step()
	QuestBoard.update_task(text, event)

	sendUpdatedEvent.emit(event)


func show_dialog(title: String, file_path: StringName, bg_name: String, chars: Array = []):
	showDialogEvent.emit(file_path, bg_name, chars)
	DialogScene.set_title(title)


func hideQuest(isHide: bool) -> void:
	QuestBoard.visible = !isHide


func hideTimeUI(isHide: bool) -> void:
	if isHide:
		hide_time.emit()
	else:
		show_time.emit()
