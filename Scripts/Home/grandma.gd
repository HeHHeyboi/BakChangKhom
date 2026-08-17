extends TextureButton

@onready var notify = $"caution"


func _on_pressed() -> void:
	if notify.visible:
		var arr = ["ขม", "ยาย"]
		EventManager.update_event(EventManager.EventID.MAIN)
		EventManager.show_dialog(
			"บ้านของยาย", Constant.CHAPTER1_RETURN_HOME_TEXT, Constant.CHAPTER2_BG_IMAGE, arr
		)
