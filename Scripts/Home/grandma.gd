extends TextureButton

@onready var notify = $"caution"
var float_tween: Tween

func _ready() -> void:
	var start_y = notify.position.y
	
	# Antigravity: สุ่ม delay เริ่มต้นไม่ให้ caution.png ขยับพะงาบๆ ตรงกันเป๊ะเกินไป
	await get_tree().create_timer(randf_range(0.0, 1.2)).timeout
	if not is_inside_tree(): return
	
	float_tween = create_tween().set_loops()
	float_tween.tween_property(notify, "position:y", start_y - 15.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(notify, "position:y", start_y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(_delta: float) -> void:
	if DialogScene.visible:
		self.disabled = true
	else:
		self.disabled = false

	if EventManager.currentEvent == EventManager.MainEvent.GRANDMA:
		notify.show()
		# Antigravity: เรียกให้ Navi แนะนำผู้เล่นเมื่อมียายมี Alert
		if get_tree().root.has_node("Navi"):
			Navi.guide_to_grandma()
	else:
		notify.hide()


func _on_pressed() -> void:
	if EventManager.currentEvent == EventManager.MainEvent.GRANDMA:
		EventManager.currentEvent = EventManager.MainEvent.CLEAN_RAM
		var arr = ["ขม", "ยาย"]
		DialogScene.show_dialog("res://Assets/Chapter1ReturnHome.txt", "Chapter2_bg.jpg", arr)
		DialogScene.set_title("บ้านของยาย")
		# Antigravity: แสดง Quest และชี้ทางไปห้องหลังรับเควส
		if get_tree().root.has_node("Navi"):
			Navi.guide_quest_door()
