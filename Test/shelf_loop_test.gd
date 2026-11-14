extends Node
## [Claude 15 พ.ย. 2569 · 0.3.0 ขั้น C–D] ใบรับเครื่อง → ชั้นวาง → ซ่อมจากชั้น → ลูกค้ามารับ/จ่ายเงิน (PLAN_0_3_0 ข้อ 3)
## ฉาก DoorCard · WorkOrderCard · RepairShelfPanel + DayLoop + GameState.pay_pickup
## เปิด Test/shelf_loop_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var ts: TimeSystem
var e: EconomyConfig


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	e = GameState.economy
	DayLoop.day_skip_seconds = 0.0
	DayLoop._reset_run()
	var ram: CustomerCase = load("res://Resources/Customers/lv2_teacher_ram.tres")
	var ram2: CustomerCase = load("res://Resources/Customers/lv2_yai_ram.tres")
	var ram3: CustomerCase = load("res://Resources/Customers/lv2_headman_ram.tres")
	var os_case: CustomerCase = load("res://Resources/Customers/lv1_amnuay_startup.tres")
	DayLoop._parts_seen[&"part_ram"] = true
	DayLoop._parts_seen[ram.part_id] = true
	var slots := DayLoop.job_slots(ram)
	_check(DayLoop.door_card is DoorCard and DayLoop.work_order is WorkOrderCard and DayLoop.shelf_panel is RepairShelfPanel, "ฉากแยก 3 ฉากอยู่ใน DayLoop")
	_check(_layer(DayLoop.door_card) == 90 and _layer(DayLoop.work_order) == 91 and _layer(DayLoop.shelf_panel) == 95, "เลเยอร์: หน้าประตู 90 · ใบรับเครื่อง 91 · ชั้นวาง 95")

	# ---------------- A · ปุ่มรับเครื่อง: ฮาร์ดแวร์ → ใบรับเครื่อง · ขมOS → ทำเลย
	_reset_door(9 * 60)
	DayLoop.door_queue.append(DayLoop.door_entry(ram))
	_show(DayLoop.Card.DOOR)
	_check(_door("Accept").text == "รับเครื่อง" and _door("Detail").text.contains("รับเครื่องไว้ซ่อมบนชั้น"), "งานฮาร์ดแวร์: ปุ่ม \"รับเครื่อง\" · บอกว่ารับเครื่องไว้บนชั้น")
	_door("Accept").pressed.emit()
	_check(DayLoop._work_order_open and DayLoop.door_queue.size() == 1, "กดรับเครื่อง → เปิดใบรับเครื่อง (ลูกค้ายังยืนหน้าประตู)")
	_show(DayLoop.Card.WORK_ORDER)
	var opts := _wo("Options").get_children()
	_check(DayLoop.work_order.visible and not DayLoop.door_card.visible and opts.size() == 3, "ใบรับเครื่องขึ้นแทนการ์ดหน้าประตู · วันนัด 3 แบบ (09:00 ซ่อมทันวันนี้)")
	_check(DayLoop.work_order.selected() == 1 and not _wo("Confirm").disabled, "เลือก \"วันเปิดร้านถัดไป\" ไว้ก่อน")
	var fee := DayLoop._fee(ram)
	_check((opts[0] as Button).text.contains("฿%d" % roundi(fee * e.promise_mult(0))) and (opts[0] as Button).text.contains("วันนี้") and (opts[2] as Button).text.contains("฿%d" % roundi(fee * e.promise_mult(2))), "ตัวเลือกบอกค่าแรงตามวันนัด (×%.1f · ×%.1f)" % [e.promise_mult(0), e.promise_mult(2)])
	_check(_wo("Hint").text.contains("เงินเข้าตอนลูกค้ามารับเครื่อง") and _wo("Shelf").text == "ชั้นวาง 0/2", "ใบรับเครื่องบอกเรื่องเงิน/ผ่อนผัน · ชั้นวาง 0/2")
	_wo("Cancel").pressed.emit()
	_check(not DayLoop._work_order_open and DayLoop.door_queue.size() == 1 and DayLoop.accepted_today == 0, "กดกลับ → ปิดใบรับเครื่อง ลูกค้ายังรอ ไม่นับโควตา")
	DayLoop.open_work_order()
	_show(DayLoop.Card.WORK_ORDER)
	DayLoop.work_order.select(1)
	var money0 := GameState.money
	_wo("Confirm").pressed.emit()
	await _end_dialog()
	var o: RepairShelf.Order = DayLoop._order_of(ram)
	_check(o != null and o.due == ts.shift + 1 and o.state == RepairShelf.State.WAITING and DayLoop.accepted_today == 1 and DayLoop.door_queue.is_empty() and GameState.money == money0, "ออกใบรับเครื่อง → เครื่องขึ้นชั้น นัดวันถัดไป · นับโควตา · ยังไม่ได้เงิน")
	_check(DayLoop.visitor_toast._queue.any(func(q: PackedStringArray) -> bool: return q[0].contains("ฝากเครื่องไว้บนชั้น")), "ป้ายแจ้ง \"ฝากเครื่องไว้บนชั้น\"")
	# ขมOS ไม่เปิดใบรับเครื่อง
	DayLoop.door_queue.append(DayLoop.door_entry(os_case))
	_show(DayLoop.Card.DOOR)
	_check(_door("Accept").text.contains("ทำเลย") and not DayLoop.open_work_order(), "งานขมOS: \"รับงาน (ทำเลย)\" ไม่มีใบรับเครื่อง")
	DayLoop.door_queue.clear()

	# ---------------- B · ใกล้ปิดร้าน ซ่อมไม่ทันวันนี้ → ไม่มี "ด่วน วันนี้" · ชั้นเต็ม → รับไม่ได้
	_reset_door(TimeSystem.CLOSE - 60)
	DayLoop.door_queue.append(DayLoop.door_entry(ram2))
	_check(DayLoop.promise_options_for(ram2).size() == 2 and DayLoop.promise_options_for(ram2)[0]["days"] == 1, "เหลือ 2 เทิร์น ซ่อมไม่ทัน → ไม่มีตัวเลือก \"ด่วน วันนี้\"")
	DayLoop.shelf.slots = 1
	_show(DayLoop.Card.DOOR)
	_check(_door("Accept").disabled and _door("Accept").text == "ชั้นเต็ม" and not DayLoop.open_work_order(), "ชั้นเต็ม → ปุ่ม \"ชั้นเต็ม\" กดไม่ได้")
	DayLoop.shelf.slots = 2
	DayLoop.door_queue.clear()

	# ---------------- C · ซ่อมงานบนชั้น (ยังไม่ถึงนัด) → เก็บเงินไว้ · วันถัดไปลูกค้ามารับ → จ่าย
	_reset_door(9 * 60)
	var r := _fake_repair(o, 95)
	_check(r.get("held", false) and int(r["money"]) == 0 and int(r["money_due"]) > 0 and not GameState.hold_next_payment, "ซ่อมงานบนชั้น → ผลยังไม่จ่าย (เก็บ ฿%d ไว้)" % int(r.get("money_due", 0)))
	_check(GameState.money == money0 and o.state == RepairShelf.State.DONE and DayLoop.last_shelf["pickup"].is_empty() and ts.current_minute == 9 * 60 + slots * TimeSystem.SLOT_MIN, "เงินยังไม่เข้า · เครื่องซ่อมเสร็จรอบนชั้น · เวลาเดิน %d เทิร์น" % slots)
	_show(DayLoop.Card.RESULT)
	_check(DayLoop._title.text == "ซ่อมเสร็จ · วางรอบนชั้น" and DayLoop._body.text.contains("มารับเครื่อง วันเปิดร้านถัดไป") and DayLoop._body.text.contains("ได้ตอนลูกค้ามารับ"), "การ์ดผลงาน: วางรอบนชั้น · บอกวันลูกค้ามารับ")
	DayLoop._result_pending = false
	var sat_n := GameState.satisfaction_history.size()
	var expect := _expected_pay(r, e.promise_mult(1))
	ts.end_shift()
	await _frames(2)
	DayLoop.forced_case = null
	_check(GameState.money == money0 + expect and DayLoop.shelf.orders.is_empty() and o.state == RepairShelf.State.PICKED, "เปิดร้านวันนัด → ลูกค้ามารับ จ่าย ฿%d (เงิน %d → %d)" % [expect, money0, GameState.money])
	_check(GameState.satisfaction_history.size() == sat_n + 1 and GameState.satisfaction_history[-1] == mini(int(r["satisfaction"]) + e.on_time_sat_bonus, 100), "ทันนัด → ความพอใจ +%d" % e.on_time_sat_bonus)
	_check(DayLoop.shelf_news.size() == 1 and DayLoop.shelf_news[0].contains("มารับเครื่อง") and DayLoop.shelf_news[0].contains("ทันนัด") and DayLoop.door_view()["note"].contains("มารับเครื่อง"), "การ์ดหน้าร้านบอกว่าใครมารับเครื่อง (%s)" % ", ".join(DayLoop.shelf_news))

	# ---------------- D · ด่วน วันนี้ → ซ่อมเสร็จลูกค้ามารับเลย ×1.2
	_reset_door(9 * 60)
	var od: RepairShelf.Order = DayLoop.shelf.add(ram2, ts.shift, 0)
	var m1 := GameState.money
	r = _fake_repair(od, 95)
	var p: Dictionary = DayLoop.last_shelf["pickup"]
	expect = _expected_pay(r, e.promise_mult(0))
	_check(not p.is_empty() and p["on_time"] and GameState.money == m1 + expect and int(DayLoop.last_result["money"]) == expect, "ด่วน วันนี้ → ซ่อมเสร็จลูกค้ามารับทันที ได้ ฿%d (×%.1f)" % [expect, e.promise_mult(0)])
	_show(DayLoop.Card.RESULT)
	_check(DayLoop._title.text.contains("มารับเครื่อง") and DayLoop._title.text.contains("ทันนัด"), "การ์ดผลงาน: ลูกค้ามารับเครื่อง · ทันนัด")
	DayLoop._result_pending = false

	# ---------------- E · ซ่อมเสร็จหลังนัด → มารับเลยแต่ช้า · ไม่ซ่อมเลยผ่อนผัน → มาเอาคืน
	var ol: RepairShelf.Order = DayLoop.shelf.add(ram3, ts.shift - 2, 1)
	var m2 := GameState.money
	r = _fake_repair(ol, 95)
	p = DayLoop.last_shelf["pickup"]
	var mult := e.promise_mult(1) * (1.0 - e.late_pay_cut_per_day)
	expect = _expected_pay(r, mult)
	_check(not p.is_empty() and int(p["late"]) == 1 and GameState.money == m2 + expect and GameState.satisfaction_history[-1] == clampi(int(r["satisfaction"]) - e.late_sat_per_day, 0, 100), "ช้ากว่านัด 1 วัน → ค่าแรง ×%.2f (฿%d) ความพอใจ −%d" % [mult, expect, e.late_sat_per_day])
	DayLoop._result_pending = false
	var ret: RepairShelf.Order = DayLoop.shelf.add(ram, ts.shift - e.late_grace_days - 2, 1)
	var rep := GameState.reputation
	DayLoop._open_shelf_day(ts)
	_check(ret.state == RepairShelf.State.RETURNED and GameState.reputation == rep + e.rep_returned and GameState.satisfaction_history[-1] == e.returned_satisfaction and DayLoop.shelf_news[0].contains("มาเอาเครื่องคืน"), "ไม่ซ่อมเลยช่วงผ่อนผัน → ลูกค้ามาเอาคืน ชื่อเสียง %d" % e.rep_returned)

	# ---------------- F · ในร้านจริง: แผงชั้นวาง + กดซ่อม → มินิเกม (เก็บเงินไว้)
	DayLoop.force_active = true
	DayLoop._break_done = true
	SceneRouter.go(SceneRouter.ROOM)
	await get_tree().create_timer(2.5).timeout
	DayLoop.forced_case = null
	_reset_door(10 * 60)
	DayLoop.shelf = RepairShelf.new(e)
	var o1: RepairShelf.Order = DayLoop.shelf.add(ram, ts.shift, 1)
	var o2: RepairShelf.Order = DayLoop.shelf.add(ram2, ts.shift - 2, 1)
	await _frames(3)
	var v := DayLoop.shelf_view()
	_check(v["show"] and v["button"] == "ชั้นวาง 2/2" and v["alert"] and (v["rows"] as Array).size() == 2, "แผงชั้นวาง: ปุ่ม \"ชั้นวาง 2/2\" · มีงานเลยนัด (เตือน)")
	_check(DayLoop._shelf_rows[0] == o2 and String(v["rows"][0]["status"]).contains("เลยนัด") and String(v["rows"][1]["status"]).contains("วันเปิดร้านถัดไป"), "เรียงนัดใกล้สุดก่อน · บอกสถานะ/วันนัด")
	_check(DayLoop.shelf_panel.get_node("%OpenButton").visible and DayLoop.shelf_panel.get_node("%OpenButton").text == "ชั้นวาง 2/2", "ปุ่มชั้นวางโชว์ในร้าน")
	DayLoop.shelf_panel.get_node("%OpenButton").pressed.emit()
	await _frames(2)
	var row_btn := DayLoop.shelf_panel.get_node("%List").get_child(0).find_child("Repair", true, false) as Button
	_check(DayLoop.shelf_panel.is_open() and row_btn != null and not row_btn.disabled and row_btn.text.contains("ซ่อม"), "เปิดแผง → แถวมีปุ่ม \"ซ่อม\"")
	var m3 := GameState.money
	row_btn.pressed.emit()
	await get_tree().create_timer(1.0).timeout # รอ Fade ของ SceneRouter.push_node
	_check(is_instance_valid(DayLoop._minigame) and GameState.hold_next_payment and DayLoop.current_job.get("order") == o2 and not DayLoop.shelf_panel.is_open(), "กดซ่อม → เปิดมินิเกมงานบนชั้น (ไม่มีบทลูกค้า · เก็บเงินไว้)")
	await _frames(2)
	_check(not DayLoop.shelf_panel.get_node("%OpenButton").visible, "ระหว่างมินิเกมซ่อนปุ่มชั้นวาง")
	r = GameState.record_repair(o2.case.part(), 95, false, o2.case.fee, o2.case.level)
	SceneRouter.pop()
	await _frames(3)
	_check(not Global.in_minigame and not is_instance_valid(DayLoop._minigame), "ปิดมินิเกม → กลับร้าน")
	expect = _expected_pay(r, e.promise_mult(1) * (1.0 - e.late_pay_cut_per_day))
	_check(not GameState.hold_next_payment and o2.state == RepairShelf.State.PICKED and GameState.money == m3 + expect, "ซ่อมเสร็จ (เลยนัด) → ลูกค้ามารับเลย ได้ ฿%d" % expect)
	DayLoop._result_pending = false
	await _frames(3)
	_check(DayLoop.shelf_view().get("button", "") == "ชั้นวาง 1/2" and o1.state == RepairShelf.State.WAITING, "เหลือเครื่องบนชั้น 1/2")
	# งานขมOS หลังงานบนชั้นไม่ถูกเก็บเงิน
	GameState.hold_next_payment = false
	var m4 := GameState.money
	var r2 := GameState.record_repair(&"part_desktop", 95, false, 100, 1)
	_check(not r2.get("held", false) and GameState.money > m4, "งานปกติจ่ายทันทีเหมือนเดิม")
	DayLoop._result_pending = false

	DayLoop.force_active = false
	DayLoop._reset_run()
	print("T DONE fails=", fails)
	get_tree().quit()


