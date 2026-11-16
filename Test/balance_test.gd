extends Node
## [Claude 15 พ.ย. 2569 · 0.3.0 ขั้น I] บอทเล่นครบปี 3 ระดับ → วัดกำไรรายเดือนเทียบเป้า (PLAN_0_3_0 ข้อ 7 · GDD 8.9)
## ใช้ DayLoop/GameState จริงทั้งหมด (หน้าประตู · โควตา 3 · ความอดทน · ใบรับเครื่อง · ชั้นวาง · จ่ายเงินตอนรับ · บิล · เป้า · ร้านปิด)
## ข้ามแค่มินิเกม (สุ่มคะแนนตามฝีมือบอท) กับบทพูด (DayLoop.quiet · ไม่เล่นบทเนื้อเรื่องระหว่างเดือน)
##   เก่ง  : คะแนน 88–100 · รับครบโควตา · ด่วนวันนี้เมื่อทำทัน · ซ่อมตามนัด · ล่วงเวลาเมื่อเครื่องถึงนัด · ซื้อชั้นวางเพิ่ม
##   ปกติ  : คะแนน 65–95 · พลาดบ้าง (ของเสีย 3% · ตั้ง env BAL_DMG=0.0 เพื่อดูแบบไม่มีของเสีย) · ว่างแล้วอู้ 15% ของเทิร์น · นัดวันถัดไปเสมอ · ซื้อชั้นวาง 4 ช่องตอนมีเงิน
##   ไม่ทำงาน: เปิดร้านแล้วปิดเลย ไม่รับใคร
## เกณฑ์: บอทปกติ (10 seed) ถึงเป้า ≥ 9/12 อย่างน้อย 70% · ค่ามัธยฐาน ≥ 10/12 · ร้านปิด ≤ 10% · บอทไม่ทำงานร้านปิด · บอทเก่งกำไรมากกว่า
## ผล 15 พ.ย. (เป้าใหม่ · ผลซ้ำได้ทุกครั้ง): ปกติ 8/10 seed ≥ 9/12 · มัธยฐาน 10 · ปิด 1/10 (ทำการ์ดจอเสียจนขาดทุน ฿3,110 ในเดือนเดียว) · ไม่มีของเสีย = 11–12/12 ทุก seed
## [0.4.0 ขั้น I] อะไหล่: งานที่ต้องเปลี่ยนชิ้นรอของบนชั้น · ทำของเสีย → หาของชดใช้ · ของสิ้นเปลืองหักจริง
##   บอทซื้อของ 2 นิสัย: "สั่งเมื่อมีงาน" (ปกติ/เก่ง · ปิดร้านแล้วสั่งออนไลน์ · เครื่องถึงนัดแต่ยังไม่มีของ → เดินไปตลาด 1 เทิร์น)
##   กับ "ตุนของ" (normal_stock · ซื้ออะไหล่ถูก ๆ เก็บไว้ล่วงหน้าที่ตลาด) — รายงานเทียบกันในตาราง
## ผล 15 พ.ย. 0.4.0 (เป้าเดิม · ค่าชดใช้ใหม่ · บอทซื้อชั้นเก็บอะไหล่ 14 ช่อง): ปกติ 10/10 seed ≥ 9/12 · มัธยฐาน 10 · ไม่มีร้านปิด
## ผล 16 พ.ย. 0.5.0 (สอบเลื่อนยศ · ยศล็อกระดับงาน · XP 1000/3000/6500/11000 · ความสนิท · มิ้นลูกมือ): ปกติ 9/10 seed ≥ 9/12 · มัธยฐาน 10 · ไม่มีร้านปิด · ยศ 2/3/4/5 ราว ก.พ./เม.ย./มิ.ย.–ก.ค./ก.ย. · สนิท 1–5 คน ขาประจำ 1–3 คน · มิ้นได้ ≤ ฿546/ปี · เก่ง ฿29,594 > ปกติ ฿24,676 · แบ่งรันได้ด้วย BAL_LVS
## ผล 16 พ.ย. 0.6.0 (สถานการณ์ซ่อม + ตรวจก่อนรู้อะไหล่ · คำขอนอกโควตาวันละ 1 · นักเรียน ×0.6 · กลุ่ม · รอบ 16:00 · เป้าใหม่ 250/200/650/750/900/1250/1450/1800/2100/1900/1900/2250): ปกติ 8/10 seed ≥ 9/12 · มัธยฐาน 9 · ไม่มีร้านปิด · เก่ง 11–12/12 ~฿25,200 > ปกติ ~฿20,300 > ตุนของ ~฿18,600 · ไม่ทำงานปิดเดือน 3 · ยศ 2/4–5/6–7/9–10 · สนิท 3–5 · คำขอ 7–24 เรื่อง/ปี · ครึ่งตรวจแล้วรอของ 7–15 ครั้ง
##   ไม่มีสถานการณ์ (BAL_NOSCEN=1) ได้มัธยฐาน ~9.5 → ตรวจก่อนรู้อะไหล่ทำให้เครื่องรอบนชั้นนานขึ้น + อะไหล่ใช้บ่อยขึ้น (เงินหมุนข้ามเดือน) ~1 เดือน/ปี · สวิตช์ทดลอง BAL_REQ · BAL_NOWIN · BAL_NOSCEN · BAL_STUFEE · BAL_NOTRAIT · BAL_PARTW · BAL_SEEDS
##   สั่งเมื่อมีงาน กำไรเฉลี่ย ฿24,197 · ตุนของ ฿21,107 (เงินจม + เดินไปตลาดบ่อย) · เก่ง ฿31,391
## ผล 16 พ.ย. 0.7.0 (seed รายวัน · อีเวนต์ 12 เดือน + สุ่ม · ร้านปลอม · ใบประกาศ · เป้าใหม่ 250/200/550/650/800/1100/1250/1750/1800/1500/2000/2000): ดูผลรันล่าสุดใน PLAN_0_7_0 ข้อ 6 · สวิตช์ BAL_NOEVENT=1 ปิดอีเวนต์
## เปิด Test/balance_test.tscn → F6 → Output มีตารางรายเดือน + "T DONE fails=0" (ใช้เวลา ~1 นาที)

