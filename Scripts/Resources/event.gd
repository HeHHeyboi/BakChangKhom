class_name Event extends Resource

signal on_task_update(int, String)

@export var name: String = "UnknowEvent"
@export_multiline var Tasks: Array[String] = []:
	set(value):
		totalTask = value.size()
		_tasks = value

var isActive: bool = false
var isDone: bool = false

var totalTask = 0
var currentTask = 0
var _tasks: Array[String] = []


func _ready() -> void:
	on_task_update.emit(currentTask, _tasks[currentTask])


func next_step() -> String:
	if isDone:
		return ""

	currentTask += 1
	if currentTask >= totalTask:
		isDone = true
		return ""
	else:
		return get_task()


func get_task() -> String:
	return _tasks[currentTask]
