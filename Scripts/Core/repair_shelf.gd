class_name RepairShelf extends RefCounted
## [Claude 14 พ.ย. 2569 · 0.3.0 ขั้น A] ใบรับเครื่อง + ชั้นวางเครื่อง — ข้อมูลล้วน ไม่มี UI (PLAN_0_3_0 ข้อ 3)
## งานฮาร์ดแวร์: รับเครื่อง → วางบนชั้น (WAITING) → ซ่อมเมื่อพร้อม (DONE เก็บผลไว้) → ลูกค้ามารับตามนัด → จ่ายค่าแรง
## "วัน" ในไฟล์นี้ = วันเปิดร้าน (shift ของ TimeSystem · 1 shift = 1 วันเปิดร้าน)
##   นัดวันที่ due · มารับวัน d:
##     d <= due            → ทันนัด  (ความพอใจ + on_time_sat_bonus)
##     due < d <= due+grace → ช้า (late) วันละ −late_sat_per_day · ค่าแรงลดวันละ late_pay_cut_per_day
##     d > due+grace แต่ยังไม่ซ่อม → ลูกค้ามาเอาคืนตามสภาพ (RETURNED) ชื่อเสียง rep_returned
## ซ่อมเสร็จวันที่ >= วันนัด → ลูกค้ามารับในวันนั้นเลย (pickup ทันทีหลัง finish)

enum State { WAITING, DONE, PICKED, RETURNED }

## ใบรับเครื่อง 1 ใบ
class Order extends RefCounted:
	var case: CustomerCase
	## วันที่รับเครื่อง (shift)
	var accepted: int
	## วันนัดรับ (shift)
	var due: int
	## index ของ EconomyConfig.promise_days ที่เลือก (ค่าแรงคูณ)
	var promise: int = 1
	var state: int = State.WAITING
	## ผลซ่อม {score, damaged, gave_up} — เก็บไว้จนลูกค้ามารับ
	var result: Dictionary = { }
	## วันที่ลูกค้ามารับ/มาเอาคืน (-1 = ยัง)
	var closed_on: int = -1
	## [0.3.0] เลื่อนนัดไปแล้ว (เลื่อนได้ครั้งเดียว)
	var postponed := false
	## [0.3.0] ความพอใจที่บวก/ลบเพิ่มตอนมารับ (เลื่อนนัด − · โทรเรียกมารับก่อน +)
	var sat_adjust := 0
	## [0.4.0] รหัสใบรับเครื่อง (ไม่ซ้ำ) — ใช้จองอะไหล่ในคลัง (GameState.reserve(ids, key))
	var key := ""
	## [0.4.0] ทำของลูกค้าเสีย → ต้องหาอะไหล่ชิ้นนี้มาชดใช้ก่อนซ่อมใหม่ (จองด้วย replace_key()) · ว่าง = ไม่มี
	var replace_part: StringName

	func late_days(day: int) -> int:
		return maxi(day - due, 0)

	## [0.6.0 ขั้น E] ตรวจแล้ว (ครึ่งแรกของมินิเกม) — งานที่มีสถานการณ์ซ่อมรู้อะไหล่หลังตรวจเท่านั้น
	var inspected := false
	## ผลครึ่งตรวจที่เก็บไว้เล่นต่อ { mistakes, wrong, skipped, did_optional } · ว่าง = ยังไม่ได้แบ่ง
	var partial: Dictionary = { }

	## [0.4.0] อะไหล่ที่งานนี้ต้องใช้ (ตามเคส) — จองด้วย key · [0.6.0] งานมีสถานการณ์ = ว่างจนกว่าจะตรวจ
	func part_ids() -> Array[StringName]:
		if case == null or (case.scenario() != null and not inspected):
			return [] as Array[StringName]
		return case.part_ids()

	func replace_key() -> String:
		return key + "!r"

	func to_dict() -> Dictionary:
		return {
			"case": CustomerCase.to_ref(case), # [0.6.0] งานกลาง = { path · npc · device }
			"accepted": accepted, "due": due, "promise": promise,
			"state": state, "result": result, "closed_on": closed_on,
			"postponed": postponed, "sat_adjust": sat_adjust,
			"key": key, "replace_part": String(replace_part),
			"inspected": inspected, "partial": partial,
		}

	static func from_dict(d: Dictionary) -> Order:
		var c := CustomerCase.from_ref(d.get("case", ""))
		if c == null:
			return null
		var o := Order.new()
		o.case = c
		o.accepted = int(d.get("accepted", 0))
		o.due = int(d.get("due", 0))
		o.promise = int(d.get("promise", 1))
		o.state = int(d.get("state", State.WAITING))
		o.result = d.get("result", { })
		o.closed_on = int(d.get("closed_on", -1))
		o.postponed = bool(d.get("postponed", false))
		o.sat_adjust = int(d.get("sat_adjust", 0))
		o.key = String(d.get("key", ""))
		o.replace_part = StringName(d.get("replace_part", ""))
		o.inspected = bool(d.get("inspected", false))
		o.partial = d.get("partial", { }) if d.get("partial") is Dictionary else { }
		return o


