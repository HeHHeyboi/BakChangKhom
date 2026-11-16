extends Node
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น A–B] แยกคนกับงาน — งานกลาง (customer ว่าง) · จับคู่ด้วยป้าย · ใส่ชื่อ/เครื่อง · เซฟ/โหลด · ช่วงเวลาของคน
## เปิด Test/match_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	var gs := GameState
	gs.reset()
	var e: EconomyConfig = gs.economy

	# A · งานกลางในคลัง: ไม่มีปัญหา · มีคนรับได้อย่างน้อย 2 คน
	var generic: Array[CustomerCase] = []
	var bad := PackedStringArray()
	for f in DirAccess.get_files_at("res://Resources/Customers/"):
		var path := "res://Resources/Customers/" + f.trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var c := load(path) as CustomerCase
		if c and c.is_generic():
			generic.append(c)
			for p in c.problems():
				bad.append("%s: %s" % [c.id, p])
			var who := NpcBook.all().filter(func(n: CustomerNPC) -> bool: return n.matches(c))
			if who.size() < (1 if c.group_ok else 2):
				bad.append("%s มีคนเอามาได้ %d คน" % [c.id, who.size()])
	_check(generic.size() >= 5, "งานกลาง %d ไฟล์" % generic.size())
	_check(bad.is_empty(), "งานกลางไม่มีปัญหา %s" % ", ".join(bad))

	# B · ใส่ชื่อ · เครื่อง · ต้นแบบ · of_case/npc_id เหมือนเดิม
	var ram: CustomerCase = load("res://Resources/Customers/any_ram.tres")
	var amn := NpcBook.by_id(&"amnuay")
	var c1 := ram.instance_for(amn)
	_check(c1 != ram and c1.template() == ram and ram.template() == ram, "instance_for = สำเนาที่จำต้นแบบ")
	_check(c1.customer == "ลุงอำนวย" and NpcBook.of_case(c1) == amn and DayLoop.npc_id(c1) == &"amnuay", "ชื่อในสำเนา = char_key → of_case/npc_id ใช้ได้")
	_check(c1.device == amn.devices[0] and not c1.reason.contains("{") and c1.reason.contains("ลุงอำนวย"), "{name} {device} ถูกแทน: %s" % c1.reason)
	_check(ram.customer == "" and ram.device == "{device}", "ต้นแบบไม่ถูกแก้")
	var bound: CustomerCase = load("res://Resources/Customers/lv2_headman_ram.tres")
	_check(bound.instance_for(amn) == bound, "งานผูกคน → ตัวเดิม")

	# C · บทกลาง: {npc} = ชื่อคนพูด
	var dp := DayLoop.arrival_dialog_path(c1)
	_check(dp.begins_with("user://") and DialogUtil.speakers_in(dp).has("ลุงอำนวย") and not FileAccess.get_file_as_string(dp).contains("{"), "บทกลางเติมชื่อแล้ว (%s)" % dp)
	_check(DayLoop.arrival_dialog_path(bound) == bound.arrive_dialog, "งานผูกคนใช้บทเดิม")

	# D · เซฟ: ref ของงานกลาง = dict · ผูกคน = path · โหลดกลับได้คนเดิม/เครื่องเดิม
	var r1: Variant = CustomerCase.to_ref(c1)
	_check(r1 is Dictionary and r1.npc == "amnuay", "ref งานกลาง = dict")
	_check(CustomerCase.to_ref(bound) == bound.resource_path, "ref งานผูกคน = path (เซฟเก่าอ่านได้)")
	var c2 := CustomerCase.from_ref(JSON.parse_string(JSON.stringify(r1)))
	_check(c2 and c2.template() == ram and c2.customer == c1.customer and c2.device == c1.device, "โหลดงานกลางกลับมาได้คนเดิม")
	_check(CustomerCase.from_ref(bound.resource_path) == bound and CustomerCase.from_ref("res://ไม่มี.tres") == null, "โหลด path เดิม · ไฟล์หาย = null")
	var o := RepairShelf.Order.new()
	o.case = c1
	o.key = "k1"
	var o2 := RepairShelf.Order.from_dict(JSON.parse_string(JSON.stringify(o.to_dict())))
	_check(o2 and o2.case.customer == "ลุงอำนวย" and o2.case.template() == ram, "ใบรับเครื่องงานกลางเซฟ/โหลดได้")

	# E · ป้าย · ความสนิทขั้นต่ำ · กลุ่ม
	var gpu: CustomerCase = load("res://Resources/Customers/any_gpu.tres")
	_check(NpcBook.by_id(&"bew").matches(gpu) and not NpcBook.by_id(&"amnuay").matches(gpu), "การ์ดจอ: น้องบิว (gamer) ได้ · ลุงอำนวยไม่ได้")
	var picky := ram.duplicate() as CustomerCase
	picky.min_affinity = 60
	_check(not amn.matches(picky, 20) and amn.matches(picky, 60), "min_affinity กันคนไม่สนิท")

	# F · ช่วงเวลา: ลุงเช้า · ครูเช้า/เย็น · นักเรียนหลัง 16:00 เว้นปิดเทอม
	var fai := NpcBook.by_id(&"fai")
	var tea := NpcBook.by_id(&"teacher")
	_check(amn.available_at(600, 1) and not amn.available_at(840, 1), "ลุงอำนวยมาช่วงเช้า")
	_check(tea.available_at(540, 1) and not tea.available_at(660, 1) and tea.available_at(960, 1), "ครูก่อน 09:30 หรือหลัง 16:00")
	_check(not fai.available_at(840, 1, e.school_break_months, e.school_after_minute) and fai.available_at(960, 1, e.school_break_months, e.school_after_minute), "เปิดเทอม: น้องฝ้ายหลัง 16:00")
	_check(fai.available_at(600, 3, e.school_break_months, e.school_after_minute), "ปิดเทอม มี.ค.: น้องฝ้ายมาได้ทั้งวัน")

	# G · สุ่มหน้าประตู (DayLoop): 14:00 เปิดเทอมไม่มีนักเรียน · 16:00 มีได้ · งานกลางได้ชื่อคนจริง · โทรเข้าไม่เช็กช่วงเวลา
	await get_tree().process_frame
	var ts: TimeSystem = EventManager.time_system
	DayLoop.day_skip_seconds = 0.0
	DayLoop.tutorials = false
	DayLoop._reset_run()
	gs.reset()
	ts.set_clock(840)
	var students := 0
	var seen := { }
	var generic_named := 0
	var unnamed := 0
	for i in 40:
		DayLoop.door_queue.clear()
		DayLoop._recent.clear()
		DayLoop.add_visitors(3, false, 0, 840)
		for j in DayLoop.door_queue:
			var c: CustomerCase = j["case"]
			var n := NpcBook.of_case(c)
			if n and n.is_student():
				students += 1
			if c.customer == "":
				unnamed += 1
			if c.template() != c:
				generic_named += 1
			seen[c.customer] = true
	_check(students == 0, "14:00 เดือน ม.ค. ไม่มีนักเรียน (%d)" % students)
	_check(unnamed == 0, "ไม่มีลูกค้าไร้ชื่อหน้าประตู")
	_check(not seen.has("เพื่อนร่วมงาน"), "เพื่อนร่วมงาน (16:00+) ไม่มาตอน 14:00")
	students = 0
	for i in 40:
		DayLoop.door_queue.clear()
		DayLoop._recent.clear()
		DayLoop.add_visitors(3, false, 0, 960)
		for j in DayLoop.door_queue:
			var n := NpcBook.of_case(j["case"])
			if n and n.is_student():
				students += 1
			if (j["case"] as CustomerCase).template() != j["case"]:
				generic_named += 1
	_check(students > 0, "16:00 มีนักเรียนมาได้ (%d)" % students)
	_check(generic_named > 0, "งานกลางถูกสุ่มมาพร้อมชื่อคน (%d)" % generic_named)
	DayLoop.door_queue.clear()
	_check(DayLoop.add_visitors(1, true) == 1, "โทรเข้า (ไม่เช็กช่วงเวลา) ได้ 1 สาย")
	_check(DayLoop.is_case_busy((DayLoop.door_queue[0]["case"] as CustomerCase).template()), "ต้นแบบของคนที่ยืนอยู่ = ไม่ว่าง (ไม่สุ่มซ้ำ)")
	DayLoop.door_queue.clear()

	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
