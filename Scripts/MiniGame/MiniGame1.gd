extends Node2D

@onready var eraser = $"Eraser" as Sprite2D
@onready var ram = $"Ram" as Sprite2D

@onready var pos1 = $"pos1" as Marker2D
@onready var pos2 = $"pos2" as Marker2D
@onready var button = $"MiniGame" as Control
@onready var startText = $"StartText" as Label
@onready var miniGameBG = $"MiniGameBackgroud" as Panel

var moveRight = true
var moving = true
var isStart = false
var isFinish = false
var goalPos
var curPos
var clikTime = 0
var t = 1.0
var RamIMG = [
	load("res://Assets/MiniGame/ramDirty.png"),
	load("res://Assets/MiniGame/ramSligtDirty.png"),
	load("res://Assets/MiniGame/ram.png")
]

enum RamStatus { DIRTY = 0, BETTER = 10, CLEAN = 15 }


func _ready() -> void:
	goalPos = pos1.position
	curPos = pos1.position
	eraser.position = curPos
	
	# แสดงยางลบตั้งแต่แรกเพื่อให้คลิกได้
	eraser.show()
	startText.text = "คลิกที่ยางลบเพื่อเริ่ม"
	
	# ปรับขนาดตัวอักษรให้เล็กลง (เปลี่ยนจากค่าเดิมที่อาจจะใหญ่ไป)
	startText.add_theme_font_size_override("font_size", 42)
	# ปรับให้ข้อความอยู่ตรงกลาง (เผื่อกล่องขยายเกินจอ)
	startText.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


	# ปรับขนาดตัวอักษรของปุ่ม Return to Room ที่ซ่อนอยู่ (เผื่อใหญ่เกินกรอบ)
	for n in miniGameBG.get_children():
		if n is Button:
			n.add_theme_font_size_override("font_size", 30)
	
	# Antigravity: แสดง Progress Bar และสอนซ่อมเมื่อเข้ามินิเกม
	if get_tree().root.has_node("Navi"):
		Navi.guide_repair()
		Navi.show_progress(RamStatus.CLEAN)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if !isStart:
			# เช็คว่าคลิกคลิกซ้าย และตำแหน่งเมาส์อยู่ในกรอบขอบเขตของยาบลบ
			if event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
				var local_pos = eraser.get_local_mouse_position()
				if eraser.get_rect().has_point(local_pos):
					isStart = true
					ram.show()
					button.show()
					miniGameBG.show()
					startText.hide()


func _physics_process(delta: float) -> void:
	if moving && !isFinish:
		t += delta * 2
		if t >= 1.0:
			t = 1.0
			moving = false
		eraser.position = curPos.lerp(goalPos, t)

	match clikTime:
		RamStatus.DIRTY:
			ram.texture = RamIMG[0]
		RamStatus.BETTER:
			ram.texture = RamIMG[1]
		RamStatus.CLEAN:
			ram.texture = RamIMG[2]


func _on_button_pressed() -> void:
	if moveRight:
		goalPos = pos2.position
		curPos = pos1.position
	else:
		goalPos = pos1.position
		curPos = pos2.position
	t = 1.0 - t
	moveRight = !moveRight
	moving = true

	clikTime += 1
	# Antigravity: อัปเดต Progress Bar ทุกครั้งที่คลิก
	if get_tree().root.has_node("Navi"):
		Navi.update_progress(clikTime)

	if clikTime == RamStatus.CLEAN:
		isFinish = true
		button.hide()
		# Antigravity: ซ่อน Progress Bar และซ่อน Quest เมื่อซ่อมเสร็จ
		if get_tree().root.has_node("Navi"):
			Navi.hide_progress()
			Navi.hide_quest()
			Navi.show_tip("เยี่ยมเลยครับ! ซ่อม RAM เสร็จแล้ว ✨ กลับไปรายงานยายได้เลย", 6.0)
		for n in miniGameBG.get_children():
			n.show()


func _on_return_pressed() -> void:
	Global.in_minigame = false
	EventManager.currentEvent = EventManager.MainEvent.MAIN_FINISH
	TimeSystem.change_time(TimeSystem.TIME.NOON)
	get_tree().root.remove_child(self)