var econ: EconomyConfig
## จำนวนช่องบนชั้น (อัปเกรดได้)
var slots := 2
## ใบที่ยังอยู่บนชั้น (WAITING/DONE) — ใบที่ปิดแล้วย้ายไป history
var orders: Array[Order] = []
## ใบที่ปิดแล้ว (PICKED/RETURNED) ล่าสุดก่อน · ไว้ทำสรุปเดือน/ข้อความข้ามวัน
var history: Array[Order] = []
## [0.4.0] ตัวนับรหัสใบรับเครื่อง (Order.key = "wo<n>")
var next_key := 1


func _init(e: EconomyConfig = null) -> void:
	econ = e if e else EconomyConfig.new()
	slots = econ.shelf_slots_start


func used() -> int:
	return orders.size()


func is_full() -> bool:
	return orders.size() >= slots


## ตัวเลือกวันนัด: [{index, days, due, name, mult}] — "ด่วน วันนี้" ซ่อนถ้าวันนี้ไม่มีเวลาพอ (allow_today = false)
func promise_options(today: int, allow_today := true) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in econ.promise_days.size():
		var d: int = econ.promise_days[i]
		if d == 0 and not allow_today:
			continue
		out.append({
			"index": i, "days": d, "due": today + d,
			"name": econ.promise_names[i] if i < econ.promise_names.size() else "อีก %d วัน" % d,
			"mult": econ.promise_mult(i),
		})
	return out


## รับเครื่องขึ้นชั้น · ชั้นเต็ม → null
func add(c: CustomerCase, today: int, promise_index := 1) -> Order:
	if is_full() or c == null:
		return null
	var o := Order.new()
	o.case = c
	o.accepted = today
	o.promise = clampi(promise_index, 0, maxi(econ.promise_days.size() - 1, 0))
	o.due = today + (econ.promise_days[o.promise] if econ.promise_days.size() > 0 else 1)
	o.key = _new_key()
	orders.append(o)
	return o


func _new_key() -> String:
	var k := "wo%d" % next_key
	next_key += 1
	return k


## งานที่ยังไม่ซ่อม เรียงวันนัดใกล้สุดก่อน
func waiting() -> Array[Order]:
	var out: Array[Order] = []
	for o in orders:
		if o.state == State.WAITING:
			out.append(o)
	out.sort_custom(func(a: Order, b: Order) -> bool: return a.due < b.due)
	return out


## ซ่อมเสร็จ (เก็บผล) · ถ้าวันนี้ถึง/เลยวันนัด ลูกค้ามารับเลย → คืนผลจ่ายเงิน (ดู pickup) ไม่งั้นคืน {}
func finish(o: Order, result: Dictionary, today: int) -> Dictionary:
	if o == null or not orders.has(o) or o.state != State.WAITING:
		return { }
	o.state = State.DONE
	o.result = result
	if today >= o.due:
		return pickup(o, today)
	return { }


