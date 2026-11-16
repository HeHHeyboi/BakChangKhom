extends Node
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น A] seed รายวัน — seed เดิม + วันเดิม = ลูกค้า/สถานการณ์/รถขายของเดิม · โหลดเซฟแล้วได้ผลเดิม · กดเรื่องอื่นไม่เลื่อนผล
## เปิด Test/daily_seed_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var ts: TimeSystem


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	GameState.seed_override = 4242
	DayLoop._reset_run()
	_check(GameState.run_seed == 4242, "seed_override → run_seed")
	ts.shift = 6
	ts.set_clock(600)
	var a := _snap()
	var b := _snap()
	if a != b: print(a, "\n", b)
	_check(a == b and a.size() > 0, "seed เดิม วันเดิม = ผลเดิม (%d รายการ)" % a.size())

	# กดเรื่องอื่น (อีเวนต์ · ความเห็นกลุ่ม · ลูกมือ) ก่อน → ลูกค้าไม่เปลี่ยน
	DayLoop.reseed_day()
	for k in 7:
		DayLoop.rng(&"event").randf()
		DayLoop.rng(&"debate").randi()
		DayLoop.rng(&"helper").randf()
	_check(_snap(false) == a, "สุ่มเรื่องอื่นก่อน ไม่เลื่อนลูกค้า/สถานการณ์")

	ts.shift = 7
	var c := _snap()
	_check(c != a, "วันถัดไปได้ผลต่าง")
	ts.shift = 6
	GameState.run_seed = 99
	DayLoop.reseed_day()
	_check(_snap() != a, "seed ต่างได้ผลต่าง")

	# เซฟ → เล่นต่อ (สุ่มไปเรื่อย ๆ) → โหลด → ได้ผลเดิม
	GameState.run_seed = 4242
	DayLoop.reseed_day()
	DayLoop.door_queue.clear()
	SaveGame.allow_in_tests = true
	_check(SaveGame.save(), "เซฟได้")
	for k in 20:
		DayLoop.rng(&"visitors").randf()
		DayLoop.rng(&"scenario").randf()
	GameState.run_seed = 1
	SaveGame.load_into()
	_check(GameState.run_seed == 4242, "โหลดเซฟได้ run_seed เดิม")
	ts.shift = 6
	_check(_snap(false) == a, "หลังโหลดเซฟ ลูกค้า/สถานการณ์/รถขายของเหมือนก่อนเซฟ")
	GameState.seed_override = 0
	GameState.reset()
	_check(GameState.run_seed != 4242 or GameState.run_seed > 0, "เกมใหม่สุ่ม run_seed")
	DayLoop.door_queue.clear()
	print("T DONE fails=%d" % fails)
	get_tree().quit()


## ลูกค้า 4 คน (ref ที่มีสถานการณ์/เครื่อง) + รถขายของ ของวันนี้
func _snap(reseed := true) -> Array:
	if reseed:
		DayLoop.reseed_day()
	DayLoop.door_queue.clear()
	DayLoop._recent.clear()
	DayLoop.scenario_recent.clear()
	DayLoop._recent_requests.clear()
	DayLoop.requests_spawned_today = 0
	var last := GameState.npc_last_visit.duplicate()
	DayLoop.add_visitors(4, false, 0, 600)
	GameState.npc_last_visit = last
	var out: Array = []
	for j in DayLoop.door_queue:
		out.append(JSON.stringify(CustomerCase.to_ref(j["case"])))
	DayLoop._plan_vendor(ts)
	out.append(JSON.stringify(DayLoop.vendor.get("items", [])))
	DayLoop.door_queue.clear()
	return out


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
