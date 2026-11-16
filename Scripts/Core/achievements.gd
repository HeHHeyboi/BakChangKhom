extends Node
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น J] ใบประกาศ (Achievement) — autoload "Achievements" (PLAN_0_7_0 ข้อ 5)
## เงื่อนไขส่วนใหญ่อ่านค่าที่ GameState เก็บอยู่แล้ว (scenario_log · request_log · npc_affinity · month_results · event_state · …)
## ตัวนับที่ไม่มีที่อื่นเก็บ → GameState.ach_stats (ฟัง repair_recorded) · ได้แล้วเก็บ 2 ชั้น: ต่อเซฟ (GameState.achievements) + ทั้งโปรไฟล์ (user://achievements.cfg)
## ตรวจทุก CHECK_EVERY วินาที (ไม่ต้องเรียกจากทุกระบบ) + DayLoop เรียก check_all() หลังอีเวนต์/ร้านปลอม · ป๊อปอัปรอจนออกจากมินิเกม/บทพูด

signal unlocked(a: Achievement)

const DIR := "res://Resources/Achievement/"
const PROFILE := "user://achievements.cfg"
const CORE_PARTS: Array[StringName] = [&"part_ram", &"part_mainboard", &"part_gpu", &"part_front_panel", &"part_bios"]
const CHECK_EVERY := 1.0
const POPUP_SECONDS := 3.0

## ปิดการตรวจอัตโนมัติ (เทสต์บางชุด)
var auto_check := true
var _all: Array[Achievement] = []
var _t := 0.0
var _queue: Array[Achievement] = []
var _layer: CanvasLayer
var _popup: PanelContainer
var _popup_title: Label
var _popup_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_popup()
	if has_node(^"/root/GameState"):
		GameState.repair_recorded.connect(_on_repair)


func all() -> Array[Achievement]:
	if _all.is_empty():
		for f in DirAccess.get_files_at(DIR):
			var p := DIR + f.trim_suffix(".remap")
			if p.ends_with(".tres"):
				var a := load(p) as Achievement
				if a:
					_all.append(a)
		_all.sort_custom(func(x: Achievement, y: Achievement) -> bool: return String(x.id) < String(y.id))
	return _all


func by_id(id: StringName) -> Achievement:
	for a in all():
		if a.id == id:
			return a
	return null


func has(id: StringName) -> bool:
	return GameState.achievements.has(String(id))


func count() -> int:
	return GameState.achievements.size()


func _process(delta: float) -> void:
	_tick_popup(delta)
	if not auto_check:
		return
	_t += delta
	if _t < CHECK_EVERY:
		return
	_t = 0.0
	if Global.on_start:
		return
	check_all()


## ตรวจทุกใบ · คืน id ที่เพิ่งได้
func check_all() -> Array[StringName]:
	var got: Array[StringName] = []
	for a in all():
		if has(a.id):
			continue
		var p := progress(a)
		if p.x >= p.y:
			unlock(a)
			got.append(a.id)
	return got


func unlock(a: Achievement) -> void:
	if a == null or has(a.id):
		return
	var when := GameState._ledger_when()
	GameState.achievements[String(a.id)] = { "month": when.x, "day": when.y }
	var dl := get_node_or_null(^"/root/DayLoop")
	var bot := dl != null and bool(dl.get("quiet"))
	if not bot: # บอท/เทสต์ (quiet) ไม่เขียนโปรไฟล์ผู้เล่น/ไม่ขึ้นป๊อปอัป
		_save_profile(a)
		_append_csv(a, when)
		_queue.append(a)
	unlocked.emit(a)


## ความคืบหน้า (ค่าตอนนี้, เป้า)
func progress(a: Achievement) -> Vector2i:
	return Vector2i(mini(_value(a), a.target), a.target)


