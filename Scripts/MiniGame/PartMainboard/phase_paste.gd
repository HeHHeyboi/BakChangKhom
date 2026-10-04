extends Phase2D
## Phase 7 · PASTE — เลือกชนิดซิลิโคน แล้วลากแถบกะปริมาณ → บีบลงกลาง CPU
## ชนิด: นำความร้อนธรรมดา ✅ · โลหะเหลว 🟡 −5 (ปิ๊บไม่ให้ใช้ในงานร้าน) · กาว/ยาสีฟัน ❌ −10
## ปริมาณ: น้อย (< 35) ผ่านแต่ร้อนขึ้น +8°C −5 · พอดี (35–65) ✅ · มาก (> 65) ล้น −5 → เช็ดออกแล้วบีบใหม่
## (ดีไซน์เดิมให้ย้อนไป Phase 4 — ในเกมเช็ดออกแล้วลองใหม่ในขั้นนี้เลย ผลเหมือนกันแต่ไม่ต้องเล่นซ้ำยาว)
## [Claude 2 ต.ค. 2569]

const TYPES := [
	["ซิลิโคนนำความร้อน (ไม่นำไฟฟ้า)", "good"],
	["ซิลิโคนโลหะเหลว", "liquid_metal"],
	["กาวตราช้าง", "glue"],
	["ยาสีฟัน", "toothpaste"],
]
const AMOUNT_LOW := 35.0
const AMOUNT_HIGH := 65.0

var _built := false
var _chk: Array[Label] = []
var _type_box: VBoxContainer
var _amount_box: VBoxContainer
var _slider: HSlider
var _amount_label: Label
var _done := false
var _wipe := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเมนบอร์ด — ขั้นที่ 7/8 · ทาซิลิโคน")
		for t in ["เลือกชนิดซิลิโคน", "บีบปริมาณให้พอดี"]:
			_chk.append(PhaseUI.check_item(rail, t))
		_type_box = VBoxContainer.new()
		rail.add_child(_type_box)
		for t in TYPES:
			PhaseUI.rail_button(_type_box, t[0], choose_type.bind(t[1]))
		_amount_box = VBoxContainer.new()
		rail.add_child(_amount_box)
		_amount_label = PhaseUI.label(_amount_box, "", 18, PhaseUI.COL_GOAL)
		_slider = HSlider.new()
		_slider.min_value = 0
		_slider.max_value = 100
		_slider.step = 1
		_slider.custom_minimum_size = Vector2(0, 32)
		_slider.value_changed.connect(_on_amount)
		_amount_box.add_child(_slider)
		PhaseUI.rail_button(_amount_box, "บีบลงกลาง CPU ►", squeeze)
	_done = false
	_wipe = false
	for c in _chk:
		PhaseUI.set_check(c, false)
	_type_box.show()
	_amount_box.hide()
	_slider.value = 10
	_on_amount(_slider.value)
	(node("Cpu") as Item2D).set_state("clean")
	show()
	allow([])
	cam(&"Socket")
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("PASTE_INTRO")


func choose_type(id: String) -> void:
	if _done or not _type_box.visible:
		return
	match id:
		"good":
			PhaseUI.set_check(_chk[0], true)
			_type_box.hide()
			_amount_box.show()
			PhaseUI.refresh(self)
			say("PASTE_TYPE_GOOD", PibHint.Mood.HAPPY)
		"liquid_metal":
			mistake.emit(&"paste", 5)
			say("PASTE_TYPE_LIQUID_METAL", PibHint.Mood.WORRY)
		"glue":
			mistake.emit(&"paste", 10)
			say("PASTE_TYPE_GLUE", PibHint.Mood.WORRY)
		"toothpaste":
			mistake.emit(&"paste", 10)
			say("PASTE_TYPE_TOOTHPASTE", PibHint.Mood.WORRY)


func _on_amount(v: float) -> void:
	var t := "น้อยมาก" if v < 15.0 else ("น้อยไปหน่อย" if v < AMOUNT_LOW else ("ราวเม็ดถั่วเขียว" if v <= AMOUNT_HIGH else "เยอะเกิน"))
	_amount_label.text = "ปริมาณ: %s" % t


func squeeze() -> void:
	if _done or not _amount_box.visible:
		return
	var v := _slider.value
	var cpu := node("Cpu") as Item2D
	if v > AMOUNT_HIGH:
		mistake.emit(&"paste", 5)
		cpu.set_state("large")
		_wipe = true
		_amount_box.hide()
		say("PASTE_AMOUNT_MUCH", PibHint.Mood.WORRY)
		return
	_done = true
	_amount_box.hide()
	PhaseUI.set_check(_chk[1], true)
	PhaseUI.refresh(self)
	if v < AMOUNT_LOW:
		owner.paste_amount = 0
		mistake.emit(&"paste", 5)
		cpu.set_state("small")
		say("PASTE_AMOUNT_LITTLE")
	else:
		owner.paste_amount = 1
		cpu.set_state("ok")
		say("PASTE_AMOUNT_OK", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if not visible:
		return
	if _wipe:
		# ล้นแล้วเช็ดออกด้วย IPA แล้วบีบใหม่
		_wipe = false
		(node("Cpu") as Item2D).set_state("clean")
		_slider.value = 10
		_amount_box.show()
		PhaseUI.refresh(self)
		return
	if _done:
		finish()