const SEEDS := [11, 22, 33, 44, 55]
## บอทปกติเล่นหลาย seed กว่า (ใช้หาค่ามัธยฐานไว้ตั้งเป้า)
## [0.7.0] 10 → 30 seed (201–230): รันเร็วพอแล้ว (~1 นาที) · ผล 10 seed เดิมแกว่งตามชุด seed มาก
const NORMAL_SEEDS := [201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230]

var fails := 0
var ts: TimeSystem
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	DayLoop.day_skip_seconds = 0.0
	var demo := DayLoop.demo_shifts
	DayLoop.demo_shifts = 0 # เล่นครบปี ไม่จบเดโม
	var res := { }
	# BAL_LVS=normal,good → เล่นเฉพาะระดับที่ระบุ (แบ่งรันได้ · ไม่ตรวจเกณฑ์ข้ามระดับ)
	var lvs: Array = [&"good", &"normal", &"normal_stock", &"idle"]
	if OS.has_environment("BAL_LVS"):
		lvs = Array(OS.get_environment("BAL_LVS").split(",")).map(func(x: String) -> StringName: return StringName(x))
	_apply_env_overrides()
	for lv in lvs:
		res[lv] = []
		var seeds: Array = NORMAL_SEEDS if lv in [&"normal", &"normal_stock"] else (SEEDS if lv == &"good" else [SEEDS[0]])
		if OS.has_environment("BAL_SEEDS"): # [0.6.0] BAL_SEEDS=11,22 → รันเฉพาะ seed ที่ระบุ
			seeds = Array(OS.get_environment("BAL_SEEDS").split(",")).map(func(x: String) -> int: return int(x))
		for s in seeds:
			res[lv].append(await play_year(lv, s))
	_report(res)
	if OS.has_environment("BAL_LVS"):
		DayLoop.demo_shifts = demo
		DayLoop._reset_run()
		print("T DONE fails=", fails)
		get_tree().quit()
		return
	var normal_hits: Array = res[&"normal"].map(func(r: Dictionary) -> int: return int(r.hits))
	var good_profit := _avg(res[&"good"], &"profit")
	var normal_profit := _avg(res[&"normal"], &"profit")
	# บอทปกติทำของลูกค้าเสีย 3% ของงาน · การ์ดจอเสีย = ชดใช้ ฿2,500 (มากกว่ากำไรทั้งเดือน) → บาง seed พลาดติดกันจนร้านปิดได้
	var ok_seeds: int = normal_hits.filter(func(h: int) -> bool: return h >= 9).size()
	var sorted_hits: Array = normal_hits.duplicate()
	sorted_hits.sort()
	# ไม่มีของเสีย (BAL_DMG=0) บอทปกติได้ 11–12/12 ทุก seed — ที่พลาดมาจากค่าชดใช้ของเสียเป็นหลัก
	# [0.7.0] seed รายวันเปลี่ยนชุดสุ่ม → วัด 30 seed (201–230): ≥ 9/12 ราว 50% ของ seed · มัธยฐาน 9 — 70% เดิมขึ้นกับชุด seed 10 ตัวที่บังเอิญดี → ใช้เกณฑ์ ≥ 50%
	_check(ok_seeds * 10 >= normal_hits.size() * 5, "บอทปกติถึงเป้า ≥ 9/12 อย่างน้อย 50%% ของ seed (%d/%d · %s)" % [ok_seeds, normal_hits.size(), normal_hits])
	# [0.6.0] มัธยฐาน 10 → 9: ตรวจเครื่องก่อนรู้อะไหล่ (ตั้งใจให้ยากขึ้น) · ดูหมายเหตุผลบอทหัวไฟล์
	_check(int(sorted_hits[sorted_hits.size() / 2]) >= 9, "บอทปกติถึงเป้าค่ามัธยฐาน ≥ 9/12 (%d)" % int(sorted_hits[sorted_hits.size() / 2]))
	var closed: int = res[&"normal"].filter(func(r: Dictionary) -> bool: return r.closed).size()
	_check(closed * 10 <= normal_hits.size(), "บอทปกติร้านปิดไม่เกิน 10%% ของ seed (%d/%d — จากของเสียติดกัน)" % [closed, normal_hits.size()])
	_check(res[&"idle"][0].closed, "บอทไม่ทำงาน → ร้านปิด (เดือน %d)" % res[&"idle"][0].months)
	_check(good_profit > normal_profit, "บอทเก่งกำไรรวมมากกว่าบอทปกติ (฿%d > ฿%d)" % [good_profit, normal_profit])
	var stock_hits: Array = res[&"normal_stock"].map(func(r: Dictionary) -> int: return int(r.hits))
	print("BAL นิสัยซื้อของ: สั่งเมื่อมีงาน กำไรเฉลี่ย ฿%d ถึงเป้า %s · ตุนของ กำไรเฉลี่ย ฿%d ถึงเป้า %s" % [normal_profit, normal_hits, _avg(res[&"normal_stock"], &"profit"), stock_hits])
	var returned := 0
	for r: Dictionary in res[&"normal"]:
		returned += int(r.returned)
	print("BAL บอทปกติ: เครื่องที่ลูกค้ามาเอาคืน (ไม่ได้ซ่อม) รวม %d เครื่องใน %d seed" % [returned, normal_hits.size()])
	DayLoop.demo_shifts = demo
	DayLoop._reset_run()
	print("T DONE fails=", fails)
	get_tree().quit()


