class_name EndingBook
## [Claude 16 พ.ย. 2569 · 0.8.0 ขั้น D–E] ฉากจบ — ประกอบบทจากการเล่นจริงแล้วเขียนเป็นไฟล์ชั่วคราวให้ DialogScene เล่น
## ลำดับ: Ending/<ฉาก>.txt (เปิด) → ปิ๊บสรุปปี → คนที่สนิทที่สุด 3 คนขอบคุณ (Ending/thanks_<id>.txt) → [กลับเมือง] มิ้นดูแลร้าน (สรุปจากความสัมพันธ์ + สิ่งที่สอนมิ้น) → Ending/<ฉาก>_close.txt
## ร้านปิด: Ending/failure.txt + สาเหตุ (ไม่มีสรุปปี) · ทุกบรรทัดห้ามมี , หรือ : (_clean)

const DIR := "res://Assets/Dialog/Ending/"
const OUT := "user://dialog_tmp_ending.txt"
const TITLES := {
	&"stay": "ฉากจบ · ร้านของหมู่บ้าน",
	&"coworking": "ฉากจบ · ทำงานโลกกว้างจากบ้านเกิด",
	&"city": "ฉากจบ · มิ้นดูแลร้าน",
	&"failure": "ฉากจบ · ร้านปิด",
}
const BGS := {
	&"stay": "res://Assets/Background/bg_year_after.jpg",
	&"coworking": "res://Assets/Background/bg_shop_busy.jpg",
	&"city": "res://Assets/Background/bg_path_sunset.jpg",
	&"failure": "res://Assets/Background/bg_shop_empty.jpg",
}
## Part ที่มิ้นเรียนจากขม (ชื่อไทย) · ครั้งที่ขมซ่อมผ่าน ≥ TAUGHT_AT = มิ้นทำเองได้ · 1+ = ยังต้องเปิดคู่มือ
const PART_NAMES := {
	&"part_desktop": "แก้ปัญหาในเครื่อง",
	&"part_ram": "แรม",
	&"part_mainboard": "เมนบอร์ด",
	&"part_gpu": "การ์ดจอ",
	&"part_front_panel": "สายหน้าเคส",
	&"part_bios": "ไบออส",
}
const TAUGHT_AT := 3
const THANKS_MAX := 3
const THANKS_MIN_AFFINITY := 40
## คนที่ไม่ขึ้นขอบคุณ (มีบทของตัวเองแล้ว)
const NOT_THANKS := [&"yai", &"min"]


static func title(e: StringName) -> String:
	return TITLES.get(e, "ฉากจบ")


static func bg(e: StringName) -> String:
	return BGS.get(e, "")


## เขียนบทฉากจบลงไฟล์ชั่วคราว → path
static func build(e: StringName) -> String:
	var lines := lines_for(e)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f == null:
		return DIR + "stay.txt"
	f.store_string("\n".join(lines) + "\n")
	f.close()
	return OUT


static func lines_for(e: StringName) -> PackedStringArray:
	var out: PackedStringArray = []
	_file(out, DIR + "%s.txt" % e)
	if e == &"failure":
		out.append("ปิ๊บ,%s" % _clean(failure_reason()))
		_file(out, DIR + "failure_close.txt")
		return out
	out.append_array(recap_lines())
	for id in top_npcs():
		var p := DIR + "thanks_%s.txt" % id
		if FileAccess.file_exists(p):
			_file(out, p)
		else:
			var n := NpcBook.by_id(id)
			if n:
				out.append("%s,ขอบใจนะขม ปีนี้ได้พึ่งร้านขมหลายเรื่องเลย" % n.char_key)
	if e == &"city":
		out.append_array(min_lines())
	_file(out, DIR + "%s_close.txt" % e)
	return out


## ปิ๊บสรุปปี (ตัวเลขจริง)
static func recap_lines() -> PackedStringArray:
	var gs := GameState
	var hit := gs.month_results.filter(func(r: Dictionary) -> bool: return bool(r.get("reached", false))).size()
	var out: PackedStringArray = []
	out.append("ปิ๊บ,ปีนี้ร้านเราซ่อมไปทั้งหมด %d งาน ถึงเป้า %d จาก %d เดือนค่ะ" % [gs.satisfaction_history.size(), hit, gs.month_results.size()])
	var extra := "พี่ขมเป็น%sแล้ว ได้ใบประกาศ %d ใบ" % [gs.rank_name(), gs.achievements.size()]
	var gifts := gs.gifts_received.size()
	if gifts > 0:
		extra += " แล้วก็ได้ของขวัญจากคนในหมู่บ้าน %d ชิ้น" % gifts
	out.append("ปิ๊บ,%s" % _clean(extra))
	return out


