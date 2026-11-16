extends Node
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น I] ร้านออนไลน์ลดราคา/ร้านปลอม + บัญชีดำ (PLAN_0_7_0 ข้อ 4)
## เปิด Test/fake_shop_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	var ts: TimeSystem = EventManager.time_system
	var e: EconomyConfig = GameState.economy
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	GameState.seed_override = 5
	DayLoop._reset_run()
	DayLoop.quiet = true
	GameState.money = 5000
	ts.shift = 14 # เม.ย.
	DayLoop.reseed_day()

	var fakes := DayLoop.sellers().filter(func(s: OnlineSeller) -> bool: return s.fake)
	var reals := DayLoop.sellers().filter(func(s: OnlineSeller) -> bool: return not s.fake)
	_check(fakes.size() >= 3 and reals.size() >= 2, "ร้านปลอม %d · ร้านจริง %d" % [fakes.size(), reals.size()])
	_check(fakes.all(func(s: OnlineSeller) -> bool: return s.signs.size() >= 3 and s.discount >= 0.5) and reals.all(func(s: OnlineSeller) -> bool: return s.discount < 0.3), "ร้านปลอมมีสัญญาณเตือน ≥ 3 · ลดแรงกว่าร้านจริง")

	# วันที่มีอีเวนต์ลดแรง = ร้านปลอมแน่
	DayLoop.fake_sale_today = true
	DayLoop._plan_deals(ts)
	_check(DayLoop.deals_today.size() == 1 and DayLoop.seller_by_id(StringName(DayLoop.deals_today[0].seller)).fake, "อีเวนต์ลดแรง → ร้านปลอมขึ้นในแอป")
	var d0: Dictionary = DayLoop.deals_today.duplicate(true)[0]
	DayLoop.reseed_day()
	DayLoop._plan_deals(ts)
	_check(DayLoop.deals_today[0].seller == d0.seller and DayLoop.deals_today[0].item == d0.item, "seed เดิมได้ร้าน/ของเดิม")

	# ซื้อร้านปลอม → เงินหาย · ของไม่มา · บัญชีดำ · ซื้อซ้ำไม่ได้
	var m0 := GameState.money
	var pend0 := GameState.pending_orders.size()
	var r := DayLoop.deal_buy(0)
	var sid := String(DayLoop.deals_today[0].seller)
	_check(bool(r.ok) and bool(r.fake) and GameState.money == m0 - int(d0.price) and GameState.pending_orders.size() == pend0, "ซื้อร้านปลอม: เสีย ฿%d ของไม่มา" % int(d0.price))
	_check(GameState.seller_blacklist.has(sid) and GameState.ledger.back().kind == &"scam", "ร้านขึ้นบัญชีดำ · ledger หมวดโดนโกง")
	_check(not bool(DayLoop.deal_buy(0).ok), "ซื้อซ้ำไม่ได้")
	# วันหลังร้านเดิมโผล่มาอีก → ขึ้นบัญชีดำ ซื้อไม่ได้
	DayLoop.deals_today = [{ "seller": sid, "item": d0.item, "price": d0.price, "done": "" }]
	var v: Array = DayLoop.deals_view()
	_check(bool(v[0].blacklisted) and not bool(v[0].can_buy), "ร้านในบัญชีดำโผล่มาอีก = ซื้อไม่ได้")

	# รายงานร้านปลอมอีกร้าน → บัญชีดำ + นับ · รายงานร้านจริง → ไม่ขึ้นบัญชีดำ
	var other: OnlineSeller = fakes.filter(func(s: OnlineSeller) -> bool: return String(s.id) != sid)[0]
	DayLoop.deals_today = [{ "seller": String(other.id), "item": d0.item, "price": 10, "done": "" }, { "seller": String(reals[0].id), "item": d0.item, "price": 300, "done": "" }]
	var rr := DayLoop.deal_report(0)
	_check(bool(rr.fake) and GameState.seller_blacklist.has(String(other.id)) and int(GameState.event_state.get("fake_reported", 0)) == 1, "รายงานร้านปลอม = บัญชีดำ + นับดูออก")
	var rr2 := DayLoop.deal_report(1)
	_check(not bool(rr2.fake) and not GameState.seller_blacklist.has(String(reals[0].id)) and String(DayLoop.deals_today[1].done) == "", "รายงานร้านจริง = ปิ๊บบอกว่าน่าเชื่อถือ (ยังซื้อได้)")
	m0 = GameState.money
	var rb := DayLoop.deal_buy(1)
	_check(bool(rb.ok) and not bool(rb.fake) and GameState.money == m0 - 300 and GameState.pending_orders.back().cost == 300, "ซื้อร้านจริง: ของมาวันถัดไปราคาลด")

	# เปิดแอป: ขึ้นการ์ดร้าน
	var app: Node = load("res://Scene/UI/online_shop_app.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	app.refresh(true)
	_check(app.find_child("Deal_0", true, false) != null and app.find_child("Deal_1", true, false) != null, "แอปร้านออนไลน์ขึ้นการ์ดร้านลดราคา")
	app.queue_free()

	# สุ่มทั้งปี: มีดีลราว deal_chance · ร้านปลอมมากกว่าครึ่ง
	DayLoop.fake_sale_today = false
	var days := 0
	var fk := 0
	for sh in range(5, 49):
		ts.shift = sh
		DayLoop.reseed_day()
		DayLoop._plan_deals(ts)
		if not DayLoop.deals_today.is_empty():
			days += 1
			if DayLoop.seller_by_id(StringName(DayLoop.deals_today[0].seller)).fake:
				fk += 1
	_check(days >= 4 and days <= 22, "ดีลทั้งปี %d วัน" % days)
	_check(fk >= 1, "มีร้านปลอม %d วัน" % fk)

	DayLoop.deals_today.clear()
	DayLoop.quiet = false
	GameState.seed_override = 0
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
