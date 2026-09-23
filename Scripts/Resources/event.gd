class_name Event extends Resource

signal on_task_update(int, String)

@export var name: String = "UnknowEvent"
@export var Tasks: Array[QuestStep] = []:
	set(value):
		totalTask = value.size()
		_tasks = value

var isActive: bool = false
var isDone: bool = false

var totalTask = 0
var currentTask = 0
var _tasks: Array[QuestStep] = []


func _ready() -> void:
	on_task_update.emit(currentTask, _tasks[currentTask])


func reset() -> void:
	currentTask = 0
	isDone = false
	for task in _tasks:
		task.reset()


func next_step() -> QuestStep:
	if isDone:
		return null

	currentTask += 1
	if currentTask >= totalTask:
		isDone = true
		return null
	else:
		return get_task()


func get_task() -> QuestStep:
	if isDone:
		return null
	return _tasks[currentTask]


# Jumps directly to a task index (used by the debug menu to skip ahead).
func set_step(index: int) -> QuestStep:
	currentTask = clampi(index, 0, maxi(totalTask - 1, 0))
	isDone = false
	for i in range(0, currentTask):
		_tasks[i].set_done()
	for i in range(currentTask, totalTask):
		_tasks[i].reset()
	return get_task()
