extends TextureButton

@onready var notify = $"caution"


func _process(delta: float) -> void:
	if EventManager.currentEvent == EventManager.MainEvent.GRANDMA:
		notify.show()
	else:
		notify.hide()


func _on_pressed() -> void:
	if EventManager.currentEvent == EventManager.MainEvent.GRANDMA:
		EventManager.currentEvent = EventManager.MainEvent.GOTO_ROOM
		var arr = ["ขม", "ยาย"]
		DialogScene.show_dialog(
			"res://Assets/Chapter1ReturnHome.txt", "res://Assets/Background/Chapter2_bg.jpg", arr
		)
