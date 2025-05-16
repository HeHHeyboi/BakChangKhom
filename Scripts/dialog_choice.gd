extends Button
signal get_choice(button: Button)

# func _gui_input(event: InputEvent) -> void:
# 	if event is InputEventMouseButton:
# 		event = event as InputEventMouseButton
# 		if event.get_button_index() == MOUSE_BUTTON_LEFT and event.is_pressed():
# 			emit_signal("get_choice", self)


func _on_pressed() -> void:
	emit_signal("get_choice", self)
