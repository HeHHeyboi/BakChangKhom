extends SceneHotspot
## ทางออกร้าน → หน้าบ้านยาย · [Claude 9 ต.ค. 2569] เดิมเป็นรูปประตูวาด ตอนนี้เป็นจุดกดทับประตูในภาพร้าน


func _on_pressed() -> void:
	if Global.isDialogShown() or Global.isInMinigame():
		return
	SceneRouter.go(SceneRouter.HOME)
