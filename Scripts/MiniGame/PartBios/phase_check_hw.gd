extends Phase2D
## Phase 3 · CHECK_HW — ตอบ 3 คำถามจากค่าบนจอ BIOS (ปุ่มตัวเลือกใน rail) · ตอบผิด −5 read แล้วตอบใหม่ได้
## [Claude 2 ต.ค. 2569]

## [คำถาม, [ตัวเลือก...], ข้อที่ถูก, หัวข้อปิ๊บเมื่อตอบผิด]
const QUESTIONS := [
	["BIOS เห็นแรมรวมกี่ GB?", ["8 GB", "16 GB", "32 GB"], 1, "CHECK_WRONG_GB"],
	["แรมวิ่งเต็มความเร็วข้างกล่อง (3200) หรือยัง?", ["เต็มแล้ว", "ยัง วิ่งแค่ 2133"], 1, "CHECK_WRONG_SPEED"],
	["ดิสก์ที่มี Windows ของลูกค้ายังอยู่มั้ย?", ["อยู่ (SATA 1)", "หายไปแล้ว"], 0, "CHECK_WRONG_DISK"],
]

var _built := false
var _rail: VBoxContainer
var _box: VBoxContainer
var _q := 0
var _wrong := {}
var _done := false


func init():
	if not _built:
		_built = true
		_rail = PhaseUI.make_frame(self, "ซ่อมเครื่องค้าง BIOS — ขั้นที่ 3/8 · ตรวจฮาร์ดแวร์")
		_box = VBoxContainer.new()
		_box.add_theme_constant_override("separation", 6)
		_rail.add_child(_box)
	_q = 0
	_wrong.clear()
	_done = false
	show()
	allow([node("MemPanel"), node("StoragePanel")])
	cam(&"Bios")
	listen(owner.pib.all_lines_finished, _on_pib_done)
	_show_q()
	say("CHECK_HW")


func _show_q() -> void:
	for c in _box.get_children():
		c.queue_free()
	if _q >= QUESTIONS.size():
		return
	var qd: Array = QUESTIONS[_q]
	PhaseUI.label(_box, "ข้อ %d/%d  %s" % [_q + 1, QUESTIONS.size(), qd[0]], 18, PhaseUI.COL_OK)
	for i in (qd[1] as Array).size():
		rail_button(_box, qd[1][i], answer.bind(i))
	PhaseUI.refresh(self)


func answer(i: int) -> void:
	if _done or _q >= QUESTIONS.size():
		return
	var qd: Array = QUESTIONS[_q]
	if i != qd[2]:
		if not _wrong.has(_q):
			_wrong[_q] = true
			mistake.emit(&"read", 5)
		say(qd[3], PibHint.Mood.WORRY)
		return
	_q += 1
	if _q >= QUESTIONS.size():
		_done = true
		_show_q()
		say("CHECK_HW_DONE", PibHint.Mood.HAPPY)
	else:
		_show_q()


func _on_pib_done() -> void:
	if visible and _done:
		finish()
