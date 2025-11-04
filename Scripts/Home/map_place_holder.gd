extends Button


func _process(delta: float) -> void:
	if Global.isDialogShown():
		self.disabled = true
	else:
		self.disabled = false


func _on_map_button_pressed() -> void:
	MapPanel.show()
