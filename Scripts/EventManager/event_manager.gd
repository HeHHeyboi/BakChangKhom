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
signal on_minigame_end
signal on_dialog_end


func _ready() -> void:
	var root_tree = get_tree().root.get_tree()
	root_tree.node_added.connect(self._on_node_added)
	DialogScene.on_dialog_finish.connect(self._on_dialog_finish)
	if eventMap.size() <= 0:
		return
	currentEvent = EventID.MAIN
	var event = eventMap[currentEvent]
	event.reset()
	event.isActive = true
	questboard.update_task(event.get_task().quest_text_th, event)
	sendUpdatedEvent.emit(currentEvent, event)
	tutorial.on_tutorial_end.connect(_on_tutorial_end)


func _on_node_added(node: Node) -> void:
	if node is CautionMarker:
		sendUpdatedEvent.emit(currentEvent, self.eventMap[currentEvent])
		if not node.caution_press.is_connected(trigger_step):
			node.caution_press.connect(trigger_step)


func init_manager() -> void:
	currentEvent = EventID.MAIN
	var event = eventMap[currentEvent]
	questboard.update_task(event.get_task().quest_text_th, event)
	sendUpdatedEvent.emit(EventID.MAIN, event)


func update_event(id: EventID) -> QuestStep:
	var event = eventMap[id]
	if event == null:
		return

	var quest_step = event.next_step()
	if event.isDone:
		sendUpdatedEvent.emit(id, null)
		return null
	else:
		sendUpdatedEvent.emit(id, event)

	questboard.update_task(quest_step.quest_text_th, event)
	return quest_step


# Jumps an event straight to a task index (used by the debug menu).
func jump_event(id: EventID, task_index: int) -> void:
	var event = eventMap[id]
	if event == null:
		return
	currentEvent = id
	var quest_step = event.set_step(task_index)
	questboard.update_task(quest_step.quest_text_th, event)
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
	if event == null:
		return
	var data = event.get_task()
	if data == null:
		return
	elif data.emitType == QuestStep.EmitType.TRIGGER:
		_process_data(id, data)


func _on_dialog_finish() -> void:
	showUI()
	on_dialog_end.emit()
	var event = eventMap[currentEvent]
	if event == null:
		return
	var id = currentEvent
	var data = event.get_task()
	if data == null:
		return
	print(data.isDone)
	if data.isDone && data.action == QuestStep.Action.DIALOG:
		data = update_event(id)
		if data == null:
			return
		# if data.emitType == QuestStep.EmitType.DIALOG_END:
		# 	_process_data(currentEvent, data)
	if data.emitType == QuestStep.EmitType.DIALOG_END:
		_process_data(id, data)


func _on_tutorial_end():
	on_tutorial_finish.emit()
	showUI()
	var event = eventMap[currentEvent]
	if event == null:
		return
	var id = currentEvent
	var data = event.get_task()
	if data == null:
		return
	if data.isDone && data.action == QuestStep.Action.TUTORIAL:
		data = update_event(id)
		if data == null:
			return
		# if data.emitType == QuestStep.EmitType.TUTORIAL_END:
		# 	_process_data(currentEvent, data)
	if data.emitType == QuestStep.EmitType.TUTORIAL_END:
		_process_data(id, data)


func minigame_end() -> void:
	showUI()
	on_minigame_end.emit()
	var event = eventMap[currentEvent]
	if event == null:
		return
	var id = currentEvent
	var data = event.get_task()
	if data == null:
		return
	if data.isDone && (
		data.action == QuestStep.Action.MINIGAME || data.action == QuestStep.Action.SCENE_CHANGE
	):
		data = update_event(id)
		if data == null:
			return
		# if data.emitType == QuestStep.EmitType.MINIGAME_END:
		# 	_process_data(currentEvent, data)
	if data.emitType == QuestStep.EmitType.MINIGAME_END:
		_process_data(id, data)


func _process_data(id: EventID, data: QuestStep):
	if data == null || id == EventID.NONE:
		return

	_hud_state(data.showHUD)
	match data.action:
		QuestStep.Action.DIALOG:
			DialogScene.show_dialog(data.dialog_file, data.bg_name, data.chars)
			DialogScene.set_title(data.title)
			if !on_dialog_end.is_connected(data.set_done):
				on_dialog_end.connect(data.set_done, CONNECT_ONE_SHOT)
		QuestStep.Action.MINIGAME, QuestStep.Action.SCENE_CHANGE:
			var scene = load(data.scene_path) as PackedScene
			get_tree().root.add_child(scene.instantiate())
			Global.in_minigame = true
			if !on_minigame_end.is_connected(data.set_done):
				on_minigame_end.connect(data.set_done, CONNECT_ONE_SHOT)
		QuestStep.Action.TUTORIAL:
			tutorial.show_tutorial(data.tutorial)
			if !on_tutorial_finish.is_connected(data.set_done):
				on_tutorial_finish.connect(data.set_done, CONNECT_ONE_SHOT)


func _hud_state(state: bool):
	questboard.visible = state
	time_system.visible = state


func hideUI():
	_hud_state(false)


func showUI():
	_hud_state(true)


const TutorialState = Tutorial.TutorialState


func show_tutorial(index: TutorialState) -> void:
	tutorial.show_tutorial(index)