## คนที่สนิทที่สุด (ไม่รวมยาย/มิ้น/กลุ่ม) สูงสุด THANKS_MAX คน · สนิท ≥ THANKS_MIN_AFFINITY
static func top_npcs() -> Array[StringName]:
	var rows: Array = []
	for id in GameState.npc_affinity:
		var n := NpcBook.by_id(id)
		if n == null or n.is_group() or not n.has_affinity or NOT_THANKS.has(id):
			continue
		var a := int(GameState.npc_affinity[id])
		if a >= THANKS_MIN_AFFINITY:
			rows.append([a, id])
	rows.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0] or (x[0] == y[0] and String(x[1]) < String(y[1])))
	var out: Array[StringName] = []
	for r in rows.slice(0, THANKS_MAX):
		out.append(r[1])
	return out


## [กลับเมือง] มิ้นดูแลร้าน — สรุปจากสิ่งที่ขมสอนมิ้น (Part ที่ซ่อมผ่านบ่อย · เรื่องส่วนตัวมิ้น · ให้มิ้นช่วยงาน) + ลูกค้าที่สนิท + ความสนิทของมิ้น
## คืน { taught, learning, untaught (ชื่อ Part), loyal (ชื่อคน), drift, min_aff, lessons, score, tier (good/ok/hard) }
static func min_report() -> Dictionary:
	var gs := GameState
	var taught: Array[String] = []
	var learning: Array[String] = []
	var untaught: Array[String] = []
	for p in PART_NAMES:
		var n := int(gs.part_clears.get(p, 0))
		if n >= TAUGHT_AT:
			taught.append(PART_NAMES[p])
		elif n > 0:
			learning.append(PART_NAMES[p])
		else:
			untaught.append(PART_NAMES[p])
	var loyal: Array[String] = []
	var drift := 0
	for id in gs.npc_affinity:
		var npc := NpcBook.by_id(id)
		if npc == null or npc.is_group() or not npc.has_affinity or NOT_THANKS.has(id):
			continue
		var a := int(gs.npc_affinity[id])
		if a >= 60:
			loyal.append(npc.display_name)
		elif a < 40:
			drift += 1
	var min_aff := gs.affinity(&"min")
	# บทเรียนที่สอนมิ้นโดยตรง: เรื่องส่วนตัวมิ้น · ให้มิ้นทำงานแทน · เลือกฝากร้านในบท 11
	var lessons := 0
	for f in ["min_learned", "npc_regular_min", "helper_used"]:
		if bool(gs.story_flags.get(f, false)):
			lessons += 1
	lessons += mini(int(gs.ach_stats.get("helper_runs", 0)), 5) / 2
	var score := taught.size() * 2 + learning.size() + mini(loyal.size(), 5) + lessons + (2 if min_aff >= 60 else 0)
	# ร้านไปได้ดีต้องทั้งสอนมาเยอะและมิ้นสนิทพอจะมั่นใจ (บอทปกติสอน Part ครบ ~6 · ทดลอง · ปรับจากผู้เล่นจริง)
	var tier := "good" if score >= 16 and min_aff >= 60 else ("ok" if score >= 9 else "hard")
	return {
		"taught": taught, "learning": learning, "untaught": untaught, "loyal": loyal, "drift": drift,
		"min_aff": min_aff, "lessons": lessons, "score": score, "tier": tier,
	}