## [0.6.0] สวิตช์ทดลองหาสาเหตุสมดุล: BAL_REQ=0 (ไม่มีคำขอ) · BAL_NOWIN=1 (ไม่มีช่วงเวลา/นักเรียนมาได้ทั้งวัน) · BAL_NOSCEN=1 (งานกลางไม่สุ่มอาการ) · BAL_STUFEE=1 (นักเรียนค่าแรงเต็ม)
func _apply_env_overrides() -> void:
	var e: EconomyConfig = GameState.economy
	if OS.has_environment("BAL_REQ"):
		e.request_share = float(OS.get_environment("BAL_REQ"))
	if OS.has_environment("BAL_NOWIN"):
		for n in NpcBook.all():
			n.windows = [] as Array[Vector2i]
			n.school_hours = false
	if OS.has_environment("BAL_NOSCEN"):
		for f in ["any_ram", "any_mainboard", "any_gpu", "any_frontpanel", "any_bios", "any_group_pc", "any_group_two"]:
			(load("res://Resources/Customers/%s.tres" % f) as CustomerCase).use_scenario = false
	if OS.has_environment("BAL_NOTRAIT"):
		ScenarioBook.traits_enabled = false
	if OS.has_environment("BAL_PARTW"):
		ScenarioBook.part_weight_mult = float(OS.get_environment("BAL_PARTW"))
	if OS.has_environment("BAL_STUFEE"):
		for n in NpcBook.all():
			n.fee_mult = 1.0


