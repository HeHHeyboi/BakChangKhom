extends Node
## [Claude 16 พ.ย. 2569 · 0.5.0 ขั้น F–I] ยศเก็บไว้ · สอบกับปิ๊บ · ของปลดต่อยศ · ความสามารถช่าง (PLAN_0_5_0 ข้อ 5–7)
## เปิด Test/rank_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

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
	GameState.reset()

	# ---------------- F · ยศเก็บไว้
	var ready_sig := []
	var ups := []
	var on_ready := func(t: int) -> void: ready_sig.append(t)
	var on_up := func(r: int, n: String) -> void: ups.append(r)
	GameState.rank_exam_ready.connect(on_ready)
	GameState.rank_up.connect(on_up)
	GameState.add_xp(e.rank_xp[1] - 1)
	_check(not GameState.rank_ready() and ready_sig.is_empty(), "XP ยังไม่ถึง → ยังสอบไม่ได้")
	GameState.add_xp(1)
	_check(GameState.rank_ready() and ready_sig == [1] and GameState.rank() == 0 and ups.is_empty(), "XP ถึง 500 → พร้อมสอบ (สัญญาณ 1 ครั้ง) · ยศยังเป็นมือใหม่")
	GameState.add_xp(e.rank_xp[2])
	_check(ready_sig == [1] and GameState.xp_rank() == 2 and GameState.rank() == 0, "XP สะสมต่อระหว่างรอสอบ · ไม่ยิงซ้ำ")
	_check(GameState.promote() and GameState.rank() == 1 and ups == [1], "สอบผ่าน → ฝึกหัด (ทีละขั้น)")
	_check(GameState.rank_ready() and GameState.promote() and GameState.rank() == 2 and not GameState.rank_ready() and not GameState.promote(), "สอบผ่านอีกครั้ง → ประจำหมู่บ้าน · XP ไม่พอ = เลื่อนต่อไม่ได้")
	GameState.rank_exam_ready.disconnect(on_ready)
	GameState.rank_up.disconnect(on_up)

	# ---------------- G · คลังข้อสอบ
	var bank := RankExam.bank()
	var bad := PackedStringArray()
	var levels := { }
	for q in bank:
		for p in q.problems():
			bad.append("%s: %s" % [q.id, p])
		levels[q.level] = int(levels.get(q.level, 0)) + 1
	_check(bank.size() >= 40 and bad.is_empty(), "คลังข้อสอบ %d ข้อ ไม่มีปัญหา %s" % [bank.size(), ", ".join(bad)])
	_check(levels.has(1) and levels.has(4), "มีข้อสอบทุกระดับ %s" % str(levels))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var pick := RankExam.pick(1, 3, rng, [&"part_ram"], { })
	var parts := { }
	for q in pick:
		parts[q.part] = true
	_check(pick.size() == 3 and pick.all(func(q: ExamQuestion) -> bool: return q.level <= 1 and (q.part == &"general" or q.part == &"part_ram")) and parts.size() >= 2, "สอบขึ้นฝึกหัด: ระดับ 1 · ถามเรื่องที่ซ่อมผ่านแล้ว (แรม) + ทั่วไป · ไม่ซ้ำหมวด")

	# ข้อดูภาพ: ทุกชุดมี 1 ข้อ (ถ้าคลังมี) · หมวดบนหัวข้อ
	var imgs_in_bank := bank.filter(func(q: ExamQuestion) -> bool: return q.image != null).size()
	var one_img := true
	for k in 20:
		var ps := RankExam.pick(2, 3, rng, [&"part_ram", &"part_mainboard", &"part_gpu"], { })
		one_img = one_img and ps.filter(func(q: ExamQuestion) -> bool: return q.image != null).size() == 1 and ps.size() == 3
	_check(imgs_in_bank >= 10 and one_img, "ข้อดูภาพ %d ข้อในคลัง · สุ่ม 20 ชุด มีข้อดูภาพชุดละ 1 ข้อพอดี" % imgs_in_bank)
	_check(bank.all(func(q: ExamQuestion) -> bool: return q.domain_name() != ""), "ทุกข้อมีหมวด")

	# สอบตก → ไม่เลื่อน · สอบใหม่ข้อไม่ซ้ำ · สอบผ่าน → เลื่อน
	GameState.reset()
	GameState.part_clears[&"part_ram"] = 2
	GameState.add_xp(e.rank_xp[1])
	DayLoop.quiet = true
	var qs := DayLoop.exam_begin()
	for q in qs:
		DayLoop.exam_answer("ไม่ใช่คำตอบ")
	_check(not DayLoop.exam_finish() and GameState.rank() == 0 and GameState.learn_log.size() == 3 and GameState.exam_attempts[1] == 1, "ตอบผิดหมด → สอบตก ยศเดิม · จดผล 3 ข้อ")
	var first_ids := qs.map(func(q: ExamQuestion) -> StringName: return q.id)
	var qs2 := DayLoop.exam_begin()
	_check(qs2.all(func(q: ExamQuestion) -> bool: return not first_ids.has(q.id)), "สอบใหม่ได้ข้อใหม่ (ไม่ซ้ำข้อที่เคยถาม)")
	DayLoop.exam_answer(qs2[0].correct_text())
	DayLoop.exam_answer(qs2[1].correct_text())
	DayLoop.exam_answer("ผิด")
	_check(DayLoop.exam_finish() and GameState.rank() == 1 and GameState.exam_attempts[1] == 2, "ถูก 2/3 → ผ่าน เป็นช่างฝึกหัด (สอบครั้งที่ 2)")
	var last: Dictionary = GameState.learn_log[-1]
	_check(GameState.learn_log.size() == 6 and int(last.target) == 1 and int(last.attempt) == 2 and not bool(last.correct), "learn_log เก็บ ยศเป้าหมาย · ครั้งที่สอบ · ถูก/ผิด")
	DayLoop.quiet = false
	# แอป "สอบช่าง" ในคอมของขม: หน้าแรก → ข้อ → เฉลย → ผล · สอบได้วันละครั้ง
	GameState.add_xp(e.rank_xp[2])
	ts.shift += 1
	var app = load("res://Scene/UI/rank_exam_app.tscn").instantiate()
	add_child(app)
	await _frames(1)
	_check(String(app.get_node("%Title").text).contains("พร้อมสอบเป็นช่างประจำหมู่บ้าน") and app.get_node("%Action").visible and app.get_node("%Action").text == "เริ่มสอบ", "หน้าแรก: พร้อมสอบ · ปุ่มเริ่มสอบ")
	_check(app.get_node("%History").visible and String(app.get_node("%History").text).contains("ช่างฝึกหัด ครั้งที่ 2 · ถูก 2/3 ผ่าน") and String(app.get_node("%Sub").text).begins_with("สุ่ม 3 ข้อ"), "ประวัติการสอบ (%s)" % String(app.get_node("%History").text).replace("\n", " / "))
	var min_exam := ts.current_minute
	app.get_node("%Action").pressed.emit()
	_check(app.page == &"question" and app.get_node("%Choices").get_child_count() == 3 and app.get_node("%Title").text == "ข้อ 1/3" and DayLoop.exam_running(), "กดเริ่มสอบ → ข้อ 1/3 ตัวเลือก 3 ปุ่ม")
	_check(not DayLoop.exam_can_start() and GameState.exam_last_shift == ts.shift, "เริ่มสอบแล้วนับว่าวันนี้สอบแล้ว")
	app.answer((DayLoop.exam.questions[0] as ExamQuestion).correct_text())
	_check(app.page == &"feedback" and app.get_node("%Title").text == "ถูกต้อง!" and app.get_node("%Action").text == "ข้อถัดไป", "ตอบถูก → \"ถูกต้อง!\" + เฉลย")
	app.get_node("%Action").pressed.emit()
	app.answer("ไม่ใช่คำตอบ")
	_check(app.get_node("%Title").text == "ยังไม่ใช่" and String(app.get_node("%Body").text).contains("คำตอบคือ"), "ตอบผิด → บอกคำตอบที่ถูก")
	app.get_node("%Action").pressed.emit()
	app.answer((DayLoop.exam.questions[2] as ExamQuestion).correct_text())
	_check(app.get_node("%Action").text == "ดูผลสอบ", "ข้อสุดท้าย → ปุ่มดูผลสอบ")
	app.get_node("%Action").pressed.emit()
	_check(app.get_node("%Unlocks").visible and String(app.get_node("%Unlocks").text).begins_with("ผลแยกหมวด") and String(app.get_node("%Sub").text).begins_with("คะแนน 2/3"), "ใบแจ้งผล: คะแนน + ผลแยกหมวด (%s)" % String(app.get_node("%Unlocks").text).replace("\n", " / "))
	_check(app.page == &"result" and app.get_node("%Title").text == "ผ่านแล้ว!" and GameState.rank() == 2 and ts.current_minute == min_exam, "ถูก 2/3 → ผ่าน เป็นช่างประจำหมู่บ้าน · ไม่ใช้เวลาในร้าน")
	app.get_node("%Action").pressed.emit()
	_check(app.page == &"home" and not app.get_node("%Action").visible and String(app.get_node("%Sub").text).contains("ต้องมี XP อีก"), "กลับหน้าแรก: XP ยังไม่ถึงยศถัดไป")
	GameState.add_xp(e.rank_xp[3])
	app.refresh()
	_check(String(app.get_node("%Sub").text).contains("วันนี้สอบแล้ว") and not app.get_node("%Action").visible, "XP ครบอีกแต่วันนี้สอบแล้ว → สอบวันถัดไป")
	ts.shift += 1
	DayLoop.visitor_toast.clear()
	DayLoop._exam_reminder()
	_check(DayLoop.exam_can_start() and DayLoop.visitor_toast._queue.any(func(q: PackedStringArray) -> bool: return q[0].contains("XP ครบแล้ว")), "วันใหม่ → ป้ายเตือนให้เปิดคอมไปสอบ")
	app.queue_free()


	# ---------------- เซฟ: ยศ · learn_log · โหลดเซฟเก่า (ไม่มี rank_level) = ยศตาม XP
	SaveGame.allow_in_tests = true
	SaveGame.save()
	var lvl := GameState.rank_level
	GameState.reset()
	SaveGame.load_into()
	_check(GameState.rank_level == lvl and GameState.learn_log.size() == 9 and int(GameState.exam_attempts.get(1, 0)) == 2 and int(GameState.exam_attempts.get(2, 0)) == 1 and GameState.exam_last_shift >= 0, "โหลดเซฟ → ยศ · ผลสอบ · ครั้งที่สอบ · วันที่สอบล่าสุด")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveGame.PATH))
	(d["game"] as Dictionary).erase("rank_level")
	d["game"]["xp"] = e.rank_xp[3] + 10
	d["version"] = 5
	var f := FileAccess.open(SaveGame.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	SaveGame.load_into()
	_check(GameState.rank_level == 3 and not GameState.rank_ready(), "โหลดเซฟ v5 → ยศตาม XP (เชี่ยวชาญ) ไม่ต้องสอบย้อนหลัง")
	SaveGame.clear()
	SaveGame.allow_in_tests = false

	# ---------------- H · ของปลดต่อยศ
	GameState.reset()
	DayLoop._reset_run()
	GameState.level_stars[2] = 5
	GameState.level_stars[3] = 5
	_check(not GameState.level_unlocked(3) and GameState.level_lock_reason(3) == "ต้องเป็นช่างฝึกหัด", "ดาว Lv2 ครบแต่ยังมือใหม่ → Lv3 ล็อก (%s)" % GameState.level_lock_reason(3))
	GameState.set_rank(1)
	_check(GameState.level_unlocked(3) and not GameState.level_unlocked(4) and GameState.level_lock_reason(4) == "ต้องเป็นช่างประจำหมู่บ้าน", "ฝึกหัด → Lv3 เปิด · Lv4 ต้องประจำหมู่บ้าน")
	GameState.level_stars.erase(3)
	GameState.set_rank(2)
	_check(not GameState.level_unlocked(4) and GameState.level_lock_reason(4).begins_with("ต้องทำ Lv3"), "ยศถึงแต่ดาว Lv3 ไม่ครบ → ยังล็อก (%s)" % GameState.level_lock_reason(4))
	var ul1 := " ".join(GameState.rank_unlock_lines(1))
	var ul2 := " ".join(GameState.rank_unlock_lines(2))
	var ul3 := " ".join(GameState.rank_unlock_lines(3))
	_check(ul1.contains("Lv3") and ul1.contains("ซื้อ ") and ul2.contains("ประกาศเสียงตามสาย") and ul3.contains("มิ้น"), "การ์ดยศใหม่บอกของที่ปลด (ฝึกหัด: %s)" % ul1)
	ts.shift = 5 # วันแรกของเดือน 2
	DayLoop._plan_visitors(ts)
	var with_ann := DayLoop.visitors_today
	GameState.rank_level = 1
	DayLoop._plan_visitors(ts)
	_check(with_ann == DayLoop.visitors_today + e.announce_extra_visitors, "ประจำหมู่บ้าน: วันแรกของเดือนผู้ใหญ่บ้านประกาศ ลูกค้า +%d (%d → %d)" % [e.announce_extra_visitors, DayLoop.visitors_today, with_ann])
	ts.shift = 6
	GameState.rank_level = 2
	var base_day := e.visitors_for(ts.month(), GameState.reputation)
	DayLoop._plan_visitors(ts)
	_check(DayLoop.visitors_today == base_day, "วันอื่นของเดือนไม่ประกาศ")

	# ---------------- I · ความสามารถช่าง
	GameState.reset()
	DayLoop._reset_run()
	_check(GameState.perk_pending() == 0, "มือใหม่ไม่มีความสามารถให้เลือก")
	GameState.set_rank(2)
	_check(GameState.perk_pending() == 1 and not GameState.choose_perk(1, &"power_saver"), "ขึ้นมา 2 ยศ → เลือกของยศฝึกหัดก่อน · เลือกของยศอื่นไม่ได้")
	DayLoop.quiet = false
	var pv := DayLoop.perk_view()
	DayLoop.perk_picker.show_view(pv)
	_check(DayLoop.perk_picker.visible and String(DayLoop.perk_picker.get_node("%A").text).begins_with("ปากหวาน") and String(DayLoop.perk_picker.get_node("%Title").text).contains("ช่างฝึกหัด"), "หน้าเลือก: ปากหวาน / ใจเย็น · ชื่อยศ")
	DayLoop.perk_picker.get_node("%A").pressed.emit()
	await _frames(1)
	_check(GameState.has_perk(&"sweet_talk") and GameState.perk_pending() == 2 and not DayLoop.perk_picker.visible, "กดปากหวาน → ได้ · ต่อด้วยของยศประจำหมู่บ้าน")
	_check(not GameState.choose_perk(1, &"patient"), "เลือกซ้ำยศเดิมไม่ได้")
	var a0 := GameState.affinity(&"teacher")
	GameState.affinity_event(&"teacher", &"pass")
	var gp: int = e.affinity_gain[&"pass"]
	_check(GameState.affinity(&"teacher") == a0 + ceili(gp * e.perk_affinity_mult), "ปากหวาน: ผ่าน +%d → +%d" % [gp, ceili(gp * e.perk_affinity_mult)])
	GameState.choose_perk(2, &"punctual")
	var o := DayLoop.shelf.add(load("res://Resources/Customers/lv2_teacher_ram.tres"), 1, 1)
	o.due = 1
	var od := DayLoop.shelf.open_day(1 + e.late_grace_days + 1)
	_check(od["returned"].is_empty() and od["late_waiting"].size() == 1, "นัดแม่น: เลยนัด %d วันยังไม่มาเอาคืน" % (e.late_grace_days + 1))
	DayLoop.shelf.orders.clear()
	GameState.set_rank(4)
	GameState.choose_perk(3, &"power_saver")
	var bill := GameState.pay_month_bill(1, 40)
	_check(int(bill.power) == roundi((e.month_value(e.power_base, 1) + e.power_per_slot * 40) * e.perk_power_mult), "ประหยัดไฟ: ค่าไฟ ×%.2f (฿%d)" % [e.perk_power_mult, int(bill.power)])
	GameState.choose_perk(4, &"mentor")
	_check(GameState.perk_pending() == 0, "เลือกครบ 4 ยศ")

	# ---------------- J · มิ้นเป็นลูกมือ
	DayLoop.helper_used_today = 0
	var os1: CustomerCase = load("res://Resources/Customers/lv1_amnuay_startup.tres")
	var hw: CustomerCase = load("res://Resources/Customers/lv2_teacher_ram.tres")
	ts.set_clock(9 * 60)
	DayLoop.door_queue.clear()
	DayLoop.door_queue.append(DayLoop.door_entry(hw))
	_check(not DayLoop.helper_button(DayLoop.door_front()).visible, "งานฮาร์ดแวร์: ไม่มีปุ่มให้มิ้นทำ")
	DayLoop.door_queue.clear()
	DayLoop.door_queue.append(DayLoop.door_entry(os1))
	GameState.level_three_stars[1] = 2
	var hb := DayLoop.helper_button(DayLoop.door_front())
	_check(hb.visible and DayLoop.helper_chance(os1) == minf(e.helper_base + e.helper_per_star * 2 + e.perk_helper_bonus, e.helper_max) and String(hb.text).contains("%"), "งานขมOS Lv1 · เคย ⭐⭐⭐ 2 ครั้ง + ครูช่าง → โอกาส %d%%" % roundi(DayLoop.helper_chance(os1) * 100))
	var acc0 := DayLoop.accepted_today
	var m0 := GameState.money
	var min0 := ts.current_minute
	var hr := DayLoop.door_helper()
	_check(not hr.is_empty() and DayLoop.accepted_today == acc0 and ts.current_minute == min0 and DayLoop.door_queue.is_empty(), "ให้มิ้นทำ: ไม่นับโควตา · ไม่ใช้เวลาขม")
	_check((bool(hr.ok) and GameState.money - m0 == roundi(DayLoop._fee(os1) * e.helper_fee_share)) or (not bool(hr.ok) and GameState.money == m0), "ผ่าน = ได้ค่าแรง %d%% · ไม่ผ่าน = ไม่ได้เงิน (%s)" % [roundi(e.helper_fee_share * 100), "ผ่าน" if hr.ok else "ไม่ผ่าน"])
	DayLoop.door_queue.append(DayLoop.door_entry(os1))
	_check(not DayLoop.helper_button(DayLoop.door_front()).visible and DayLoop.door_helper().is_empty(), "วันละ %d งาน" % e.helper_per_day)
	DayLoop.door_queue.clear()
	GameState.rank_level = 2
	DayLoop.helper_used_today = 0
	_check(not DayLoop.helper_can(os1), "ยังไม่ถึงเชี่ยวชาญ → ไม่มีลูกมือ")
	GameState.set_rank(4)

	# เซฟ: perks · ⭐⭐⭐
	SaveGame.allow_in_tests = true
	SaveGame.save()
	GameState.reset()
	SaveGame.load_into()
	_check(GameState.has_perk(&"sweet_talk") and GameState.has_perk(&"mentor") and GameState.perk_pending() == 0 and int(GameState.level_three_stars.get(1, 0)) == 2, "โหลดเซฟ → ความสามารถครบ 4 · ⭐⭐⭐ ของมิ้น")
	SaveGame.clear()
	SaveGame.allow_in_tests = false

	# ---------------- L · บทสอนครั้งแรก 4 บท
	GameState.reset()
	DayLoop._reset_run()
	var files_ok := ["tut_affinity", "tut_story", "tut_exam", "tut_helper"].all(func(k: String) -> bool: return DialogUtil.has_lines(DayLoop.TUTORIALS[k]))
	_check(files_ok, "บทสอนครั้งแรก 4 ไฟล์มีบทพูด")
	_check(DayLoop._npc_tutorials().is_empty(), "เริ่มเกม: ยังไม่มีบทสอนลูกค้าประจำ/ยศ")
	GameState.affinity_event(&"teacher", &"pass")
	GameState.add_xp(e.rank_xp[1])
	var tl := DayLoop._npc_tutorials()
	_check(tl.has("tut_affinity") and tl.has("tut_exam"), "หัวใจขึ้นครั้งแรก + XP ครบ → บทสอนความสนิท/สอบ (%s)" % ", ".join(tl))
	GameState.set_rank(3)
	DayLoop.door_queue.clear()
	DayLoop.door_queue.append(DayLoop.door_entry(load("res://Resources/Customers/lv1_amnuay_startup.tres")))
	_check(DayLoop._npc_tutorials().has("tut_helper"), "เชี่ยวชาญ + งานขมOS หน้าประตู → บทสอนมิ้นลูกมือ")
	DayLoop.door_queue.clear()

	GameState.reset()
	DayLoop._reset_run()
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
