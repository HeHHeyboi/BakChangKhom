extends Node
## [Claude 14 พ.ย. 2569 · 0.3.0 ขั้น B] ทดสอบลูกค้าหน้าประตูใน DayLoop (PLAN_0_3_0 ข้อ 2)
## คิวทีละคน · โควตา 3 คน/วัน · รับเครื่อง/นัดวันถัดไป/ปฏิเสธ · โทรเข้า = นัดอย่างเดียว · ความอดทน (2 · ผู้สูงอายุ 3 · รีบ 1) · คนนัดมาก่อน · ปิดร้าน = กลับบ้าน
## เปิด Test/door_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0
var ts: TimeSystem
var e: EconomyConfig


func _ready() -> void:
	await get_tree().process_frame
	ts = EventManager.time_system
	e = GameState.economy
	DayLoop.day_skip_seconds = 0.0
	DayLoop._reset_run()
	var hw: Array[CustomerCase] = []
	for n in ["lv2_teacher_ram", "lv2_yai_ram", "lv2_headman_ram", "lv2_coworker_ram", "lv2_kid_keyboard", "lv2_teacher_monitor"]:
		hw.append(load("res://Resources/Customers/%s.tres" % n))
	var os_case: CustomerCase = load("res://Resources/Customers/lv1_amnuay_startup.tres")
	_check(e.daily_cap == 3 and e.door_patience_slots == 2 and e.rep_door_walkout == -1, "ค่าเริ่ม: รับได้ 3 คน/วัน · รอได้ 2 เทิร์น · เดินกลับ −1")
	_check(hw[0].takes_machine() and not os_case.takes_machine(), "งานฮาร์ดแวร์ต้องรับเครื่อง · งานขมOS ทำต่อหน้าลูกค้า")
	_check(DayLoop.shelf != null and DayLoop.shelf.slots == e.shelf_slots_start, "DayLoop มีชั้นวาง %d ช่อง" % e.shelf_slots_start)
	_check(DayLoop.door_queue.size() == 3 and DayLoop.accepted_today == 0 and DayLoop.forced_case != null, "เปิดร้านกะ 1: ลูกค้ายืนหน้าประตู 3 คน (รอบ 08:30) · ลุงอำนวยงานเนื้อเรื่อง")

	# ---------------- A · ระหว่างงานเนื้อเรื่องบังคับ ความอดทนไม่เดิน
	ts.set_clock(11 * 60)
	_check(DayLoop.door_queue.size() == 4 and DayLoop.walkouts.is_empty(), "งานเนื้อเรื่องค้าง 08:30 → 11:00 ไม่มีใครเดินกลับ (+รอบ 11:00 = 4 คน)")
	DayLoop.forced_case = null
	_reset_door(9 * 60)

	# ---------------- B · โควตา 3 คน · รับเครื่องขึ้นชั้น
	DayLoop.shelf.slots = 6
	for i in 5:
		DayLoop.door_queue.append(DayLoop.door_entry(hw[i]))
	_check(DayLoop.door_front().case == hw[0] and DayLoop.quota_left() == 3, "คนแรกยืนหน้าประตู · วันนี้รับได้อีก 3")
	await _show_door()
	_check(_btn("Accept").text == "รับเครื่อง" and not _btn("Accept").disabled and not _btn("Appoint").disabled and DayLoop._board_note.text.contains("วันนี้รับเครื่องแล้ว 0/3"), "การ์ดหน้าประตู: ปุ่มรับเครื่อง/นัด/ปฏิเสธ · ตัวนับ 0/3")
	_check(DayLoop._board_list.get_child_count() == 2 and _all_text(DayLoop._board_list).contains("รอคิวอีก 4 คน"), "เห็นจำนวนคนที่รอคิว")
	for i in 3:
		_check(DayLoop.door_accept_state(1) == &"ok" and DayLoop.door_accept(1), "รับเครื่องคนที่ %d → ใบรับเครื่อง (นัดวันถัดไป)" % (i + 1))
		await _end_dialog()
	_check(DayLoop.accepted_today == 3 and DayLoop.shelf.used() == 3 and DayLoop.shelf.orders[0].case == hw[0] and DayLoop.shelf.orders[0].due == ts.shift + 1, "รับครบ 3 คน · เครื่องขึ้นชั้น 3 เครื่อง · นัดวันที่ %d" % (ts.shift + 1))
	_check(DayLoop.door_accept_state(1) == &"full" and not DayLoop.door_accept(1) and DayLoop.door_queue.size() == 2, "ครบโควตา → รับคนที่ 4 ไม่ได้")
	await _show_door()
	_check(_btn("Accept").disabled and _btn("Accept").text == "วันนี้คิวเต็ม" and not _btn("Appoint").disabled and DayLoop._board_note.text.contains("วันนี้คิวเต็ม"), "การ์ด: \"วันนี้คิวเต็ม\" เหลือปุ่มนัด/ปฏิเสธ")
	# งานเนื้อเรื่อง/เอาเครื่องมาลองใหม่ (free) ไม่นับโควตา
	DayLoop.door_queue.push_front(DayLoop.door_entry(hw[5], false, false, true))
	_check(DayLoop.door_accept_state(1) == &"ok" and DayLoop.door_accept(1) and DayLoop.accepted_today == 3, "งานเนื้อเรื่อง (free) รับได้แม้คิวเต็ม · ไม่นับโควตา")
	await _end_dialog()
	DayLoop.shelf.slots = DayLoop.shelf.used()
	DayLoop.accepted_today = 0
	_check(DayLoop.door_accept_state(1) == &"shelf_full" and not DayLoop.door_accept(1), "ชั้นเต็ม → รับงานฮาร์ดแวร์ขึ้นชั้นไม่ได้")
	DayLoop.accepted_today = 3

	# ---------------- C · นัดวันเปิดร้านถัดไป · ปฏิเสธ · โทรเข้า
	var rep := GameState.reputation
	var who: CustomerCase = DayLoop.door_front().case
	_check(DayLoop.door_appoint() and DayLoop.appointments.size() == 1 and DayLoop.appointments[0].case == who and GameState.reputation == rep and DayLoop.accepted_today == 3, "นัดวันเปิดร้านถัดไป → ไม่หักชื่อเสียง ไม่กินโควตา")
	DayLoop.door_queue.push_front(DayLoop.door_entry(hw[1], true))
	_check(DayLoop.door_accept_state() == &"phone" and DayLoop.door_accept_state(1) == &"phone" and not DayLoop.door_accept(), "โทรเข้า → รับเครื่องไม่ได้ (ยังไม่มีเครื่อง)")
	await _show_door()
	_check(not _btn("Accept").visible and not _btn("Appoint").disabled and _all_text(DayLoop._board_list).contains("โทรมาขอนัด"), "การ์ดโทรเข้า: เหลือปุ่มนัด/ปฏิเสธ")
	_check(DayLoop.door_appoint() and DayLoop.appointments.size() == 2, "โทรเข้า → นัดเอาเครื่องมาวันถัดไป")
	var n_before := DayLoop.door_queue.size()
	_check(DayLoop.door_reject() and DayLoop.door_queue.size() == n_before - 1 and GameState.reputation == rep + e.rep_reject, "ปฏิเสธ → ชื่อเสียง %d" % e.rep_reject)
	_check(not DayLoop.door_appoint() and not DayLoop.door_reject() and DayLoop.door_front().is_empty(), "ไม่มีคนหน้าประตู → กดอะไรไม่ได้")

	# ---------------- D · ปิดร้าน: คนที่ยังยืนอยู่กลับบ้าน · วันถัดไปคนนัดมาเป็นคิวแรก
	DayLoop.door_queue.append(DayLoop.door_entry(hw[2]))
	await _show_card(DayLoop.Card.SHIFT_END)
	_check(DayLoop._body.text.contains("ลูกค้าหน้าร้าน 1 คนยังไม่ได้คุย") and DayLoop._body.text.contains("นัดไว้วันเปิดร้านถัดไป 2 คน"), "การ์ดปิดร้านบอกคนที่จะกลับบ้าน + คนที่นัดไว้ (%s)" % DayLoop._body.text.replace("\n", " | "))
	rep = GameState.reputation
	ts.end_shift()
	await _frames(2)
	DayLoop.forced_case = null
	_check(ts.shift == 2 and DayLoop.left_home.size() == 1 and GameState.reputation == rep + e.rep_left_unserved and DayLoop.accepted_today == 0, "กะ 2: คนที่ไม่ได้คุยกลับบ้าน ชื่อเสียง %d · โควตาเริ่มใหม่" % e.rep_left_unserved)
	_check(DayLoop.appointments.is_empty() and DayLoop.door_queue.size() >= 2 and DayLoop.door_queue[0].case == who and DayLoop.door_queue[0].appointed and DayLoop.door_queue[1].case == hw[1] and DayLoop.door_queue[1].appointed and not DayLoop.door_queue[1].phone, "คนนัด 2 คนยืนหน้าประตูเป็นคิวแรก (คนโทรมาเอาเครื่องมาแล้ว)")
	_check(not DayLoop.door_can_appoint(), "คนที่นัดไว้แล้วเลื่อนอีกไม่ได้")
	await _show_door()
	_check(_btn("Appoint").disabled and _all_text(DayLoop._board_list).contains("นัดไว้"), "การ์ดบอกว่านัดไว้ · ปุ่มนัดกดไม่ได้")
	DayLoop.shelf.slots = 6
	_check(DayLoop.door_accept(1) and DayLoop.accepted_today == 1, "รับเครื่องคนที่นัดไว้ → นับโควตาของวันนี้ (1/3)")
	await _end_dialog()

	# ---------------- E · ความอดทน: ปกติ 2 · ผู้สูงอายุ 3 · รีบ 1 · ไม่นับพักเที่ยง
	_reset_door(9 * 60)
	var normal: CustomerCase = hw[3]
	var elder: CustomerCase = hw[4].duplicate()
	elder.patience = 3
	var rush: CustomerCase = hw[5].duplicate()
	rush.customer = "คนรีบ"
	rush.patience = 1
	DayLoop.door_queue.append(DayLoop.door_entry(normal))
	DayLoop.door_queue.append(DayLoop.door_entry(elder))
	DayLoop.door_queue.append(DayLoop.door_entry(rush))
	_check(DayLoop.door_patience_left(DayLoop.door_queue[0]) == 2 and DayLoop.door_patience_left(DayLoop.door_queue[1]) == 3 and DayLoop.door_patience_left(DayLoop.door_queue[2]) == 1, "รอได้ 2 / 3 / 1 เทิร์น")
	rep = GameState.reputation
	ts.set_clock(9 * 60 + 30)
	_check(DayLoop.door_queue.size() == 2 and DayLoop.walkouts == PackedStringArray(["คนรีบ"]) and GameState.reputation == rep + e.rep_door_walkout, "1 เทิร์น → คนรีบเดินกลับ ชื่อเสียง %d" % e.rep_door_walkout)
	_check(DayLoop.door_patience_left(DayLoop.door_queue[0]) == 1, "คนปกติรอได้อีก 1 เทิร์น")
	ts.set_clock(10 * 60)
	_check(DayLoop.door_queue.size() == 1 and DayLoop.door_front().case == elder, "2 เทิร์น → คนปกติเดินกลับ · ผู้สูงอายุยังรอ")
	ts.set_clock(9 * 60) # เวลาถอยหลัง (Debug) ไม่นับ
	_check(DayLoop.door_queue.size() == 1, "เวลาถอยหลังไม่นับความอดทน")
	ts.set_clock(9 * 60 + 30)
	_check(DayLoop.door_queue.is_empty() and DayLoop.walkouts.size() == 3 and GameState.reputation == rep + 3 * e.rep_door_walkout, "เดินต่อ 1 เทิร์น → ผู้สูงอายุครบ 3 เทิร์น เดินกลับ (รวม 3 คน)")
	await _show_door()
	_check(DayLoop._board_note.text.contains("รอนานเกินจนเดินกลับ"), "การ์ดบอกคนที่เดินกลับ")
	_reset_door(11 * 60 + 30)
	DayLoop.door_queue.append(DayLoop.door_entry(normal))
	ts.set_clock(13 * 60)
	_check(DayLoop.door_queue.size() == 1 and DayLoop.door_patience_left(DayLoop.door_queue[0]) == 1, "11:30 → 13:00 (พักเที่ยง) นับแค่ 1 เทิร์น")
	ts.set_clock(13 * 60 + 30)
	_check(DayLoop.door_queue.is_empty(), "13:30 ครบ 2 เทิร์น → เดินกลับ")

	# ---------------- F · รอบที่มาระหว่างผู้เล่นทำงาน (รอไปแล้วบางส่วน แต่ได้ยืนให้เห็นอย่างน้อย 1 เทิร์น)
	_reset_door(10 * 60 + 30)
	DayLoop.visitor_waves = [{ "minute": 11 * 60, "count": 1 }] as Array[Dictionary]
	ts.set_clock(13 * 60 + 30)
	_check(DayLoop.door_queue.size() == 1 and DayLoop.door_patience_left(DayLoop.door_queue[0]) == 1, "รอบ 11:00 มาถึงตอน 13:30 → ยังยืนรอ เหลือ 1 เทิร์น")

	# ---------------- G · สุ่มลูกค้าไม่ซ้ำคนที่อยู่ในร้าน (หน้าประตู · นัด · บนชั้น)
	_reset_door(9 * 60)
	DayLoop.add_visitors(20)
	var busy := DayLoop.shelf.orders.map(func(o: RepairShelf.Order) -> CustomerCase: return o.case)
	_check(DayLoop.door_queue.size() == e.board_max and DayLoop.door_queue.all(func(j: Dictionary) -> bool: return not busy.has(j.case)), "คิวยาวสุด %d คน · ไม่สุ่มเคสที่เครื่องอยู่บนชั้น" % e.board_max)

	# ---------------- H · วันสุดท้ายของเกมนัดไม่ได้
	ts.set_shift(TimeSystem.TOTAL_SHIFTS)
	_reset_door(9 * 60)
	DayLoop.door_queue.append(DayLoop.door_entry(hw[0]))
	_check(not DayLoop.door_can_appoint(), "วันสุดท้ายของเกม → นัดวันถัดไปไม่ได้")

	DayLoop._reset_run()
	print("T DONE fails=", fails)
	get_tree().quit()


## ล้างหน้าประตู + ตั้งนาฬิกา (นับความอดทนจากเวลานี้)
func _reset_door(minute: int) -> void:
	DayLoop.forced_case = null
	DayLoop.door_queue.clear()
	DayLoop.visitor_waves.clear()
	DayLoop.walkouts.clear()
	ts.set_clock(minute)


func _show_door() -> void:
	await _show_card(DayLoop.Card.DOOR)


func _show_card(card: DayLoop.Card) -> void:
	DayLoop._show_card(card)
	await _frames(1)


func _btn(n: String) -> Button:
	return DayLoop._board_list.find_child(n, true, false) as Button


## บทลูกค้าตอนรับเครื่อง → ปิด
func _end_dialog() -> void:
	await _frames(2)
	if DialogScene.visible:
		DialogScene.dialog_end()
	await _frames(3)
	_check(not DayLoop._working, "จบบทลูกค้า → กลับมาที่หน้าประตู")


func _all_text(n: Node) -> String:
	var t := ""
	if n is Label:
		t += (n as Label).text
	for ch in n.get_children():
		t += _all_text(ch)
	return t


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
