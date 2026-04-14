class_name Event extends Resource

@export var name: String = "UnknowEvent"
@export var totalTask: int = 1

var currentStep = 1
var isActive: bool = false
var isDone: bool = false


func next_step() -> int:
	currentStep += 1
	if currentStep >= totalTask:
		isDone = true

	return currentStep
