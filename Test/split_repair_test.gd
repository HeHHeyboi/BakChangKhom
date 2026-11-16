extends Node
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น E–F] มินิเกมแบ่งครึ่ง: ครึ่งตรวจ → รออะไหล่ → ครึ่งซ่อม · เลือกชิ้นจากคลัง (PLAN_0_6_0 ข้อ 4)
## เปิด Test/split_repair_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var ts: TimeSystem


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	DayLoop.force_active = true
	DayLoop._reset_run()
	GameState.reset()
	DayLoop.force_active = true
	DayLoop._break_done = true
	SceneRouter.go(SceneRouter.ROOM)
	await get_tree().create_timer(2.5).timeout
	DayLoop.door_queue.clear()
	DayLoop.visitor_waves.clear()
	DayLoop.shelf = RepairShelf.new(GameState.economy)
	DayLoop.shelf.slots = 12
	ts.set_clock(9 * 60)
	var e: EconomyConfig = GameState.economy
	var any_ram: CustomerCase = load("res://Resources/Customers/any_ram.tres")
	var amn := NpcBook.by_id(&"amnuay")

	# A · รับเครื่อง R-3 (แรมเสีย ต้องใช้แรม) · ยังไม่ตรวจ = ไม่รู้อะไหล่ ไม่จอง
	var c := any_ram.instance_for(amn)
	c.apply_scenario({ "scenario": ScenarioBook.by_id(&"ram_r3_bad"), "trait": &"normal", "condition": &"old" }, e)
	var o := DayLoop.shelf.add(c, ts.shift, 1)
	_check(o.part_ids().is_empty() and DayLoop.order_has_parts(o), "ยังไม่ตรวจ: ไม่มีอะไหล่ให้จอง · ซ่อม (ตรวจ) ได้เลย")
	_check(DayLoop.part_line(c).contains("ยังไม่รู้"), "การ์ดบอกว่ารู้อะไหล่หลังตรวจ")
	_check(DayLoop.order_inspect_note(o) == "ยังไม่ได้ตรวจ", "ชั้นวาง: ยังไม่ได้ตรวจ")

	# B · ครึ่งตรวจ: วินิจฉัย → ถึงจุดแบ่ง (CLEAN) → ไม่มีแรมในคลัง → หยุด · เวลาเดิน 40%
	var m := _open(c, o)
	await _wait_mg(m)
	_check(m.has_meta("checkpoint") and not m.has_meta("resume") and m.split_phase() == 5, "มินิเกมได้ checkpoint · จุดแบ่ง = CLEAN")
	m._phase_nodes[1]._on_choice("wrong")
	m._phase_nodes[1]._on_choice("correct")
	var t0 := ts.current_minute
	m.debug_jump(5)
	await _frames(4)
	_check(not is_instance_valid(m) or m.is_queued_for_deletion() or m.inspection_stopped, "ถึงจุดแบ่งแล้วหยุด (ไม่มีแรม)")
	await _frames(3)
	var slots := DayLoop.job_slots(c)
	var insp := slots - ceili(slots * DayLoop.SPLIT_REPAIR_SHARE)
	_check(o.inspected and int(o.partial.get("wrong", -1)) == 1 and int((o.partial.mistakes as Dictionary).get("diagnosis", 0)) == 10, "ใบรับเครื่องเก็บผลครึ่งตรวจ (ผิด 1 · หัก 10)")
	_check(ts.current_minute - t0 == maxi(1, insp) * TimeSystem.SLOT_MIN, "เวลาเดินครึ่งตรวจ %d เทิร์น (%d นาที)" % [insp, ts.current_minute - t0])
	_check(o.part_ids() == [&"ram_ddr4_8gb_used", &"ram_ddr4_8gb_new"] and DayLoop.shelf_repair_state(o) == &"no_part", "ตรวจแล้วรู้ว่าต้องใช้แรม → รอของ")
	_check(DayLoop.last_inspection.cause == ScenarioBook.by_id(&"ram_r3_bad").cause and DayLoop.order_inspect_note(o).begins_with("ตรวจแล้ว"), "ป้าย/ชั้นวางบอกสาเหตุ")
	_check(GameState.scenario_log.is_empty() and not GameState.hold_next_payment, "ครึ่งตรวจยังไม่จดผล/ไม่ค้างจ่าย")

	# C · เซฟ/โหลดใบรับเครื่องที่ตรวจแล้ว
	var o2 := RepairShelf.Order.from_dict(JSON.parse_string(JSON.stringify(o.to_dict())))
	_check(o2.inspected and int(o2.partial.wrong) == 1 and o2.part_ids().size() == 2, "เซฟ/โหลด: ตรวจแล้ว + ผลครึ่งตรวจ")

	# D · ซื้อแรม → จองให้อัตโนมัติ → ครึ่งซ่อมเริ่มที่ CLEAN · คะแนนที่หักกลับมา · ถาดเลือกชิ้น
	GameState.give_item(&"ram_ddr4_8gb_used", 1, false)
	DayLoop.assign_parts(false)
	_check(DayLoop.order_has_parts(o), "ได้แรมแล้ว → จองให้เครื่องนี้")
	var m2 := _open(c, o)
	await _wait_mg(m2)
	_check(m2.has_meta("resume") and m2.current_phase == 5 and int(m2._mistakes[&"diagnosis"]) == 10 and m2._diag_done, "ครึ่งซ่อมเริ่มที่ CLEAN · คะแนนหักเดิมกลับมา")
	_check(m2._pick_layer != null and m2._pick_layer.visible, "ถาดเลือกชิ้นจากคลังขึ้น")
	var right: Button = null
	var wrong: Button = null
	for b in m2._pick_layer.find_children("*", "Button", true, false):
		if (b as Button).text.contains("DDR4"):
			right = b
		elif wrong == null:
			wrong = b
	_check(right != null and wrong != null, "มีชิ้นที่ถูก + ของหลอก")
	wrong.pressed.emit()
	_check(wrong.disabled and int(m2._mistakes.get(&"tools", 0)) == PartMinigame.TOOLS_PICK_WRONG, "เลือกผิด → หัก tools")
	right.pressed.emit()
	await _frames(2)
	_check(m2._pick_layer == null, "เลือกถูก → ถาดปิด ซ่อมต่อ")

	# E · ซ่อมจบ → เวลา 60% · ผลเข้า (จ่ายตอนมารับ) · จดผลสถานการณ์
	var t1 := ts.current_minute
	m2._finish(true)
	await _frames(4)
	_check(ts.current_minute - t1 == maxi(1, ceili(slots * DayLoop.SPLIT_REPAIR_SHARE)) * TimeSystem.SLOT_MIN, "ครึ่งซ่อมใช้เวลา 60%")
	_check(o.state != RepairShelf.State.WAITING, "ใบรับเครื่องปิดงานแล้ว")
	_check(GameState.scenario_log.size() == 1 and int(GameState.scenario_log[0].wrong) == 1, "จดผลสถานการณ์ (ผิด 1 จากครึ่งตรวจ)")

	# F · มีของอยู่แล้ว → ไม่แบ่ง: ถึงจุดแบ่งจองเลยแล้วเล่นต่อ (R-4 ผิดรุ่น)
	GameState.give_item(&"ram_ddr4_8gb_new", 1, false)
	var c2 := any_ram.instance_for(NpcBook.by_id(&"headman"))
	c2.apply_scenario({ "scenario": ScenarioBook.by_id(&"ram_r4_wrong_ddr"), "trait": &"normal", "condition": &"old" }, e)
	var ob := DayLoop.shelf.add(c2, ts.shift, 1)
	var m3 := _open(c2, ob)
	await _wait_mg(m3)
	m3._phase_nodes[1]._on_choice("correct")
	m3.debug_jump(5)
	await _frames(3)
	_check(is_instance_valid(m3) and not m3.inspection_stopped and m3.current_phase == 5 and ob.inspected and GameState.reserved_index(ob.key) >= 0, "มีแรมในคลัง → จองแล้วซ่อมต่อ ไม่แบ่ง")
	_check(m3._pick_layer != null, "ถาดเลือกชิ้นขึ้นด้วย")
	var labels := []
	for b in m3._pick_layer.find_children("*", "Button", true, false):
		labels.append((b as Button).text)
	_check(labels.any(func(t: String) -> bool: return t.contains("DDR3")), "R-4 มีแรม DDR3 เป็นของหลอก %s" % [labels])
	m3._finish(false)
	await _frames(3)

	# G · งานไม่ใช้อะไหล่ (R-2) → ไม่หยุด ไม่มีถาด
	var c3 := any_ram.instance_for(amn)
	c3.apply_scenario({ "scenario": ScenarioBook.by_id(&"ram_r2_loose"), "trait": &"normal", "condition": &"old" }, e)
	var oc := DayLoop.shelf.add(c3, ts.shift, 1)
	var m4 := _open(c3, oc)
	await _wait_mg(m4)
	m4._phase_nodes[1]._on_choice("correct")
	m4.debug_jump(5)
	await _frames(3)
	_check(is_instance_valid(m4) and not m4.inspection_stopped and m4.current_phase == 5 and m4._pick_layer == null, "ไม่ใช้อะไหล่ → เล่นรวดเดียว ไม่มีถาด")
	m4._finish(false)
	await _frames(3)

	# H · อีก 4 Part: จุดแบ่งมีจริง · ถึงจุดแบ่งแล้วหยุดได้ (ไม่มีของ) · เล่นต่อเริ่มที่จุดแบ่ง
	var any_cases := {
		&"part_mainboard": [&"mb_m4_cap", "res://Resources/Customers/any_mainboard.tres"],
		&"part_gpu": [&"gpu_g4_psu", "res://Resources/Customers/any_gpu.tres"],
		&"part_front_panel": [&"fp_f2_switch", "res://Resources/Customers/any_frontpanel.tres"],
		&"part_bios": [&"bios_b1_cmos", "res://Resources/Customers/any_bios.tres"],
	}
	for p in any_cases:
		var sc := ScenarioBook.by_id(any_cases[p][0])
		var cc := (load(any_cases[p][1]) as CustomerCase).instance_for(NpcBook.by_id(&"min"))
		cc.apply_scenario({ "scenario": sc, "trait": &"normal", "condition": &"old" }, e)
		var oo := DayLoop.shelf.add(cc, ts.shift, 1)
		var mm := _open(cc, oo)
		await _wait_mg(mm)
		var sp: int = mm.split_phase()
		mm.scenario_answer(true)
		mm.debug_jump(sp)
		await _frames(4)
		var stopped := oo.inspected and not oo.partial.is_empty()
		await _frames(2)
		GameState.give_item(sc.needs_part, 1, false)
		DayLoop.assign_parts(false)
		var mr := _open(cc, oo)
		await _wait_mg(mr)
		_check(sp > 1 and stopped and mr.current_phase == sp and mr._pick_layer != null, "%s: แบ่งที่ %s · หยุดรอของ · เล่นต่อที่จุดแบ่ง + ถาด" % [p, mr._phase_name(sp)])
		mr._finish(false)
		await _frames(3)

	DayLoop.force_active = false
	print("T DONE fails=%d" % fails)
	get_tree().quit()


## เปิดมินิเกมแบบที่ DayLoop เปิดจากชั้นวาง (shelf_repair → start_repair)
func _open(c: CustomerCase, o: RepairShelf.Order) -> PartMinigame:
	DayLoop.current_job = { "case": c, "order": o }
	DayLoop.today_case = c
	GameState.hold_next_payment = true
	DayLoop.start_repair()
	return DayLoop._minigame as PartMinigame


## รอมินิเกมเข้า scene tree (SceneRouter.push_node มีจอมืดก่อน)
func _wait_mg(m: PartMinigame) -> void:
	var t := 0.0
	while is_instance_valid(m) and (not m.is_inside_tree() or m._phase_nodes.is_empty()) and t < 5.0:
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	await _frames(3)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