## ซ่อมงานบนชั้นแบบไม่เปิดมินิเกม (เหมือน shelf_repair แต่ส่งผลเอง)
func _fake_repair(o: RepairShelf.Order, score: int) -> Dictionary:
	DayLoop.current_job = { "case": o.case, "order": o }
	DayLoop.today_case = o.case
	GameState.hold_next_payment = true
	return GameState.record_repair(o.case.part(), score, false, o.case.fee, o.case.level)


## เงินที่ควรได้ตอนลูกค้ามารับ (ค่าแรง+ทิป × mult แยกปัดเศษเหมือน GameState.pay_pickup)
func _expected_pay(r: Dictionary, mult: float) -> int:
	var due := int(r.get("money_due", 0))
	var tip := int(r.get("tip_due", 0))
	return roundi((due - tip) * mult) + roundi(tip * mult)


func _reset_door(minute: int) -> void:
	DayLoop.forced_case = null
	DayLoop.door_queue.clear()
	DayLoop.visitor_waves.clear()
	DayLoop.walkouts.clear()
	DayLoop.accepted_today = 0
	DayLoop._result_pending = false
	DayLoop.close_work_order()
	ts.overtime = false
	ts.set_clock(minute)


## วาดการ์ดทันที (เช็กก่อนเฟรมถัดไป — นอกร้าน DayLoop._process จะซ่อนการ์ด)
func _show(card: DayLoop.Card) -> void:
	DayLoop._show_card(card)


func _door(n: String) -> Control:
	return DayLoop.door_card.get_node("%" + n) as Control


func _wo(n: String) -> Control:
	return DayLoop.work_order.get_node("%" + n) as Control


func _layer(n: Node) -> int:
	var p := n.get_parent()
	return (p as CanvasLayer).layer if p is CanvasLayer else -1


func _end_dialog() -> void:
	await _frames(2)
	if DialogScene.visible:
		DialogScene.dialog_end()
	await _frames(3)
	_check(not DayLoop._working, "จบบทลูกค้า → กลับมาที่หน้าประตู")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
