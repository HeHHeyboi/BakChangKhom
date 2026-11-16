extends Node
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น J] เครื่องมือ + ไกด์ตามยศ (PLAN_0_6_0 ข้อ 7)
## เปิด Test/tools_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	var gs := GameState
	gs.reset()
	var e: EconomyConfig = gs.economy

	# A · ได้เครื่องมือตอนเลื่อนยศ · ป้ายเลื่อนยศบอก
	_check(not gs.has_tool(&"magnet_driver") and not gs.has_tool(&"multimeter"), "ยศมือใหม่ยังไม่มีเครื่องมือพิเศษ")
	gs.set_rank(2)
	_check(gs.has_tool(&"magnet_driver") and gs.has_tool(&"multimeter") and not gs.has_tool(&"post_card"), "ยศประจำหมู่บ้าน: ไขควงแม่เหล็ก + มัลติมิเตอร์")
	_check(" ".join(gs.rank_unlock_lines(2)).contains("มัลติมิเตอร์") and " ".join(gs.rank_unlock_lines(3)).contains("การ์ดอ่านโค้ด POST") and " ".join(gs.rank_unlock_lines(3)).contains("ขอคำใบ้"), "ป้ายเลื่อนยศบอกเครื่องมือ + ไกด์")

	# B · มัลติมิเตอร์ในแผงวินิจฉัย (F-2): ปิ๊บบอกเบาะแส + ตัดตัวเลือกผิด 1 ข้อ
	var job := (load("res://Resources/Customers/any_frontpanel.tres") as CustomerCase).instance_for(NpcBook.by_id(&"min"))
	var f2 := ScenarioBook.by_id(&"fp_f2_switch")
	job.apply_scenario({ "scenario": f2, "trait": &"normal", "condition": &"new" }, e)
	var m: PartMinigame = load(job.scene_path()).instantiate()
	m.set_meta("work_order", job)
	add_child(m)
	await _frames(3)
	m._advance_phase()
	await _frames(2)
	var tool_btn: Button = m._diag_panel.find_child("Tool_multimeter", true, false)
	_check(tool_btn != null and m.diag_tools().size() == 1, "แผงวินิจฉัยมีปุ่มใช้มัลติมิเตอร์")
	tool_btn.pressed.emit()
	var crossed := m._diag_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("✗"))
	_check(tool_btn.disabled and crossed.size() == 1 and not String(crossed[0].text).contains(f2.diag_choices[0]), "ใช้แล้ว: ตัดตัวเลือกผิด 1 ข้อ · ใช้ได้ครั้งเดียว")
	m.queue_free()
	await _frames(2)
	gs.set_rank(1)
	var m1: PartMinigame = load(job.scene_path()).instantiate()
	m1.set_meta("work_order", job)
	add_child(m1)
	await _frames(3)
	_check(m1.diag_tools().is_empty(), "ยศฝึกหัดยังไม่มีมัลติมิเตอร์")
	m1.queue_free()
	await _frames(2)

	# C · การ์ด POST ในแรม (R-3) · ปุ่มอยู่ในแถบวินิจฉัยของแรม
	gs.set_rank(3)
	var rj := (load("res://Resources/Customers/any_ram.tres") as CustomerCase).instance_for(NpcBook.by_id(&"amnuay"))
	rj.apply_scenario({ "scenario": ScenarioBook.by_id(&"ram_r3_bad"), "trait": &"normal", "condition": &"new" }, e)
	var ram: PartMinigame = load(rj.scene_path()).instantiate()
	ram.set_meta("work_order", rj)
	add_child(ram)
	await _frames(3)
	_check(ram._phase_nodes[1]._choice_box.find_child("Tool_post_card", true, false) != null, "แรม R-3: ปุ่มการ์ด POST ในแถบวินิจฉัย")

	# D · ยศเชี่ยวชาญ: ไกด์ปิดจนกว่าจะขอคำใบ้ · ไม่ขอ = โบนัส +5 · ขอ = ไม่มีโบนัส
	_check(not ram.guide_on() and ram.self_bonus() == e.self_bonus and ram._hint_btn != null, "ยศเชี่ยวชาญ: ไกด์ปิด · มีปุ่มขอคำใบ้ · โบนัสทำเอง +%d" % e.self_bonus)
	ram.request_hint()
	_check(ram.hint_requested and ram.self_bonus() == 0 and ram._hint_btn.disabled, "ขอคำใบ้ → ไกด์กลับมา · ไม่มีโบนัส")
	ram.queue_free()
	await _frames(2)
	gs.set_rank(0)
	var low: PartMinigame = load(rj.scene_path()).instantiate()
	low.set_meta("work_order", rj)
	add_child(low)
	await _frames(3)
	_check(low.guide_on() and low.self_bonus() == 0 and low._hint_btn == null, "ยศมือใหม่: ไกด์เต็ม ไม่มีปุ่มขอคำใบ้")
	low.queue_free()
	await _frames(2)

	# E · ไขควงแม่เหล็ก: โซน QTE กว้างขึ้นเล็กน้อย
	gs.set_rank(1)
	var q: PartMinigame = load(rj.scene_path()).instantiate()
	q.set_meta("work_order", rj)
	add_child(q)
	await _frames(2)
	_check(is_equal_approx(q.qte_zone_scale(), 1.5 * e.magnet_qte_mult), "ไขควงแม่เหล็ก: โซน QTE ×%.2f" % e.magnet_qte_mult)
	q.queue_free()

	await _frames(2)

	# F · ความสามารถทาง C (ตาไว · มือนิ่ง · นักสืบ) + หน้าเลือก 3 ปุ่ม
	_check(gs.perk_options(1).size() == 3 and gs.perk_options(2)[2].id == "steady_hand" and gs.perk_options(4)[2].id == "detective", "ยศ 1/2/4 มีทาง C")
	gs.reset()
	gs.set_rank(2)
	gs.perks[2] = &"steady_hand"
	var q2: PartMinigame = load(rj.scene_path()).instantiate()
	q2.set_meta("work_order", rj)
	add_child(q2)
	await _frames(2)
	_check(is_equal_approx(q2.qte_zone_scale(), 1.5 * e.magnet_qte_mult * e.perk_steady_mult), "มือนิ่ง: โซน QTE ×%.1f" % e.perk_steady_mult)
	q2.queue_free()
	await _frames(2)
	gs.perks[1] = &"sharp_eye"
	gs.set_rank(4)
	gs.perks[4] = &"detective"
	var r5 := (load("res://Resources/Customers/any_ram.tres") as CustomerCase).instance_for(NpcBook.by_id(&"headman"))
	r5.apply_scenario({ "scenario": ScenarioBook.by_id(&"ram_r5_missing"), "trait": &"normal", "condition": &"new" }, e)
	var d: PartMinigame = load(r5.scene_path()).instantiate()
	d.set_meta("work_order", r5)
	add_child(d)
	await _frames(4)
	_check(d.sharp_eye_flashed.size() >= 3, "ตาไว: จุดตรวจกะพริบ %d จุด" % d.sharp_eye_flashed.size())
	_check(d.detective_said, "นักสืบ: ปิ๊บเล่าความลับ + เตือนจุดหลอก")
	d.queue_free()
	await _frames(2)
	var pp: PerkPicker = load("res://Scene/UI/perk_picker.tscn").instantiate()
	add_child(pp)
	await _frames(1)
	pp.show_view({ "rank": 1, "title": "t", "unlocks": PackedStringArray(), "options": gs.perk_options(1) })
	var got := []
	pp.chosen.connect(func(r: int, id: StringName) -> void: got.append(id))
	_check(pp._buttons().size() == 3 and pp._buttons()[2].visible and pp._buttons()[2].text.begins_with("ตาไว"), "หน้าเลือกมี 3 ปุ่ม")
	pp._buttons()[2].pressed.emit()
	_check(got == [&"sharp_eye"], "กดปุ่มที่ 3 → เลือกตาไว")
	pp.queue_free()

	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
