class_name CautionMarker extends Control

## Events this marker watches, mapped to the task step at which it is shown.
@export var trackEvents: Dictionary[Event, int]


func _enter_tree() -> void:
	self.visible = false
	EventManager.sendUpdatedEvent.connect(checkTrackEvent)


func _exit_tree() -> void:
	EventManager.sendUpdatedEvent.disconnect(checkTrackEvent)


func checkTrackEvent(event: Event) -> void:
	visible = (event != null and trackEvents.has(event) and trackEvents[event] == event.currentTask)
