extends Control

@export var SettingScene: TextureRect
@export var tutorial: TextureRect
var showTutorial = false


func _ready() -> void:
	EventManager.hideUI()
	EventManager.on_tutorial_finish.connect(tutorial_end)
	EventManager.on_dialog_end.connect(dialog_end)

func dialog_end():
	SceneRouter.go(SceneRouter.HOME)
	Fade.set_opacity(1)
	EventManager.on_dialog_end.disconnect(dialog_end)

	
func tutorial_end():

	EventManager.show_dialog("ออฟฟิส", Constant.PROLOUGE_TEXT, Constant.OFFICE_BG)
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
