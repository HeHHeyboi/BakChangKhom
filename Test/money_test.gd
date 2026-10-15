extends Node
## [0.2.0-C · 15 ต.ค. 2569] บันทึกรายรับ–รายจ่าย (GameState.ledger) — Docs/ROADMAP_1_0_0.md ข้อ 8.1 C
## เปิด Test/money_test.tscn → F6 → "T DONE fails=0"
## เช็ก: ทุกการเปลี่ยนเงินถูกจดตามหมวด · ผลรวม ledger = เงินที่เปลี่ยนจริง · กำไรบทไม่นับลงทุน · บิลจดเข้าบทที่จ่าย · เพดานเงิน · เซฟ/โหลด

var fails := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	Global.on_start = false
	var ts: TimeSystem = EventManager.time_system
	GameState.reset()
	_check(GameState.ledger.is_empty(), "เริ่มใหม่ ledger ว่าง")
	ts.set_shift(2) # บท 1 วันที่ 2
	GameState.money = 10000 # ตั้งตรง ๆ = ไม่จด (ใช้เป็นฐานเทียบ)
	var m0 := GameState.money

	# ---- งานซ่อม: แยกค่าแรง / ทิป / ชดใช้
	var r := GameState.record_repair(&"part_ram", 100, false, -1, 1) # Lv1 ⭐⭐⭐ = ค่าแรง 60 + ทิป 20
	var by := GameState.chapter_by_kind(1)
	_check(int(r.money) == 80 and int(by.get(&"fee", 0)) == 60 and int(by.get(&"tip", 0)) == 20, "ซ่อม ⭐⭐⭐ → ค่าแรง 60 + ทิป 20 (เงินรวม %d)" % r.money)
	GameState.record_repair(&"part_ram", 70, false, -1, 2) # ผ่านแบบมีจุดพลาด = ค่าแรง 150 ไม่มีทิป
	GameState.record_repair(&"part_gpu", 30, true, -1, 3) # ทำของเสีย = ชดใช้
	by = GameState.chapter_by_kind(1)
	var dmg := -int(GameState.economy.damage_penalty.get(&"part_gpu", GameState.economy.default_penalty))
	_check(int(by.get(&"fee", 0)) == 210 and int(by.get(&"damage", 0)) == dmg, "ค่าแรงรวม 210 · ชดใช้การ์ดจอ %d" % dmg)
	var e0: Dictionary = GameState.ledger[0]
	_check(int(e0.ch) == 1 and int(e0.day) == 2 and e0.kind == &"fee" and String(e0.note) == "part_ram", "รายการจดบท/วัน/หมวด/หมายเหตุ (%s)" % e0)

	# ---- ซื้อของ: ของสิ้นเปลือง/อะไหล่ = ซื้อของ · ชั้นคลัง = ลงทุน
	var ipa: ItemDef = load("res://Resources/Shop/ipa90.tres")
	var ram: ItemDef = load("res://Resources/Shop/ram_ddr3_4gb_used.tres")
	var shelf: ItemDef = load("res://Resources/Shop/storage_shelf.tres")
	_check(GameState.buy(ipa) == "" and GameState.buy(ram) == "" and GameState.buy(shelf) == "", "ซื้อ IPA · แรมมือสอง · ชั้นเหล็ก ได้")
	by = GameState.chapter_by_kind(1)
	_check(int(by.get(&"buy", 0)) == -(ipa.price + ram.price) and int(by.get(&"invest", 0)) == -shelf.price, "ซื้อของ −%d · ลงทุน −%d" % [ipa.price + ram.price, shelf.price])
	var idx := -1
	for i in GameState.inventory.size():
		if GameState.inventory[i].id == ram.id:
			idx = i
	var got := GameState.sell_back(idx)
	_check(got == roundi(ram.price * 0.5) and int(GameState.chapter_by_kind(1).get(&"sell", 0)) == got, "ขายแรมมือสองคืน 50%% = %d → หมวดขายของคืน" % got)

	# ---- ค่าไฟล่วงเวลา · หมวดแปลก → อื่น ๆ
	GameState.add_money(-60, &"ot_power", "ล่วงเวลา 2 เทิร์น")
	GameState.add_money(-5, &"ไม่มีหมวดนี้")
	_check(GameState.ledger.back().kind == &"other", "หมวดที่ไม่รู้จัก → อื่น ๆ")

	# ---- บิล: จ่ายหลัง TimeSystem ขึ้นบท 2 แล้ว ต้องจดเข้าบท 1
	ts.set_shift(21) # ขึ้นเดือน ก.พ. แล้ว
	var bill := GameState.pay_month_bill(1, 10)
	_check(int(GameState.chapter_by_kind(4).get(&"bill", 0)) == -int(bill.paid) and GameState.month_entries(2).is_empty(), "บิล ม.ค. (จ่ายตอนขึ้น ก.พ.) จดเข้าบท 4 = เดือน ม.ค. · ก.พ. ยังว่าง")
	_check(GameState.month_of(1) == 1 and GameState.month_of(4) == 1 and GameState.month_of(5) == 2 and GameState.month_of(12) == 3, "บท 1–4 = ม.ค. · 5 = ก.พ. · 12 = มี.ค.")

	# ---- ผลรวม = เงินที่เปลี่ยนจริง · กำไรไม่นับลงทุน
	var total := 0
	for e in GameState.ledger:
		total += int(e.amount)
	_check(total == GameState.money - m0, "ผลรวม ledger = เงินที่เปลี่ยนจริง (%d)" % total)
	var inc := GameState.month_income(1)
	var ex := GameState.month_expense(1)
	var inv := GameState.month_invest(1)
	_check(inc == 60 + 20 + 150 + got and inv == shelf.price, "รายรับบท 1 = %d · ลงทุน = %d" % [inc, inv])
	_check(ex == -dmg + ipa.price + ram.price + 60 + 5 + int(bill.paid), "รายจ่ายบท 1 = %d (ไม่รวมลงทุน)" % ex)
	_check(GameState.month_profit(1) == inc - ex and GameState.month_profit(1) - inv == total, "กำไรเดือน = รายรับ − รายจ่าย (%d) · กำไร − ลงทุน = เงินที่เปลี่ยน" % GameState.month_profit(1))

	# ---- เพดานเงิน: จดเฉพาะส่วนที่เข้ากระเป๋าจริง
	GameState.money = GameState.MONEY_CAP - 10
	GameState.add_money(100, &"fee", "เพดาน")
	_check(GameState.money == GameState.MONEY_CAP and int(GameState.ledger.back().amount) == 10, "ชนเพดาน ฿50,000 → จดแค่ 10")

	# ---- เซฟ/โหลด ledger
	SaveGame.allow_in_tests = true
	var backup := FileAccess.get_file_as_string(SaveGame.PATH) if SaveGame.exists() else ""
	var n := GameState.ledger.size()
	var last: Dictionary = GameState.ledger[2].duplicate()
	_check(SaveGame.save(), "บันทึกได้")
	GameState.reset()
	SaveGame.load_into()
	_check(GameState.ledger.size() == n and GameState.ledger[2].kind == last.kind and int(GameState.ledger[2].amount) == int(last.amount) and GameState.ledger[2].kind is StringName, "โหลด → ledger ครบ %d รายการ หมวดเป็น StringName" % n)

	# ---- [0.2.0-D] แถบเป้าเดือน (Scene/UI/month_goal_bar.tscn ใน DayLoop/GoalLayer)
	var bar: MonthGoalBar = DayLoop.goal_bar
	_check(bar != null and bar.get_parent().name == "GoalLayer" and (bar.get_parent() as CanvasLayer).layer == 100, "แถบเป้าอยู่ใน day_loop.tscn → GoalLayer ชั้น 100")
	_check(DayLoop._day_skip != null and DayLoop._day_skip.get_parent().name == "DaySkipLayer" and (DayLoop._day_skip.get_parent() as CanvasLayer).layer == 110, "ข้ามวันอยู่ใน day_loop.tscn → DaySkipLayer ชั้น 110")
	_check(GameState.economy.target_for(1) == 2000 and GameState.economy.target_for(3) == 10000, "เป้า ม.ค. = ฿2,000 · มี.ค. = ฿10,000")
	GameState.reset()
	ts.set_shift(2)
	GameState.record_repair(&"part_ram", 100, false, -1, 1) # +80
	bar.refresh()
	_check(bar._title.text == "เป้า ม.ค." and bar._value.text.begins_with("฿80/฿2,000") and bar._value.text.contains("เหลือ 18 วัน") and is_equal_approx(bar._bar.value, 0.04), "แถบเป้า: %s · %.2f" % [bar._value.text, bar._bar.value])
	GameState.buy(load("res://Resources/Shop/storage_shelf.tres"))
	bar.refresh()
	_check(bar._value.text.begins_with("฿80/"), "ซื้อชั้นเหล็ก (ลงทุน) ไม่ทำให้กำไรในแถบลด")
	ts.set_shift(10) # บท 2 (สัปดาห์ 2) ยังเป็น ม.ค. → กำไรรวมทั้งเดือน
	GameState.add_money(1950, &"fee", "test")
	bar.refresh()
	_check(bar._value.text.begins_with("฿2,030/") and bar._value.text.contains("ถึงเป้าแล้ว") and bar._fill.bg_color == bar.reached_color, "กำไรรวม 2 สัปดาห์ ฿2,030 ≥ ฿2,000 → ถึงเป้าแล้ว (แถบเขียว)")
	GameState.add_money(-2300, &"buy", "test")
	bar.refresh()
	_check(bar._value.text.begins_with("−฿270/") and is_zero_approx(bar._bar.value), "ขาดทุน → แสดง −฿270 แถบว่าง")
	ts.set_shift(21)
	bar.refresh()
	_check(bar._title.text == "เป้า ก.พ." and bar._value.text.begins_with("฿0/฿7,000"), "ขึ้นบท 5 = ก.พ. → เป้า ฿7,000 เริ่มจาก 0")

	# ---- [0.2.0-E/F] ปิดเดือน: เป้า · ค่าปรับ · พลาดเป้า · ร้านปิด
	GameState.reset()
	GameState.help_mode = false
	ts.set_shift(1)
	GameState.add_money(500, &"fee", "test")
	var r1 := GameState.close_month(1)
	_check(not r1.reached and not r1.counted and not r1.strike and GameState.missed_months == 0, "ม.ค. ไม่ถึงเป้าแต่เดือนแรกยังไม่นับ")
	_check(String(r1.hint) != "" and r1.target == 2000 and r1.profit == 500, "รายงานเดือน: กำไร ฿500 / เป้า ฿2,000 · ปิ๊บ: %s" % r1.hint)
	ts.set_shift(21)
	GameState.add_money(300, &"fee", "test")
	var r2 := GameState.close_month(2)
	_check(r2.strike and GameState.missed_months == 1 and not GameState.shop_closed, "ก.พ. ไม่ถึงเป้า → พลาด 1/2 ร้านยังเปิด")
	GameState.money = 100
	GameState.debt = 0
	var bill := GameState.pay_month_bill(2, 0)
	_check(bill.late_fee == 0 and GameState.debt > 0, "บิลเกินเงิน → ค้าง ฿%d (ยังไม่มีค่าปรับ)" % GameState.debt)
	var d0 := GameState.debt
	GameState.money = 0
	var bill2 := GameState.pay_month_bill(3, 0)
	_check(bill2.late_fee == ceili(d0 * 0.1) and bill2.prev_debt == d0, "เดือนต่อไปค่าปรับ 10%% ของยอดค้าง = ฿%d" % bill2.late_fee)
	GameState.help_mode = true
	_check(GameState.target_of(3) == 7000 and GameState.pay_month_bill(3, 0).late_fee == 0, "โหมดช่วย: เป้า ×0.7 (฿7,000) · ไม่มีค่าปรับ")
	GameState.help_mode = false
	ts.set_shift(41)
	var r3 := GameState.close_month(3)
	_check(r3.strike and GameState.missed_months == 2 and GameState.shop_closed and GameState.decide_ending() == &"failure", "พลาดเป้า 2 เดือน → ร้านปิด → ฉากจบล้มเหลว")
	_check(GameState.month_results.size() == 3, "เก็บผล 3 เดือนไว้ใน month_results")
	GameState.reset()
	_check(not GameState.shop_closed and GameState.missed_months == 0 and GameState.month_results.is_empty(), "reset() ล้างผลสิ้นเดือน")
	# ถึงเป้า → ชื่อเสียงเพิ่ม · ไม่นับพลาด
	ts.set_shift(21)
	var rep0 := GameState.reputation
	GameState.add_money(9500, &"fee", "test")
	var r4 := GameState.close_month(2)
	_check(r4.reached and r4.over and not r4.strike and GameState.reputation > rep0, "ก.พ. ฿9,500 ≥ ฿7,000×1.3 → เกินเป้า · ชื่อเสียง +%d" % (GameState.reputation - rep0))
	# ข้อความสรุปเดือนในการ์ด
	var txt := DayLoop.month_summary_text(r4, { })
	_check(txt.contains("เกินเป้า") and txt.contains("฿9,500"), "การ์ดสรุปเดือนมีกำไรและผลเป้า")
	# ค้างบิล 2 เดือนติด → ร้านปิด
	GameState.reset()
	ts.set_shift(21)
	GameState.add_money(9000, &"fee", "test")
	GameState.debt = 50
	GameState.close_month(2)
	GameState.debt = 50
	var r5 := GameState.close_month(3)
	_check(GameState.debt_streak == 2 and r5.shop_closed, "ค้างบิล 2 เดือนติด → ร้านปิด")
	if backup != "":
		var f := FileAccess.open(SaveGame.PATH, FileAccess.WRITE)
		f.store_string(backup)
	else:
		SaveGame.clear()
	GameState.reset()
	ts.set_shift(1)
	print("T DONE fails=", fails)
	get_tree().quit()


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