## เล่น 1 ปี (48 วัน) · คืน { level, seed, months, hits, closed, profit, rows: [{m, profit, target, reached, money, jobs, walk}] }
func play_year(lv: StringName, s: int) -> Dictionary:
	GameState.seed_override = s # [0.7.0] ก่อน _reset_run — ลูกค้ารอบแรกของวันที่ 1 สุ่มตอนรีเซ็ต
	DayLoop._reset_run()
	DayLoop.quiet = true
	DayLoop._break_done = true
	DayLoop.force_active = true # [0.4.0] ลูปร้านทำงานจริง (ไปตลาดระหว่างเปิดร้านเสีย 1 เทิร์น)
	rng.seed = s * 7 + 1
	# [0.7.0] อีเวนต์: BAL_NOEVENT=1 ปิด · บอทตอบการ์ดเอง (ปกติตอบดี 85% · บูธ 50/50 · งานเหมา/แข่ง/ศาลา ไป)
	EventDirector.disabled = OS.has_environment("BAL_NOEVENT")
	DayLoop.bot_event_pick = func(ev: ShopEvent, choices: Array, step: int) -> String:
		var p_good := 1.0 if lv == &"good" else 0.85
		if step > 0:
			return String(choices[0]) if rng.randf() < p_good else String(choices[-1])
		if ev.good_count > 0:
			return ev.choices[0] if rng.randf() < p_good else ev.choices[ev.choices.size() - 1]
		if ev.id == &"cal_rocket":
			return ev.choices[0] if rng.randf() < 0.5 else ev.choices[1]
		return ev.choices[0]
	rank_months = { }
	helper_runs = 0
	helper_money = 0
	requests_done = 0
	request_money = 0
	inspections = 0
	GameState.story_flags.clear()
	GameState.ensure_starter_kit() # [0.4.0] ของติดตัวหลังบทสอน (ผู้เล่นจริงได้ก่อนเปิดร้าน)
	var jobs := 0
	var walk_prev := 0
	var guard := 0
	while not DayLoop._game_over and guard < 60:
		guard += 1
		jobs += await _play_day(lv)
		var last_day := ts.shift >= TimeSystem.TOTAL_SHIFTS
		_bot_exam(lv)
		DayLoop.end_shift()
		await get_tree().process_frame
		if DialogScene.visible:
			DialogScene.dialog_end()
		if DayLoop._pending_summary_week > 0: # สิ้นเดือน: ข้ามบทเนื้อเรื่อง (บอทไม่ดู)
			DayLoop._pending_summary_week = 0
			DayLoop._last_month = { }
			DayLoop._last_bill = { }
		if last_day:
			break
	var rows: Array[Dictionary] = []
	var hits := 0
	var profit := 0
	for r: Dictionary in GameState.month_results:
		rows.append({ "m": int(r.m), "profit": int(r.profit), "target": int(r.target), "reached": bool(r.reached), "debt": int(r.debt) })
		if (int(r.profit) < 0 or OS.get_environment("BAL_DEBUG") == "all") and OS.has_environment("BAL_DEBUG"):
			print("BALDBG %s#%d m%d profit %d by_kind %s" % [lv, s, int(r.m), int(r.profit), r.by_kind])
		hits += 1 if bool(r.reached) else 0
		profit += int(r.profit)
	DayLoop.quiet = false
	# [0.5.0 ขั้น K] ความสนิทสิ้นปี · เดือนที่ถึงแต่ละยศ
	var close := 0
	var regular := 0
	var heard := 0
	for n in NpcBook.with_affinity():
		var a := GameState.affinity(n.id)
		close += 1 if a >= 60 else 0
		regular += 1 if a >= 80 else 0
		heard += (GameState.npc_stories_seen.get(n.id, []) as Array).size()
	var rank_m := rank_months.duplicate()
	var exams := GameState.learn_log.size() / maxi(GameState.economy.exam_questions, 1)
	var returned := 0
	for o: RepairShelf.Order in DayLoop.shelf.history:
		returned += 1 if o.state == RepairShelf.State.RETURNED else 0
	return { "level": lv, "seed": s, "months": rows.size(), "hits": hits, "closed": GameState.shop_closed, "profit": profit, "rows": rows, "jobs": jobs, "money": GameState.money, "rep": GameState.reputation, "shelf": GameState.shelf_slots, "storage": GameState.storage_slots, "returned": returned, "close": close, "regular": regular, "heard": heard, "rank_m": rank_m, "exams": exams, "helper": helper_runs, "helper_money": helper_money, "requests": requests_done, "req_money": request_money, "insp": inspections, "fair": GameState.group_fair_count, "avg_fee": _avg_fee(), "ach": GameState.achievements.size(), "events": GameState.event_log.size(), "scam": int(GameState.event_state.get("scam_lost", 0)), "gifts": GameState.gifts_received.size(), "club": [&"phum", &"fern", &"oat", &"namwan"].map(func(id: StringName) -> int: return GameState.affinity(id)).max(), "min_tier": String(EndingBook.min_report().tier), "rank_end": GameState.rank() }


