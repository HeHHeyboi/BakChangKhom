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
##   สั่งเมื่อมีงาน กำไรเฉลี่ย ฿24,197 · ตุนของ ฿21,107 (เงินจม + เดินไปตลาดบ่อย) · เก่ง ฿31,391
## เปิด Test/balance_test.tscn → F6 → Output มีตารางรายเดือน + "T DONE fails=0" (ใช้เวลา ~1 นาที)

const SEEDS := [11, 22, 33, 44, 55]
## บอทปกติเล่นหลาย seed กว่า (ใช้หาค่ามัธยฐานไว้ตั้งเป้า)
const NORMAL_SEEDS := [11, 22, 33, 44, 55, 66, 77, 88, 99, 111]

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
	for lv in [&"good", &"normal", &"normal_stock", &"idle"]:
		res[lv] = []
		for s in (NORMAL_SEEDS if lv in [&"normal", &"normal_stock"] else (SEEDS if lv == &"good" else [SEEDS[0]])):
			res[lv].append(await play_year(lv, s))
	_report(res)
	var normal_hits: Array = res[&"normal"].map(func(r: Dictionary) -> int: return int(r.hits))
	var good_profit := _avg(res[&"good"], &"profit")
	var normal_profit := _avg(res[&"normal"], &"profit")
	# บอทปกติทำของลูกค้าเสีย 3% ของงาน · การ์ดจอเสีย = ชดใช้ ฿2,500 (มากกว่ากำไรทั้งเดือน) → บาง seed พลาดติดกันจนร้านปิดได้
	var ok_seeds: int = normal_hits.filter(func(h: int) -> bool: return h >= 9).size()
	var sorted_hits: Array = normal_hits.duplicate()
	sorted_hits.sort()
	# ไม่มีของเสีย (BAL_DMG=0) บอทปกติได้ 11–12/12 ทุก seed — ที่พลาดมาจากค่าชดใช้ของเสียเป็นหลัก
	_check(ok_seeds * 10 >= normal_hits.size() * 7, "บอทปกติถึงเป้า ≥ 9/12 อย่างน้อย 70%% ของ seed (%d/%d · %s)" % [ok_seeds, normal_hits.size(), normal_hits])
	_check(int(sorted_hits[sorted_hits.size() / 2]) >= 10, "บอทปกติถึงเป้าค่ามัธยฐาน ≥ 10/12 (%d)" % int(sorted_hits[sorted_hits.size() / 2]))
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


## เล่น 1 ปี (48 วัน) · คืน { level, seed, months, hits, closed, profit, rows: [{m, profit, target, reached, money, jobs, walk}] }
func play_year(lv: StringName, s: int) -> Dictionary:
	DayLoop._rng.seed = s # ก่อน _reset_run — ลูกค้ารอบแรกของวันที่ 1 สุ่มตอนรีเซ็ต
	DayLoop._reset_run()
	DayLoop.quiet = true
	DayLoop._break_done = true
	DayLoop.force_active = true # [0.4.0] ลูปร้านทำงานจริง (ไปตลาดระหว่างเปิดร้านเสีย 1 เทิร์น)
	rng.seed = s * 7 + 1
	GameState.story_flags.clear()
	GameState.ensure_starter_kit() # [0.4.0] ของติดตัวหลังบทสอน (ผู้เล่นจริงได้ก่อนเปิดร้าน)
	var jobs := 0
	var walk_prev := 0
	var guard := 0
	while not DayLoop._game_over and guard < 60:
		guard += 1
		jobs += await _play_day(lv)
		var last_day := ts.shift >= TimeSystem.TOTAL_SHIFTS
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
	var returned := 0
	for o: RepairShelf.Order in DayLoop.shelf.history:
		returned += 1 if o.state == RepairShelf.State.RETURNED else 0
	return { "level": lv, "seed": s, "months": rows.size(), "hits": hits, "closed": GameState.shop_closed, "profit": profit, "rows": rows, "jobs": jobs, "money": GameState.money, "rep": GameState.reputation, "shelf": GameState.shelf_slots, "storage": GameState.storage_slots, "returned": returned }


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
			continue
		if bool(j.get("phone", false)):
			if not (DayLoop.door_can_appoint() and DayLoop.door_appoint()):
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
	# มัธยฐานกำไรรายเดือนของบอทปกติ (ร้านปิดไปแล้ว = ไม่นับเดือนนั้น) + 70% ไว้ใช้ตั้งเป้า
	var med := "BAL %-14s" % "มัธยฐานปกติ"
	var sug := "BAL %-14s" % "70% (ปัด 50)"
	for m in 12:
		var xs: Array[int] = []
		for r: Dictionary in res[&"normal"]:
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
