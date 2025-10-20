extends TextureButton

@onready var notify = $"caution" as TextureRect


func _process(_delta: float) -> void:
	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
		notify.show()
	else:
		notify.hide()


func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/Room.tscn")
