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
		for spec: QteSpec in [ALIGN, PRESS]:
			for msg in spec.problems():
				push_warning("QteSpec %s: %s" % [spec.resource_path, msg])
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
	if _slot != null:
		return # กันวางซ้ำระหว่างกำลังเล่น QTE
	_slot = s
	PhaseUI.set_check(_chk[0], true)
	cam(&"Slots")
	await wait(0.25)
	if not _alive():
		return
	p.position.y -= RAISED # วางแล้วแต่ยังไม่ลงสุด
	p.mode = Item2D.Mode.STATIC # ระหว่าง QTE ลากไม่ได้
	allow([])
	if s != node("SlotA2"):
		say_text(["ใส่ได้เหมือนกัน แต่ถ้ามีสองแถวต้องคู่ A2 กับ B2 นะ เรื่องนี้เดี๋ยวได้เรียนตอน Front Panel"])
		await wait(1.2)
	if _qte() == null:
		push_warning("PhaseInstall: ไม่มี QteRunner — ใส่แรมให้เลย")
	else:
		await _qte_align(p)
		if not _alive():
			return
		await _qte_press(p)
	if not _alive():
		return
	for l in _slot.locks:
		if is_instance_valid(l):
			l.set_toggle(false) # คลิก! สลักดีดล็อก
	PhaseUI.set_check(_chk[2], true)
	owner.ram_seated = true
	await wait(0.5)
	if _alive():
		_complete()


## phase ยังเล่นอยู่ (ไม่ถูกข้าม/ปิดมินิเกมระหว่าง await)
func _alive() -> bool:
	return is_inside_tree() and visible and is_instance_valid(owner)


func _qte() -> QteRunner:
	if not is_instance_valid(owner):
		return null
	var q = owner.get("qte")
	return q if is_instance_valid(q) and q.is_inside_tree() else null


## QTE A — ร่องบากต้องตรงสันในสล็อต
func _qte_align(p: Item2D) -> void:
	var q := _qte()
	var base_x := p.position.x
	var follow := func(v: float) -> void:
		if is_instance_valid(p):
			p.position.x = base_x + (v - 0.5) * 2.0 * SWAY
	q.value_changed.connect(follow)
	say(MinigameHeader.INSTALL_QTE_ALIGN)
	for i in MAX_TRIES:
		await _wait_pib()
		if not _alive() or not is_instance_valid(q):
			break
		var r: QteRunner.Result = await q.run(ALIGN, p, owner.qte_zone_scale())
		if not _alive():
			break
		if r != QteRunner.Result.MISS:
			break
		if i == MAX_TRIES - 1:
			_help(&"align")
		else:
			toast(MinigameHeader.INSTALL_QTE_ALIGN_MISS)
			await wait(0.5)
	if is_instance_valid(q) and q.value_changed.is_connected(follow):
		q.value_changed.disconnect(follow)
	if not _alive() or not is_instance_valid(p):
		return
	var tw := create_tween()
	tw.tween_property(p, "position:x", base_x, 0.12)
	await tw.finished
	PhaseUI.set_check(_chk[1], true)


## QTE B — กดค้างให้แรมลง ปล่อยตอนสลักดีด
func _qte_press(p: Item2D) -> void:
	var q := _qte()
	if q == null:
		return
	var top_y := p.position.y
	var zone_x := maxf(PRESS.zone.x, 0.01)
	var follow := func(v: float) -> void:
		if is_instance_valid(p):
			p.position.y = top_y + RAISED * minf(v / zone_x, 1.0)
	q.value_changed.connect(follow)
	say(MinigameHeader.INSTALL_QTE_PRESS)
	for i in MAX_TRIES:
		await _wait_pib()
		if not _alive() or not is_instance_valid(q):
			break
		var r: QteRunner.Result = await q.run(PRESS, p, owner.qte_zone_scale())
		if not _alive():
			break
		if r != QteRunner.Result.MISS:
			break
		var over: bool = q.last_value > maxf(PRESS.zone.x, PRESS.zone.y)
		if over:
			_penalize(&"press_over")
		if i == MAX_TRIES - 1:
			_help(&"press")
		else:
			toast(MinigameHeader.INSTALL_QTE_PRESS_OVER if over else MinigameHeader.INSTALL_QTE_PRESS_EARLY)
			p.position.y = top_y # แรมเด้งกลับขึ้นมา
			await wait(0.5)
	if is_instance_valid(q) and q.value_changed.is_connected(follow):
		q.value_changed.disconnect(follow)
	if is_instance_valid(p):
		p.position.y = top_y + RAISED


## รอให้ผู้เล่นกดปิดกล่องคำพูดปิ๊บก่อน — ไม่งั้นคลิกปิดกล่องจะนับเป็นการกด QTE
## เช็กทุก 0.1 วิ (ไม่ await สัญญาณตรง ๆ กันค้างถ้าปิ๊บถูกซ่อนแบบอื่น) · รอได้นานสุด PIB_WAIT_MAX วิ
const PIB_WAIT_MAX := 60.0
func _wait_pib() -> void:
	if not _alive():
		return
	await get_tree().process_frame
	var t := 0.0
	while _alive() and t < PIB_WAIT_MAX:
		var pib = owner.get("pib")
		if not is_instance_valid(pib) or not pib.visible or not pib.dialog_panel.visible or pib._closing:
			break
		await wait(0.1)
		t += 0.1
	if _alive():
		await wait(0.2)


## พลาด 3 ครั้ง → ปิ๊บช่วยทำให้ (หักคะแนน)
func _help(key: StringName) -> void:
	if not _alive():
		return
	_penalize(StringName("help_" + key))
	say(MinigameHeader.INSTALL_QTE_HELP, PibHint.Mood.HAPPY)


func _penalize(key: StringName) -> void:
	if _penalized.has(key):
		return
	_penalized[key] = true
	mistake.emit(&"handling", MISS_POINTS)


func _complete() -> void:
	var ram := node("RamA2") as Item2D
	if ram:
		ram.mode = Item2D.Mode.DRAGGABLE
	finish()