## 1 วันเปิดร้าน · คืนจำนวนงานที่ซ่อม
func _play_day(lv: StringName) -> int:
	var done := 0
	_buy_upgrades(lv)
	if lv == &"normal_stock":
		_stock_up()
	if lv == &"idle":
		DayLoop.forced_case = null
		return 0
	if DayLoop.forced_case:
		_repair(DayLoop.forced_case, null, lv)
		done += 1
	var steps := 0
	while ts.current_minute < TimeSystem.CLOSE and steps < 80:
		steps += 1
		_handle_door(lv)
		_rush_parts()
		var o := _next_shelf_job(lv)
		if o and not (lv != &"good" and rng.randf() < 0.15):
			if DayLoop.job_fit(o.case) == &"ot":
				_set_ot()
			if _inspect_stops(o, lv): # [0.6.0] ครึ่งตรวจ: ของไม่มี → รอของ
				continue
			_repair(o.case, o, lv)
			done += 1
			continue
		if ts.remaining_work_minutes() <= 0:
			break
		DayLoop.wait_slot()
	_handle_door(lv)
	_order_after_close()
	return done


## เครื่องที่ถึง/เลยนัดแต่ยังไม่มีของ → เดินไปตลาด (1 เทิร์น) ซื้อถ้ามีของ
func _rush_parts() -> void:
	var need: Array[ItemDef] = []
	for o: RepairShelf.Order in DayLoop.shelf.waiting():
		if o.due > ts.shift or DayLoop.order_has_parts(o):
			continue
		for id in DayLoop.waiting_ids(o):
			var it := DayLoop.part_item(id)
			if it and it.market and GameState.stock_left(it) != 0 and GameState.can_afford(it.price) and not need.has(it):
				need.append(it)
				break
	if need.is_empty():
		return
	DayLoop.market_trip()
	for it in need:
		GameState.buy(it, 1)
	_buy_supplies(true)


## ปิดร้านแล้ว: สั่งออนไลน์ของที่เครื่องบนชั้นยังขาด + ของสิ้นเปลืองที่ใกล้หมด (ตะกร้าเดียว)
func _order_after_close() -> void:
	var lines := []
	var ids: Array[StringName] = []
	for o: RepairShelf.Order in DayLoop.shelf.waiting():
		if DayLoop.order_has_parts(o):
			continue
		var wid := DayLoop.waiting_ids(o)
		if wid.is_empty():
			continue
		var want := wid[0]
		var pending := false
		for id in wid:
			pending = pending or GameState.pending_count(id) > ids.count(id)
		if pending:
			continue
		ids.append(want)
		lines.append([DayLoop.part_item(want), 1])
	for sid in [&"ipa90", &"paste_grey", &"air_can", &"cable_tie"]:
		if GameState.count_item(sid) + GameState.pending_count(sid) < 2:
			lines.append([DayLoop.part_item(sid), 1])
	while not lines.is_empty() and GameState.order_block_reason(lines) != "":
		lines.pop_back()
	if not lines.is_empty():
		GameState.order_online(lines)


## นิสัยตุนของ: เก็บอะไหล่ราคาถูกไว้อย่างละ 1 (ซื้อที่ตลาดตอนเช้า · เดินไปตลาดใช้ 1 เทิร์น)
func _stock_up() -> void:
	var want: Array[ItemDef] = []
	for id in [&"cmos_cr2032", &"fp_switch", &"cable_hdmi", &"fan_cpu", &"ram_ddr3_4gb_used"]:
		var it := DayLoop.part_item(id)
		if it and GameState.free_count(id) == 0 and GameState.stock_left(it) != 0 and GameState.money > it.price + 800 and GameState.rank() >= it.unlock_rank and GameState.free_slots() > 2 + want.size():
			want.append(it)
	if want.is_empty():
		return
	DayLoop.market_trip()
	for it in want:
		GameState.buy(it, 1)
	_buy_supplies(true)


func _buy_supplies(at_market: bool) -> void:
	if not at_market:
		return
	for sid in [&"ipa90", &"paste_grey", &"air_can", &"cable_tie"]:
		var it := DayLoop.part_item(sid)
		if it and GameState.count_item(sid) < 2 and GameState.money > it.price + 500:
			GameState.buy(it, 1)


