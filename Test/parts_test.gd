extends Node
## [Claude 15 พ.ย. 2569 · 0.4.0 ขั้น A] ทดสอบอะไหล่ผูกกับงาน + ร้านออนไลน์ + สต็อกตลาดรอบ 2 สัปดาห์ — ข้อมูลล้วน (GameState)
## เปิด Test/parts_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	var gs := GameState
	var ts: TimeSystem = EventManager.time_system
	var e: EconomyConfig = gs.economy
	gs.reset()
	ts.shift = 1
	var ram: ItemDef = load("res://Resources/Shop/ram_ddr4_8gb_used.tres")
	var ram_new: ItemDef = load("res://Resources/Shop/ram_ddr4_8gb_new.tres")
	var ipa: ItemDef = load("res://Resources/Shop/ipa90.tres")
	var tie: ItemDef = load("res://Resources/Shop/cable_tie.tres")
	var rack: ItemDef = load("res://Resources/Shop/storage_shelf.tres")
	gs.money = 10000

	# A · ซื้อในตลาด → ราคาที่จ่ายติดไปกับชิ้น
	_check(gs.buy(ram, 1) == "" and gs.count_item(ram.id) == 1, "ซื้อแรมมือสองในตลาด 1 ชิ้น")
	_check(int(gs.inventory[0].cost) == ram.price, "จำราคาที่จ่าย ฿%d" % ram.price)
	_check(gs.give_item(ram.id, 1, false) and int(gs.inventory[1].cost) == 0, "ของได้ฟรี (give_item) ราคาทุน 0")

	# B · จอง / ปลด / ใช้
	var i := gs.reserve([ram.id], "job1")
	_check(i >= 0 and String(gs.inventory[i].reserved_for) == "job1", "จองแรมให้งาน job1")
	_check(gs.reserve([ram.id], "job1") == i, "จองซ้ำงานเดิม = ชิ้นเดิม ไม่จองเพิ่ม")
	var j := gs.reserve([ram.id], "job2")
	_check(j >= 0 and j != i, "งาน job2 ได้อีกชิ้น")
	_check(gs.reserve([ram.id], "job3") == -1 and gs.free_count(ram.id) == 0, "ของหมด job3 จองไม่ได้")
	_check(not gs.take_item(ram.id) and gs.sell_back(i) == -1, "ของที่จองไว้ หยิบ/ขายไม่ได้")
	_check(gs.reserve([ram_new.id, ram.id], "job3") == -1, "ของแทน (มือสอง) ก็จองหมดแล้ว")
	gs.release("job2")
	_check(gs.free_count(ram.id) == 1 and gs.reserved_index("job2") == -1, "ปลดจอง job2 → ชิ้นกลับเป็นของว่าง")
	_check(gs.reserve([ram_new.id, ram.id], "job3") >= 0, "job3 ไม่มีของใหม่ → ใช้มือสองแทนได้ (part_alternatives)")
	var used := gs.consume_reserved("job1")
	_check(used.get("item") == ram and int(used.cost) == ram.price and gs.count_item(ram.id) == 1, "ซ่อมผ่าน job1 → ใช้ชิ้นที่ซื้อ ฿%d ออกจากคลัง" % ram.price)
	_check(gs.consume_reserved("job1").is_empty(), "ใช้แล้วใช้ซ้ำไม่ได้")
	gs.release("job3")

	# C · ค่าอะไหล่ตามยศ 2 / 2.5 / 5 / 10 %
	var want := [0.02, 0.025, 0.05, 0.10, 0.10]
	var ok := true
	for r in e.rank_xp.size():
		gs.set_rank(r)
		ok = ok and gs.rank() == r and is_equal_approx(e.part_markup(r), want[r])
	_check(ok, "ค่าบวกอะไหล่ตามยศ: มือใหม่ 2% · ฝึกหัด 2.5% · ประจำหมู่บ้าน 5% · เชี่ยวชาญ/มือโปร 10%")
	gs.xp = 0
	gs.rank_level = 0
	_check(gs.part_charge(450) == 459 and gs.part_charge(30) == 31 and gs.part_charge(0) == 0, "มือใหม่: ฿450 → ฿459 · ฿30 → ฿31 (ปัดขึ้น) · ของฟรีไม่เก็บ")
	gs.set_rank(1)
	_check(gs.part_charge(200) == 205, "ฝึกหัด: ฿200 → ฿205")
	gs.set_rank(3)
	_check(gs.part_charge(450) == 495 and gs.part_charge(900) == 990, "เชี่ยวชาญ: ฿450 → ฿495 · ฿900 → ฿990")
	gs.xp = 0
	gs.rank_level = 0

	# D · ของสิ้นเปลือง
	gs.buy(ipa, 1)
	_check(gs.count_item(ipa.id) == ipa.uses and gs.has_supplies({ ipa.id: 2 }), "IPA %d ครั้ง พอใช้ 2 ครั้ง" % ipa.uses)
	var miss := gs.use_supplies({ ipa.id: 2, tie.id: 1 })
	_check(gs.count_item(ipa.id) == ipa.uses - 2 and miss.size() == 1 and int(miss[tie.id]) == 1, "หัก IPA 2 · เคเบิลไทไม่มี → รายงานว่าขาด")
	miss = gs.use_supplies({ ipa.id: 99 })
	_check(gs.count_item(ipa.id) == 0 and int(miss[ipa.id]) == 99 - (ipa.uses - 2), "ขาดบางส่วน → หักที่เหลือจนหมด")

	# E · สั่งออนไลน์: จ่ายทันที (ของ + ค่าส่ง) · จองช่อง · มาถึงวันเปิดร้านถัดไป
	gs.reset()
	ts.shift = 3
	gs.money = 2000
	_check(ipa.online_cost() == ipa.price and ram.online_cost() < ram.price, "ไม่ตั้งราคาออนไลน์ = ราคาตลาด · แรมออนไลน์ถูกกว่าตลาด")
	var lines := [[ram, 2], [ipa, 1]]
	var total := ram.online_cost() * 2 + ipa.online_cost() + e.online_ship_fee
	_check(gs.order_total(lines) == total, "ราคาตะกร้า = ของ + ค่าส่ง ฿%d" % e.online_ship_fee)
	_check(gs.order_online(lines) == "" and gs.money == 2000 - total, "สั่งได้ จ่ายทันที ฿%d" % total)
	_check(gs.used_slots() == 3 and gs.inventory.is_empty() and gs.pending_count(ram.id) == 2, "ยังไม่มา แต่จองช่องคลัง 3 ช่องแล้ว")
	_check(gs.inventory_value() == ram.online_cost() * 2 + ipa.online_cost(), "มูลค่าคลังนับของที่รอส่งด้วย")
	_check(gs.deliver_orders(3).is_empty(), "วันเดียวกัน ของยังไม่มา")
	var got := gs.deliver_orders(4)
	_check(got.size() == 2 and gs.count_item(ram.id) == 2 and gs.count_item(ipa.id) == ipa.uses and gs.pending_orders.is_empty(), "เปิดร้านวันถัดไป → พัสดุเข้าคลัง")
	_check(gs.used_slots() == 3 and int(gs.inventory[0].cost) == ram.online_cost(), "ช่องเท่าเดิม · ราคาทุนติดชิ้น")
	gs.money = 10
	_check(gs.order_block_reason([[ram, 1]]) == "เงินไม่พอ", "เงินไม่พอ สั่งไม่ได้")
	gs.money = 99999
	_check(gs.order_block_reason([[ram, 6]]).begins_with("คลังเต็ม"), "ช่องไม่พอ (เหลือ 5) สั่ง 6 ชิ้นไม่ได้")
	_check(gs.order_block_reason([[rack, 1]]) != "", "อัปเกรดคลังไม่ขายออนไลน์")
	_check(gs.order_block_reason([]) != "", "ตะกร้าว่าง สั่งไม่ได้")

	# F · สต็อกตลาดรีทุก 2 วันเปิดร้าน (วันที่ 4 · 18)
	_check(GameState.restock_period(1, 2) == 1 and GameState.restock_period(2, 2) == 1 and GameState.restock_period(3, 2) == 2 and GameState.restock_period(5, 2) == 3, "รอบสต็อก: วันที่ 4–11 รอบ 1 · 18–25 รอบ 2 · เดือนถัดไปรอบ 3")
	gs.reset()
	gs.money = 99999
	ts.shift = 1
	var stock := ram.weekly_stock
	_check(stock > 0 and gs.buy(ram, stock) == "" and gs.stock_left(ram) == 0, "วันที่ 4 ซื้อหมดสต็อก (%d ชิ้น)" % stock)
	_check(gs.buy_block_reason(ram) == "ของหมด (มาใหม่วันที่ 18)", "ข้อความ: ของหมด (มาใหม่วันที่ 18)")
	ts.shift = 2
	_check(gs.stock_left(ram) == 0, "วันที่ 11 (รอบเดิม) ยังหมด")
	ts.shift = 3
	_check(gs.stock_left(ram) == stock, "วันที่ 18 ตลาดเติมของแล้ว")
	gs.buy(ram, stock)
	ts.shift = 4
	_check(gs.buy_block_reason(ram) == "ของหมด (มาใหม่เดือนหน้า)", "วันที่ 25 หมด → มาใหม่เดือนหน้า")
	ts.shift = 5
	_check(gs.stock_left(ram) == stock, "เดือนถัดไปวันที่ 4 เติมแล้ว")

	# G · เซฟ/โหลด (ผ่าน JSON เหมือนไฟล์จริง)
	gs.reset()
	ts.shift = 6
	gs.money = 5000
	gs.buy(ram, 1)
	gs.reserve([ram.id], "jobS")
	gs.order_online([[ram_new, 1]])
	var data: Dictionary = JSON.parse_string(JSON.stringify({ "items": gs.inventory, "pending": gs.pending_orders }))
	_check(int(data.items[0].cost) == ram.price and String(data.items[0].reserved_for) == "jobS" and int(data.pending[0].arrive) == 7, "ข้อมูลเซฟมี ราคาทุน · จอง · พัสดุ (มาถึงวันที่ 7)")

	# H · [ขั้น B] เคสที่ต้องใช้อะไหล่ในคลังงานสุ่ม
	var bad := PackedStringArray()
	var month_ok := true
	var month_line := PackedStringArray()
	for m in range(1, 13):
		var hw := 0
		var need := 0
		for c: CustomerCase in DayLoop.random_pool:
			if c.forced or not c.in_month(m) or not c.takes_machine():
				continue
			hw += 1
			if c.needs_part != &"":
				need += 1
		month_line.append("%d:%d/%d" % [m, need, hw])
		month_ok = month_ok and need >= 2 and need <= roundi(hw * 0.4)
	for c: CustomerCase in DayLoop.random_pool:
		for id in c.part_ids():
			var it := load("res://Resources/Shop/%s.tres" % id) as ItemDef
			if it == null or it.kind != ItemDef.Kind.PART or not it.online:
				bad.append("%s→%s" % [c.id, id])
		if c.needs_part != &"" and c.part_hint.strip_edges() == "":
			bad.append("%s ไม่มี part_hint" % c.id)
		if not c.takes_machine() and c.needs_part != &"":
			bad.append("%s งานขมOS ใช้อะไหล่ไม่ได้" % c.id)
	_check(bad.is_empty(), "อะไหล่ของทุกเคสมีจริง · มีคำใบ้ · ไม่มีงานขมOS ใช้อะไหล่ %s" % str(bad))
	_check(month_ok, "ทุกเดือนมีงานต้องใช้อะไหล่ ≥ 2 และไม่เกิน 40%% ของงานฮาร์ดแวร์ (%s)" % " ".join(month_line))
	var mb_need := (load("res://Resources/Customers/lv3_min_mainboard.tres") as CustomerCase).supply_need(e)
	_check(int(mb_need.get(&"ipa90", 0)) == 1 and int(mb_need.get(&"paste_grey", 0)) == 1, "งานเมนบอร์ดใช้ IPA 1 + ซิลิโคน 1 (ค่าตาม Part)")
	var gpu_rep := 0
	for f in DirAccess.get_files_at("res://Resources/Shop/"):
		var it := load("res://Resources/Shop/" + f.trim_suffix(".remap")) as ItemDef
		if it and it.replaces == &"part_gpu":
			gpu_rep += 1
			_check(not it.market and it.online_cost() < it.price, "การ์ดจอมือสองชดใช้: ออนไลน์อย่างเดียว ฿%d" % it.online_cost())
	_check(gpu_rep == 1, "มีของชดใช้การ์ดจอ 1 ชิ้น")

	gs.reset()
	ts.shift = 1
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  ok  ", msg)
	else:
		fails += 1
		print("  FAIL ", msg)
