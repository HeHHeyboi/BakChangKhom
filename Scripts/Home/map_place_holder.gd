extends Button

@onready var map = self.get_parent().get_node("Map") as Control


func _on_map_button_pressed() -> void:
	map.show()
