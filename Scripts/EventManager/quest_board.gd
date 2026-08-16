class_name QuesetBoard extends CanvasLayer

signal on_update_task(String)

@export var QuestList: Node

var _event_map: Dictionary[Event,Label] = {}


# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	on_update_task.connect(self._on_update_task)


func _exit_tree() -> void:
	on_update_task.disconnect(self._on_update_task)


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


func _on_update_task(text: String) -> void:
	print(text)
