extends TextureButton

@onready var notify = $"caution"


func _process(_delta: float) -> void:
	if DialogScene.visible:
		self.disabled = true
	else:
		self.disabled = false

	if EventManager.currentEvent == EventManager.MainEvent.GRANDMA:
		notify.show()
	else:
		notify.hide()


func _on_pressed() -> void:
	if EventManager.currentEvent == EventManager.MainEvent.GRANDMA:
		var arr = ["ขม", "ยาย"]
		EventManager.currentEvent = EventManager.MainEvent.CLEAN_RAM
		EventManager.show_dialog(
			"บ้านของยาย", "res://Assets/Chapter1ReturnHome.txt", "Chapter2_bg.jpg", arr
		)
