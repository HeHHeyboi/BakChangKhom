extends TextureButton

var minigame = Global.ReturnMiniGame("MiniGame1") as Node2D


func _ready() -> void:
	self.hide()


func _process(_delta: float) -> void:
	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
		self.show()
	else:
		self.hide()


func _on_pressed() -> void:
	get_tree().root.add_child(minigame)
	Global.in_minigame = true
