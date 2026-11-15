extends Node
## [Claude 15 พ.ย. 2569 · 0.4.0 ขั้น C–H] อะไหล่ในลูปร้านจริง: รับเครื่องที่ขาดอะไหล่ → ชั้น "รอของ" → ซื้อ/พัสดุมา → จองอัตโนมัติ
## → ซ่อม (หักของสิ้นเปลือง) → ลูกค้ามารับ จ่ายค่าแรง + ค่าอะไหล่ · ทำของเสีย → รอของชดใช้ (PLAN_0_4_0)
## เปิด Test/parts_loop_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var ts: TimeSystem
var e: EconomyConfig


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	e = GameState.economy
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	DayLoop._reset_run()
	DayLoop.quiet = true
	var bios: CustomerCase = load("res://Resources/Customers/lv5_teacher_bios.tres")
	var ram_plain: CustomerCase = load("res://Resources/Customers/lv2_teacher_ram.tres")
	var mb: CustomerCase = load("res://Resources/Customers/lv3_min_mainboard.tres")
	var gpu: CustomerCase = load("res://Resources/Customers/lv3_kid_gpu_used.tres")
	var cmos: ItemDef = load("res://Resources/Shop/cmos_cr2032.tres")
	for c in [bios, ram_plain, mb, gpu]:
		DayLoop._parts_seen[StringName(c.part_id)] = true
	DayLoop.force_active = true
	DayLoop._break_done = true
	SceneRouter.go(SceneRouter.ROOM)
	await get_tree().create_timer(2.5).timeout
	GameState.money = 5000
	GameState.set_shelf_slots(6)
	DayLoop.shelf.slots = 6

	# ---------------- C · รับเครื่องที่ขาดอะไหล่ → รอของ
	_reset_door(9 * 60)
	DayLoop.door_queue.append(DayLoop.door_entry(bios))
	var fv := DayLoop._door_front_view(DayLoop.door_front())
	_check(String(fv["detail"]).contains("ถ่าน CMOS") and String(fv["detail"]).contains("✗ ยังไม่มีในคลัง") and String(fv["detail"]).contains("ออนไลน์ ฿%d" % cmos.online_cost()), "การ์ดหน้าประตูบอกอะไหล่ที่ต้องใช้ · ยังไม่มี · ราคาตลาด/ออนไลน์")
	var wv := DayLoop.work_order_view()
	_check(String(wv["detail"]).contains("อะไหล่"), "ใบรับเครื่องบอกเรื่องอะไหล่")
	_check(DayLoop.door_accept(1), "รับเครื่องครู (นัดวันเปิดร้านถัดไป)")
	var o: RepairShelf.Order = DayLoop.shelf.orders[0]
	_check(o.key != "" and not DayLoop.order_has_parts(o) and DayLoop.shelf_repair_state(o) == &"no_part", "ยังไม่มีถ่าน → เครื่องรอของ ซ่อมไม่ได้")
	var sv := DayLoop.shelf_view()
	_check(String(sv["rows"][0]["status"]).begins_with("รอของ: ถ่าน CMOS") and sv["rows"][0]["repair"]["disabled"] and sv["rows"][0]["repair"]["text"] == "รอของ", "แผงชั้น: \"รอของ\" ปุ่มซ่อมเทา")
	DayLoop._app_rows.clear()
	var av := DayLoop.work_app_view()
	_check(String(av["sections"][0]["rows"][0]["status"]).begins_with("รอของ") and av["sections"][0]["rows"][0]["actions"][0]["disabled"], "แอปงานซ่อม: รอของ")

	# ซื้อที่ตลาด → จองให้อัตโนมัติ
	_check(GameState.buy(cmos, 1) == "", "ซื้อถ่าน CMOS ที่ตลาด ฿%d" % cmos.price)
	await _frames(2)
	_check(DayLoop.order_has_parts(o) and String(GameState.inventory[GameState.reserved_index(o.key)].id) == "cmos_cr2032", "ของเข้าคลัง → จองให้เครื่องครูเอง")
	_check(GameState.free_count(cmos.id) == 0 and DayLoop.shelf_repair_state(o) in [&"ok", &"ot", &"busy"], "ชิ้นที่จองไม่ว่างแล้ว · ซ่อมได้")

	# ซ่อมผ่าน → ใช้อะไหล่ · ลูกค้ามารับ จ่ายค่าแรง + ค่าอะไหล่
	var r := _fake_repair(o, 95)
	_check(GameState.count_item(cmos.id) == 0 and int(o.result.get("part_due", 0)) == GameState.part_charge(cmos.price), "ซ่อมผ่าน → ใช้ถ่านออกจากคลัง · จดค่าอะไหล่ ฿%d (มือใหม่ +2%%)" % GameState.part_charge(cmos.price))
	ts.shift += 1
	DayLoop._open_shelf_day(ts)
	var pick := DayLoop.door_front()
	_check(DayLoop.is_pickup(pick) and DayLoop.pickup_money(pick["pickup"]) == _expected_pay(r, e.promise_mult(1)) + GameState.part_charge(cmos.price), "วันนัด ลูกค้ามารับ: เงิน = ค่าแรง + ค่าอะไหล่")
	_check(String(DayLoop._door_front_view(pick)["detail"]).contains("ค่าอะไหล่ ฿%d" % GameState.part_charge(cmos.price)), "การ์ดมารับบอกค่าอะไหล่แยก")
	var m := GameState.money
	var fee_ledger := _ledger_sum(&"part_fee")
	DayLoop.door_handover()
	_check(GameState.money == m + DayLoop.pickup_money(pick["pickup"]) and _ledger_sum(&"part_fee") == fee_ledger + GameState.part_charge(cmos.price), "ส่งมอบ → ได้เงินครบ · ledger หมวดค่าอะไหล่จากลูกค้า")

	# ---------------- C · ไม่ผ่าน/ยอมแพ้ → ปลดจอง · งานไม่ใช้อะไหล่ไม่เกี่ยว
	_reset_door(9 * 60)
	GameState.give_item(&"cmos_cr2032", 1, false)
	var o2 := DayLoop.shelf.add(bios, ts.shift, 1)
	DayLoop.assign_parts(false)
	_check(DayLoop.order_has_parts(o2), "มีถ่านในคลังอยู่แล้ว → จองตอนรับเครื่อง")
	DayLoop.current_job = { "case": bios, "order": o2 }
	DayLoop.today_case = bios
	GameState.hold_next_payment = true
	GameState.record_repair(bios.part(), 10, false, bios.fee, bios.level, true)
	_check(GameState.free_count(cmos.id) == 1 and GameState.reserved_index(o2.key) < 0, "ยอมแพ้ → ถ่านกลับเป็นของว่าง")
	var o3 := DayLoop.shelf.add(ram_plain, ts.shift, 1)
	_check(DayLoop.order_has_parts(o3) and DayLoop.order_missing_parts(o3).is_empty(), "งานที่ไม่ใช้อะไหล่ ซ่อมได้เลย")

	# ---------------- F · ของสิ้นเปลือง: ขาด → +1 เทิร์น · ซ่อมแล้วหักจริง
	DayLoop.shelf = RepairShelf.new(e)
	DayLoop.shelf.slots = 6
	var base := DayLoop.job_slots(mb)
	GameState.give_item(&"ipa90", 1, false)
	GameState.give_item(&"paste_grey", 1, false)
	_check(DayLoop.job_slots(mb) == base - e.no_supply_extra_slots, "มี IPA + ซิลิโคน → ไม่เสียเวลาเพิ่ม (ขาด = +%d เทิร์น)" % e.no_supply_extra_slots)
	var ipa_before := GameState.count_item(&"ipa90")
	var om := DayLoop.shelf.add(mb, ts.shift, 1)
	_fake_repair(om, 90)
	_check(GameState.count_item(&"ipa90") == ipa_before - 1 and GameState.count_item(&"paste_grey") == 4, "ซ่อมเมนบอร์ดเสร็จ → หัก IPA 1 · ซิลิโคน 1")

	# ---------------- G · ทำการ์ดจอเสีย → รอของชดใช้ (ไม่หักเงินทันที)
	var og := DayLoop.shelf.add(gpu, ts.shift, 1)
	m = GameState.money
	var rep := GameState.reputation
	DayLoop.current_job = { "case": gpu, "order": og }
	DayLoop.today_case = gpu
	GameState.hold_next_payment = true
	GameState.record_repair(gpu.part(), 30, true, gpu.fee, gpu.level)
	_check(og.state == RepairShelf.State.WAITING and og.replace_part == &"gpu_used" and GameState.money == m and GameState.reputation == rep + e.rep_damaged, "ทำการ์ดจอเสีย → ไม่หักเงิน · ชื่อเสียง %d · เครื่องรอการ์ดจอมือสองมาชดใช้" % e.rep_damaged)
	_check(DayLoop.shelf_repair_state(og) == &"no_part" and DayLoop.order_missing_parts(og)[0].contains("ชดใช้"), "ยังไม่มีของชดใช้ → ซ่อมใหม่ไม่ได้")
	_check(GameState.order_online([[load("res://Resources/Shop/gpu_used.tres"), 1]]) == "", "สั่งการ์ดจอมือสองออนไลน์")
	ts.shift += 1
	DayLoop._deliver_parcels(ts)
	await _frames(2)
	_check(DayLoop.order_has_parts(og) and DayLoop.shelf_news[-1].contains("พัสดุมาส่ง"), "พัสดุมาถึงตอนเปิดร้าน → จองให้เครื่องเด็กเอง")
	var rg := _fake_repair(og, 90)
	_check(GameState.count_item(&"gpu_used") == 0 and int(og.result.get("part_due", 0)) == 0 and og.replace_part == &"", "ซ่อมใหม่ผ่าน → ใช้การ์ดจอชดใช้ไป ลูกค้าไม่จ่ายค่าชิ้นนี้")
	_check(og.sat_adjust == -e.damage_replace_sat and rg.get("grade") != GameState.Grade.FAIL, "ความพอใจตอนมารับ −%d" % e.damage_replace_sat)

	# G · ไม่หาของชดใช้จนเลยผ่อนผัน → มาเอาคืน + จ่ายค่าของแทน
	var og2 := DayLoop.shelf.add(gpu, ts.shift, 1)
	DayLoop.current_job = { "case": gpu, "order": og2 }
	DayLoop.today_case = gpu
	GameState.hold_next_payment = true
	GameState.record_repair(gpu.part(), 30, true, gpu.fee, gpu.level)
	m = GameState.money
	ts.shift = og2.due + e.late_grace_days + 1
	DayLoop._open_shelf_day(ts)
	var gu: ItemDef = load("res://Resources/Shop/gpu_used.tres")
	_check(og2.state == RepairShelf.State.RETURNED and GameState.money == m - gu.online_cost(), "ไม่หาของชดใช้ → ลูกค้ามาเอาคืน หัก ฿%d (เดิม ฿%d)" % [gu.online_cost(), int(e.damage_penalty.get(&"part_gpu", 0))])

	# ---------------- E · แอปร้านออนไลน์ในคอมของขม
	_reset_door(10 * 60)
	DayLoop.shelf = RepairShelf.new(e)
	DayLoop.shelf.slots = 6
	GameState.inventory.clear()
	GameState.pending_orders.clear()
	GameState.money = 3000
	var ob := DayLoop.shelf.add(bios, ts.shift, 1)
	var app := (load("res://Scene/UI/online_shop_app.tscn") as PackedScene).instantiate() as OnlineShopApp
	add_child(app)
	await _frames(2)
	var list: Node = app.get_node("%List")
	var first_head := list.get_child(0) as Label
	var cm_row := list.find_child("Row_cmos_cr2032", true, false)
	_check(first_head.text.contains("รอของ") and list.get_child(1) == cm_row and (cm_row.find_child("*", true, false) != null), "แอปร้านออนไลน์: ของที่เครื่องรออยู่ขึ้นบนสุด (ถ่าน CMOS)")
	var cm_labels := cm_row.find_children("*", "Label", true, false)
	_check(cm_labels.any(func(l: Label) -> bool: return l.text.contains("เครื่องของครูรอชิ้นนี้")) and cm_labels.any(func(l: Label) -> bool: return l.text.contains("฿%d" % cmos.online_cost()) and l.text.contains("ตลาด ฿%d" % cmos.price)), "แถวบอกราคาออนไลน์เทียบตลาด · เครื่องของใครรออยู่")
	_check(list.find_child("Row_gpu_used", true, false) != null and list.find_child("Row_shelf_rack_4", true, false) == null, "มีการ์ดจอมือสอง (ออนไลน์อย่างเดียว) · ไม่มีของอัปเกรดร้าน")
	_check((app.get_node("%Order") as Button).disabled, "ตะกร้าว่าง → ปุ่มสั่งกดไม่ได้")
	(cm_row.find_child("Plus", true, false) as Button).pressed.emit()
	(list.find_child("Row_ipa90", true, false).find_child("Plus", true, false) as Button).pressed.emit()
	await _frames(1)
	var total := cmos.online_cost() + (load("res://Resources/Shop/ipa90.tres") as ItemDef).online_cost() + e.online_ship_fee
	_check((app.get_node("%Cart") as Label).text.contains("รวม ฿%d" % total) and not (app.get_node("%Order") as Button).disabled, "ใส่ตะกร้า 2 ชิ้น รวม ฿%d (รวมค่าส่ง)" % total)
	m = GameState.money
	(app.get_node("%Order") as Button).pressed.emit()
	await _frames(1)
	_check(GameState.money == m - total and GameState.pending_orders.size() == 2 and app.cart.is_empty() and (app.get_node("%Note") as Label).text.contains("กำลังมาส่ง"), "กดสั่ง → จ่ายทันที · ตะกร้าว่าง · บอกของที่กำลังมา")
	_check(not DayLoop.order_has_parts(ob), "ของยังไม่มา → เครื่องยังรอของ")
	app.queue_free()
	DayLoop.day_skip_notes.clear()
	DayLoop._day_skip_pending = true
	ts.shift += 1
	DayLoop._deliver_parcels(ts)
	DayLoop.assign_parts(false)
	DayLoop._day_skip_pending = false
	_check(DayLoop.order_has_parts(ob) and GameState.count_item(&"ipa90") == 8 and Array(DayLoop.day_skip_notes).any(func(n: String) -> bool: return n.contains("พัสดุ")), "เปิดร้านวันถัดไป → พัสดุเข้าคลัง จองถ่านให้ครูเอง · ปิ๊บบอกตอนข้ามวัน")

	# ---------------- H · ไปตลาดระหว่างเปิดร้าน = 1 เทิร์น · ปิดร้านแล้วไม่เสียเวลา
	_reset_door(10 * 60)
	var t0 := ts.current_minute
	_check(DayLoop.market_trip() == e.market_walk_slots and ts.current_minute == t0 + e.market_walk_slots * TimeSystem.SLOT_MIN, "ไปตลาดตอนร้านเปิด → ใช้ %d เทิร์น" % e.market_walk_slots)
	t0 = ts.current_minute
	DayLoop._last_location = -1
	DayLoop._on_location_changed(SceneRouter.MARKET)
	_check(ts.current_minute == t0, "โหลดเซฟมาอยู่ที่ตลาด → ไม่คิดเวลาเดิน")
	DayLoop._on_location_changed(SceneRouter.ROOM)
	DayLoop._on_location_changed(SceneRouter.MARKET)
	_check(ts.current_minute == t0 + e.market_walk_slots * TimeSystem.SLOT_MIN, "จากร้านไปตลาดผ่านแผนที่ → เดินไป 1 เทิร์น")
	ts.set_clock(TimeSystem.CLOSE)
	_check(DayLoop.market_trip() == 0 and ts.current_minute == TimeSystem.CLOSE, "ปิดร้านแล้วไปตลาด → ไม่เสียเวลา")

	# ---------------- J · รถขายของ
	_reset_door(9 * 60)
	DayLoop.vendor = { }
	var vd: Array = []
	var came := 0
	for k in 200:
		ts.shift = 2 + (k % 3)
		DayLoop._plan_vendor(ts)
		if not DayLoop.vendor.is_empty():
			came += 1
			vd = DayLoop.vendor.items
	ts.shift = 1
	DayLoop._plan_vendor(ts)
	_check(DayLoop.vendor.is_empty(), "วันแรกของบทรถขายของไม่มา")
	_check(came > 25 and came < 80 and vd.size() == e.vendor_items, "รถขายของมาราว 1 ใน 4 วัน (%d/200) · ของ %d ชิ้น" % [came, e.vendor_items])
	DayLoop.vendor = { "items": ["fan_cpu", "cmos_cr2032", "psu_450w"], "sold": [false, false, false], "arrive": e.vendor_arrive_minute, "leave": e.vendor_arrive_minute + e.vendor_stay_slots * TimeSystem.SLOT_MIN, "told": false }
	ts.set_clock(10 * 60)
	_check(not DayLoop.vendor_here() and not DayLoop.vendor_view()["show"], "ก่อน 11 โมงรถยังไม่มา")
	ts.set_clock(e.vendor_arrive_minute)
	await _frames(2)
	_check(DayLoop.vendor_here() and DayLoop.vendor["told"] and DayLoop.vendor_view()["show"], "11:00 รถมาจอด · ป้ายบอก · ปุ่มรถโชว์ในร้าน")
	_check(DayLoop.vendor_panel.get_node("%OpenButton").visible and (DayLoop.vendor_panel.get_parent() as CanvasLayer).layer == 92, "ปุ่มรถขายของอยู่ชั้น 92")
	var fan: ItemDef = load("res://Resources/Shop/fan_cpu.tres")
	var vp := DayLoop.vendor_price(fan)
	_check(vp == roundi(fan.online_cost() * (1.0 - e.vendor_discount)) and vp < fan.online_cost(), "ราคารถ ฿%d (ออนไลน์ ฿%d −%d%%)" % [vp, fan.online_cost(), roundi(e.vendor_discount * 100)])
	GameState.inventory.clear()
	GameState.money = 1000
	DayLoop.vendor_panel.get_node("%OpenButton").pressed.emit()
	await _frames(3)
	var vbtn := DayLoop.vendor_panel.get_node("%List").get_child(0).find_child("Buy", true, false) as Button
	_check(vbtn != null and not vbtn.disabled, "แผงรถมีปุ่มซื้อ")
	vbtn.pressed.emit()
	await _frames(2)
	_check(GameState.money == 1000 - vp and GameState.count_item(fan.id) == 1 and int(GameState.inventory[0].cost) == vp and DayLoop.vendor.sold[0], "ซื้อพัดลม → เข้าคลังทันที ราคาทุน ฿%d · ขายแล้ว" % vp)
	_check(DayLoop.vendor_buy(0) == "ขายไปแล้ว", "ชิ้นเดิมซื้อซ้ำไม่ได้ (มีชิ้นเดียว)")
	ts.set_clock(e.vendor_arrive_minute + e.vendor_stay_slots * TimeSystem.SLOT_MIN)
	await _frames(2)
	_check(not DayLoop.vendor_here() and DayLoop.vendor_buy(1) == "รถไปแล้ว" and not DayLoop.vendor_panel.get_node("%OpenButton").visible, "ครบ %d เทิร์น รถไปแล้ว" % e.vendor_stay_slots)
	DayLoop.vendor = { }

	# ---------------- K · บทสอนอะไหล่ + งานสอนบทที่ 1 วันที่ 2
	var w1: WeekPlan = load("res://Resources/Week/week1.tres")
	var tut_case := w1.case_for_shift(2)
	_check(tut_case != null and not tut_case.forced and tut_case.needs_part == &"cable_hdmi" and not DayLoop.random_pool.has(tut_case), "บท 1 วันที่ 2: ครูเอาเครื่องจอไม่ขึ้นมา (ต้องใช้สาย HDMI · ไม่อยู่ในคลังสุ่ม)")
	DayLoop.shelf = RepairShelf.new(e)
	GameState.inventory.clear()
	GameState.story_flags.clear()
	DayLoop.shelf.add(tut_case, ts.shift, 1)
	_check(DayLoop._part_tutorials().has("tut_part_missing"), "มีเครื่องรอของ → บทสอน \"ต้องใช้อะไหล่\"")
	for f in ["part_missing", "parcel", "part_pay", "damage_replace", "vendor"]:
		var path: String = DayLoop.TUTORIALS["tut_" + f]
		var bad_line: Array = Array(FileAccess.get_file_as_string(path).split("\n")).filter(func(l: String) -> bool: return l.strip_edges() != "" and not l.begins_with("#") and (l.get_slice(",", 0).strip_edges() == "" or l.contains(":")))
		_check(ResourceLoader.exists(path) or FileAccess.file_exists(path), "มีไฟล์บทสอน %s" % path.get_file())
		_check(bad_line.is_empty(), "บทสอน %s รูปแบบ ชื่อ,ข้อความ ไม่มีทวิภาค %s" % [f, str(bad_line)])

	DayLoop.quiet = false
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _ledger_sum(kind: StringName) -> int:
	var n := 0
	for l in GameState.ledger:
		if l.kind == kind:
			n += int(l.amount)
	return n


func _fake_repair(o: RepairShelf.Order, score: int) -> Dictionary:
	DayLoop.current_job = { "case": o.case, "order": o }
	DayLoop.today_case = o.case
	GameState.hold_next_payment = true
	return GameState.record_repair(o.case.part(), score, false, o.case.fee, o.case.level)


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


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("T PASS ", msg)
	else:
		fails += 1
		print("T FAIL ", msg)