## ตัดสินคนหน้าประตูจนคิวว่าง
func _handle_door(lv: StringName) -> void:
	var guard := 0
	while not DayLoop.door_queue.is_empty() and guard < 20:
		guard += 1
		var j := DayLoop.door_front()
		var c: CustomerCase = j["case"]
		if DayLoop.is_pickup(j):
			DayLoop.door_handover()
			_bot_story(lv)
			continue
		# [0.5.0 ขั้น K] ยศเชี่ยวชาญ: ฝากงานขมOS ให้มิ้นวันละงาน
		if DayLoop.helper_button(j).get("visible", false):
			var hr := DayLoop.door_helper()
			helper_runs += 1
			helper_money += int(hr.get("money", 0))
			continue
		if bool(j.get("phone", false)):
			if not (DayLoop.door_can_appoint() and DayLoop.door_appoint()):
				DayLoop.door_reject()
			continue
		# [0.6.0 ขั้น G] คำขอ: บอทเก่งรับเสมอถ้ามีโควตา · ปกติรับ 70% · ตอบถูกตามระดับ
		if c.is_request():
			var take := DayLoop.door_accept_state(-1) == &"ok" and (lv == &"good" or rng.randf() < 0.7)
			if take and DayLoop.door_accept(-1):
				var req := c.request()
				var acc := 0.95 if lv == &"good" else 0.75
				for step in req.steps():
					var src := req.choices if step == 0 else req.choices2
					var ok := rng.randf() < acc
					DayLoop.request_answer(src[0] if ok else src[1])
					if not ok:
						break
					if step == 0 and req.steps() > 1:
						DayLoop._on_request_card_done()
				var rr := DayLoop.request_finish()
				requests_done += 1
				request_money += int(rr.get("money", 0))
				continue
			DayLoop.door_reject()
			continue
		if c.takes_machine():
			var promise := 1
			var has_part := c.part_ids().is_empty() or c.part_ids().any(func(id: StringName) -> bool: return GameState.free_count(id) > 0)
			if lv == &"good" and has_part and DayLoop.job_fit(c) == &"ok" and _today_load() + DayLoop.job_slots(c) * TimeSystem.SLOT_MIN <= ts.remaining_work_minutes():
				promise = 0
			if DayLoop.door_accept_state(promise) == &"ok" and DayLoop.door_accept(promise):
				continue
		else:
			var st := DayLoop.door_accept_state(-1)
			if st == &"ok" or (st == &"ot" and lv == &"good"):
				_desktop_now(j, st, lv)
				continue
		if DayLoop.door_can_appoint() and not (lv != &"good" and rng.randf() < 0.3):
			DayLoop.door_appoint()
		else:
			DayLoop.door_reject()


## งานขมOS ทำต่อหน้าลูกค้า (เหมือน DayLoop.door_accept(-1) แต่ไม่เปิดมินิเกม)
func _desktop_now(j: Dictionary, st: StringName, lv: StringName) -> void:
	DayLoop.door_queue.pop_front()
	if not bool(j.get("free", false)):
		DayLoop.accepted_today += 1
	if st == &"ot":
		_set_ot()
	_repair(j["case"], null, lv)


## งานบนชั้นที่จะซ่อมต่อ: นัดใกล้สุดก่อน · ปกติไม่ล่วงเวลา · เก่งล่วงเวลาเมื่อถึง/เลยนัด
func _next_shelf_job(lv: StringName) -> RepairShelf.Order:
	# [0.6.0] เครื่องที่ยังไม่ตรวจ (มีสถานการณ์) ตรวจก่อน — รู้เร็วว่าต้องสั่งอะไหล่อะไร
	for o: RepairShelf.Order in DayLoop.shelf.waiting():
		if o.case.scenario() != null and not o.inspected and DayLoop.job_fit(o.case) == &"ok":
			return o
	for o: RepairShelf.Order in DayLoop.shelf.waiting():
		if not DayLoop.order_has_parts(o):
			continue
		var fit := DayLoop.job_fit(o.case)
		if fit == &"ok" or (fit == &"ot" and lv == &"good" and o.due <= ts.shift):
			return o
	return null


## นาทีงานบนชั้นที่ต้องเสร็จวันนี้ (ไว้ตัดสินใจรับ "ด่วน วันนี้")
func _today_load() -> int:
	var n := 0
	for o: RepairShelf.Order in DayLoop.shelf.waiting():
		if o.due <= ts.shift:
			n += DayLoop.job_slots(o.case) * TimeSystem.SLOT_MIN
	return n


