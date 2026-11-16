class_name RequestBook
extends RefCounted
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น G] คลังคำขอ (Resources/Request/*.tres)

const DIR := "res://Resources/Request/"
const TEMPLATE := "res://Resources/Customers/any_request.tres"

static var _all: Array[RequestTask] = []
static var _by_id: Dictionary = { }


static func all() -> Array[RequestTask]:
	if _all.is_empty():
		var files := Array(DirAccess.get_files_at(DIR))
		files.sort()
		for f in files:
			var path: String = DIR + String(f).trim_suffix(".remap")
			if not path.ends_with(".tres"):
				continue
			var r := load(path) as RequestTask
			if r and r.id != &"":
				_all.append(r)
				_by_id[r.id] = r
	return _all


static func by_id(id: StringName) -> RequestTask:
	all()
	return _by_id.get(id)


## คนนี้เอาเรื่องนี้มาได้ไหม (ป้าย · ยศ)
static func fits(r: RequestTask, n: CustomerNPC, rank: int) -> bool:
	if r == null or n == null or r.min_rank > rank:
		return false
	if n.is_group() != r.npc_tags.has("group"): # กลุ่มเอาเฉพาะเรื่องของกลุ่ม
		return false
	for t in r.npc_tags:
		if t == "any" or n.tags.has(t):
			return true
	return false


## เคสหน้าประตูของคำขอนี้ (สำเนาของ any_request ใส่ชื่อคน)
static func make_case(r: RequestTask, n: CustomerNPC) -> CustomerCase:
	var t := load(TEMPLATE) as CustomerCase
	var c := t.instance_for(n)
	c.apply_request(r)
	return c
