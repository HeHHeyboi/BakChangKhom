extends Phase2D
## Phase 9 · SUMMARY — การ์ดสรุป ดาว คะแนน 6 หมวด อุณหภูมิ ปุ่มกลับ (โครงเดียวกับ Part RAM)
## ⭐⭐⭐ ต้องได้ ≥ 95 และอุณหภูมิ ≤ 60°C (PART_MAINBOARD_DESIGN.md หัวข้อ 9) · [Claude 2 ต.ค. 2569]

const FULL := { &"inspect": 15, &"safety": 15, &"tools": 20, &"cpu": 25, &"paste": 15, &"screws": 10 }
const NAMES := {
	&"inspect": "ตรวจสภาพ",
	&"safety": "ความปลอดภัย + ESD",
	&"tools": "เลือกอุปกรณ์เช็ด",
	&"cpu": "วาง CPU",
	&"paste": "ซิลิโคน (ชนิด + ปริมาณ)",
	&"screws": "ลำดับขันน็อต",
}
const STAR_AT := [60, 80, 95]
const LEARNED := [
	"ซิลิโคนไล่อากาศระหว่าง CPU กับฮีตซิงก์ ไม่ใช่กาว",
	"สามเหลี่ยมทองต้องตรงกัน CPU ลงเอง ห้ามกด",
	"ทาเท่าเม็ดถั่วเขียว ไม่ต้องเกลี่ย",
	"ขันน็อตแบบทแยงมุมให้แรงกดเท่ากัน",
]

var _built := false
var _stars: Label
var _total: Label
var _temp: Label
var _rows: VBoxContainer
var _back: Button
var total := 0


func init():
	if not _built:
		_build()
	total = 0
	for c in _rows.get_children():
		c.queue_free()
	for k in FULL:
		var got: int = maxi(FULL[k] - int(owner._mistakes.get(k, 0)), 0)
		total += got
		var l := PhaseUI.label(_rows, "%s   %d / %d" % [NAMES[k], got, FULL[k]], 18, Color(0.15, 0.12, 0.1))
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
	var stars := 0
	for s in STAR_AT:
		if total >= s:
			stars += 1
	if stars == 3 and owner.temp_result > 60.0:
		stars = 2
	_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	_total.text = "คะแนน %d / 100  ·  %s" % [total, "ผ่าน" if total >= 60 else "ยังไม่ผ่าน"]
	_temp.text = "อุณหภูมิ CPU ตอนโหลดเต็ม  %d°C%s" % [int(owner.temp_result), "   (ขาซ็อกเก็ตพับไป 1 ครั้ง)" if owner.pins_bent else ""]
	_back.disabled = false
	show()
	allow([])
	stage().user_camera = false
	nav_enabled = false
	cam(&"Overview")
	say("SUMMARY", PibHint.Mood.HAPPY)


func _build() -> void:
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = PhaseUI.SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := PhaseUI.panel(self, Rect2(96, 24, 960, 440), "Card", Color(0.97, 0.95, 0.9, 0.96))
	var dark := Color(0.15, 0.12, 0.1)
	_stars = PhaseUI.label(card, "", 64, Color(0.95, 0.7, 0.1))
	_stars.position = Vector2(40, 16)
	_total = PhaseUI.label(card, "", 28, dark)
	_total.position = Vector2(300, 30)
	_temp = PhaseUI.label(card, "", 18, Color(0.55, 0.25, 0.1))
	_temp.position = Vector2(300, 76)
	var learned := PhaseUI.label(card, "สิ่งที่เรียนรู้\n• " + "\n• ".join(LEARNED), 17, dark)
	learned.position = Vector2(40, 130)
	learned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	learned.size = Vector2(440, 230)
	var head := PhaseUI.label(card, "ตารางคะแนน", 18, dark)
	head.position = Vector2(520, 130)
	_rows = VBoxContainer.new()
	_rows.position = Vector2(520, 165)
	_rows.size = Vector2(400, 200)
	card.add_child(_rows)
	_back = PhaseUI.button(card, "กลับ ►", Rect2(760, 370, 170, 52), _on_back)


func _on_back() -> void:
	if not visible:
		return
	_back.disabled = true
	finish()