static func min_lines() -> PackedStringArray:
	var r := min_report()
	var out: PackedStringArray = []
	out.append("คำบรรยาย,สามเดือนหลังขมกลับเข้าเมือง มิ้นโทรหาขมทุกคืนวันอาทิตย์")
	if not (r.taught as Array).is_empty():
		out.append("มิ้น,งาน%s มิ้นทำเองได้แล้วค่ะ พี่ขมทำให้ดูบ่อยจนมิ้นจำได้ทุกขั้น" % _clean(" ".join(r.taught)))
	if not (r.learning as Array).is_empty():
		out.append("มิ้น,งาน%s มิ้นยังต้องเปิดคู่มือ ทำช้าหน่อยแต่ก็ทำได้ค่ะ" % _clean(" ".join(r.learning)))
	if not (r.untaught as Array).is_empty():
		out.append("มิ้น (กังวล),ส่วนงาน%s มิ้นไม่เคยเห็นพี่ทำเลย เลยต้องส่งต่อให้ร้านในอำเภอค่ะ" % _clean(" ".join(r.untaught)))
	if (r.loyal as Array).size() > 0:
		out.append("มิ้น,%s ยังมาที่ร้านเหมือนเดิมค่ะ บอกว่าร้านพี่ขมก็คือร้านมิ้น" % _clean(" ".join((r.loyal as Array).slice(0, 4))))
	if int(r.drift) > (r.loyal as Array).size():
		out.append("มิ้น,ลูกค้าหลายคนที่ยังไม่ค่อยรู้จักร้านไปร้านใหม่ในอำเภอ มิ้นจะค่อย ๆ ทำให้เขากลับมานะคะ")
	if int(r.min_aff) >= 60:
		out.append("มิ้น (ยิ้ม),ขอบคุณที่ไว้ใจให้มิ้นดูแลร้านนะคะพี่ขม")
	else:
		out.append("มิ้น,มิ้นยังไม่ค่อยมั่นใจเท่าไหร่ แต่จะพยายามค่ะ")
	match String(r.tier):
		"good":
			out.append("คำบรรยาย,ร้านบักช่างขมยังเปิดทุกวัน ลูกค้าแน่นเหมือนเดิม และมิ้นเริ่มสอนเด็ก ๆ ต่อจากที่ขมเคยสอน")
		"ok":
			out.append("คำบรรยาย,ร้านยังไปได้ แม้บางงานต้องส่งต่อ มิ้นจดทุกอย่างที่ไม่รู้ไว้ถามขมตอนกลับมาเยี่ยม")
		_:
			out.append("คำบรรยาย,ร้านเปิดน้อยวันลง มิ้นรับเฉพาะงานที่ทำเป็น และนับวันรอขมกลับมาเยี่ยมช่วงปีใหม่")
	return out


static func failure_reason() -> String:
	var miss := GameState.month_results.filter(func(r: Dictionary) -> bool: return not bool(r.get("reached", false))).size()
	if GameState.debt > 0:
		return "ร้านค้างค่าใช้จ่ายสองเดือนติดค่ะพี่ขม รายจ่ายมากกว่ารายรับ ครั้งหน้าลองดูหน้าสรุปเดือนว่าเงินไปไหนบ้างนะคะ"
	return "ร้านไม่ถึงเป้าติดกันหลายเดือนค่ะพี่ขม (พลาดเป้า %d เดือน) ครั้งหน้าลองรับงานที่ทำทันและคุมค่าอะไหล่ดูนะคะ" % miss


## จด user://playlog/ending.csv (ประกอบเล่มรายงาน) · บอท/เทสต์ไม่เขียน
static func log_ending() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var dl: Node = tree.root.get_node_or_null(^"/root/DayLoop") if tree else null
	if dl and bool(dl.get("quiet")):
		return
	var gs := GameState
	var hit := gs.month_results.filter(func(r: Dictionary) -> bool: return bool(r.get("reached", false))).size()
	Playlog.append("ending.csv", ["ending", "ch11_pick", "ch12_pick", "months_hit", "rank", "achievements", "gifts", "repairs", "min_tier", "playtime_sec"], [
		String(gs.ending), String(gs.story_flags.get("ch11_pick", "")), String(gs.story_flags.get("ch12_pick", "")), hit, gs.rank(),
		gs.achievements.size(), gs.gifts_received.size(), gs.satisfaction_history.size(), String(min_report().tier), roundi(gs.playtime_sec),
	]) # [0.9.0]


static func _file(out: PackedStringArray, path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	for l in FileAccess.get_file_as_string(path).split("\n"):
		var t := String(l).strip_edges()
		if t != "" and not t.begins_with("#"):
			out.append(t)


static func _clean(t: String) -> String:
	return t.replace(",", " ").replace(":", " ").replace("\n", " ")
