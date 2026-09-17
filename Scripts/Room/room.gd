extends Control

var minigame = Global.ReturnMiniGame("MiniGame1") as Node2D


func _ready() -> void:
	DialogScene.on_dialog_finish.connect(self._on_dialog_finish)
	pass # Replace with function body.


func _on_dialog_finish():
	EventManager.show_tutorial(EventManager.TutorialState.RAM_CLEANING)
	get_tree().root.add_child(minigame)
	Global.in_minigame = true
	pass


const EventID = EventManager.EventID


func _on_event_pressed(id: EventID, event: Event) -> void:
	if id == EventID.MAIN:
		if event.currentTask == 1:
			EventManager.hideUI()
			EventManager.update_event(id)
			DialogScene.show_dialog(Constant.MAIN_DIALOG_1, "")
			DialogScene.set_title("ห้องของขม")
	pass
