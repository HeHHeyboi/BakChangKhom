extends Button

@export var print_event: Event


func _on_button_down() -> void:
	print_event.emit("Hello")
	pass  # Replace with function body.
