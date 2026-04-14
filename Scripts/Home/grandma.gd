extends TextureButton

@onready var notify = $"caution"

# func _enter_tree() -> void:
# 	EventManager.sendUpdatedEvent.connect(processEvent)
#
#
# func _exit_tree() -> void:
# 	EventManager.sendUpdatedEvent.disconnect(processEvent)

# func _ready() -> void:
# processEvent()

# func processEvent():
# if EventManager.currentEvent == EventManager.MainEvent.GRANDMA:
# 	notify.show()
# else:
# 	notify.hide()

# func _process(_delta: float) -> void:
# 	if DialogScene.visible:
# 		self.disabled = true
# 	else:
# 		self.disabled = false


func _on_pressed() -> void:
	if notify.visible:
		var arr = ["ขม", "ยาย"]
		EventManager.update_event()
		EventManager.show_dialog(
			"บ้านของยาย", "res://Assets/Chapter1ReturnHome.txt", "Chapter2_bg.jpg", arr
		)
