extends TextureButton

@onready var notify = $"caution"


func _on_pressed() -> void:
	if notify.visible:
		var arr = ["ขม", "ยาย"]
		EventManager.update_event(EventManager.EventID.MAIN)
		EventManager.show_dialog(
			"บ้านของยาย", "res://Assets/Chapter1ReturnHome.txt", "Chapter2_bg.jpg", arr
		)
