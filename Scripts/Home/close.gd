extends Button

@export var map: Control


func _on_close_button_pressed() -> void:
	map.hide()
