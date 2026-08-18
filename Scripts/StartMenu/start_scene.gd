extends Control

@export var SettingScene: TextureRect
@export var tutorial: TextureRect
var showTutorial = false


func _ready() -> void:
	EventManager.hideUI()
	EventManager.on_tutorial_finish.connect(tutorial_end)


func tutorial_end():
	get_tree().change_scene_to_file(Constant.HOME_SCENE)
	EventManager.show_dialog("ออฟฟิส", Constant.PROLOUGE_TEXT, Constant.PLACEHOLDER_IMAGE)
	Global.on_start = false
	showTutorial = false
	EventManager.showUI()
	self.hide()
	EventManager.on_tutorial_finish.disconnect(tutorial_end)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_option_button_pressed() -> void:
	SettingScene.show()


func _on_start_button_pressed() -> void:
	showTutorial = true
	EventManager.show_tutorial(EventManager.TutorialState.BASIC_START)
