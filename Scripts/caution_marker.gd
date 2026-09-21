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
	if event == null || event.isDone:
		self.visible = false
		return
	var is_track = trackEvents.has(id)
	var has_step = is_track and trackEvents[id].has(event.currentTask)
	if has_step:
		cur_id = id

	self.visible = has_step


func _on_pressed() -> void:
	if not self.visible:
		return
	# cur_id จะถูกตั้งใน checkTrackEvent เท่านั้น ถ้ายังเป็น NONE แปลว่าโดนกดก่อนที่
	# marker จะผูกกับ event ใด ๆ — eventMap[NONE] ไม่มีคีย์นี้ จะ crash
	if not EventManager.eventMap.has(cur_id):
		push_warning("CautionMarker ถูกกดตอนที่ยังไม่มี event ผูกอยู่ (cur_id=%d)" % cur_id)
		return
	caution_press.emit(cur_id, EventManager.eventMap[cur_id])
