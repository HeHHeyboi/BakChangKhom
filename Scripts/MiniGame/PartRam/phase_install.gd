extends Phase2D
## Phase 6 · INSTALL — ลากแรมจากแผ่น ESD กลับลงสล็อต (หันร่องบากให้ตรง · R หมุน)
## แล้วเล่น QTE 2 จังหวะ (Docs/CORE_PART_QTE.md 3.1):
##   A จังหวะ (ram_align.tres) — แรมเลื่อนซ้าย-ขวาเหนือสล็อต กดตอนร่องบากตรงสัน · Miss = ลองใหม่ (ไม่หักคะแนน)
##   B กดค้าง (ram_press.tres) — ค้างให้แรมลง ปล่อยในโซนเขียว · ปล่อยเร็ว = ลองใหม่ · ค้างจนสุดเกจ = แรงเกิน −5 handling (ครั้งเดียว)
##   พลาดจุดเดิม 3 ครั้ง → ปิ๊บช่วยทำให้ −5 handling (ครั้งเดียว) · ไม่มีวันติด
## [Claude 29 ก.ย. 2569] โค้ด + ฉาก 2.5D · [Claude 5 ต.ค. 2569] เปลี่ยนคลิก 2 ครั้งเป็น QTE

const ALIGN: QteSpec = preload("res://Resources/Qte/ram_align.tres")
const PRESS: QteSpec = preload("res://Resources/Qte/ram_press.tres")
const RAISED := 10.0 # แรมลอยค้างเท่านี้ (พิกเซล) ก่อนกดลงสุด
const SWAY := 26.0 # QTE A: แรมเลื่อนซ้าย-ขวาได้ไกลสุดเท่านี้ (พิกเซล)
const MAX_TRIES := 3
const MISS_POINTS := 5

var _penalized := {} # หักคะแนนจุดละครั้ง
var _slot: Socket2D
var _built := false
var _chk: Array[Label] = []


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมแรม — ขั้นที่ 6/8 · ใส่แรมกลับ")
		PhaseUI.set_rail_overlay(self, true)
		PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
		for t in ["ลากแรมลงสล็อต (ร่องบากตรงสันเหลือง)", "กดตอนร่องบากตรงสัน (QTE)", "กดค้าง ปล่อยตอนสลักดีด (QTE)"]:
			_chk.append(PhaseUI.check_item(rail, t))
		PhaseUI.rail_button(
			rail,
			"↻ หมุนแรมในมือ (R)",
			func():
				stage().rotate_held(),
		)
	_penalized.clear()
	_slot = null
	for c in _chk:
		PhaseUI.set_check(c, false)
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
	if not visible:
		return
	p.position.y -= RAISED # วางแล้วแต่ยังไม่ลงสุด
	p.mode = Item2D.Mode.STATIC # ระหว่าง QTE ลากไม่ได้
	allow([])
	if s != node("SlotA2"):
		say_text(["ใส่ได้เหมือนกัน แต่ถ้ามีสองแถวต้องคู่ A2 กับ B2 นะ เรื่องนี้เดี๋ยวได้เรียนตอน Front Panel"])
		await wait(1.2)
	await _qte_align(p)
	if not visible:
		return
	await _qte_press(p)
	if not visible:
		return
	for l in _slot.locks:
		l.set_toggle(false) # คลิก! สลักดีดล็อก
	PhaseUI.set_check(_chk[2], true)
	owner.ram_seated = true
	await wait(0.5)
	_complete()


## QTE A — ร่องบากต้องตรงสันในสล็อต
func _qte_align(p: Item2D) -> void:
	var base_x := p.position.x
	var follow := func(v: float): p.position.x = base_x + (v - 0.5) * 2.0 * SWAY
	owner.qte.value_changed.connect(follow)
	say(MinigameHeader.INSTALL_QTE_ALIGN)
	for i in MAX_TRIES:
		await _wait_pib()
		var r: QteRunner.Result = await owner.qte.run(ALIGN, p, owner.qte_zone_scale())
		if not visible:
			break
		if r != QteRunner.Result.MISS:
			break
		if i == MAX_TRIES - 1:
			_help(&"align")
		else:
			toast(MinigameHeader.INSTALL_QTE_ALIGN_MISS)
			await wait(0.5)
	owner.qte.value_changed.disconnect(follow)
	var tw := create_tween()
	tw.tween_property(p, "position:x", base_x, 0.12)
	await tw.finished
	PhaseUI.set_check(_chk[1], true)


## QTE B — กดค้างให้แรมลง ปล่อยตอนสลักดีด
func _qte_press(p: Item2D) -> void:
	var top_y := p.position.y
	var follow := func(v: float): p.position.y = top_y + RAISED * minf(v / PRESS.zone.x, 1.0)
	owner.qte.value_changed.connect(follow)
	say(MinigameHeader.INSTALL_QTE_PRESS)
	for i in MAX_TRIES:
		await _wait_pib()
		var r: QteRunner.Result = await owner.qte.run(PRESS, p, owner.qte_zone_scale())
		if not visible:
			break
		if r != QteRunner.Result.MISS:
			break
		var over: bool = owner.qte.last_value > PRESS.zone.y
		if over:
			_penalize(&"press_over")
		if i == MAX_TRIES - 1:
			_help(&"press")
		else:
			toast(MinigameHeader.INSTALL_QTE_PRESS_OVER if over else MinigameHeader.INSTALL_QTE_PRESS_EARLY)
			p.position.y = top_y # แรมเด้งกลับขึ้นมา
			await wait(0.5)
	owner.qte.value_changed.disconnect(follow)
	p.position.y = top_y + RAISED


## รอให้ผู้เล่นกดปิดกล่องคำพูดปิ๊บก่อน — ไม่งั้นคลิกปิดกล่องจะนับเป็นการกด QTE
func _wait_pib() -> void:
	await get_tree().process_frame
	var pib: PibHint = owner.pib
	while visible and pib and pib.visible and pib.dialog_panel.visible and not pib._closing:
		await pib.all_lines_finished
	await wait(0.2)


## พลาด 3 ครั้ง → ปิ๊บช่วยทำให้ (หักคะแนน)
func _help(key: StringName) -> void:
	_penalize(StringName("help_" + key))
	say(MinigameHeader.INSTALL_QTE_HELP, PibHint.Mood.HAPPY)


func _penalize(key: StringName) -> void:
	if _penalized.has(key):
		return
	_penalized[key] = true
	mistake.emit(&"handling", MISS_POINTS)


func _complete() -> void:
	(node("RamA2") as Item2D).mode = Item2D.Mode.DRAGGABLE
	finish()
