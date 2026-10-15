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
	ts.set_shift(6)
	var bill := GameState.pay_month_bill(1, 10)
	_check(int(GameState.chapter_by_kind(1).get(&"bill", 0)) == -int(bill.paid) and GameState.chapter_entries(2).is_empty(), "บิลบท 1 (จ่ายตอนขึ้นบท 2) จดเข้าบท 1 · บท 2 ยังว่าง")

	# ---- ผลรวม = เงินที่เปลี่ยนจริง · กำไรไม่นับลงทุน
	var total := 0
	for e in GameState.ledger:
		total += int(e.amount)
	_check(total == GameState.money - m0, "ผลรวม ledger = เงินที่เปลี่ยนจริง (%d)" % total)
	var inc := GameState.chapter_income(1)
	var ex := GameState.chapter_expense(1)
	var inv := GameState.chapter_invest(1)
	_check(inc == 60 + 20 + 150 + got and inv == shelf.price, "รายรับบท 1 = %d · ลงทุน = %d" % [inc, inv])
	_check(ex == -dmg + ipa.price + ram.price + 60 + 5 + int(bill.paid), "รายจ่ายบท 1 = %d (ไม่รวมลงทุน)" % ex)
	_check(GameState.chapter_profit(1) == inc - ex and GameState.chapter_profit(1) - inv == total, "กำไร = รายรับ − รายจ่าย (%d) · กำไร − ลงทุน = เงินที่เปลี่ยน" % GameState.chapter_profit(1))

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
