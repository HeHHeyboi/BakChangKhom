extends TextureButton

@onready var notify = $"caution" as TextureRect
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
	if EventManager.currentEvent == EventManager.MainEvent.CLEAN_RAM:
		notify.show()
	else:
		notify.hide()


func _on_pressed() -> void:
	# Antigravity: ซ่อน Quest panel เมื่อเข้าห้องแล้ว
	if get_tree().root.has_node("Navi"):
		Navi.hide_quest()
	get_tree().change_scene_to_file("res://Scene/Room.tscn")
