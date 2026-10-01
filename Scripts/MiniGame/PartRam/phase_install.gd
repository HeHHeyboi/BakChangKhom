extends Phase2D
## Phase 6 · INSTALL — ลากแรมจากแผ่น ESD กลับลงสล็อต (หันร่องบากให้ตรง · R หมุน) แล้วคลิกแรม 2 ครั้งกดลงจนสลักล็อก
## [Claude 29 ก.ย. 2569] โค้ด + ฉาก 2.5D · กด "เสร็จแล้ว" ก่อนสลักล็อก = ใส่ไม่สุด → VERIFY ไม่ผ่าน + −10 tidiness (หักตอน VERIFY)

const PRESS_NEEDED := 2
const RAISED := 10.0 # แรมลอยค้างเท่านี้ (พิกเซล) ก่อนกดลงสุด

var _presses := 0
var _slot: Socket2D
var _built := false
var _chk: Array[Label] = []
var _done_btn: Button


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมแรม — ขั้นที่ 6/8 · ใส่แรมกลับ")
		PhaseUI.set_rail_overlay(rail,true)
		PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
		print(PhaseUI.is_rail_overlay(rail))
		for t in ["ลากแรมลงสล็อต (ร่องบากตรงสันเหลือง)", "คลิกแรม 2 ครั้งกดลงจนสลักล็อก"]:
			_chk.append(PhaseUI.check_item(rail, t))
		rail_button(
			rail,
			"↻ หมุนแรมในมือ (R)",
			func():
				stage().rotate_held(),
		)
		_done_btn = rail_button(rail, "เสร็จแล้ว ►", _on_done)
	_presses = 0
	_slot = null
	for c in _chk:
		PhaseUI.set_check(c, false)
	_done_btn.disabled = true
	var ram := node("RamA2") as Item2D
	ram.mode = Item2D.Mode.DRAGGABLE
	ram.set_yaw(180.0 if randf() < 0.5 else 0.0, false) # บางรอบวางกลับด้านไว้ ผู้เล่นต้องสังเกตเอง (กด R หมุน)
	show()
	allow([ram])
	var slots: Array = []
	for n in ["SlotA1", "SlotA2", "SlotB1", "SlotB2"]:
		slots.append(node(n))
	allow_sockets(slots)
	cam(&"Mat")
	listen(
		stage().part_returned,
		func(_p):
			cam(&"Mat"),
	)
	listen(stage().part_installed, _on_installed)
	listen(stage().drop_rejected, _on_rejected)
	listen(stage().part_clicked, _on_clicked)
	say(MinigameHeader.INSTALL)


func _on_rejected(_p: Item2D, _s: Socket2D, reason: Socket2D.Result) -> void:
	match reason:
		Socket2D.Result.WRONG_ORIENTATION:
			toast(MinigameHeader.INSTALL_FLIPPED)
		Socket2D.Result.LOCKED:
			say_text(["สลักของช่องนั้นยังล็อกอยู่ กางออกก่อนนะ"])


func _on_installed(p: Item2D, s: Socket2D) -> void:
	if s.accept_any:
		cam(&"Mat")
		return
	_slot = s
	PhaseUI.set_check(_chk[0], true)
	cam(&"Slots")
	await wait(0.25)
	p.position.y -= RAISED # วางแล้วแต่ยังไม่ลงสุด
	p.mode = Item2D.Mode.CLICK # ตอนนี้คลิก = กดลง
	allow([p])
	_done_btn.disabled = false
	if s != node("SlotA2"):
		say_text(["ใส่ได้เหมือนกัน แต่ถ้ามีสองแถวต้องคู่ A2 กับ B2 นะ เรื่องนี้เดี๋ยวได้เรียนตอน Front Panel"])


func _on_clicked(p: Item2D) -> void:
	if p != node("RamA2") or _slot == null or _presses >= PRESS_NEEDED:
		return
	_presses += 1
	var tw := create_tween()
	tw.tween_property(p, "position:y", p.position.y + RAISED / PRESS_NEEDED + 3.0, 0.06)
	tw.tween_property(p, "position:y", p.position.y + RAISED / PRESS_NEEDED, 0.06)
	if _presses >= PRESS_NEEDED:
		for l in _slot.locks:
			l.set_toggle(false) # คลิก! สลักดีดล็อก
		PhaseUI.set_check(_chk[1], true)
		owner.ram_seated = true
		await wait(0.5)
		_complete()


func _on_done() -> void:
	if _slot == null:
		return
	owner.ram_seated = _presses >= PRESS_NEEDED
	_complete()


func _complete() -> void:
	(node("RamA2") as Item2D).mode = Item2D.Mode.DRAGGABLE
	finish()