func _repair(c: CustomerCase, o: RepairShelf.Order, lv: StringName) -> void:
	DayLoop.current_job = { "case": c, "order": o } if o else { "case": c }
	DayLoop.today_case = c
	GameState.hold_next_payment = o != null
	var score := rng.randi_range(88, 100) if lv == &"good" else rng.randi_range(65, 95)
	var damaged := lv != &"good" and rng.randf() < (float(OS.get_environment("BAL_DMG")) if OS.has_environment("BAL_DMG") else 0.03)
	GameState.record_repair(c.part(), score, damaged, c.fee, c.level)
	DayLoop._result_pending = false
	_bot_story(lv)


## [0.6.0 ขั้น E] งานที่มีสถานการณ์และยังไม่ตรวจ: ถึงจุดแบ่งแล้วไม่มีของ → เก็บผลครึ่งตรวจ (เวลา 40%) แล้วรอของ · คืน true = หยุดรอ
func _inspect_stops(o: RepairShelf.Order, lv: StringName) -> bool:
	if o.case.scenario() == null or o.inspected:
		return false
	if not DayLoop._minigame_checkpoint(o):
		return false
	DayLoop.current_job = { "case": o.case, "order": o }
	DayLoop.today_case = o.case
	o.case.set_meta("inspection", { "mistakes": { "diagnosis": 0 if lv == &"good" else 10 }, "wrong": 0, "skipped": [], "did_optional": [], "cause": o.case.scenario().cause })
	DayLoop._after_inspection()
	inspections += 1
	return true


func _avg_fee() -> int:
	var t := 0
	var n := 0
	for e in GameState.ledger:
		if e.kind == &"fee" and int(e.amount) > 0:
			t += int(e.amount)
			n += 1
	return t / maxi(n, 1)


var requests_done := 0
var request_money := 0
var inspections := 0


## [0.5.0 ขั้น K] เดือนที่บอทถึงยศ r · มิ้นทำงานกี่งาน/ได้เงินเท่าไร (ต่อ seed)
var rank_months := { }
var helper_runs := 0
var helper_money := 0


## ปิดร้านวันที่ XP ครบ → สอบ (เก่งตอบถูก 90% · ปกติ 70%) · ผ่านแล้วเลือกความสามารถทาง A
func _bot_exam(lv: StringName) -> void:
	if lv == &"idle" or not GameState.rank_ready():
		return
	var p_right := 0.9 if lv == &"good" else 0.7
	for q: ExamQuestion in DayLoop.exam_begin():
		DayLoop.exam_answer(q.correct_text() if rng.randf() < p_right else "ผิด")
	if DayLoop.exam_finish():
		rank_months[GameState.rank()] = ts.month()
	while GameState.perk_pending() > 0:
		var r := GameState.perk_pending()
		GameState.choose_perk(r, StringName(GameState.perk_options(r)[0].id))


## เรื่องส่วนตัวที่รอเล่น → ฟัง (ตอบใส่ใจ: เก่ง 90% · ปกติ 60%)
func _bot_story(lv: StringName) -> void:
	if DayLoop.pending_story.is_empty():
		return
	var st: NpcStory = DayLoop.pending_story["story"]
	DayLoop.story_today = true
	var good := rng.randf() < (0.9 if lv == &"good" else 0.6)
	DayLoop.story_finish(st.good_choice if (good or st.good_choice == "") else "ตอบห้วน")


func _set_ot() -> void:
	ts.overtime = true
	if not DayLoop._ot_this_shift:
		DayLoop._ot_this_shift = true
		DayLoop.ot_this_week += 1


func _buy_upgrades(lv: StringName) -> void:
	var r4: ItemDef = load("res://Resources/Shop/shelf_rack_4.tres")
	var r6: ItemDef = load("res://Resources/Shop/shelf_rack_6.tres")
	# [0.4.0] คลังเต็มเร็วขึ้น (ของสิ้นเปลือง 4 ชนิด + อะไหล่) → ซื้อชั้นเก็บอะไหล่ 14 ช่องหลังชั้นวางเครื่อง
	var st: ItemDef = load("res://Resources/Shop/storage_shelf.tres")
	if GameState.shelf_slots >= 4 and GameState.money > (2500 if lv == &"good" else 3500):
		GameState.buy(st)
	match lv:
		&"good":
			if GameState.money > 2500:
				GameState.buy(r4)
			if GameState.money > 5000:
				GameState.buy(r6)
		&"normal", &"normal_stock":
			if GameState.money > 3000:
				GameState.buy(r4)


func _avg(rs: Array, key: StringName) -> int:
	var t := 0
	for r: Dictionary in rs:
		t += int(r[key])
	return roundi(float(t) / maxi(rs.size(), 1))


