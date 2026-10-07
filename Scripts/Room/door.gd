extends TextureButton


func _on_pressed() -> void:
	if Global.isDialogShown() or Global.isInMinigame():
		return
	SceneRouter.go(SceneRouter.HOME)
