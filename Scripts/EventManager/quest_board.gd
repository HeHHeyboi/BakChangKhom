class_name QuestBoard extends CanvasLayer

@export var QuestList: Node

var _event_map: Dictionary[Event, Label] = { }


func update_task(text: String, event: Event) -> void:
	if _event_map.has(event):
		var label = _event_map.get(event)
		if text == "":
			_event_map.erase(event)
			label.queue_free()
		else:
			label.text = "- " + text
	else:
		var label = Label.new()
		label.text = "- " + text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		QuestList.add_child(label)
		_event_map.set(event, label)
