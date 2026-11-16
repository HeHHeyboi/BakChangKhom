extends Node
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น C–D] สถานการณ์ซ่อม + ตัวสุ่มอาการ (PLAN_0_6_0 ข้อ 3)
## คลัง 25 แบบ · สุ่มไม่ซ้ำ 2 ครั้งล่าสุด · ใส่ในงานกลาง · เซฟ/โหลด · มินิเกมเปลี่ยนบท/ถามสาเหตุ/ข้ามขั้นที่ไม่จำเป็น · จดผล
## เปิด Test/scenario_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	var gs := GameState
	gs.reset()
	var e: EconomyConfig = gs.economy

	# A · คลัง: 5 Part × 5 · ข้อมูลไม่มีปัญหา · Part ละ 1 แบบเป็นเคสเดิม (default) · อะไหล่มีจริง · ชื่อ phase ที่ข้ามได้มีจริง
	var parts := [&"part_ram", &"part_mainboard", &"part_gpu", &"part_front_panel", &"part_bios"]
	var bad := PackedStringArray()
	for p in parts:
		var list := ScenarioBook.all_of(p)
		if list.size() != 5:
			bad.append("%s มี %d แบบ" % [p, list.size()])
		var defaults := list.filter(func(s: RepairScenario) -> bool: return s.flags.get("default", false)).size()
		if defaults != 1:
			bad.append("%s มีเคสเดิม %d แบบ" % [p, defaults])
		for s in list:
			for x in s.problems():
				bad.append("%s: %s" % [s.id, x])
			for it in [s.needs_part] + s.part_alternatives:
				if it != &"" and not ResourceLoader.exists("res://Resources/Shop/%s.tres" % it):
					bad.append("%s: ไม่มีของ %s" % [s.id, it])
	_check(bad.is_empty(), "คลังสถานการณ์ 25 แบบไม่มีปัญหา %s" % ", ".join(bad))

	# B · สุ่ม: ไม่ซ้ำ 2 ครั้งล่าสุด · น้ำท่วมเฉพาะเดือน 8+ · seed เดิมผลเดิม
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var recent: Array = []
	var repeat := false
	var floods := 0
	for i in 60:
		var r := ScenarioBook.roll(&"part_gpu", rng, recent, 4, 3)
		var id: StringName = (r.scenario as RepairScenario).id
		if recent.slice(-2).has(id):
			repeat = true
		recent.append(id)
		if r.condition == &"flood":
			floods += 1
	_check(not repeat, "60 ครั้งไม่ซ้ำ 2 ครั้งล่าสุด")
	_check(floods == 0, "เดือน มี.ค. ไม่มีเครื่องน้ำท่วม")
	var r1 := ScenarioBook.roll(&"part_ram", _seeded(3), [], 4, 9)
	var r2 := ScenarioBook.roll(&"part_ram", _seeded(3), [], 4, 9)
	_check(r1.scenario == r2.scenario and r1.trait == r2.trait and r1.condition == r2.condition, "seed เดิม = ผลเดิม")

	# C · ใส่ในงานกลาง: อาการ · อะไหล่ · ลูกค้ารีบ/งบน้อย · ต้นแบบไม่เปลี่ยน
	var any_ram: CustomerCase = load("res://Resources/Customers/any_ram.tres")
	var amn := NpcBook.by_id(&"amnuay")
	var r3 := ScenarioBook.by_id(&"ram_r3_bad")
	var c := any_ram.instance_for(amn)
	c.apply_scenario({ "scenario": r3, "trait": &"budget", "condition": &"old" }, e)
	_check(c.symptom == r3.symptom and c.needs_part == &"ram_ddr4_8gb_used" and c.job_title == r3.job_title, "R-3: อาการ · อะไหล่แรม · ชื่องาน")
	_check(c.fee == int(round(e.fee_for_level(2) * e.budget_fee_mult)) and c.device.contains("ห้าปี"), "งบน้อย ค่าแรง ×%.1f · เครื่องเก่าห้าปี" % e.budget_fee_mult)
	_check(any_ram.needs_part == &"" and any_ram.fee == -1 and not any_ram.has_meta("scenario"), "ต้นแบบไม่ถูกแก้")
	var c2 := any_ram.instance_for(amn)
	c2.apply_scenario({ "scenario": ScenarioBook.by_id(&"ram_r2_loose"), "trait": &"rushed", "condition": &"new" }, e)
	_check(c2.patience == 1 and c2.needs_part == &"", "ลูกค้ารีบรอได้ 1 เทิร์น · R-2 ไม่ใช้อะไหล่")

	# D · เซฟ/โหลด: ได้สถานการณ์ นิสัย สภาพ เครื่อง เดิม (ไม่ต่อสภาพซ้ำ)
	var ref: Variant = CustomerCase.to_ref(c)
	var back := CustomerCase.from_ref(JSON.parse_string(JSON.stringify(ref)))
	_check(back and back.scenario() == r3 and back.get_meta("trait") == &"budget" and back.device == c.device and back.fee == c.fee, "เซฟ/โหลดงานกลาง + สถานการณ์ครบ (%s)" % (back.device if back else "null"))
	var o := RepairShelf.Order.new()
	o.case = c
	var o2 := RepairShelf.Order.from_dict(JSON.parse_string(JSON.stringify(o.to_dict())))
	_check(o2 and o2.case.scenario() == r3 and o2.case.needs_part == &"ram_ddr4_8gb_used", "ใบรับเครื่องจำสถานการณ์ + อะไหล่")

	# E · DayLoop สุ่มให้งานกลางทุกครั้ง · จำล่าสุดต่อ Part
	DayLoop._reset_run()
	var c3 := any_ram.instance_for(amn)
	var before: Array = (DayLoop.scenario_recent.get(&"part_ram", []) as Array).duplicate()
	var rr := DayLoop.roll_scenario(c3)
	var after: Array = DayLoop.scenario_recent.get(&"part_ram", [])
	_check(not rr.is_empty() and c3.scenario() != null and after.back() == c3.scenario().id and not before.slice(-2).has(c3.scenario().id), "DayLoop.roll_scenario ใส่สถานการณ์ + จำล่าสุด (ไม่ซ้ำ 2 ครั้งก่อน)")

	# F · มินิเกมแรม (R-2): แรมสะอาดตั้งแต่ต้น · ตัวเลือกของสถานการณ์ · บทเปลี่ยน · ข้าม CLEAN ได้
	var r2s := ScenarioBook.by_id(&"ram_r2_loose")
	var job := any_ram.instance_for(amn)
	job.apply_scenario({ "scenario": r2s, "trait": &"normal", "condition": &"new" }, e)
	var ram: PartMinigame = load("res://Scene/MiniGame/PartRam/part_ram.tscn").instantiate()
	ram.set_meta("work_order", job)
	add_child(ram)
	await _frames(3)
	_check(ram.scenario == r2s and (ram.get_node("%RamA2") as Item2D).get("state") == "clean", "R-2: มินิเกมรู้สถานการณ์ · แรมสะอาด")
	var clue: Array = ram.dialog_dict.get("DIAGNOSIS_CLUE_DUST", [])
	_check(clue.size() == 2 and (clue[0] as DialogToken).dialog.contains("เอียง"), "บทส่องในเคสเปลี่ยนตามสถานการณ์")
	_check((ram.dialog_dict["SUMMARY"][0] as DialogToken).dialog.contains(r2s.cause), "บทสรุปขึ้นต้นด้วยสาเหตุ")
	var diag = ram._phase_nodes[1]
	var labels := []
	for b in diag._choice_box.get_children():
		if b is Button:
			labels.append(b.text)
	_check(labels.size() == 4 and labels.has(r2s.diag_choices[0]), "แรม: ปุ่มวินิจฉัย = ตัวเลือกของสถานการณ์ (%s)" % [labels])
	diag._on_choice("wrong")
	_check(int(ram._mistakes[&"diagnosis"]) == 10 and int(ram.scenario_stats.wrong) == 1, "ตอบผิด −10 · นับ 1")
	diag._on_choice("correct")
	_check(ram._diag_done, "ตอบถูก → วินิจฉัยแล้ว")
	ram.debug_jump(5) # CLEAN
	await _frames(2)
	_check(ram._skip_opt_btn != null and ram._skip_opt_btn.visible, "CLEAN ไม่จำเป็น → มีปุ่มข้าม")
	_check(ram.skip_optional_phase() and ram.current_phase == 6 and (ram.scenario_stats.skipped as Array).has("CLEAN"), "ข้าม CLEAN → ไป INSTALL")
	await _frames(2)
	_check(ram._skip_opt_btn == null, "INSTALL ไม่มีปุ่มข้าม")
	var rep: Dictionary = ram.scenario_report()
	_check(rep.id == "ram_r2_loose" and not rep.first_try and rep.wrong == 1 and rep.skipped == ["CLEAN"], "รายงานผลสถานการณ์")
	ram.queue_free()
	await _frames(2)

	# G · มินิเกมการ์ดจอ (G-3): ตรวจครบ → แผงถามสาเหตุ → ตอบถูกแล้วไปขั้นต่อไป · ไม่มีสถานการณ์ = เหมือนเดิม
	var any_gpu: CustomerCase = load("res://Resources/Customers/any_gpu.tres")
	var g3 := ScenarioBook.by_id(&"gpu_g3_hdmi")
	var gjob := any_gpu.instance_for(NpcBook.by_id(&"bew"))
	gjob.apply_scenario({ "scenario": g3, "trait": &"normal", "condition": &"new" }, e)
	var gpu: PartMinigame = load("res://Scene/MiniGame/PartGpu/part_gpu.tscn").instantiate()
	gpu.set_meta("work_order", gjob)
	add_child(gpu)
	await _frames(3)
	_check((gpu.dialog_dict["BRIEFING"] as Array).size() == 3 and not (gpu.dialog_dict["BRIEFING"][2] as DialogToken).dialog.contains("ลืมต่อสาย"), "ไม่ใช่เคสเดิม → บทบรีฟไม่บอกสาเหตุเดิม")
	_check(gpu.current_phase == 1, "เริ่มที่ INSPECT")
	gpu._advance_phase()
	await _frames(1)
	_check(gpu.current_phase == 1 and gpu._diag_panel != null and gpu._diag_panel.visible, "ตรวจเสร็จ → แผงถามสาเหตุ (ยังไม่ไปขั้นต่อไป)")
	var right: Button = null
	var wrong_b: Button = null
	for b in gpu._diag_panel.get_child(0).get_children():
		if b is Button:
			if b.text == g3.diag_choices[0]:
				right = b
			elif wrong_b == null:
				wrong_b = b
	wrong_b.pressed.emit()
	_check(wrong_b.disabled and int(gpu._mistakes.get(&"diagnosis", 0)) == 10, "ตอบผิด → ปุ่มนั้นปิด · หัก 10")
	right.pressed.emit()
	gpu._diag_advancing = false
	gpu._advance_phase()
	await _frames(2)
	_check(not gpu._diag_panel.visible and gpu.current_phase == 2, "ตอบถูก → ไป BRIEFING")
	gpu.queue_free()
	await _frames(2)
	var plain: PartMinigame = load("res://Scene/MiniGame/PartGpu/part_gpu.tscn").instantiate()
	add_child(plain)
	await _frames(2)
	plain._advance_phase()
	await _frames(2)
	_check(plain.scenario == null and plain.current_phase == 2 and plain._diag_panel == null, "ไม่มีสถานการณ์ → เล่นแบบเดิม")
	plain.queue_free()
	await _frames(2)

	# H · ทุกสถานการณ์เปิดมินิเกมได้ · ขั้นที่ข้ามได้มีอยู่จริงใน Part · บทที่เปลี่ยนมี header จริงในไฟล์ปิ๊บ
	bad.clear()
	for p in parts:
		for s in ScenarioBook.all_of(p):
			var cc := CustomerCase.new()
			cc.part_id = String(p)
			cc.apply_scenario({ "scenario": s, "trait": &"normal", "condition": &"new" }, e)
			var m: PartMinigame = load(cc.scene_path()).instantiate()
			var orig := PhaseDialogParser.parse(m.dialog_path if m.dialog_path != "" else "")
			m.set_meta("work_order", cc)
			add_child(m)
			await _frames(2)
			if m.scenario != s:
				bad.append("%s ไม่ถึงมินิเกม" % s.id)
			var names := []
			for ph in m._phase_nodes:
				names.append(m._phase_name(ph))
			for op in s.optional_phases:
				if not names.has(op):
					bad.append("%s: ไม่มี phase %s" % [s.id, op])
			if not orig.is_empty():
				for h in s.lines:
					if not orig.has(h):
						bad.append("%s: header %s ไม่มีในไฟล์ปิ๊บ" % [s.id, h])
			m.queue_free()
			await _frames(1)
	_check(bad.is_empty(), "ทุกสถานการณ์เปิดมินิเกมได้ · phase/header ตรง %s" % ", ".join(bad))

	# I · จดผล: DayLoop._log_scenario → scenario_log · บรรทัดบนการ์ดผล
	gs.scenario_log.clear()
	DayLoop.quiet = true
	job.set_meta("scenario_report", rep)
	DayLoop._log_scenario(job, { "score": 80 })
	_check(gs.scenario_log.size() == 1 and gs.scenario_log[0].id == "ram_r2_loose" and int(gs.scenario_log[0].skipped) == 1, "จดผลลง scenario_log")
	_check(DayLoop.scenario_line(job).contains(r2s.cause) and DayLoop.scenario_line(job).contains("ผิด 1"), "การ์ดผลบอกสาเหตุ + วินิจฉัยผิดกี่ครั้ง")
	DayLoop.quiet = false

	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _seeded(n: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = n
	return r


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
