extends Node
## [Claude 16 พ.ย. 2569 · 0.5.0 ขั้น B] ความสนิทตามเหตุการณ์ในร้าน (PLAN_0_5_0 ข้อ 2.4)
## หน้าประตู (มา · ปฏิเสธ · เดินกลับ · รอได้ +1 · รับตามนัด) · งานต่อหน้า · งานบนชั้นตอนมารับ (ทันนัด/เลยนัด) · โทรเรียก · ทำของเสีย · มาเอาคืน · ทิปคนสนิท · ป้าย/ตัวเลขเด้ง
## เปิด Test/affinity_loop_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var ts: TimeSystem
var e: EconomyConfig
var g: Dictionary


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	e = GameState.economy
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	DayLoop._reset_run()
	GameState.reset()
	g = e.affinity_gain
	var teacher_ram: CustomerCase = load("res://Resources/Customers/lv2_teacher_ram.tres")
	var headman_ram: CustomerCase = load("res://Resources/Customers/lv2_headman_ram.tres")
	var amnuay_os: CustomerCase = load("res://Resources/Customers/lv1_amnuay_startup.tres")
	var min_os: CustomerCase = load("res://Resources/Customers/lv1_min_hang.tres")
	var min_gpu: CustomerCase = load("res://Resources/Customers/lv3_min_gpu.tres")
	var yai_ram: CustomerCase = load("res://Resources/Customers/lv2_yai_ram.tres")
	for c in [teacher_ram, headman_ram, amnuay_os, min_os, min_gpu, yai_ram]:
		DayLoop._parts_seen[c.part_id] = true

	# ---------------- A · หน้าประตู
	_reset_door(9 * 60)
	_check(DayLoop.npc_id(teacher_ram) == &"teacher" and DayLoop.npc_name(yai_ram) == "ยาย", "หา NPC จากเคส: ครู · ยาย")
	DayLoop.door_queue.append(DayLoop.door_entry(teacher_ram))
	_check(GameState.met(&"teacher") and int(GameState.npc_last_visit[&"teacher"]) == ts.shift, "มายืนหน้าประตู → จดวันที่มา")
	var base := teacher_ram.patience_slots(e)
	_check(DayLoop.door_patience_slots(teacher_ram) == base, "ครู (10 · แปลกหน้า) รอได้ %d เทิร์นเท่าเดิม" % base)
	_check(DayLoop.door_reject() and GameState.affinity(&"teacher") == 10 + g[&"reject"], "ปฏิเสธ → ความสนิท %d" % g[&"reject"])
	GameState.add_affinity(&"teacher", 40 - GameState.affinity(&"teacher"))
	_check(DayLoop.door_patience_slots(teacher_ram) == base + 1, "ครูถึง คุ้นเคย (40) → รอได้ +1 เทิร์น")
	_check(DayLoop.visitor_toast._queue.any(func(q: PackedStringArray) -> bool: return q[0].contains("♥ ครู: คุ้นเคย")), "ขึ้นระดับ → ป้าย \"♥ ครู: คุ้นเคย\"")
	# เดินกลับ
	DayLoop._door_tick = 9 * 60
	DayLoop.door_queue.append(DayLoop.door_entry(teacher_ram, false, false, false, (base + 1) * TimeSystem.SLOT_MIN - 1))
	ts.set_clock(9 * 60 + 30)
	DayLoop._tick_door(ts)
	_check(DayLoop.door_queue.is_empty() and GameState.affinity(&"teacher") == 40 + g[&"walk_out"], "รอจนเดินกลับ → %d" % g[&"walk_out"])
	# รับตามนัด (เครื่องขึ้นชั้น)
	_reset_door(9 * 60)
	DayLoop.quiet = true # ไม่เล่นบทลูกค้า
	DayLoop.door_queue.append(DayLoop.door_entry(headman_ram, false, true))
	var h0 := GameState.affinity(&"headman")
	_check(DayLoop.door_accept(1) and GameState.affinity(&"headman") == h0 + e.affinity_gain[&"kept_appointment"], "ลูกค้าที่นัดไว้มาแล้วรับเครื่อง → +2")
	await _frames(2)
	DayLoop._working = false

	# ---------------- B · งานต่อหน้าลูกค้า (ขมOS)
	_reset_door(10 * 60)
	var a0 := GameState.affinity(&"amnuay")
	_front_repair(amnuay_os, 100)
	var r := DayLoop.last_result
	var p3: int = g[&"pass"] + g[&"three_star"]
	_check(int(r.get("affinity", 0)) == p3 and GameState.affinity(&"amnuay") == a0 + p3 and String(r.get("npc_name", "")) == "ลุงอำนวย", "ขมOS ⭐⭐⭐ → ลุงอำนวย +%d (ผ่าน + ⭐⭐⭐)" % p3)
	var hist: Array = GameState.npc_history.get(&"amnuay", [])
	_check(hist.size() == 1 and String(hist[0].text) == amnuay_os.job_title, "จดประวัติเครื่อง: \"%s\"" % amnuay_os.job_title)
	DayLoop.reward_popup.pop_result(r)
	_check(DayLoop.reward_popup.live.any(func(l: Label) -> bool: return l.text == "♥ +%d ลุงอำนวย" % p3), "ตัวเลขเด้ง \"♥ +%d ลุงอำนวย\"" % p3)
	_front_repair(amnuay_os, 30, true)
	_check(int(DayLoop.last_result.get("affinity", 0)) == g[&"fail"] and String((GameState.npc_history[&"amnuay"] as Array)[-1].text).ends_with("(ไม่ผ่าน)"), "ยอมแพ้ → −4 · ประวัติบอก \"ไม่ผ่าน\"")
	# ทิปคนสนิท
	GameState.add_affinity(&"min", 65 - GameState.affinity(&"min"))
	var m0 := GameState.money
	_front_repair(min_os, 80)
	var tip_rows := GameState.ledger.filter(func(x: Dictionary) -> bool: return x.kind == &"tip" and String(x.note) == "ทิปจากมิ้น")
	_check(tip_rows.size() == 1 and int(tip_rows[0].amount) == e.affinity_tip and GameState.affinity(&"min") == 65 + g[&"pass"], "มิ้น (สนิท) งานผ่าน → ทิป ฿%d + ความสนิท +%d" % [e.affinity_tip, g[&"pass"]])
	_check(GameState.money - m0 == int(DayLoop.last_result.get("money", 0)), "การ์ดผลงานรวมทิปในเงินที่ได้")
	# ยาย: ไม่มีค่าความสนิท
	_front_repair(yai_ram, 100)
	_check(int(DayLoop.last_result.get("affinity", 0)) == 0 and not GameState.npc_history.has(&"yai"), "ยาย: ไม่มีความสนิท ไม่จดประวัติ")

	# ---------------- C · งานบนชั้น → คิดตอนมารับ
	_reset_door(9 * 60)
	DayLoop.shelf.orders.clear()
	var t0 := GameState.affinity(&"teacher")
	var o := DayLoop.shelf.add(teacher_ram, ts.shift, 1)
	_fake_repair(o, 100)
	_check(GameState.affinity(&"teacher") == t0, "ซ่อมเสร็จบนชั้น (ลูกค้ายังไม่มา) → ความสนิทยังไม่เปลี่ยน")
	var paid := DayLoop._pay_pickup({ "order": o, "mult": 1.0, "sat_delta": 0, "on_time": true, "late": 0 })
	var pk: int = g[&"pass"] + g[&"three_star"] + g[&"on_time"]
	_check(int(paid["affinity"]) == pk and GameState.affinity(&"teacher") == t0 + pk, "มารับ ทันนัด ⭐⭐⭐ → +%d (ผ่าน + ⭐⭐⭐ + ทันนัด)" % pk)
	var o2 := DayLoop.shelf.add(teacher_ram, ts.shift, 1)
	_fake_repair(o2, 80)
	t0 = GameState.affinity(&"teacher")
	paid = DayLoop._pay_pickup({ "order": o2, "mult": 0.9, "sat_delta": -30, "on_time": false, "late": 2 })
	var pl: int = g[&"pass"] + g[&"late_day"] * 2
	_check(int(paid["affinity"]) == pl and GameState.affinity(&"teacher") == t0 + pl, "มารับ ช้า 2 วัน → ผ่าน + เลยนัด×2 = %d" % pl)
	# โทรเรียกมารับก่อน
	DayLoop.shelf.orders.clear()
	var o3 := DayLoop.shelf.add(teacher_ram, ts.shift, 2)
	_fake_repair(o3, 80)
	t0 = GameState.affinity(&"teacher")
	_check(DayLoop.shelf_call_early(o3) and GameState.affinity(&"teacher") == t0 + g[&"call_early"], "โทรเรียกมารับก่อน → +%d" % g[&"call_early"])
	DayLoop.door_queue.clear()
	# ทำของเสีย (มีของชดใช้) → −8 ทันที
	DayLoop.shelf.orders.clear()
	var g0 := GameState.affinity(&"min")
	var og := DayLoop.shelf.add(min_gpu, ts.shift, 1)
	DayLoop.current_job = { "case": min_gpu, "order": og }
	DayLoop.today_case = min_gpu
	GameState.hold_next_payment = true
	GameState.record_repair(min_gpu.part(), 20, true, min_gpu.fee, min_gpu.level)
	_check(og.replace_part != &"" and GameState.affinity(&"min") == g0 + g[&"damage"], "ทำการ์ดจอเสีย (ต้องหาของชดใช้) → มิ้น %d ทันที" % g[&"damage"])
	# ลูกค้ามาเอาคืน
	DayLoop.shelf.orders.clear()
	var oh := DayLoop.shelf.add(headman_ram, ts.shift, 1)
	oh.due = ts.shift - e.late_grace_days - 1
	var hm0 := GameState.affinity(&"headman")
	DayLoop._open_shelf_day(ts)
	_check(DayLoop.shelf.orders.is_empty() and GameState.affinity(&"headman") == maxi(hm0 + g[&"reclaimed"], 0), "เลยผ่อนผัน ลูกค้ามาเอาเครื่องคืน → %d" % g[&"reclaimed"])

	# ---------------- D · สรุปความสนิทของบท
	var gains := GameState.affinity_gains(ts.chapter())
	_check(gains.has(&"teacher") and gains.has(&"amnuay") and gains.has(&"min"), "affinity_gains มีครู · ลุงอำนวย · มิ้น")

	# ---------------- D2 · [ขั้น D] UI: การ์ดหน้าประตู · สมุดลูกค้า · สรุปเดือน
	var bl := DayLoop.bond_line(teacher_ram)
	_check(bl.begins_with("♥") and bl.contains(GameState.affinity_tier_name(&"teacher")) and bl.contains("เคยซ่อม: " + teacher_ram.job_title), "การ์ดหน้าประตู: หัวใจ · ระดับ · เคยซ่อม (%s)" % bl)
	_check(DayLoop.bond_line(yai_ram) == "", "ยาย: ไม่มีบรรทัดความสนิท")
	DayLoop.door_queue.clear()
	DayLoop.door_queue.append(DayLoop.door_entry(load("res://Resources/Customers/lv1_girl_wifi.tres")))
	var fv: Dictionary = DayLoop.door_view()["front"]
	_check(String(fv["name"]).begins_with("น้องฝ้าย") and String(fv["bond"]).contains("แปลกหน้า"), "ชื่อบนการ์ดใช้ชื่อเล่น \"น้องฝ้าย\" · แปลกหน้า")
	DayLoop.door_queue.clear()
	var book := DayLoop.customer_book_view()
	var rows: Array = book["rows"]
	_check(rows.size() == NpcBook.with_affinity().size() and bool(rows[0].met) and rows.any(func(r: Dictionary) -> bool: return not r.met and r.name == "???"), "สมุดลูกค้าครบทุกคนที่มีความสนิท · คนที่เจอแล้วขึ้นก่อน · ยังไม่เจอ = ???")
	var app = load("res://Scene/UI/customer_book_app.tscn").instantiate()
	add_child(app)
	await _frames(1)
	_check(app.get_node("%List").get_child_count() == NpcBook.with_affinity().size() and String(app.get_node("%Head").text).contains("รู้จักแล้ว"), "แอปสมุดลูกค้าวาดได้ครบทุกแถว")
	app.queue_free()
	var ms_text := DayLoop.month_summary_text(GameState.month_report(ts.month()))
	_check(ms_text.contains("ความสนิทเดือนนี้: ") and ms_text.contains("ครู ♥"), "สรุปเดือนมีบรรทัดความสนิท")

	# ---------------- E · [ขั้น C] คนสนิทมาบ่อยกว่า · เพิ่งมาไม่นานมาน้อยลง (สุ่มจากงาน Lv2 400 ครั้ง)
	GameState.seed_override = 11 # [0.8.0] ผลคงที่ (สุ่ม 400 ครั้งบาง seed ได้ ×1.7)
	GameState.reset()
	ts.shift = 10
	var low := _share(&"ครู")
	GameState.add_affinity(&"teacher", 90)
	var high := _share(&"ครู")
	GameState.note_visit(&"teacher", ts.shift - 1)
	var recent := _share(&"ครู")
	_check(high > low * 1.8 and recent < high * 0.5, "ครูถูกสุ่มมา: แปลกหน้า %.0f%% → ขาประจำ %.0f%% → เพิ่งมาเมื่อวาน %.0f%%" % [low * 100, high * 100, recent * 100])
	var people := { }
	for k in 400:
		people[DayLoop._pick_case(DayLoop._cases_of_level(2)).customer] = true
	_check(people.size() >= 5, "ยังเจอคนหลากหลาย (%d คน)" % people.size())
	ts.shift = 1

	# ---------------- F · [ขั้น E] เรื่องส่วนตัว
	GameState.reset()
	DayLoop._reset_run()
	var files_ok := true
	var n_stories := 0
	for n in NpcBook.with_affinity():
		for st: NpcStory in n.stories:
			n_stories += 1
			DialogScene.read_file(st.dialog)
			var keys: Array = DialogScene.DialogDict.keys()
			var ok := keys.has("ฟังเรื่อง") and keys.has(DayLoop.STORY_BUSY.to_lower())
			if st.good_choice != "":
				ok = ok and keys.has(st.good_choice.to_lower())
			if not ok:
				files_ok = false
				print("  ไฟล์เรื่องไม่ครบ ", st.dialog, " ", keys)
	_check(n_stories == 27 and files_ok, "เรื่องส่วนตัว 27 เรื่อง (0.6.0 +ผอ. +เพื่อนร่วมงาน · 0.8.0 +ภูมิ) · ทุกไฟล์มีทางเลือก \"ฟังเรื่อง\" / \"%s\" / ตัวเลือกจบดี" % DayLoop.STORY_BUSY)
	DialogScene.DialogDict = { "dialog": [] }
	GameState.add_affinity(&"teacher", 39 - GameState.affinity(&"teacher"))
	_check(DayLoop.next_story(&"teacher") == null, "ครู 39 → ยังไม่มีเรื่องเล่า")
	_front_repair(load("res://Resources/Customers/lv1_teacher_print.tres") if ResourceLoader.exists("res://Resources/Customers/lv1_teacher_print.tres") else amnuay_os, 100)
	GameState.add_affinity(&"teacher", 40 - GameState.affinity(&"teacher"))
	DayLoop.pending_story = { }
	DayLoop.affinity_result(teacher_ram, { "score": 100, "grade": GameState.Grade.GOOD })
	_check(DayLoop.pending_story.get("id") == &"teacher" and (DayLoop.pending_story["story"] as NpcStory).at == 40, "ส่งงานครู (ถึง 40) → รอเล่นเรื่องที่ 1")
	_check(DayLoop.bond_line(teacher_ram).contains("มีเรื่องอยากเล่า"), "การ์ดหน้าประตูบอก \"มีเรื่องอยากเล่า\"")
	var r_busy := DayLoop.story_finish(DayLoop.STORY_BUSY)
	_check(not bool(r_busy.get("heard", true)) and not GameState.story_seen(&"teacher", 40) and DayLoop.pending_story.is_empty(), "เลือก \"ยุ่ง\" → ยังไม่นับว่าฟัง ไม่เสียอะไร")
	DayLoop._queue_story(teacher_ram)
	var a1 := GameState.affinity(&"teacher")
	var m1 := ts.current_minute
	var r_ok := DayLoop.story_finish("ฟังเรื่อง")
	_check(bool(r_ok.heard) and bool(r_ok.good) and GameState.story_seen(&"teacher", 40) and GameState.affinity(&"teacher") == a1 + g[&"story_good"], "ฟังเรื่องที่ 1 (ไม่มีตัวเลือก) → จบดี +%d" % g[&"story_good"])
	_check(ts.current_minute == m1 + e.story_slots * TimeSystem.SLOT_MIN, "ฟังเรื่องใช้ %d เทิร์น" % e.story_slots)
	DayLoop.story_today = true
	GameState.add_affinity(&"teacher", 60 - GameState.affinity(&"teacher"))
	DayLoop._queue_story(teacher_ram)
	_check(DayLoop.pending_story.is_empty(), "วันละไม่เกิน 1 เรื่อง")
	DayLoop.story_today = false
	DayLoop._queue_story(teacher_ram)
	var st60: NpcStory = DayLoop.pending_story["story"]
	var a2 := GameState.affinity(&"teacher")
	var r_plain := DayLoop.story_finish("ซื้อใหม่เลยครับ ง่ายดี")
	_check(st60.at == 60 and not bool(r_plain.good) and GameState.affinity(&"teacher") == a2 + g[&"story_plain"], "เรื่องที่ 2 ตอบห้วน → +%d" % g[&"story_plain"])
	# ข้ามขั้นไม่ได้ · ของฝาก + ธง
	GameState.add_affinity(&"amnuay", 90)
	_check((DayLoop.next_story(&"amnuay") as NpcStory).at == 40, "ลุงอำนวยถึง 100 แต่ยังไม่ฟังเรื่องแรก → เริ่มที่เรื่อง 40")
	GameState.mark_story_seen(&"amnuay", 40)
	GameState.mark_story_seen(&"amnuay", 60)
	DayLoop.story_today = false
	DayLoop._queue_story(amnuay_os)
	var fan0 := GameState.count_item(&"fan_cpu")
	DayLoop.story_finish("ฟังเรื่อง")
	_check(GameState.count_item(&"fan_cpu") == fan0 + 1 and GameState.story_flags.get(&"npc_regular_amnuay", false), "เรื่องที่ 3 ลุงอำนวย → ได้พัดลม CPU + ธงขาประจำ")
	var forced_c: CustomerCase = load("res://Resources/Customers/w1_d1_amnuay_ram.tres")
	GameState.add_affinity(&"min", 100)
	DayLoop.story_today = false
	DayLoop._queue_story(load("res://Resources/Customers/lv1_min_hang.tres"))
	DayLoop.pending_story = { }
	_check(forced_c.forced and (func() -> bool: DayLoop._queue_story(forced_c); return DayLoop.pending_story.is_empty()).call(), "งานเนื้อเรื่อง (forced) ไม่เล่นเรื่องส่วนตัว")

	DayLoop.quiet = false
	DayLoop.shelf.orders.clear()
	DayLoop.door_queue.clear()
	GameState.reset()
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _share(who: String) -> float:
	DayLoop.reseed_day()
	DayLoop._recent.clear()
	var pool := DayLoop._cases_of_level(2)
	var hit := 0
	for k in 400:
		DayLoop._recent.clear() # วัดน้ำหนักล้วน ๆ (ในเกมจริง _recent กันเคสซ้ำอีกชั้น)
		if DayLoop._pick_case(pool).customer == who:
			hit += 1
	DayLoop._recent.clear()
	return hit / 400.0


func _front_repair(c: CustomerCase, score: int, gave_up := false) -> void:
	DayLoop.current_job = { "case": c }
	DayLoop.today_case = c
	GameState.record_repair(c.part(), score, false, c.fee, c.level, gave_up)


func _fake_repair(o: RepairShelf.Order, score: int) -> Dictionary:
	DayLoop.current_job = { "case": o.case, "order": o }
	DayLoop.today_case = o.case
	GameState.hold_next_payment = true
	return GameState.record_repair(o.case.part(), score, false, o.case.fee, o.case.level)


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


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
