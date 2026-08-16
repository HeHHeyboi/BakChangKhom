extends Control

@export var SettingScene: TextureRect
@export var Tutorial: TextureRect
var showTutorial = false


func _enter_tree() -> void:
	EventManager.hideTimeUI(true)
	EventManager.hideQuest(true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and showTutorial:
			get_tree().change_scene_to_file("res://Scene/Location/Home.tscn")
			EventManager.show_dialog("ออฟฟิส", "res://Assets/Prolouge.txt", "placeholder.png")
			Global.on_start = false
			EventManager.hideTimeUI(false)
			EventManager.hideQuest(false)
			self.hide()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_option_button_pressed() -> void:
	SettingScene.show()


func _on_start_button_pressed() -> void:
	showTutorial = true
	Tutorial.show()
