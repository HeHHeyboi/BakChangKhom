extends TextureButton

@export var notify: TextureRect


func _on_pressed() -> void:
	# ห้ามเปลี่ยนฉากระหว่างบทสนทนาหรือมินิเกม ไม่งั้นฉากใต้ UI จะถูกปล่อยทิ้ง
	# แล้วเหลือแต่ฉากใหม่กับมินิเกมที่ค้างอยู่บน root
	if Global.isDialogShown() or Global.isInMinigame():
		return
	SceneRouter.go(SceneRouter.ROOM)