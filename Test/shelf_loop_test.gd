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
	DayLoop._day_skip_pending = true # ให้จดข้อความข้ามวันเหมือนเล่นจริง
	DayLoop.day_skip_notes.clear()
	DayLoop.day_skip_seconds = 0.01
	ts.end_shift()
	await _frames(2)
	DayLoop.day_skip_seconds = 0.0
	DayLoop.forced_case = null
	_check(DayLoop.day_skip_notes.has("วันนี้ครูจะมารับเครื่อง"), "[ขั้น E] ข้ามวัน: ปิ๊บบอกว่าครูจะมารับเครื่องวันนี้ (%s)" % ", ".join(DayLoop.day_skip_notes))
	DayLoop.day_skip_notes.clear()
	DayLoop._day_skip_pending = false
	var pj := DayLoop.door_front()
	_check(GameState.money == money0 and DayLoop.shelf.orders.is_empty() and o.state == RepairShelf.State.PICKED and DayLoop.is_pickup(pj) and pj["case"] == ram, "[ขั้น E] เปิดร้านวันนัด → ครูยืนหน้าประตูเป็นคิวแรก (ยังไม่จ่าย · ชั้นว่าง)")
	_check(DayLoop.door_accept_state() == &"pickup" and not DayLoop.door_can_appoint() and not DayLoop.door_reject() and DayLoop.accepted_today == 0, "ลูกค้ามารับ: นัด/ปฏิเสธไม่ได้ · ไม่นับโควตา")
	_show(DayLoop.Card.DOOR)
	_check(_door("Accept").text == "ส่งมอบเครื่อง" and not _door("Appoint").visible and not _door("Reject").visible and not _door("PatienceBar").visible and _door("Detail").text.contains("฿%d" % expect) and _door("Name").text.contains("มารับเครื่อง"), "การ์ด: \"ส่งมอบเครื่อง\" · บอกค่าแรง ฿%d · ไม่มีแถบความอดทน" % expect)
	ts.set_clock(ts.current_minute + 120)
	_check(DayLoop.is_pickup(DayLoop.door_front()) and not DayLoop.walkouts.has("ครู"), "ลูกค้ามารับไม่หมดความอดทน (คนอื่นเดินกลับได้: %s)" % [DayLoop.walkouts])
	_door("Accept").pressed.emit()
	_check(GameState.money == money0 + expect and not DayLoop.is_pickup(DayLoop.door_front()) and DayLoop.last_handover["order"] == o, "กดส่งมอบ → จ่าย ฿%d (เงิน %d → %d)" % [expect, money0, GameState.money])
	_check(GameState.satisfaction_history.size() == sat_n + 1 and GameState.satisfaction_history[-1] == mini(int(r["satisfaction"]) + e.on_time_sat_bonus, 100), "ทันนัด → ความพอใจ +%d" % e.on_time_sat_bonus)
	_check(DayLoop.visitor_toast._queue.any(func(q: PackedStringArray) -> bool: return q[0].contains("ครู มารับเครื่อง") and q[0].contains("ทันนัด")), "ป้าย \"ครู มารับเครื่อง +฿ (ทันนัด)\"")
	# ไม่ได้ส่งมอบจนปิดร้าน → ส่งให้อัตโนมัติ · เซฟ/โหลดลูกค้ามารับได้
	var oa: RepairShelf.Order = DayLoop.shelf.add(ram3, ts.shift, 1)
	var ra := _fake_repair(oa, 95)
	DayLoop._result_pending = false
	_check(oa.state == RepairShelf.State.DONE, "ซ่อมเสร็จก่อนนัด (เครื่องผู้ใหญ่บ้าน)")
	DayLoop.door_queue.push_front(DayLoop.pickup_entry(DayLoop.shelf.pickup(oa, oa.due)))
	SaveGame.allow_in_tests = true
	var backup := FileAccess.get_file_as_string(SaveGame.PATH) if SaveGame.exists() else ""
	_check(SaveGame.save(), "บันทึกเกมตอนมีลูกค้ารอรับเครื่อง")
	DayLoop.door_queue.clear()
	SaveGame.load_into()
	var lj := DayLoop.door_front()
	_check(DayLoop.is_pickup(lj) and lj["case"] == ram3 and int((lj["pickup"]["order"] as RepairShelf.Order).result.get("money_due", 0)) == int(ra["money_due"]) and lj["pickup"]["on_time"], "โหลดเซฟ → ลูกค้ารอรับเครื่องกลับมาครบ (ยอดที่เก็บไว้ไม่หาย)")
	if backup != "":
		var f := FileAccess.open(SaveGame.PATH, FileAccess.WRITE)
		f.store_string(backup)
	else:
		SaveGame.clear()
	SaveGame.allow_in_tests = false
	var m5 := GameState.money
	var exp_a := _expected_pay(ra, e.promise_mult(1))
	DayLoop.end_shift()
	await _frames(2)
	DayLoop.forced_case = null
	_check(GameState.money == m5 + exp_a and not DayLoop.door_queue.any(func(q: Dictionary) -> bool: return DayLoop.is_pickup(q)), "ปิดร้านโดยยังไม่ส่งมอบ → ส่งให้อัตโนมัติ ได้ ฿%d" % exp_a)

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

	# ---------------- G · แอปงานซ่อมในคอมของขม: ตารางตามวัน · เลื่อนนัด · โทรเรียกมารับ · ไปซ่อม
	_reset_door(9 * 60)
	DayLoop.shelf = RepairShelf.new(e)
	DayLoop.shelf.slots = 4
	var g1: RepairShelf.Order = DayLoop.shelf.add(ram, ts.shift, 1)
	var g2: RepairShelf.Order = DayLoop.shelf.add(ram2, ts.shift - 2, 1)
	var g3: RepairShelf.Order = DayLoop.shelf.add(ram3, ts.shift, 2)
	var rg3 := _fake_repair(g3, 95)
	DayLoop._result_pending = false
	DayLoop.appointments.append({ "case": os_case, "free": false })
	var app := (load("res://Scene/UI/work_order_app.tscn") as PackedScene).instantiate() as WorkOrderApp
	add_child(app)
	await _frames(2)
	var av := DayLoop.work_app_view()
	var titles: Array = (av["sections"] as Array).map(func(s: Dictionary) -> String: return String(s["title"]))
	_check(titles.size() == 4 and titles[0] == "เลยนัดแล้ว!" and String(titles[1]).begins_with("วันเปิดร้านถัดไป") and String(titles[2]).begins_with("อีก 2 วัน") and String(titles[3]).begins_with("นัดมาหน้าร้าน"), "แอป: แบ่งตามวันนัด เลยนัดอยู่บนสุด + คนนัดมาหน้าร้าน (%s)" % ", ".join(titles))
	_check(DayLoop._app_rows == [g2, g1, g3], "แถวเรียงตามวันนัด")
	var pb := _app_btn(app, "Btn_postpone", 1)
	_check(pb != null and not pb.disabled and _app_btn(app, "Btn_postpone", 0).disabled and _app_btn(app, "Btn_call", 2) != null and not _app_btn(app, "Btn_call", 2).disabled, "ปุ่ม: เลื่อนนัดได้ (เลยนัดแล้วเลื่อนไม่ได้) · ซ่อมเสร็จแล้วโทรเรียกมารับได้")
	var due1 := g1.due
	pb.pressed.emit()
	await _frames(2)
	_check(g1.due == due1 + 1 and g1.postponed and g1.sat_adjust == -e.postpone_sat_penalty and not DayLoop.shelf.can_postpone(g1, ts.shift, TimeSystem.TOTAL_SHIFTS), "กดเลื่อนนัด → นัด +1 วัน · ความพอใจตอนรับ −%d · เลื่อนอีกไม่ได้" % e.postpone_sat_penalty)
	app.refresh()
	_check(_app_btn(app, "Btn_postpone", DayLoop._app_rows.find(g1)).disabled, "ปุ่มเลื่อนนัดกดไม่ได้แล้ว")
	_app_btn(app, "Btn_call", DayLoop._app_rows.find(g3)).pressed.emit()
	await _frames(2)
	var cj := DayLoop.door_front()
	_check(DayLoop.is_pickup(cj) and cj["case"] == ram3 and cj["pickup"]["on_time"] and int(cj["pickup"]["sat_delta"]) == e.on_time_sat_bonus + e.early_call_sat_bonus and float(cj["pickup"]["mult"]) == e.promise_mult(2), "โทรเรียกมารับ → ผู้ใหญ่บ้านมายืนหน้าประตู (ทันนัด · ความพอใจ +%d)" % (e.on_time_sat_bonus + e.early_call_sat_bonus))
	var m6 := GameState.money
	DayLoop.door_handover()
	_check(GameState.money == m6 + _expected_pay(rg3, e.promise_mult(2)) and GameState.satisfaction_history[-1] == mini(int(rg3["satisfaction"]) + e.on_time_sat_bonus + e.early_call_sat_bonus, 100), "ส่งมอบ → ได้เงินวันนี้ (ไม่ต้องรอนัด)")
	# ไปซ่อม: จำไว้แล้วเปิดมินิเกมเมื่อกลับมาที่หน้าร้าน
	app.refresh()
	var rb := _app_btn(app, "Btn_repair", DayLoop._app_rows.find(g1))
	_check(rb != null and not rb.disabled, "ปุ่มไปซ่อมกดได้")
	app.queue_free()
	_check(DayLoop.request_shelf_repair(g1) and DayLoop._pending_repair == g1, "กดไปซ่อม → จำงานไว้ (รอปิดคอม)")
	await get_tree().create_timer(1.0).timeout
	_check(is_instance_valid(DayLoop._minigame) and DayLoop.current_job.get("order") == g1 and GameState.hold_next_payment and DayLoop._pending_repair == null, "กลับมาหน้าร้าน → เปิดมินิเกมเครื่องครูเอง")
	while is_instance_valid(DayLoop._minigame) and not DayLoop._minigame.is_inside_tree():
		await get_tree().process_frame # รอ Fade ของ SceneRouter.push_node ให้มินิเกมเข้าฉากก่อน
	GameState.record_repair(g1.case.part(), 95, false, g1.case.fee, g1.case.level)
	SceneRouter.pop()
	await _frames(3)
	_check(not Global.in_minigame, "ปิดมินิเกม → กลับร้าน")
	DayLoop._result_pending = false
	_check(g1.state == RepairShelf.State.DONE and not GameState.hold_next_payment, "ซ่อมเสร็จก่อนนัด → รอบนชั้น")
	var gp := DayLoop.shelf.pickup(g1, g1.due)
	_check(int(gp["sat_delta"]) == e.on_time_sat_bonus - e.postpone_sat_penalty, "เครื่องที่เลื่อนนัด: มารับทันนัดได้ความพอใจ +%d −%d" % [e.on_time_sat_bonus, e.postpone_sat_penalty])
	DayLoop.appointments.clear()

	# ---------------- H · การ์ดเป้าหมายไม่กาง-พับกระพริบตอนไม่มีการ์ดชั่วครู่ (15 พ.ย. ผู้ใช้เจอตอนเวลาหมุน)
	_reset_door(9 * 60)
	EventManager.showUI() # มินิเกมจริงเรียกเองตอนจบ (เทสต์ปิดมินิเกมตรง ๆ)
	var qb = EventManager.questboard
	qb.set_collapsed(false)
	DayLoop._goal_auto_collapsed = false
	for i in 6:
		DayLoop.shelf_news.append("ข้อความยาว ๆ บรรทัดที่ %d ของการ์ดหน้าร้าน ทำให้การ์ดสูงเกินพื้นที่" % i)
	DayLoop.add_visitors(4)
	DayLoop._board_dirty = true
	await _frames(20)
	_check(qb.collapsed and DayLoop._goal_auto_collapsed, "การ์ดหน้าร้านสูง → พับการ์ดเป้าหมายให้")
	DayLoop.time_skip(30, 0.8)
	var flick := false
	for i in 70:
		await get_tree().process_frame
		flick = flick or not qb.collapsed
	_check(not flick and qb.collapsed, "เวลาหมุน (ไม่มีการ์ดชั่วครู่) → การ์ดเป้าหมายไม่กางกระพริบ")
	DayLoop.shelf_news.clear()
	DayLoop.force_active = false
	await _frames(10)
	_check(not qb.collapsed and not DayLoop._goal_auto_collapsed, "ร้านไม่ได้เปิดแล้ว → กางการ์ดเป้าหมายคืนให้")

	DayLoop.force_active = false
	DayLoop._reset_run()
	print("T DONE fails=", fails)
	get_tree().quit()


## ปุ่ม id ในแถวที่ row (index ใน DayLoop._app_rows) ของแอปงานซ่อม
func _app_btn(app: WorkOrderApp, id: String, row: int) -> Button:
	var rows_with_btns: Array = []
	for p in app.get_node("%List").get_children():
		if p is PanelContainer and p.find_child("Btn_*", true, false) != null:
			rows_with_btns.append(p)
	if row < 0 or row >= rows_with_btns.size():
		return null
	return (rows_with_btns[row] as Node).find_child(id, true, false) as Button


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
