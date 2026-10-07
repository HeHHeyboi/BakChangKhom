extends Button


func _process(_delta: float) -> void:
	self.disabled = SceneRouter.current_id == SceneRouter.MARKET


func _on_market_pressed() -> void:
	MapPanel.showmap(SceneRouter.MARKET)
