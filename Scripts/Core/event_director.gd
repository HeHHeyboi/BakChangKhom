class_name EventDirector
extends RefCounted
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น B] เลือกอีเวนต์ของวัน (PLAN_0_7_0 ข้อ 2–3)
## ข้อมูล Resources/Event/*.tres (ShopEvent) · สถานะเก็บใน GameState.event_state { last: {key: shift}, done: {id: true}, … }
## สุ่มด้วย DayLoop.rng(&"event") → โหลดเซฟต้นวันได้อีเวนต์เดิม

const DIR := "res://Resources/Event/"
## โอกาสที่วันหนึ่งมีอีเวนต์สุ่ม (ถ้าเงื่อนไขผ่าน)
static var random_chance := 0.3
## ปิดอีเวนต์ทั้งหมด (บอท BAL_NOEVENT · เทสต์เก่า)
static var disabled := false
static var _all: Array[ShopEvent] = []


static func all() -> Array[ShopEvent]:
	if _all.is_empty():
		for f in DirAccess.get_files_at(DIR):
			var path := DIR + f.trim_suffix(".remap")
			if path.ends_with(".tres"):
				var e := load(path) as ShopEvent
				if e:
					_all.append(e)
		_all.sort_custom(func(a: ShopEvent, b: ShopEvent) -> bool: return String(a.id) < String(b.id))
	return _all


static func by_id(id: StringName) -> ShopEvent:
	for e in all():
		if e.id == id:
			return e
	return null


## คำถามของกลุ่ม (QUIZ)
static func quiz(group: StringName) -> Array[ShopEvent]:
	var out: Array[ShopEvent] = []
	for e in all():
		if e.kind == ShopEvent.Kind.QUIZ and e.group == group:
			out.append(e)
	return out


## อีเวนต์ปฏิทินของวันนี้ (รายวัน + ทั้งเดือน)
static func calendar(month: int, day: int) -> Array[ShopEvent]:
	var out: Array[ShopEvent] = []
	if disabled:
		return out
	for e in all():
		if e.kind == ShopEvent.Kind.CALENDAR and e.month == month and (e.day == 0 or e.day == day):
			out.append(e)
	return out


## สุ่มอีเวนต์สุ่ม 1 อัน (null = ไม่มี) · ok(e) = เงื่อนไขในเกม (DayLoop) · shift = วันที่เล่น (นับ cooldown)
static func roll_random(month: int, day: int, shift: int, rng: RandomNumberGenerator, state: Dictionary, rank: int, ok: Callable, has_day_event: bool) -> ShopEvent:
	if disabled or day <= 1 or has_day_event:
		return null
	var roll := rng.randf()
	var last: Dictionary = state.get("last", { })
	var done: Dictionary = state.get("done", { })
	var pool: Array[ShopEvent] = []
	var weights: Array[float] = []
	for e in all():
		if e.kind != ShopEvent.Kind.RANDOM or rank < e.min_rank:
			continue
		if not e.months.is_empty() and not e.months.has(month):
			continue
		if e.once and done.has(String(e.id)):
			continue
		if last.has(String(e.key())) and shift - int(last[String(e.key())]) < e.cooldown_days:
			continue
		if ok.is_valid() and not bool(ok.call(e)):
			continue
		pool.append(e)
		weights.append(e.weight * (2.0 if e.boost_months.has(month) else 1.0))
	if pool.is_empty() or roll >= random_chance:
		return null
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in pool.size():
		r -= weights[i]
		if r <= 0.0:
			return pool[i]
	return pool[-1]


## จดว่าเกิดแล้ว (cooldown · ครั้งเดียว)
static func mark(state: Dictionary, e: ShopEvent, shift: int) -> void:
	if not state.has("last"):
		state["last"] = { }
	if not state.has("done"):
		state["done"] = { }
	state.last[String(e.key())] = shift
	state.done[String(e.id)] = true


## user://playlog/events.csv (เวลา · บท · วัน · อีเวนต์ · ตัวเลือก) ประกอบเล่มรายงาน
static func append_csv(row: Dictionary) -> void:
	Playlog.append("events.csv", ["chapter", "day", "event", "choice"], [int(row.ch), int(row.day), String(row.id), String(row.choice)]) # [0.9.0]
