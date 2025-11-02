extends Button


func _process(delta: float) -> void:
	if MapPanel.visible:
		self.disabled = true
	else:
		self.disabled = false


func _on_pressed() -> void:
	if !MapPanel.visible:
		MapPanel.visible = true
