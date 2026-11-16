class_name RankExam
extends RefCounted
## [Claude 16 พ.ย. 2569 · 0.5.0 ขั้น G] สอบเลื่อนยศกับปิ๊บ (PLAN_0_5_0 ข้อ 5.2)
## คลังข้อสอบ = Resources/Exam/*.tres (ExamQuestion) · สอบในแอป "สอบช่าง" ในคอมของขม (RankExamApp)
## DayLoop คุมลำดับ: exam_begin → exam_answer ×3 → exam_finish (ถูก ≥ exam_pass = เลื่อนยศ) · ผลแต่ละข้อลง GameState.learn_log + user://learn_log.csv

const DIR := "res://Resources/Exam/"

static var _bank: Array[ExamQuestion] = []


static func bank() -> Array[ExamQuestion]:
	if _bank.is_empty():
		var files := Array(DirAccess.get_files_at(DIR))
		files.sort()
		for f in files:
			var p: String = DIR + String(f).trim_suffix(".remap")
			if p.ends_with(".tres"):
				var q := load(p) as ExamQuestion
				if q:
					_bank.append(q)
	return _bank


## คลังข้อของการสอบขึ้นยศ target ("cap" ของข้อสอบ): ระดับ ≤ target · เรื่องที่ซ่อมผ่านแล้ว + ทั่วไป
## ถ้าน้อยกว่า n ข้อ → ขยายเป็นทุก Part ในระดับ ≤ target
static func pool(target: int, cleared: Array, n := 3) -> Array[ExamQuestion]:
	var lv: Array[ExamQuestion] = bank().filter(func(q: ExamQuestion) -> bool: return q.level <= target)
	var known: Array[ExamQuestion] = lv.filter(func(q: ExamQuestion) -> bool: return q.part == &"general" or cleared.has(q.part))
	return known if known.size() >= n else lv


## สุ่ม n ข้อใหม่ทุกครั้งจาก pool() · ข้อดูภาพ 1 ข้อ (ถ้ามี · ที่เหลือเป็นข้อความ) · ไม่เอาข้อชุดที่แล้ว (avoid) ถ้าคลังพอ · พยายามไม่ซ้ำหมวด
static func pick(target: int, n: int, rng: RandomNumberGenerator, cleared: Array, avoid: Dictionary) -> Array[ExamQuestion]:
	var cand: Array[ExamQuestion] = pool(target, cleared, n).duplicate()
	for i in range(cand.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := cand[i]
		cand[i] = cand[j]
		cand[j] = t
	var out: Array[ExamQuestion] = []
	var parts := { }
	# ข้อดูภาพ 1 ข้อก่อน (ไม่ซ้ำชุดที่แล้วถ้ามีให้เลือก)
	var imgs := cand.filter(func(q: ExamQuestion) -> bool: return q.image != null)
	var fresh := imgs.filter(func(q: ExamQuestion) -> bool: return not avoid.has(q.id))
	if n > 0 and not imgs.is_empty():
		var first: ExamQuestion = fresh[0] if not fresh.is_empty() else imgs[0]
		out.append(first)
		parts[first.part] = true
	# รอบ 0 = ข้อความ ไม่ซ้ำชุดที่แล้ว + ไม่ซ้ำหมวด · รอบ 1 = ข้อความ ไม่ซ้ำชุดที่แล้ว · รอบ 2 = อะไรก็ได้ในคลัง
	for pass_i in 3:
		for q in cand:
			if out.size() >= n or out.has(q):
				continue
			if pass_i < 2 and (avoid.has(q.id) or q.image != null):
				continue
			if pass_i == 0 and parts.has(q.part):
				continue
			out.append(q)
			parts[q.part] = true
	# สลับลำดับ ข้อภาพไม่ต้องเป็นข้อแรกเสมอ
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := out[i]
		out[i] = out[j]
		out[j] = t
	return out


## ลำดับตัวเลือกที่สลับแล้ว (index ใน q.choices)
static func shuffled(q: ExamQuestion, rng: RandomNumberGenerator) -> Array[int]:
	var idx: Array[int] = []
	for i in q.choices.size():
		idx.append(i)
	for i in range(idx.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := idx[i]
		idx[i] = idx[j]
		idx[j] = t
	return idx


## เขียนผลลง user://learn_log.csv (ใช้ประกอบผลการเรียนรู้ในเล่มรายงาน)
static func append_csv(row: Dictionary) -> void:
	var path := "user://learn_log.csv"
	var fresh := not FileAccess.file_exists(path)
	var f := FileAccess.open(path, FileAccess.READ_WRITE if not fresh else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	if fresh:
		f.store_line("time,chapter,day,target_rank,attempt,question,part,chosen,correct")
	f.store_line("%s,%d,%d,%d,%d,%s,%s,%s,%d" % [
		Time.get_datetime_string_from_system(), int(row.ch), int(row.day), int(row.target), int(row.attempt),
		String(row.qid), String(row.part), String(row.chosen).replace(",", " "), 1 if row.correct else 0,
	])
	f.close()
