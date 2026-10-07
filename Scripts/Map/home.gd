extends Button


func _process(_delta: float) -> void:
	self.disabled = SceneRouter.current_id == SceneRouter.HOME


func _on_pressed() -> void:
	MapPanel.showmap(SceneRouter.HOME)
