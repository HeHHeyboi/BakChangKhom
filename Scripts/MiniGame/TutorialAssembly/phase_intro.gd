extends Phase2D
## Phase 1 · INTRO — คลิกชิ้นบนแผ่นรองทีละชิ้น → การ์ดชื่อ/หน้าที่/Part ที่จะได้ซ่อม · ครบทุกชิ้นแล้วไปต่อ
## ระหว่าง phase นี้ชิ้นส่วนเป็นโหมด CLICK (ลากไม่ได้) · BUILD จะเปลี่ยนกลับเป็น DRAGGABLE

var _built := false
var _checks := {} # Item2D → Label
var _done := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ประกอบคอม — ขั้นที่ 1/4 · รู้จักชิ้นส่วน")
		PhaseUI.label(rail, "ชิ้นส่วนในคอม", 20, PhaseUI.COL_OK)
		for p in owner.parts():
			_checks[p] = PhaseUI.check_item(rail, p.data.display_name)
	_done = false
	for p in owner.parts():
		p.mode = Item2D.Mode.CLICK
		PhaseUI.set_check(_checks[p], false)
	show()
	allow(owner.parts())
	cam(&"Tray")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("ASM_INTRO")
	_next_hint()


func _on_clicked(p: Item2D) -> void:
	if not _checks.has(p):
		return
	PhaseUI.set_check(_checks[p], true)
	PhaseUI.part_card(self, p.data.display_name, p.data.role, owner.core_name(p.data))
	p.tint(Color(1, 0.95, 0.7))
	get_tree().create_timer(0.4).timeout.connect(p.clear_tint)
	_next_hint()


func _next_hint() -> void:
	for p in owner.parts():
		if not _checks[p].get_meta("done", false):
			hint(p, "คลิกดูชิ้นนี้", 6.0)
			return
	clear_hint()
	if not _done:
		_done = true
		await wait(1.5)
		say("ASM_INTRO_DONE", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if visible and _done:
		PhaseUI.hide_card(self)
		finish()