## ลูกค้ามารับเครื่องที่ซ่อมเสร็จแล้ว → {order, late, mult, sat_delta, on_time}
## mult = ค่าแรงคูณ (วันนัด × ช้า) — ผู้เรียกเอาไปคูณค่าแรงตอนจ่ายจริง (GameState.record_repair fee_override)
func pickup(o: Order, today: int) -> Dictionary:
	if o == null or o.state != State.DONE:
		return { }
	var late := o.late_days(today)
	var mult := econ.promise_mult(o.promise) * maxf(1.0 - late * econ.late_pay_cut_per_day, 0.0)
	var late_sat := econ.late_sat_per_day / (2 if GameState.has_perk(&"punctual") else 1) # [0.5.0] นัดแม่น
	var sat := (econ.on_time_sat_bonus if late == 0 else -late * late_sat) + o.sat_adjust
	o.state = State.PICKED
	o.closed_on = today
	_close(o)
	return { "order": o, "late": late, "mult": mult, "sat_delta": sat, "on_time": late == 0 }


## [0.3.0] เลื่อนนัดได้ไหม: ยังไม่ซ่อม · ยังไม่เลยนัด · ยังไม่เคยเลื่อน · วันนัดใหม่ไม่เกิน last_day
func can_postpone(o: Order, today: int, last_day := 1 << 20) -> bool:
	return o != null and orders.has(o) and o.state == State.WAITING and not o.postponed and today <= o.due and o.due + 1 <= last_day


## โทรเลื่อนนัด +1 วันเปิดร้าน → ความพอใจตอนมารับ −postpone_sat_penalty
func postpone(o: Order, today: int, last_day := 1 << 20) -> bool:
	if not can_postpone(o, today, last_day):
		return false
	o.due += 1
	o.postponed = true
	o.sat_adjust -= econ.postpone_sat_penalty
	return true


## [0.3.0] โทรเรียกมารับก่อนนัดได้ไหม: ซ่อมเสร็จแล้ว · วันนัดยังไม่ถึง
func can_call_early(o: Order, today: int) -> bool:
	return o != null and orders.has(o) and o.state == State.DONE and o.due > today


## โทรเรียกมารับวันนี้ → ปิดใบรับเครื่อง คืนผล pickup (ทันนัด + early_call_sat_bonus) · ผู้เรียกให้ลูกค้าเดินมาหน้าประตูเอง
func call_early(o: Order, today: int) -> Dictionary:
	if not can_call_early(o, today):
		return { }
	o.sat_adjust += econ.early_call_sat_bonus
	o.due = today
	return pickup(o, today)


## เปิดร้านวัน today: ลูกค้าเครื่องเสร็จที่ถึงนัดมารับ · งานค้างเลยช่วงผ่อนผันมาเอาคืน
## → {picked: [pickup dict], returned: [Order], due_today: [Order ที่ยังไม่ซ่อมแต่ถึงนัดวันนี้], late_waiting: [Order ช้าแต่ยังผ่อนผัน]}
func open_day(today: int) -> Dictionary:
	var picked: Array[Dictionary] = []
	var returned: Array[Order] = []
	var due_today: Array[Order] = []
	var late_waiting: Array[Order] = []
	for o: Order in orders.duplicate():
		if o.state == State.DONE and today >= o.due:
			picked.append(pickup(o, today))
		elif o.state == State.WAITING:
			var late := o.late_days(today)
			if late > econ.late_grace_days + (econ.perk_late_grace_bonus if GameState.has_perk(&"punctual") else 0):
				o.state = State.RETURNED
				o.closed_on = today
				_close(o)
				returned.append(o)
			elif late > 0:
				late_waiting.append(o)
			elif today == o.due:
				due_today.append(o)
	return { "picked": picked, "returned": returned, "due_today": due_today, "late_waiting": late_waiting }


func _close(o: Order) -> void:
	orders.erase(o)
	history.push_front(o)
	if history.size() > 40:
		history.resize(40)


func to_save() -> Dictionary:
	return {
		"slots": slots,
		"next_key": next_key,
		"orders": orders.map(func(o: Order) -> Dictionary: return o.to_dict()),
	}


func load_save(d: Dictionary) -> void:
	slots = int(d.get("slots", econ.shelf_slots_start))
	next_key = maxi(int(d.get("next_key", 1)), 1)
	orders.clear()
	for od in d.get("orders", []):
		var o := Order.from_dict(od)
		if o:
			if o.key == "": # เซฟ v4 ไม่มีรหัส
				o.key = _new_key()
			orders.append(o)
