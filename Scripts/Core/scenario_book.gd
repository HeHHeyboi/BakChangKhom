class_name ScenarioBook
extends RefCounted
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น C] คลังสถานการณ์ซ่อม (Resources/Scenario/<part>/*.tres) + ตัวสุ่มอาการ (PLAN_0_6_0 ข้อ 3)
## roll() = สถานการณ์ × นิสัยลูกค้า × สภาพเครื่อง · ไม่ซ้ำ 2 ครั้งล่าสุดของ Part นั้น

const DIR := "res://Resources/Scenario/"
## นิสัยลูกค้า · ผลอยู่ใน CustomerCase.apply_scenario
const TRAITS: Array[StringName] = [&"normal", &"rushed", &"budget"]
const TRAIT_NAMES := { &"normal": "", &"rushed": "ลูกค้ารีบ", &"budget": "งบน้อย" }
## สภาพเครื่อง · flood เฉพาะเดือน 8 ขึ้นไป (หลังพายุ)
const CONDITIONS: Array[StringName] = [&"new", &"old", &"flood"]
const CONDITION_NAMES := { &"new": "เครื่องค่อนข้างใหม่", &"old": "เครื่องใช้มาห้าปี", &"flood": "เครื่องเคยโดนน้ำท่วม" }
const RECENT := 2

## ปิดนิสัยลูกค้า (บอท/เทสต์สมดุล) → ทุกคน "ปกติ"
static var traits_enabled := true
## ตัวคูณน้ำหนักสถานการณ์ที่ต้องใช้อะไหล่ (ปรับสมดุล)
static var part_weight_mult := 1.0
static var _by_part: Dictionary = { }
static var _by_id: Dictionary = { }


static func all_of(part: StringName) -> Array[RepairScenario]:
	_load()
	var out: Array[RepairScenario] = []
	out.assign(_by_part.get(part, []))
	return out


static func by_id(id: StringName) -> RepairScenario:
	_load()
	return _by_id.get(id)


static func parts() -> Array:
	_load()
	return _by_part.keys()


static func _load() -> void:
	if not _by_id.is_empty():
		return
	for sub in DirAccess.get_directories_at(DIR):
		var files := Array(DirAccess.get_files_at(DIR + sub))
		files.sort()
		for f in files:
			var path: String = DIR + sub + "/" + String(f).trim_suffix(".remap")
			if not path.ends_with(".tres"):
				continue
			var s := load(path) as RepairScenario
			if s == null or s.id == &"":
				continue
			_by_id[s.id] = s
			if not _by_part.has(s.part):
				_by_part[s.part] = []
			(_by_part[s.part] as Array).append(s)


## [0.7.0] ตัวคูณน้ำหนักตามอีเวนต์ { scenario id: ×n } (หน้าร้อน = เคสความร้อน ×2) · DayLoop ตั้งทุกเช้า
static var bias: Dictionary = { }
## [0.7.0] สภาพ "เคยโดนน้ำท่วม" เปิดหลังพายุ ส.ค. (หรือตั้งแต่ ก.ย.)
static var flood_open := false


static func _w(s: RepairScenario) -> float:
	return s.weight * (part_weight_mult if s.needs_part != &"" else 1.0) * float(bias.get(s.id, 1.0))


## สุ่ม { scenario, trait, condition } · recent = id ที่เพิ่งเจอของ Part นี้ (เก่า → ใหม่) · rank = ยศผู้เล่น
static func roll(part: StringName, rng: RandomNumberGenerator, recent: Array = [], rank := 4, month := 1) -> Dictionary:
	var pool := all_of(part).filter(func(s: RepairScenario) -> bool: return s.min_rank <= rank)
	if pool.is_empty():
		return { }
	var fresh := pool.filter(func(s: RepairScenario) -> bool: return not recent.slice(-RECENT).has(s.id))
	if fresh.is_empty():
		fresh = pool
	var total := 0.0
	for s in fresh:
		total += _w(s)
	var r := rng.randf() * total
	var pick: RepairScenario = fresh[0]
	for s in fresh:
		r -= _w(s)
		if r <= 0.0:
			pick = s
			break
	var conds := CONDITIONS.duplicate()
	if month < 8 or (month == 8 and not flood_open):
		conds.erase(&"flood")
	return {
		"scenario": pick,
		"trait": TRAITS[rng.randi_range(0, TRAITS.size() - 1)] if traits_enabled else &"normal",
		"condition": conds[rng.randi_range(0, conds.size() - 1)],
	}


## เขียนผลลง user://playlog/scenario_log.csv (ข้อมูลการวินิจฉัยระหว่างเล่น ประกอบเล่มรายงาน) · [0.9.0] ย้ายเข้า playlog + รหัสผู้ทดสอบ
static func append_csv(row: Dictionary) -> void:
	Playlog.append("scenario_log.csv", ["chapter", "day", "scenario", "part", "first_try", "wrong", "skipped", "did_optional", "score", "gave_up"], [
		int(row.ch), int(row.day), String(row.id), String(row.part), bool(row.first_try), int(row.wrong), int(row.skipped), int(row.did_optional), int(row.score), bool(row.gave_up),
	])
