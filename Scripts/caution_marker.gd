class_name CautionMarker extends Control

## Events this marker watches, mapped to the task step at which it is shown.
@export var trackEvents: Dictionary[EventManager.EventID, PackedByteArray]

var cur_id: EventManager.EventID = EventManager.EventID.NONE
signal caution_press(EventID, Event)


func _enter_tree() -> void:
	self.visible = false
	EventManager.sendUpdatedEvent.connect(checkTrackEvent)


func _exit_tree() -> void:
	EventManager.sendUpdatedEvent.disconnect(checkTrackEvent)


func checkTrackEvent(id: EventManager.EventID, event: Event) -> void:
	if event == null:
		self.visible = false
		return
	var is_track = trackEvents.has(id)
	var has_step = is_track and trackEvents[id].has(event.currentTask)
	if has_step:
		cur_id = id

	self.visible = has_step


func _on_pressed() -> void:
	if self.visible:
		caution_press.emit(cur_id, EventManager.eventMap[cur_id])
