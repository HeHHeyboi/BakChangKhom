extends Node
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น H–I] นักเรียนเดี่ยว/กลุ่ม (PLAN_0_6_0 ข้อ 6)
## ค่าแรงนักเรียน ×0.6 · กลุ่มปลดบท 5/บิวสนิท 60 · ความสนิทกลุ่ม = เฉลี่ย · ผลเข้าทุกคน · ความเห็นไม่ตรงกัน · 2 เครื่อง = 2 ใบรับเครื่อง · สมาชิกแยกมาเองที่ 40
## เปิด Test/group_visit_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var ts: TimeSystem


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	DayLoop._reset_run()
	GameState.reset()
	DayLoop.quiet = true
	DayLoop.door_queue.clear()
	DayLoop.visitor_waves.clear()
	DayLoop.shelf = RepairShelf.new(GameState.economy)
	DayLoop.shelf.slots = 6
	var e: EconomyConfig = GameState.economy
	var g := e.affinity_gain
	var bew := NpcBook.by_id(&"bew")
	var gang := NpcBook.by_id(&"gang3")
	var chars: Array = Global._CharacterMap.keys()

	# A · ข้อมูลกลุ่ม · ตัวละครอยู่ใน _CharacterMap · บทกลุ่มทุกชื่อมีรูป
	_check(gang.is_group() and gang.member_ids() == [&"bew", &"tonkla", &"praew"] and gang.problems(chars).is_empty(), "แก๊งสามเกลอ = บิว ต้นกล้า แพรว · ข้อมูลไม่มีปัญหา %s" % [gang.problems(chars)])
	var miss := DialogUtil.speakers_in("res://Assets/Dialog/Customer/any_group_arrive.txt").filter(func(n: String) -> bool: return n != "ขม" and not chars.has(n))
	_check(miss.is_empty(), "บทกลุ่ม: ทุกผู้พูดมีรูป %s" % [miss])

	# B · ค่าแรงนักเรียน ×0.6 (เคสผูกคน = สำเนา · ต้นแบบไม่เปลี่ยน)
	var kid_kb: CustomerCase = load("res://Resources/Customers/lv2_kid_keyboard.tres")
	var c := kid_kb.with_fee_mult(bew, e)
	_check(c != kid_kb and c.fee == roundi(e.fee_for_level(2) * 0.6) and kid_kb.fee == -1 and c.template() == kid_kb, "น้องบิว ค่าแรง ×0.6 = ฿%d · ต้นแบบไม่เปลี่ยน" % c.fee)
	var back := CustomerCase.from_ref(JSON.parse_string(JSON.stringify(CustomerCase.to_ref(c))))
	_check(back and back.fee == c.fee and back.template() == kid_kb, "เซฟ/โหลดเคสนักเรียน ค่าแรงเดิม")
	_check(load("res://Resources/Customers/lv2_teacher_ram.tres").with_fee_mult(NpcBook.by_id(&"teacher"), e).fee == -1, "ครูค่าแรงปกติ")

	# C · กลุ่มปลดบท 5 หรือบิวสนิท 60 · สมาชิกแยกมาเองที่ 40 · มาหลัง 16:00
	ts.set_clock(16 * 60 + 30)
	_check(not DayLoop.person_available("แก๊งสามเกลอ"), "ม.ค. บิวยังไม่สนิท → กลุ่มยังไม่มา")
	GameState.add_affinity(&"bew", 60)
	_check(DayLoop.person_available("แก๊งสามเกลอ"), "บิวสนิท 60 → พาเพื่อนมา (กลุ่มมาได้)")
	_check(not DayLoop.person_available("ต้นกล้า"), "ต้นกล้ายังไม่มาคนเดียว (<40)")

	# D · ความสนิทกลุ่ม = เฉลี่ย · ผลงานเข้าทุกคน
	var avg := roundi((GameState.affinity(&"bew") + 0 + 0) / 3.0)
	_check(GameState.affinity(&"gang3") == avg and GameState.has_affinity(&"gang3"), "ความสนิทกลุ่ม = เฉลี่ยสมาชิก (%d)" % avg)
	var b0 := GameState.affinity(&"bew")
	GameState.affinity_event(&"gang3", &"pass")
	var per := ceili(g[&"pass"] * 1.5)
	_check(GameState.affinity(&"tonkla") == per and GameState.affinity(&"praew") == per and GameState.affinity(&"bew") == mini(b0 + per, 100), "ซ่อมผ่าน → ทุกคน +%d (นักเรียน ×1.5)" % per)

	# E · งานกลุ่มจับคู่เฉพาะกลุ่ม · กลุ่ม +1 เทิร์น
	var gpc: CustomerCase = load("res://Resources/Customers/any_group_pc.tres")
	var any_ram: CustomerCase = load("res://Resources/Customers/any_ram.tres")
	_check(gang.matches(gpc) and not bew.matches(gpc) and not gang.matches(any_ram), "งานกลุ่ม = กลุ่มเท่านั้น · กลุ่มไม่เอางานเดี่ยว")
	var gi := gpc.instance_for(gang)
	_check(gi.est_slots == gpc.est_slots + 1 and gi.customer == "แก๊งสามเกลอ", "กลุ่มใช้เวลา +1 เทิร์น")

	# F · รับงานกลุ่ม = 1 โควตา · ความเห็นไม่ตรงกัน: ตอบให้ทุกคนเข้าใจ → ทุกคน +
	DayLoop.accepted_today = 0
	DayLoop.door_queue.push_front(DayLoop.door_entry(gi))
	_check(DayLoop.door_accept(1) and DayLoop.accepted_today == 1, "รับงานกลุ่ม = 1 โควตา")
	DayLoop._start_debate(gi)
	var v := DayLoop.debate_view()
	_check((v.choices as Array).size() == 3 and String(v.ask).contains(":"), "การ์ดความเห็นไม่ตรงกัน 3 ตัวเลือก")
	var before := { &"bew": GameState.affinity(&"bew"), &"tonkla": GameState.affinity(&"tonkla"), &"praew": GameState.affinity(&"praew") }
	var r := DayLoop.debate_answer(DayLoop.debate_state.debate.fair)
	_check(r.correct and r.deltas.size() == 3 and GameState.group_fair_count == 1 and GameState.affinity(&"tonkla") > int(before[&"tonkla"]), "ตอบอธิบายให้ทุกคน → ทุกคน + · นับครั้ง")
	DayLoop.debate_finish()
	DayLoop._start_debate(gi)
	var d: Dictionary = DayLoop.debate_state.debate
	var wa := GameState.affinity(d.a)
	var lb := GameState.affinity(d.b)
	var r2 := DayLoop.debate_answer(d.side_a)
	_check(not r2.correct and GameState.affinity(d.a) > wa and GameState.affinity(d.b) < lb, "เข้าข้างคนเดียว → คนนั้น + · อีกคน −")
	DayLoop.debate_finish()

	# G · 2 เครื่อง: ยศประจำหมู่บ้าน · ใบรับเครื่อง 2 ใบ ค่าแรงรวม ×1.6 · สุ่มอาการ · ชั้นต้องว่าง 2 ช่อง
	var two: CustomerCase = load("res://Resources/Customers/any_group_two.tres")
	_check(two.min_rank == 2, "2 เครื่องเริ่มยศประจำหมู่บ้าน")
	GameState.set_rank(2)
	DayLoop.shelf = RepairShelf.new(e)
	DayLoop.shelf.slots = 6
	var ti := two.instance_for(gang)
	DayLoop.roll_scenario(ti)
	DayLoop.accepted_today = 0
	DayLoop.door_queue.push_front(DayLoop.door_entry(ti))
	_check(DayLoop.door_accept(1) and DayLoop.shelf.used() == 2 and DayLoop.accepted_today == 1, "รับ 2 เครื่อง → ชั้น 2 ใบ · โควตา 1")
	var each := roundi(e.fee_for_level(2) * e.group_fee_mult / 2.0)
	var o1: RepairShelf.Order = DayLoop.shelf.orders[0]
	var o2: RepairShelf.Order = DayLoop.shelf.orders[1]
	_check(o1.case.fee == each and o2.case.fee == each and o2.case.device.contains("เครื่องที่ 2"), "ค่าแรงต่อเครื่อง ฿%d (รวม ×%.1f)" % [each, e.group_fee_mult])
	_check(o1.case.scenario() != null and o2.case.scenario() != null, "ทั้งสองเครื่องมีสถานการณ์")
	DayLoop.shelf.slots = 3
	var t2 := two.instance_for(gang)
	DayLoop.door_queue.push_front(DayLoop.door_entry(t2))
	_check(DayLoop.door_accept_state(1) == &"shelf_full", "ชั้นว่าง 1 ช่อง → รับ 2 เครื่องไม่ได้")
	DayLoop.door_queue.clear()

	# H · คำขอของกลุ่ม: กลุ่มได้เฉพาะเรื่องกลุ่ม · คนเดี่ยวไม่ได้เรื่องกลุ่ม
	var gb := RequestBook.by_id(&"c_group_buy")
	_check(RequestBook.fits(gb, gang, 1) and not RequestBook.fits(gb, bew, 1) and not RequestBook.fits(RequestBook.by_id(&"f_homework_file"), gang, 4), "คำขอกลุ่ม = กลุ่มเท่านั้น")

	# I · ต้นกล้าสนิท 40 → มาคนเดียวได้
	GameState.add_affinity(&"tonkla", 40)
	_check(DayLoop.person_available("ต้นกล้า"), "ต้นกล้าสนิทถึง 40 → แยกมาคนเดียว")
	DayLoop.quiet = false

	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
