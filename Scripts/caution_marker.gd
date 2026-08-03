class_name CautionMarker extends Control

## Event this marker watches.
@export var trackEvent: Event
## Task step of [member trackEvent] at which this marker is shown.
@export var trackStep: int = 0


func _enter_tree() -> void:
	EventManager.sendUpdatedEvent.connect(checkTrackEvent)


func _exit_tree() -> void:
	EventManager.sendUpdatedEvent.disconnect(checkTrackEvent)


func _ready() -> void:
	checkTrackEvent()


func checkTrackEvent() -> void:
	var active := EventManager.currentEvent
	visible = active != null and active == trackEvent and active.currentTask == trackStep
