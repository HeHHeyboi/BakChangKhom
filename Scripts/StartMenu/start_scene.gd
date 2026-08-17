extends Control

@export var SettingScene: TextureRect
@export var tutorial: TextureRect
var showTutorial = false


func _ready() -> void:
	EventManager.hideUI()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and showTutorial:
			get_tree().change_scene_to_file(Constant.HOME_SCENE)
			EventManager.show_dialog("ออฟฟิส", Constant.PROLOUGE_TEXT, Constant.PLACEHOLDER_IMAGE)
			Global.on_start = false
			EventManager.showUI()
			self.hide()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_option_button_pressed() -> void:
	SettingScene.show()


func _on_start_button_pressed() -> void:
	showTutorial = true
	tutorial.show()
