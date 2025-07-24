extends TextureButton

@onready var notify = $"caution" as TextureRect


func _process(delta: float) -> void:
	if EventManager.currentEvent == EventManager.MainEvent.GOTO_ROOM:
		notify.show()
	else:
		notify.hide()


func _on_pressed() -> void:
	if EventManager.currentEvent == EventManager.MainEvent.GOTO_ROOM:
		EventManager.currentEvent = EventManager.MainEvent.CLEAN_RAM

	get_tree().change_scene_to_file("res://Scene/Room.tscn")