func _value(a: Achievement) -> int:
	var gs := GameState
	var st: Dictionary = gs.event_state
	var ach: Dictionary = gs.ach_stats
	match a.check:
		&"passes":
			return int(ach.get("passes", 0))
		&"parts_all":
			return CORE_PARTS.filter(func(p: StringName) -> bool: return int(gs.part_clears.get(p, 0)) > 0).size()
		&"part_three":
			return int(ach.get("three_" + String(a.arg), 0))
		&"diag_first":
			return gs.scenario_log.filter(func(r: Dictionary) -> bool: return bool(r.get("first_try", false))).size()
		&"scen_all":
			var ids := { }
			for r in gs.scenario_log:
				ids[String(r.get("id", ""))] = true
			ids.erase("")
			return ids.size()
		&"skip_ok":
			return gs.scenario_log.filter(func(r: Dictionary) -> bool: return int(r.get("skipped", 0)) > 0).size()
		&"safe_streak":
			return int(ach.get("safe_best", 0))
		&"no_hint":
			return int(ach.get("no_hint", 0))
		&"rank":
			return gs.rank()
		&"month1":
			return 1 if gs.month_results.any(func(r: Dictionary) -> bool: return int(r.get("m", 0)) == 1 and bool(r.get("reached", false))) else 0
		&"months_hit":
			return gs.month_results.filter(func(r: Dictionary) -> bool: return bool(r.get("reached", false))).size()
		&"over":
			return 1 if gs.month_results.any(func(r: Dictionary) -> bool: return bool(r.get("over", false))) else 0
		&"bills_clean":
			if gs.month_results.any(func(r: Dictionary) -> bool: return int(r.get("debt", 0)) > 0):
				return 0
			return gs.month_results.size()
		&"no_ot_month":
			for r in gs.month_results:
				if bool(r.get("reached", false)) and _ot_in(int(r.get("m", 0))) == 0:
					return 1
			return 0
		&"upgrades":
			return gs.upgrades.size()
		&"stat":
			return int(st.get(String(a.arg), 0)) if st.get(String(a.arg), 0) is int else (1 if bool(st.get(String(a.arg), false)) else 0)
		&"rep":
			return gs.reputation
		&"req_good":
			return gs.request_log.filter(func(r: Dictionary) -> bool: return int(r.get("right", 0)) >= int(r.get("steps", 1))).size()
		&"on_time":
			return int(ach.get("on_time", 0))
		&"honest":
			var ok := { }
			for r in gs.scenario_log:
				if String(r.get("id", "")) in ["mb_m3_pins", "fp_f3_led"] and bool(r.get("first_try", false)):
					ok[String(r.id)] = true
			return ok.size()
		&"aff_count":
			var lim := int(String(a.arg)) if String(a.arg) != "" else 40
			var n := 0
			for id in gs.npc_affinity:
				var npc := NpcBook.by_id(id)
				if npc and npc.has_affinity and not npc.is_group() and int(gs.npc_affinity[id]) >= lim:
					n += 1
			return n
		&"aff_max":
			var best := 0
			for id in gs.npc_affinity:
				var npc := NpcBook.by_id(id)
				if npc and npc.has_affinity and not npc.is_group():
					best = maxi(best, int(gs.npc_affinity[id]))
			return best
		&"gang_all":
			return [&"bew", &"tonkla", &"praew"].filter(func(id: StringName) -> bool: return int(gs.npc_affinity.get(id, 0)) >= 60).size()
		&"group_fair":
			return gs.group_fair_count
		&"stories":
			var n := 0
			for id in gs.npc_stories_seen:
				n += (gs.npc_stories_seen[id] as Array).size()
			return n
		&"referrals":
			var n := 0
			for npc in NpcBook.all():
				if npc.unlock_by != null and npc.unlock_by_affinity > 0 and int(gs.npc_affinity.get(npc.unlock_by.id, 0)) >= npc.unlock_by_affinity:
					n += 1
			return n
		&"race_first":
			return 1 if int(st.get("race_best", 0)) == 1 else 0
		&"no_ot_year":
			if gs.month_results.size() < 12:
				return 0
			return 1 if gs.ledger.all(func(e: Dictionary) -> bool: return e.kind != &"ot_power") else 0
		&"ending": # [0.8.0] ได้ฉากจบนี้ (arg = stay/coworking/city/failure)
			return 1 if gs.ending == StringName(a.arg) else 0
		&"gifts": # [0.8.0] ของขวัญสิ้นปี
			return gs.gifts_received.size()
		&"group_all": # [0.8.0] สมาชิกกลุ่ม (arg = id กลุ่ม) ที่สนิท ≥ 60
			var g := NpcBook.by_id(StringName(a.arg))
			if g == null:
				return 0
			return g.member_ids().filter(func(id: StringName) -> bool: return gs.affinity(id) >= 60).size()
		&"no_miss_year":
			if gs.month_results.size() < 12:
				return 0
			return 1 if gs.month_results.all(func(r: Dictionary) -> bool: return bool(r.get("reached", false))) else 0
	return 0


func _ot_in(m: int) -> int:
	var n := 0
	for e in GameState.ledger:
		if int(e.ch) == m and e.kind == &"ot_power":
			n += 1
	return n


