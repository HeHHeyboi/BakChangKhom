extends Node
## [0.8.0 ขั้น C–G] บทต้นเดือนตามยศ · ตัวเลือก → ธง/ความสนิท · ทางแยกบท 11–12 → ฉากจบ · บทฉากจบจากข้อมูลจริง (มิ้นดูแลร้าน)
## ของขวัญสิ้นปี · ของตกแต่ง · ใบประกาศ E01–E04 R08 R09 · เซฟ gifts_received
var fails := 0


func _ready() -> void:
	DayLoop.quiet = true
	var gs := GameState
	gs.reset()
	var known := DialogUtil.known_speakers()
	var A := get_node(^"/root/Achievements")

	# A · บทต้นเดือนตามยศ
	gs.rank_level = 1
	_check(String(gs.chapter_story(7).file).ends_with("_low.txt") and String(gs.chapter_story(9).file).ends_with("_low.txt"), "ยศต่ำ → บท 7/9 แบบยังไม่ชวน")
	gs.rank_level = 2
	_check(not String(gs.chapter_story(7).file).ends_with("_low.txt") and String(gs.chapter_story(3).file).ends_with("Chapter3DecorateHouse.txt"), "ยศถึง → บทปกติ")
	for ch in gs.CHAPTERS:
		if ch.has("low_file"):
			_check(DialogUtil.lint(ch.low_file, known).is_empty(), "ไฟล์บทยศต่ำผ่านตัวตรวจ %s" % String(ch.low_file).get_file())

	# B · ตัวเลือกบทต้นเดือน → ความสนิท · ทางแยก
	var amn := gs.affinity(&"amnuay")
	gs.chapter_choice(4, "ชวนลูกหลานพาพ่อแม่มาเรียนใช้เครื่อง")
	_check(gs.affinity(&"amnuay") == amn + 2 and gs.story_flags.get("ch4_pick", "") == "ชวนลูกหลานพาพ่อแม่มาเรียนใช้เครื่อง", "ตัวเลือกบท 4 → ลุงอำนวย +2 · จด ch4_pick")
	_check(gs.decide_ending() == &"stay", "ไม่ได้เลือกทางแยก = อยู่ต่อ")
	gs.chapter_choice(11, "กลับไปทำงานในเมือง")
	_check(gs.decide_ending() == &"city", "บท 11 กลับเมือง → city")
	gs.chapter_choice(12, "ทำงานกับบริษัทแบบออนไลน์จากร้าน")
	_check(gs.decide_ending() == &"coworking", "บท 12 เปลี่ยนใจได้ → coworking (ไม่ผูกยศ)")
	gs.rank_level = 0
	_check(gs.decide_ending() == &"coworking", "ยศต่ำก็เลือกได้")
	gs.shop_closed = true
	_check(gs.decide_ending() == &"failure", "ร้านปิด = failure เสมอ")
	gs.shop_closed = false

	# C · ของขวัญสิ้นปี
	gs.npc_affinity[&"amnuay"] = 85
	gs.npc_affinity[&"teacher"] = 70
	gs.npc_affinity[&"fai"] = 30
	gs.npc_affinity[&"phum"] = 90
	var list := DecorBook.year_gifts()
	var gnpc: Array = (list.gifts as Array).map(func(g: Dictionary) -> StringName: return (g.npc as CustomerNPC).id)
	_check(gnpc.has(&"yai") and gnpc.has(&"amnuay") and gnpc.has(&"phum") and not gnpc.has(&"teacher") and not gnpc.has(&"fai"), "ของขวัญ: ยายเสมอ · ≥80 ให้ของ (%s)" % str(gnpc))
	_check((list.cards as Array).has("ครู") and not (list.cards as Array).has("น้องฝ้าย"), "60–79 = การ์ดอวยพร")
	var gp := DecorBook.gift_dialog(list)
	_check(gp != "" and DialogUtil.lint(gp, known).is_empty(), "บทของขวัญผ่านตัวตรวจ %s" % str(DialogUtil.lint(gp, known)))
	var ts: TimeSystem = EventManager.time_system
	ts.shift = TimeSystem.TOTAL_SHIFTS
	DayLoop._plan_gifts(ts)
	_check(gs.gifts_received.size() == 3 and bool(gs.story_flags.get("gifts_done", false)), "วันสุดท้าย (บอท) → ได้ของขวัญ 3 ชิ้น")
	DayLoop._plan_gifts(ts)
	_check(DayLoop.gift_pending.is_empty(), "ให้ของขวัญครั้งเดียว")
	_check(DecorBook.owned().any(func(d: ShopDecor) -> bool: return d.id == &"gift_amnuay"), "ของขวัญขึ้นเป็นของตกแต่ง")
	A.check_all()
	_check(A.has(&"R08"), "ได้ R08 ของขวัญเต็มร้าน")

	# D · ของตกแต่งจากใบประกาศ · ฉายา
	gs.achievements["A02"] = { "month": 3, "day": 1 }
	_check(DecorBook.title_text() == "ช่างครบเครื่อง", "A02 → ฉายาช่างครบเครื่อง")
	gs.achievements["D03"] = { "month": 10, "day": 3 }
	_check(DecorBook.owned(ShopDecor.Spot.SHELF).any(func(d: ShopDecor) -> bool: return d.id == &"ach_trophy"), "D03 → ถ้วยบนชั้น")

	# E · บทฉากจบ (ทุกแบบผ่านตัวตรวจ · มีคนที่สนิทขอบคุณ)
	for i in 12:
		gs.month_results.append({ "m": i + 1, "reached": i != 4 })
	for e in [&"stay", &"coworking", &"city", &"failure"]:
		var lines := EndingBook.lines_for(e)
		var p := EndingBook.build(e)
		_check(DialogUtil.lint(p, known).is_empty(), "ฉากจบ %s ผ่านตัวตรวจ (%d บรรทัด) %s" % [e, lines.size(), str(DialogUtil.lint(p, known).slice(0, 2))])
	_check(EndingBook.top_npcs()[0] == &"phum", "คนที่สนิทที่สุดขึ้นขอบคุณ (ไม่รวมยาย/มิ้น)")
	var stay := "\n".join(EndingBook.lines_for(&"stay"))
	_check(stay.contains("ถึงเป้า 11 จาก 12") and stay.contains("ภูมิ,"), "สรุปปีใช้ตัวเลขจริง + คำขอบคุณ")

	# F · มิ้นดูแลร้าน: สอนมาก/สนิทมาก = ดี · ไม่สอนเลย = ลำบาก
	gs.part_clears.clear()
	gs.npc_affinity[&"min"] = 30
	for id in gs.npc_affinity.keys():
		if id != &"min":
			gs.npc_affinity[id] = 10
	var low := EndingBook.min_report()
	_check(low.tier == "hard" and (low.untaught as Array).size() == 6, "ไม่เคยสอน = มิ้นลำบาก (%s · %d)" % [low.tier, low.score])
	for p in EndingBook.PART_NAMES:
		gs.part_clears[p] = 5
	gs.npc_affinity[&"min"] = 75
	for id in [&"amnuay", &"teacher", &"headman", &"bew"]:
		gs.npc_affinity[id] = 70
	gs.story_flags["min_learned"] = true
	var hi := EndingBook.min_report()
	_check(hi.tier == "good" and (hi.taught as Array).size() == 6 and (hi.loyal as Array).size() == 4, "สอนครบ + ลูกค้าสนิท = ร้านไปได้ดี (%s · %d)" % [hi.tier, hi.score])
	var city := "\n".join(EndingBook.lines_for(&"city"))
	_check(city.contains("ทำเองได้แล้ว") and city.contains("ขอบคุณที่ไว้ใจ"), "ฉากจบกลับเมืองเล่าผลมิ้น")

	# G · ใบประกาศฉากจบ · ชมรม
	gs.ending = &"city"
	A.check_all()
	_check(A.has(&"E03") and not A.has(&"E01"), "ฉากจบกลับเมือง → E03")
	for id in [&"phum", &"fern", &"oat", &"namwan"]:
		gs.npc_affinity[id] = 65
	A.check_all()
	_check(A.has(&"R09"), "ชมรมสนิทครบ 4 → R09")
	_check(DayLoop.ending_summary().contains("มิ้นดูแลร้าน"), "การ์ดจบเกมสรุปผลมิ้น")

	# H · เซฟ/โหลด ของขวัญ + ทางแยก
	SaveGame.allow_in_tests = true
	var backup := FileAccess.get_file_as_string(SaveGame.PATH) if SaveGame.exists() else ""
	_check(SaveGame.save(), "เซฟได้")
	var gifts := gs.gifts_received.duplicate()
	gs.reset()
	_check(gs.gifts_received.is_empty(), "reset ล้างของขวัญ")
	SaveGame.load_into()
	_check(gs.gifts_received == gifts and gs.decide_ending() == &"coworking", "โหลด → ของขวัญ + ทางแยกกลับมา")
	if backup != "":
		var f := FileAccess.open(SaveGame.PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	else:
		SaveGame.clear()
	SaveGame.allow_in_tests = false
	gs.reset()
	DayLoop.quiet = false
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
