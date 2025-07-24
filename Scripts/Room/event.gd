extends TextureButton

var minigame = Global.ReturnMiniGame("MiniGame1") as Node2D


func _process(delta: float) -> void:
	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
		self.show()
	else:
		self.hide()


func _on_pressed() -> void:
	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
		EventManager.currentEvent = EventManager.MainEvent.MAIN_FINISH

	get_tree().root.add_child(minigame)
