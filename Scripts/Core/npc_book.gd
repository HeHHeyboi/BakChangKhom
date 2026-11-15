class_name NpcBook
extends RefCounted
## [Claude 15 พ.ย. 2569 · 0.5.0] รายชื่อลูกค้าประจำ (Resources/NPC/*.tres) · หา NPC จากเคส/ชื่อ (PLAN_0_5_0 ข้อ 2)

const DIR := "res://Resources/NPC/"

static var _all: Array[CustomerNPC] = []
static var _by_key: Dictionary = { }
static var _by_id: Dictionary = { }


static func all() -> Array[CustomerNPC]:
	if _all.is_empty():
		_load()
	return _all


static func _load() -> void:
	_all.clear()
	_by_key.clear()
	_by_id.clear()
	var files := Array(DirAccess.get_files_at(DIR))
	files.sort()
	for f in files:
		var path: String = DIR + String(f).trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var n := load(path) as CustomerNPC
		if n == null or n.id == &"":
			continue
		_all.append(n)
		_by_id[n.id] = n
		_by_key[n.char_key] = n


static func by_id(id: StringName) -> CustomerNPC:
	all()
	return _by_id.get(id)


## ชื่อในเคส/ชื่อตัวละคร → NPC (null = ลูกค้าขาจร)
static func of_name(char_key: String) -> CustomerNPC:
	all()
	return _by_key.get(char_key)


static func of_case(c: CustomerCase) -> CustomerNPC:
	return of_name(c.customer) if c else null


## NPC ที่มีค่าความสนิท (ไม่รวมยาย)
static func with_affinity() -> Array[CustomerNPC]:
	return all().filter(func(n: CustomerNPC) -> bool: return n.has_affinity)
