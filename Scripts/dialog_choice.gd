extends Button

signal get_choice(button: Button)


func _on_pressed() -> void:
	get_choice.emit(self)
