extends Control


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_option_button_pressed() -> void:
	pass  # Replace with function body.


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/MainGame.tscn")
	DialogScene.show_dialog("res://Assets/Prolouge.txt", null, "res://Assets/Chapter2_bg.jpg")
	self.hide()
