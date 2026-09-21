extends TextureButton


func _on_pressed() -> void:
	if Global.isDialogShown() or Global.isInMinigame():
		return
	get_tree().change_scene_to_file(Constant.HOME_SCENE)
