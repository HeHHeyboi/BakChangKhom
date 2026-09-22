extends Node
signal next_period
signal next_day

signal sendUpdatedEvent(EventID, Event)
signal showDialogEvent(arg1: StringName, arg2: String, arg3: Array)

enum EventID {
	NONE,
	MAIN,
}

@export var eventMap: Dictionary[EventID, Event]
@onready var questboard = $"QuestBoard" as QuesetBoard
@onready var time_system = $"TimeSystem" as TimeSystem
@onready var tutorial = $"Tutorial" as Tutorial
var currentEvent: EventID
var pendingTask: int = -1

signal on_tutorial_finish


func _ready() -> void:
	var root_tree = get_tree().root.get_tree()
	root_tree.node_added.connect(_on_node_added)
	DialogScene.on_dialog_finish.connect(_on_dialog_finish)
	if eventMap.size() <= 0:
		return
	currentEvent = EventID.MAIN
	var event = eventMap[currentEvent]
	questboard.update_task(event.get_task().quest_text_th, event)
	sendUpdatedEvent.emit(currentEvent, event)
	tutorial.on_tutorial_end.connect(_on_tutorial_end)


func _on_node_added(node: Node) -> void:
	if node is CautionMarker:
		sendUpdatedEvent.emit(currentEvent, self.eventMap[currentEvent])
		if not node.caution_press.is_connected(trigger_step):
			node.caution_press.connect(trigger_step)


func _on_tutorial_end():
	on_tutorial_finish.emit()


func init_manager() -> void:
	currentEvent = EventID.MAIN
	var event = eventMap[currentEvent]
	questboard.update_task(event.get_task().quest_text_th, event)
	sendUpdatedEvent.emit(EventID.MAIN, event)


func update_event(id: EventID):
	var event = eventMap[id]
	if event == null:
		return
	currentEvent = id
	var text = event.next_step()
	questboard.update_task(text, event)

	if event.isDone:
		sendUpdatedEvent.emit(id, null)
	else:
		sendUpdatedEvent.emit(id, event)


# Jumps an event straight to a task index (used by the debug menu).
func jump_event(id: EventID, task_index: int) -> void:
	var event = eventMap[id]
	if event == null:
		return
	currentEvent = id
	var text = event.set_step(task_index)
	questboard.update_task(text, event)
	questboard.show()
	time_system.show()

	sendUpdatedEvent.emit(id, event)


func show_dialog(title: String, file_path: StringName, bg_name: String, chars: Array = []):
	showDialogEvent.emit(file_path, bg_name, chars)
	DialogScene.set_title(title)


# Per-step reaction table: what happens when a quest step's caution marker is
# pressed. Called directly by CautionMarker.caution_press connections, and by
# any node that gates a press on its own marker's visibility (e.g. grandma.gd).
func trigger_step(id: EventID, event: Event) -> void:
	var data = event.get_task()
	hud_state(data.showHUD)
	match data.action:
		QuestStep.Action.DIALOG:
			DialogScene.show_dialog(data.dialog_file, data.bg_name, data.chars)
			DialogScene.set_title(data.title)
		QuestStep.Action.MINIGAME, QuestStep.Action.SCENE_CHANGE:
			var minigame = load(data.scene_path)
			get_tree().root.add_child(minigame)
			Global.in_minigame = true
			pass


func _on_dialog_finish() -> void:
	pass


func minigame_end() -> void:
	pass


func hud_state(state: bool):
	questboard.visible = state
	time_system.visible = state


func hideUI():
	hud_state(false)


func showUI():
	hud_state(true)


const TutorialState = Tutorial.TutorialState


func show_tutorial(index: TutorialState) -> void:
	tutorial.show_tutorial(index)
