extends Node
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น G] ขอคำปรึกษา / ขอให้ช่วย (PLAN_0_6_0 ข้อ 5)
## เปิด Test/request_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var ts: TimeSystem


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	DayLoop._reset_run()
	GameState.reset()
	var e: EconomyConfig = GameState.economy

	# A · คลัง 24 เรื่อง (ปรึกษา 12 · ช่วย 12) · ไม่มีปัญหา · ทุกเรื่องมีคนเอามาได้
	var all := RequestBook.all()
	var bad := PackedStringArray()
	for r in all:
		for p in r.problems():
			bad.append("%s: %s" % [r.id, p])
		if not NpcBook.all().any(func(n: CustomerNPC) -> bool: return RequestBook.fits(r, n, 4)):
			bad.append("%s ไม่มีใครเอามา" % r.id)
	_check(all.size() == 25 and all.filter(func(r: RequestTask) -> bool: return r.is_consult()).size() == 13, "คำขอ 25 เรื่อง (ปรึกษา 13 รวมเรื่องกลุ่ม)")
	_check(bad.is_empty(), "ข้อมูลคำขอไม่มีปัญหา %s" % ", ".join(bad))

	# B · ยศ: ช่างมือใหม่ไม่มีใครมาขอคำปรึกษา
	var amn := NpcBook.by_id(&"amnuay")
	var cons := RequestBook.by_id(&"c_ssd_or_new")
	_check(not RequestBook.fits(cons, amn, 0) and RequestBook.fits(cons, amn, 1), "ขอคำปรึกษาเริ่มยศฝึกหัด")
	ts.set_clock(10 * 60)
	DayLoop._recent_requests.clear()
	var kinds := { }
	for i in 30:
		var c := DayLoop._pick_request()
		if c:
			kinds[c.request().kind] = true
		DayLoop._recent_requests.clear()
	_check(not kinds.has(RequestTask.Kind.CONSULT) and kinds.has(RequestTask.Kind.FAVOR), "ยศมือใหม่ สุ่มได้แต่ขอให้ช่วย")

	# C · เคสคำขอ: ไม่รับเครื่อง · 1 เทิร์น · เซฟ/โหลดได้
	var c := RequestBook.make_case(RequestBook.by_id(&"f_sms_scam"), amn)
	_check(c.is_request() and not c.takes_machine() and c.slots(e) == 1 and c.customer == "ลุงอำนวย", "คำขอไม่รับเครื่อง · 1 เทิร์น · มีชื่อคน")
	var back := CustomerCase.from_ref(JSON.parse_string(JSON.stringify(CustomerCase.to_ref(c))))
	_check(back and back.request() == c.request() and back.customer == c.customer, "เซฟ/โหลดคำขอ")

	# D · หน้าประตู: ปุ่ม "ช่วยเลย" · รับ = นับโควตา · ตอบถูก 2 ข้อ = ♥ request_good · เวลา 1 เทิร์น
	DayLoop.quiet = true
	DayLoop.door_queue.clear()
	DayLoop.accepted_today = 0
	DayLoop.visitor_waves.clear()
	DayLoop.door_queue.append(DayLoop.door_entry(c))
	var fv := DayLoop._door_front_view(DayLoop.door_front())
	_check(String(fv.accept.text).begins_with("ช่วยเลย"), "ปุ่มหน้าประตู = ช่วยเลย (1 เทิร์น)")
	var t0 := ts.current_minute
	var a0 := GameState.affinity(&"amnuay")
	DayLoop.requests_today = 0
	_check(DayLoop.door_accept(-1) and DayLoop.accepted_today == 0 and DayLoop.requests_today == 1 and not DayLoop.request_state.is_empty(), "รับคำขอ → ไม่กินโควตา 3 คน · นับคำขอวันนี้ 1")
	var v := DayLoop.request_view()
	_check(int(v.steps) == 2 and (v.choices as Array).size() == 3 and (v.choices as Array).has(c.request().choices[0]), "ข้อ 1/2 · 3 ตัวเลือก")
	var r1 := DayLoop.request_answer(c.request().choices[0])
	_check(r1.correct and r1.more, "ข้อแรกถูก → มีข้อต่อ")
	DayLoop._on_request_card_done()
	_check(int(DayLoop.request_state.step) == 2, "ไปข้อ 2")
	DayLoop.request_answer(c.request().choices2[0])
	var out := DayLoop.request_finish()
	var g: int = e.affinity_gain[&"request_good"]
	_check(out.grade == &"good" and GameState.affinity(&"amnuay") == a0 + g and out.money == 0, "ตอบดีครบ → ♥ +%d · ขอให้ช่วยไม่คิดเงิน" % g)
	_check(ts.current_minute - t0 == TimeSystem.SLOT_MIN and not DayLoop._working, "ใช้ 1 เทิร์น")
	_check(GameState.request_log.size() == 1 and int(GameState.request_log[0].right) == 2, "จดผลลง request_log")
	DayLoop.door_queue.push_front(DayLoop.door_entry(RequestBook.make_case(RequestBook.by_id(&"f_wifi_pass"), amn)))
	_check(DayLoop.door_accept_state(-1) == &"full" and String(DayLoop._door_front_view(DayLoop.door_front()).accept.text).contains("ครบ"), "คำขอเรื่องที่ 2 ของวัน → วันนี้ช่วยครบแล้ว")
	DayLoop.door_queue.pop_front()
	_check(DayLoop.quota_left() == e.daily_cap, "โควตางานซ่อมยังเต็ม %d" % e.daily_cap)

	# E · ขอคำปรึกษา ตอบผิด → ไม่ได้เงิน ไม่ได้ความสนิท (ไม่โกรธ)
	GameState.set_rank(1)
	var tea := NpcBook.by_id(&"teacher")
	var cc := RequestBook.make_case(RequestBook.by_id(&"c_school_budget"), tea)
	DayLoop.door_queue.push_front(DayLoop.door_entry(cc))
	var m0 := GameState.money
	var t1 := GameState.affinity(&"teacher")
	DayLoop.requests_today = 0
	DayLoop.door_accept(-1)
	DayLoop.request_answer(cc.request().choices[1])
	var o2 := DayLoop.request_finish()
	_check(o2.grade == &"miss" and GameState.money == m0 and GameState.affinity(&"teacher") == t1, "ตอบผิด → ไม่ได้เงิน/ความสนิท ไม่เสียด้วย")
	var cc2 := RequestBook.make_case(RequestBook.by_id(&"c_school_budget"), tea)
	DayLoop.door_queue.push_front(DayLoop.door_entry(cc2))
	DayLoop.requests_today = 0
	DayLoop.door_accept(-1)
	DayLoop.request_answer(cc2.request().choices[0])
	var o3 := DayLoop.request_finish()
	_check(o3.grade == &"good" and GameState.money == m0 + cc2.request().fee, "ตอบดี → ค่าปรึกษา ฿%d" % cc2.request().fee)

	# F · นักเรียนได้ความสนิท ×1.5
	var fa0 := GameState.affinity(&"fai")
	GameState.affinity_event(&"fai", &"request_good")
	_check(GameState.affinity(&"fai") - fa0 == ceili(g * 1.5), "น้องฝ้าย (นักเรียน) ความสนิท ×1.5 → +%d" % (GameState.affinity(&"fai") - fa0))

	# G · หน้าประตูสุ่มคำขอได้ (request_share) · โทรเข้าไม่เป็นคำขอ
	DayLoop.door_queue.clear()
	var got := 0
	var repairs := 0
	for i in 40:
		DayLoop.door_queue.clear()
		DayLoop._recent.clear()
		DayLoop.requests_spawned_today = 0
		DayLoop.add_visitors(3, false, 0, 600)
		var rq := 0
		for j in DayLoop.door_queue:
			if (j["case"] as CustomerCase).is_request():
				rq += 1
			else:
				repairs += 1
		got += rq
		if rq > 1:
			got = -999
	_check(got > 0 and got <= 40, "สุ่มหน้าประตูได้คำขอบ้าง · วันละไม่เกิน 1 (%d/40 วัน)" % got)
	_check(repairs == 120, "คำขอเป็นคนที่มาเพิ่ม ลูกค้างานซ่อมครบ 3 คนทุกรอบ (%d/120)" % repairs)
	DayLoop.door_queue.clear()
	DayLoop.quiet = false

	# H · การ์ดคำขอ (UI) แสดงคำถาม → ตอบ → คำอธิบาย
	var card := RequestCard.new()
	add_child(card)
	await get_tree().process_frame
	card.show_question({ "kind": "ขอให้ช่วย", "title": "ทดสอบ", "ask": "ถาม", "who": "ลุง", "question": "Q", "choices": ["ก", "ข", "ค"], "step": 1, "steps": 1 })
	_check(card._choices.get_child_count() == 3 and not card._action.visible, "การ์ด: 3 ปุ่ม · ยังไม่มีปุ่มเสร็จ")
	card.show_answer({ "correct": false, "answer": "ก", "explain": "เพราะ…", "more": false })
	_check(card._action.visible and card._action.text == "เสร็จ" and card._feedback.text.contains("ก"), "ตอบแล้ว: บอกคำตอบที่ดีกว่า + ปุ่มเสร็จ")
	card.queue_free()

	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
