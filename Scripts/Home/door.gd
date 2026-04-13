extends TextureButton

@export var notify: TextureRect


func _enter_tree() -> void:
	EventManager.sendUpdatedEvent.connect(processEvent)
	processEvent()


func _exit_tree() -> void:
	EventManager.sendUpdatedEvent.disconnect(processEvent)


func processEvent():
	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
		notify.show()
	else:
		notify.hide()


# func _process(_delta: float) -> void:
# 	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
# 		notify.show()
# 	else:
# 		notify.hide()


func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/Room.tscn")
