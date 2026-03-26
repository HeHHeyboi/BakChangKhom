extends TextureButton

var minigame = Global.ReturnMiniGame("MiniGame1") as Node2D

var float_tween: Tween

func _ready() -> void:
	self.hide()
	var start_y = self.position.y
	
	# Antigravity: สุ่ม delay เริ่มต้นไม่ให้ caution.png ขยับพะงาบๆ ตรงกันเป๊ะเกินไป
	await get_tree().create_timer(randf_range(0.0, 1.2)).timeout
	if not is_inside_tree(): return
	
	float_tween = create_tween().set_loops()
	float_tween.tween_property(self, "position:y", start_y - 15.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(self, "position:y", start_y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Antigravity: เรียก Navi ให้สะกิดตอนเข้ามาในห้อง
	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
		if get_tree().root.has_node("Navi"):
			Navi.guide_to_desk()


func _process(_delta: float) -> void:
	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
		self.show()
	else:
		self.hide()


func _on_pressed() -> void:
	get_tree().root.add_child(minigame)
	Global.in_minigame = true