## ผลงานซ่อม → ตัวนับ (ผ่าน · 3 ดาวต่อ Part · ไม่ทำของเสียติดกัน)
func _on_repair(r: Dictionary) -> void:
	var ach: Dictionary = GameState.ach_stats
	var e := GameState.economy
	var grade := int(r.get("grade", 0))
	if bool(r.get("gave_up", false)):
		return
	if grade != GameState.Grade.FAIL:
		ach["passes"] = int(ach.get("passes", 0)) + 1
	if grade == GameState.Grade.GOOD and e and int(r.get("score", 0)) >= e.three_star_score:
		var k := "three_" + String(r.get("part_id", ""))
		ach[k] = int(ach.get(k, 0)) + 1
	if bool(r.get("damaged", false)):
		ach["safe_streak"] = 0
	else:
		ach["safe_streak"] = int(ach.get("safe_streak", 0)) + 1
		ach["safe_best"] = maxi(int(ach.get("safe_best", 0)), int(ach.safe_streak))


## ตัวนับจากระบบอื่น (มินิเกม · ชั้นวาง)
func bump(stat: String, n := 1) -> void:
	GameState.ach_stats[stat] = int(GameState.ach_stats.get(stat, 0)) + n


## แอป "ใบประกาศ" ← { title, rows: [{ id, title, desc, category, got, when, hidden, cur, target, reward }] }
func view() -> Dictionary:
	var rows: Array = []
	for a in all():
		var got := has(a.id)
		var p := progress(a)
		var w: Dictionary = GameState.achievements.get(String(a.id), { })
		rows.append({
			"id": String(a.id), "title": a.title if got or not a.hidden else "???", "desc": a.desc if got or not a.hidden else "ใบลับ — ลองเล่นแบบต่าง ๆ ดูนะ",
			"category": a.category_name(), "cat": int(a.category), "got": got, "hidden": a.hidden,
			"when": ("ได้เมื่อ %s" % _when_text(w)) if got else "", "cur": p.x, "target": p.y, "reward": a.reward_text,
		})
	return { "title": "ใบประกาศ · ได้แล้ว %d/%d · ทุกเซฟรวม %d" % [count(), all().size(), profile_count()], "rows": rows }


func _when_text(w: Dictionary) -> String:
	var m := clampi(int(w.get("month", 1)), 1, 12)
	return "%s วันที่ %d" % [TimeSystem.MONTH_NAME[m - 1], int(w.get("day", 1))]


# ---------------------------------------------------------------- โปรไฟล์ (ลบเซฟไม่หาย)


func _save_profile(a: Achievement) -> void:
	var cf := ConfigFile.new()
	cf.load(PROFILE)
	if not cf.has_section_key("unlocked", String(a.id)):
		cf.set_value("unlocked", String(a.id), Time.get_datetime_string_from_system())
		cf.save(PROFILE)


func profile_count() -> int:
	var cf := ConfigFile.new()
	if cf.load(PROFILE) != OK or not cf.has_section("unlocked"):
		return 0
	return cf.get_section_keys("unlocked").size()


func _append_csv(a: Achievement, when: Vector2i) -> void:
	Playlog.append("achievements.csv", ["chapter", "day", "id", "title"], [when.x, when.y, String(a.id), a.title]) # [0.9.0]


# ---------------------------------------------------------------- ป๊อปอัปมุมขวาบน


func _build_popup() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 120
	add_child(_layer)
	_popup = PanelContainer.new()
	_popup.name = "AchievementPopup"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.95, 0.82)
	sb.border_color = Color(0.72, 0.52, 0.16)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
	_popup.add_theme_stylebox_override(&"panel", sb)
	_popup.anchor_left = 1.0
	_popup.anchor_right = 1.0
	_popup.offset_left = -330
	_popup.offset_right = -16
	_popup.offset_top = 116
	_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_popup)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 10)
	_popup.add_child(hb)
	var ic := TextureRect.new()
	ic.texture = Icons.tex(&"trophy")
	ic.custom_minimum_size = Vector2(44, 44)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(ic)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	var head := Label.new()
	head.text = "ได้ใบประกาศใหม่!"
	head.add_theme_font_size_override(&"font_size", 14)
	head.add_theme_color_override(&"font_color", Color(0.55, 0.35, 0.1))
	vb.add_child(head)
	_popup_title = Label.new()
	_popup_title.add_theme_font_size_override(&"font_size", 18)
	_popup_title.add_theme_color_override(&"font_color", Color(0.25, 0.15, 0.08))
	_popup_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_popup_title)
	_popup.hide()


func _tick_popup(delta: float) -> void:
	if _popup.visible:
		_popup_time -= delta
		if _popup_time <= 0.0:
			_popup.hide()
		return
	if _queue.is_empty() or Global.in_minigame or (has_node(^"/root/DialogScene") and DialogScene.visible):
		return
	var a: Achievement = _queue.pop_front()
	_popup_title.text = a.title
	_popup_time = POPUP_SECONDS
	_popup.show()
	var au := get_node_or_null(^"/root/Audio")
	if au:
		au.sfx(&"coin")
