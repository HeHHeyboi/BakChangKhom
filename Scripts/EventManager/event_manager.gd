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
	questboard.update_task(event.get_task(), event)
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
	questboard.update_task(event.get_task(), event)
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
	if id != EventID.MAIN:
		return

	match event.currentTask:
		0:
			pendingTask = 0
			update_event(id)
			show_dialog(
				"บ้านของยาย",
				Constant.CHAPTER1_RETURN_HOME_TEXT,
				Constant.CHAPTER2_BG_IMAGE,
				["ขม", "ยาย"],
			)
		1:
			pendingTask = 1
			hideUI()
			update_event(id)
			DialogScene.show_dialog(Constant.MAIN_DIALOG_1, "")
			DialogScene.set_title("ห้องของขม")
		3:
			hideUI()
			show_tutorial(TutorialState.RAM_CLEANING)
			var minigame = load(Constant.MINIGAME1_SCENE).instantiate()
			get_tree().root.add_child(minigame)
			Global.in_minigame = true


func _on_dialog_finish() -> void:
	if currentEvent == EventID.MAIN:
		match pendingTask:
			1:
				showUI()
				var find_minigame = load(Constant.FIND_ERASER_MINIGAME_SCENE).instantiate()
				get_tree().root.add_child(find_minigame)
				Global.in_minigame = true

	pendingTask = -1


func minigame_end() -> void:
	if currentEvent == EventID.MAIN:
		var event = eventMap[currentEvent]
		if event.currentTask == 2:
			update_event(currentEvent)
		elif event.currentTask == 3:
			update_event(currentEvent)


func hideUI() -> void:
	questboard.visible = false
	time_system.visible = false


func showUI() -> void:
	questboard.visible = true
	time_system.visible = true


const TutorialState = Tutorial.TutorialState


func show_tutorial(index: TutorialState) -> void:
	tutorial.show_tutorial(index)
