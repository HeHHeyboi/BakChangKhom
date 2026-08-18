extends Node
signal next_period
signal next_day

signal sendUpdatedEvent(Event)
signal showDialogEvent(arg1: StringName, arg2: String, arg3: Array)

enum EventID { NONE, MAIN }

@export var eventMap: Dictionary[EventID,Event]
@onready var questboard = $"QuestBoard" as QuesetBoard
@onready var time_system = $"TimeSystem" as TimeSystem
@onready var tutorial = $"Tutorial" as Tutorial
var currentEvent: Event

signal on_tutorial_finish


func _ready() -> void:
	var root_tree = get_tree().root.get_tree()
	root_tree.node_added.connect(_on_node_added)
	if eventMap.size() <= 0:
		return
	var event = eventMap[EventID.MAIN]
	currentEvent = event
	questboard.update_task(event.get_task(), event)
	sendUpdatedEvent.emit(event)
	tutorial.on_tutorial_end.connect(_on_tutorial_end)


func _on_node_added(node: Node) -> void:
	if node is CautionMarker:
		sendUpdatedEvent.emit(currentEvent)


func _on_tutorial_end():
	print("Tutorial Finish")
	on_tutorial_finish.emit()


func init_manager() -> void:
	var event = eventMap[EventID.MAIN]
	currentEvent = event
	questboard.update_task(event.get_task(), event)
	sendUpdatedEvent.emit(event)


func update_event(id: EventID):
	var event = eventMap[id]
	if event == null:
		return
	currentEvent = event
	var text = event.next_step()
	questboard.update_task(text, event)

	sendUpdatedEvent.emit(event)


func show_dialog(title: String, file_path: StringName, bg_name: String, chars: Array = []):
	showDialogEvent.emit(file_path, bg_name, chars)
	DialogScene.set_title(title)


func hideUI() -> void:
	questboard.visible = false
	time_system.visible = false


func showUI() -> void:
	questboard.visible = true
	time_system.visible = true


func hideQuest(isHide: bool) -> void:
	questboard.visible = !isHide


func hideTimeUI(isHide: bool) -> void:
	time_system.visible = !isHide


const TutorialState = Tutorial.TutorialState


func show_tutorial(index: TutorialState) -> void:
	tutorial.show_tutorial(index)
