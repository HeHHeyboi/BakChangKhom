extends Node
## [Claude 15 พ.ย. 2569 · 0.5.0 ขั้น A] ลูกค้าประจำ + ความสนิท — ข้อมูลล้วน (NpcBook · GameState · เซฟ v6)
## เปิด Test/npc_test.tscn → F6 → Output ต้องจบด้วย "T DONE fails=0"

var fails := 0


func _ready() -> void:
	var gs := GameState
	var e: EconomyConfig = gs.economy
	gs.reset()

	# A · ข้อมูล NPC 10 คน · ชื่อตรง _CharacterMap
	var all := NpcBook.all()
	_check(all.size() == 10, "มีลูกค้าประจำ 10 คน (%d)" % all.size())
	var chars: Array = Global._CharacterMap.keys()
	var bad := PackedStringArray()
	for n in all:
		for p in n.problems(chars):
			bad.append("%s: %s" % [n.id, p])
	_check(bad.is_empty(), "ข้อมูล NPC ไม่มีปัญหา %s" % ", ".join(bad))
	_check(NpcBook.of_name("เด็กหญิง").display_name == "น้องฝ้าย" and NpcBook.of_name("เด็ก").id == &"bew", "เด็กหญิง = น้องฝ้าย · เด็ก = น้องบิว")
	_check(NpcBook.of_name("คนแปลกหน้า") == null, "ชื่อที่ไม่มีไฟล์ = ลูกค้าขาจร")

	# B · ทุกเคสในคลังโยงหา NPC ได้
	var miss := PackedStringArray()
	var count := 0
	for f in DirAccess.get_files_at("res://Resources/Customers/"):
		var path := "res://Resources/Customers/" + f.trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var c := load(path) as CustomerCase
		if c == null:
			continue
		count += 1
		if NpcBook.of_case(c) == null:
			miss.append("%s (%s)" % [f, c.customer])
	_check(count >= 60 and miss.is_empty(), "เคส %d ไฟล์โยงหา NPC ได้ทุกไฟล์ %s" % [count, ", ".join(miss)])

	# C · ค่าเริ่ม · ยายไม่มีค่าความสนิท
	_check(gs.affinity(&"min") == 50 and gs.affinity(&"amnuay") == 20 and gs.affinity(&"fai") == 0, "ค่าเริ่ม: มิ้น 50 · ลุงอำนวย 20 · น้องฝ้าย 0")
	_check(gs.affinity_tier(&"min") == 2 and gs.affinity_tier_name(&"amnuay") == "รู้จัก" and gs.affinity_tier_name(&"fai") == "แปลกหน้า", "ระดับ: มิ้น คุ้นเคย · ลุงอำนวย รู้จัก · น้องฝ้าย แปลกหน้า")
	_check(not gs.has_affinity(&"yai") and gs.add_affinity(&"yai", 10) == 0 and gs.affinity(&"yai") == 0, "ยายไม่มีค่าความสนิท")
	_check(gs.add_affinity(&"nobody", 10) == 0, "id ที่ไม่มี = ไม่เปลี่ยน")

	# D · ได้/เสีย · เพดาน · สัญญาณขึ้นระดับ
	var ups := []
	var changes := []
	var on_up := func(id: StringName, tier: int) -> void: ups.append([id, tier])
	var on_change := func(id: StringName, v: int, d: int, r: StringName) -> void: changes.append([id, v, d, r])
	gs.affinity_tier_up.connect(on_up)
	gs.affinity_changed.connect(on_change)
	var g := e.affinity_gain
	_check(gs.affinity_event(&"amnuay", &"pass") == g[&"pass"] and gs.affinity(&"amnuay") == 20 + g[&"pass"], "ซ่อมผ่าน +%d → %d" % [g[&"pass"], 20 + g[&"pass"]])
	_check(changes.size() == 1 and changes[0][3] == &"pass" and ups.is_empty(), "สัญญาณเปลี่ยนค่า 1 ครั้ง · ยังไม่ขึ้นระดับ")
	gs.add_affinity(&"amnuay", 41 - gs.affinity(&"amnuay"))
	_check(gs.affinity(&"amnuay") == 41 and ups.size() == 1 and ups[0] == [&"amnuay", 2], "ถึง 41 → ขึ้นระดับคุ้นเคย (สัญญาณ 1 ครั้ง)")
	var late2: int = g[&"late_day"] * 2
	_check(gs.affinity_event(&"amnuay", &"late_day", 2) == late2 and gs.affinity(&"amnuay") == 41 + late2 and ups.size() == 1, "เลยนัด 2 วัน %d → %d · ลดระดับไม่ยิงสัญญาณ" % [late2, 41 + late2])
	var amn := gs.affinity(&"amnuay")
	gs.add_affinity(&"min", 999)
	_check(gs.affinity(&"min") == 100 and gs.add_affinity(&"min", 5) == 0, "เพดาน 100")
	gs.add_affinity(&"fai", -50)
	_check(gs.affinity(&"fai") == 0 and gs.affinity_hearts(&"amnuay") == snappedf(amn / 20.0, 0.5) and gs.affinity_hearts(&"min") == 5.0, "พื้น 0 · หัวใจ %d → %.1f ดวง · 100 → 5 ดวง" % [amn, gs.affinity_hearts(&"amnuay")])
	gs.affinity_tier_up.disconnect(on_up)
	gs.affinity_changed.disconnect(on_change)
	var ch := gs._ledger_when().x
	var gains := gs.affinity_gains(ch)
	_check(int(gains.get(&"amnuay", 0)) == amn - 20 and int(gains.get(&"min", 0)) == 50, "สรุปที่ได้ในบท: ลุงอำนวย %+d · มิ้น +50" % (amn - 20))

	# E · มาร้านล่าสุด · ประวัติเครื่อง
	gs.note_visit(&"teacher", 3)
	_check(gs.met(&"teacher") and not gs.met(&"director"), "จำว่าเคยเจอครู · ยังไม่เจอ ผอ.")
	_check(gs.visited_recently(&"teacher", 5) and not gs.visited_recently(&"teacher", 6), "มาวันที่ 3 → วันที่ 5 ยังนับว่าเพิ่งมา · วันที่ 6 ไม่นับ")
	for k in 7:
		gs.add_npc_history(&"teacher", "งาน %d" % k)
	var h: Array = gs.npc_history[&"teacher"]
	_check(h.size() == e.npc_history_max and h[-1].text == "งาน 6", "ประวัติเก็บ %d รายการล่าสุด" % e.npc_history_max)
	gs.mark_story_seen(&"teacher", 40)
	_check(gs.story_seen(&"teacher", 40) and not gs.story_seen(&"teacher", 60), "จำเรื่องส่วนตัวที่ฟังแล้ว")

	# F · เซฟ v6 → โหลดกลับครบ
	SaveGame.allow_in_tests = true
	_check(SaveGame.VERSION == 6 and SaveGame.save(), "บันทึกเซฟ v6")
	gs.reset()
	_check(gs.affinity(&"amnuay") == 20 and not gs.met(&"teacher"), "reset → ค่าเริ่ม")
	SaveGame.load_into()
	_check(gs.affinity(&"amnuay") == amn and gs.affinity(&"min") == 100 and gs.met(&"teacher") and gs.story_seen(&"teacher", 40), "โหลด → ความสนิท · มาร้านล่าสุด · เรื่องที่ฟัง")
	_check((gs.npc_history[&"teacher"] as Array).size() == e.npc_history_max and int(gs.affinity_gains(gs._ledger_when().x).get(&"amnuay", 0)) == amn - 20, "โหลด → ประวัติเครื่อง · บันทึกความสนิท")
	SaveGame.clear()
	SaveGame.allow_in_tests = false

	gs.reset()
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  ok  ", msg)
	else:
		fails += 1
		print("  FAIL ", msg)
