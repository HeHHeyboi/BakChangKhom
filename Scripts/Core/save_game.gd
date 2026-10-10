class_name SaveGame extends RefCounted
## บันทึกเกมอัตโนมัติ (ไฟล์เดียว user://save.json) · [Claude 10 ต.ค. 2569]
## เก็บ: เงิน/XP/ชื่อเสียง/ดาวต่อระดับ (GameState) · กะ + ชม.งาน (TimeSystem) · กระดานงาน + สถานะเดโม (DayLoop)
##       ขั้นเควสต์หลัก (EventManager) · ฉากที่อยู่ (SceneRouter)
## บันทึกเมื่อ: เปลี่ยนฉาก · เริ่มกะใหม่ · ส่งงานลูกค้าเสร็จ · กลับเมนูหลัก (DayLoop.autosave)
## โหลด: ปุ่ม "เล่นต่อ" ในเมนูหลัก · เริ่มเกมใหม่ = ลบเซฟเดิม

const PATH := "user://save.json"
const VERSION := 1
## เทสต์อื่น (ซีนใน res://Test/) ไม่บันทึกทับเซฟของผู้เล่น · save_test ตั้งเป็น true
static var allow_in_tests := false


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## ข้อมูลย่อสำหรับปุ่มเล่นต่อ { shift, money, rank } · ไม่มีเซฟ = {}
static func info() -> Dictionary:
	var d := _read()
	if d.is_empty():
		return { }
	return { "shift": int(d.get("time", { }).get("shift", 1)), "money": int(d.get("game", { }).get("money", 0)) }


static func save() -> bool:
	var cur := (Engine.get_main_loop() as SceneTree).current_scene
	if not allow_in_tests and cur and cur.scene_file_path.begins_with("res://Test/"):
		return false
	var ts: TimeSystem = EventManager.time_system
	var ev = EventManager.eventMap.get(EventManager.EventID.MAIN)
	var board := []
	for j in DayLoop.board:
		var c: CustomerCase = j.get("case")
		if c and c.resource_path != "":
			board.append({ "case": c.resource_path, "due_shift": int(j.get("due_shift", 0)), "phone": bool(j.get("phone", false)) })
	var stars := { }
	for k in GameState.level_stars:
		stars[str(k)] = GameState.level_stars[k]
	var clears := { }
	for k in GameState.part_clears:
		clears[String(k)] = GameState.part_clears[k]
	var d := {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"game": {
			"money": GameState.money, "xp": GameState.xp, "reputation": GameState.reputation,
			"satisfaction": Array(GameState.satisfaction_history), "part_clears": clears, "story_flags": GameState.story_flags,
			"level_stars": stars, "debt": GameState.debt, "village_fund": GameState.village_fund, "ending": String(GameState.ending),
		},
		"time": { "shift": ts.shift if ts else 1, "worked": ts.worked_minutes_month if ts else 0 },
		"loop": {
			"board": board, "ot_this_week": DayLoop.ot_this_week, "parts_seen": DayLoop._parts_seen.keys().map(func(k): return String(k)),
			"break_done": DayLoop._break_done, "demo_over": DayLoop.demo_over, "demo_ack": DayLoop._demo_ack,
			"week_start_money": DayLoop.week_start_money, "force_active": DayLoop.force_active,
		},
		"quest": { "task": ev.currentTask if ev else 0, "done": ev.isDone if ev else false },
		"location": int(SceneRouter.current_id),
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveGame: เขียนไฟล์ไม่ได้ (%d)" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(d, "\t"))
	return true


## โหลดค่าเข้าเกม · คืน location id ที่ต้องไป (-1 = โหลดไม่ได้)
static func load_into() -> int:
	var d := _read()
	if d.is_empty():
		return -1
	var g: Dictionary = d.get("game", { })
	GameState.reset()
	GameState.money = int(g.get("money", GameState.money))
	GameState.xp = int(g.get("xp", 0))
	GameState.reputation = int(g.get("reputation", GameState.reputation))
	GameState.satisfaction_history.clear()
	for v in g.get("satisfaction", []):
		GameState.satisfaction_history.append(int(v))
	for k in g.get("part_clears", { }):
		GameState.part_clears[StringName(k)] = int(g.part_clears[k])
	GameState.story_flags = g.get("story_flags", { })
	for k in g.get("level_stars", { }):
		GameState.level_stars[int(k)] = int(g.level_stars[k])
	GameState.debt = int(g.get("debt", 0))
	GameState.village_fund = int(g.get("village_fund", 0))
	GameState.ending = StringName(g.get("ending", ""))
	GameState.money_changed.emit(GameState.money, 0)
	GameState.reputation_changed.emit(GameState.reputation, 0)

	var t: Dictionary = d.get("time", { })
	var ts: TimeSystem = EventManager.time_system
	if ts:
		ts.set_shift(int(t.get("shift", 1)))
		ts.worked_minutes_month = int(t.get("worked", 0))

	var l: Dictionary = d.get("loop", { })
	DayLoop.board.clear()
	for j in l.get("board", []):
		if ResourceLoader.exists(String(j.case)):
			DayLoop.board.append({ "case": load(String(j.case)), "due_shift": int(j.due_shift), "phone": bool(j.phone) })
	DayLoop.ot_this_week = int(l.get("ot_this_week", 0))
	DayLoop._parts_seen.clear()
	for k in l.get("parts_seen", []):
		DayLoop._parts_seen[StringName(k)] = true
	DayLoop._break_done = bool(l.get("break_done", false))
	DayLoop.demo_over = bool(l.get("demo_over", false))
	DayLoop._demo_ack = bool(l.get("demo_ack", false))
	DayLoop.week_start_money = int(l.get("week_start_money", GameState.money))
	DayLoop.shift_start_money = GameState.money
	DayLoop.force_active = bool(l.get("force_active", false))
	DayLoop._board_dirty = true
	if DayLoop._demo_ack:
		DayLoop._show_demo_banner(true)

	var q: Dictionary = d.get("quest", { })
	var ev = EventManager.eventMap.get(EventManager.EventID.MAIN)
	if ev:
		EventManager.currentEvent = EventManager.EventID.MAIN
		if bool(q.get("done", false)):
			ev.set_step(ev.totalTask - 1)
			ev._tasks[ev.totalTask - 1].set_done()
			ev.currentTask = ev.totalTask
			ev.isDone = true
			EventManager.questboard.update_task("", ev)
			EventManager.questboard.show()
			EventManager.time_system.show()
			EventManager.sendUpdatedEvent.emit(EventManager.EventID.MAIN, ev)
		else:
			EventManager.jump_event(EventManager.EventID.MAIN, int(q.get("task", 0)))
	var loc := int(d.get("location", SceneRouter.HOME))
	return loc if SceneRouter.LOCATIONS.has(loc) else SceneRouter.HOME


static func _read() -> Dictionary:
	if not exists():
		return { }
	var txt := FileAccess.get_file_as_string(PATH)
	var d = JSON.parse_string(txt)
	if not d is Dictionary or int(d.get("version", 0)) != VERSION:
		return { }
	return d