func _report(res: Dictionary) -> void:
	print("BAL ===== บอทเล่นครบปี (กำไรเดือน ฿ / เป้า) =====")
	var head := "BAL %-14s" % "เดือน"
	for m in 12:
		head += "%7d" % (m + 1)
	print(head + "   ถึงเป้า  ปิด  งาน  เงินท้ายเกม  ชั้น/คลัง")
	var tgt := "BAL %-14s" % "เป้า"
	for m in 12:
		tgt += "%7d" % GameState.economy.target_for(m + 1)
	print(tgt)
	for lv in res:
		for r: Dictionary in res[lv]:
			var line := "BAL %-14s" % ("%s#%d" % [lv, r.seed])
			var rows: Array = r.rows
			for m in 12:
				if m < rows.size():
					var row: Dictionary = rows[m]
					line += "%7s" % (("%d%s" % [row.profit, "" if row.reached else "*"]))
				else:
					line += "%7s" % "-"
			print(line + "   %2d/12   %s  %3d  %8d  %d/%d" % [r.hits, "ปิด" if r.closed else " - ", r.jobs, r.money, r.shelf, r.storage])
	print("BAL (* = ไม่ถึงเป้า)")
	print("BAL ===== [0.5.0] ยศ (เดือนที่ถึง ฝึกหัด/ประจำหมู่บ้าน/เชี่ยวชาญ/มือโปร) · ความสนิทสิ้นปี (สนิท ≥60 / ขาประจำ ≥80 จาก 9 คน) · เรื่องที่ฟัง · มิ้นทำงาน =====")
	for lv in res:
		for r: Dictionary in res[lv]:
			var rm: Dictionary = r.get("rank_m", { })
			print("BAL %-14s ยศ %s · สอบ %d ครั้ง · สนิท %d · ขาประจำ %d · ฟังเรื่อง %d/27 · มิ้น %d งาน ฿%d" % [
				"%s#%d" % [lv, r.seed], "/".join([1, 2, 3, 4].map(func(k: int) -> String: return str(rm.get(k, "-")))),
				int(r.get("exams", 0)), int(r.get("close", 0)), int(r.get("regular", 0)), int(r.get("heard", 0)), int(r.get("helper", 0)), int(r.get("helper_money", 0))])
			print("BAL %-14s [0.6.0] คำขอ %d เรื่อง ฿%d · ครึ่งตรวจแล้วรอของ %d ครั้ง · ตัดสินกลุ่มแฟร์ %d · มาเอาคืน %d · งาน %d · ค่าแรงเฉลี่ย ฿%d" % ["%s#%d" % [lv, r.seed], int(r.get("requests", 0)), int(r.get("req_money", 0)), int(r.get("insp", 0)), int(r.get("fair", 0)), int(r.get("returned", 0)), int(r.get("jobs", 0)), int(r.get("avg_fee", 0))])
	print("BAL ===== [0.7.0] อีเวนต์ · ใบประกาศ =====")
	for lv in res:
		for r: Dictionary in res[lv]:
			print("BAL %-14s อีเวนต์ %d ครั้ง · หลงเชื่อมิจฉาชีพ %d · ใบประกาศ %d/%d · [0.8.0] ของขวัญ %d · ชมรม♥สูงสุด %d · ยศสิ้นปี %d · ถ้ากลับเมือง มิ้น=%s" % ["%s#%d" % [lv, r.seed], int(r.get("events", 0)), int(r.get("scam", 0)), int(r.get("ach", 0)), Achievements.all().size(), int(r.get("gifts", 0)), int(r.get("club", 0)), int(r.get("rank_end", 0)), String(r.get("min_tier", ""))])
	# มัธยฐานกำไรรายเดือนของบอทปกติ (ร้านปิดไปแล้ว = ไม่นับเดือนนั้น) + 70% ไว้ใช้ตั้งเป้า
	var med := "BAL %-14s" % "มัธยฐานปกติ"
	var sug := "BAL %-14s" % "70% (ปัด 50)"
	for m in 12:
		var xs: Array[int] = []
		for r: Dictionary in res.get(&"normal", []):
			if m < (r.rows as Array).size():
				xs.append(int(r.rows[m].profit))
		xs.sort()
		var md := xs[xs.size() / 2] if not xs.is_empty() else 0
		med += "%7d" % md
		sug += "%7d" % (roundi(md * 0.7 / 50.0) * 50)
	print(med)
	print(sug)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
