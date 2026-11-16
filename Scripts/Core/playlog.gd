extends Node
## [Claude 16 พ.ย. 2569 · 0.9.0] ข้อมูลการเล่นสำหรับเล่มรายงาน (autoload Playlog) — ดู claude/PLAN_0_9_0.md
## - ทุกไฟล์ CSV ใน user://playlog/ ขึ้นต้นด้วย time · game_version (append) · หัวตารางเก่าไม่ตรง = ย้ายไฟล์เก่าเป็น *_old_<เวลา>.csv
## - session.csv = ช่วงที่เล่นจริง (ออกจากเมนูหลัก → กลับเมนู/ปิดเกม/ส่งออก) · นับเวลาเฉพาะตอนหน้าต่างโฟกัสและไม่พักเกม → GameState.playtime_sec
## - export_zip() รวม playlog + เซฟ + โปรไฟล์ใบประกาศ เป็น zip ในโฟลเดอร์เอกสาร (เว็บ = ดาวน์โหลด) · ปุ่มในเมนูหลัก/เมนูพัก
## - [ผู้ใช้ 16 พ.ย.] ในเกมไม่มีหน้ารหัสผู้ทดสอบ/แบบทดสอบ/ฟอร์ม — แบบทดสอบก่อน–หลังเล่นเป็น Google Form นอกเกม · ทีมจับคู่ zip กับคำตอบฟอร์มเอง (Docs/TESTER_GUIDE.md)
## บอท/เทสต์ (DayLoop.quiet หรือซีนใน res://Test/) ไม่เขียน session.csv · allow_in_tests = true ให้ playlog_test

const DIR := "user://playlog"
## ไฟล์จากเวอร์ชันก่อน 0.9.0 ที่อยู่นอกโฟลเดอร์ playlog (ใส่ zip ด้วยถ้ามี)
const LEGACY := ["user://learn_log.csv", "user://scenario_log.csv"]
const EXTRA := ["user://save.json", "user://achievements.cfg"]
const SESSION_COLS := ["start", "seconds", "reason", "chapter", "date", "shift", "total_playtime", "money", "rank", "ending"]

static var allow_in_tests := false

var _in_game := false
var _seg_start := ""
var _seg_sec := 0.0
var _focused := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
		NOTIFICATION_WM_CLOSE_REQUEST:
			end_session(&"quit")


func _exit_tree() -> void:
	end_session(&"quit")


func _process(delta: float) -> void:
	var playing: bool = not Global.on_start
	if playing and not _in_game:
		_begin()
	elif not playing and _in_game:
		end_session(&"menu")
	if _in_game and _focused and not get_tree().paused:
		_seg_sec += delta
		GameState.playtime_sec += delta


static func game_version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "dev"))


# ---------------------------------------------------------------- CSV


## เพิ่มแถวลง user://playlog/<file> · cols/values ไม่รวม time · game_version (ใส่ให้เอง)
static func append(file: String, cols: Array, values: Array) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := DIR.path_join(file)
	var header := ",".join(PackedStringArray(["time", "game_version"] + cols.map(func(c) -> String: return String(c))))
	if FileAccess.file_exists(path):
		var rf := FileAccess.open(path, FileAccess.READ)
		var first := rf.get_line().strip_edges() if rf else ""
		if rf:
			rf.close()
		if first != header: # รูปแบบเก่า → เก็บไว้ข้าง ๆ ไม่ปนกัน
			var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "")
			DirAccess.rename_absolute(path, path.get_basename() + "_old_" + stamp + ".csv")
	var fresh := not FileAccess.file_exists(path)
	var f := FileAccess.open(path, FileAccess.WRITE if fresh else FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	if fresh:
		f.store_line(header)
	var row: PackedStringArray = [Time.get_datetime_string_from_system(), _cell(game_version())]
	for v in values:
		row.append(_cell(v))
	f.store_line(",".join(row))
	f.close()


static func _cell(v: Variant) -> String:
	if v is bool:
		return "1" if v else "0"
	if v is float:
		return str(snappedf(v, 0.1))
	return str(v).replace(",", " ").replace("\n", " ").replace("\r", "")


static func read_rows(file: String) -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	var path := DIR.path_join(file)
	if not FileAccess.file_exists(path):
		return out
	for l in FileAccess.get_file_as_string(path).split("\n"):
		if l.strip_edges() != "":
			out.append(l.strip_edges().split(","))
	return out


# ---------------------------------------------------------------- session


func _quiet() -> bool:
	if allow_in_tests:
		return false
	if DayLoop.quiet:
		return true
	var cur := get_tree().current_scene if is_inside_tree() else null
	return cur != null and cur.scene_file_path.begins_with("res://Test/")


func _begin() -> void:
	_in_game = true
	_seg_start = Time.get_datetime_string_from_system()
	_seg_sec = 0.0


## ปิดช่วงเล่นปัจจุบัน → แถวใน session.csv (สั้นกว่า 1 วิ = ไม่จด)
func end_session(reason: StringName) -> void:
	if not _in_game:
		return
	_in_game = false
	if _seg_sec < 1.0 or not is_inside_tree() or _quiet():
		return
	var ts: TimeSystem = EventManager.time_system if EventManager else null
	append("session.csv", SESSION_COLS, [
		_seg_start, roundi(_seg_sec), String(reason),
		ts.chapter() if ts else 0, ts.date_text() if ts else "", ts.shift if ts else 0,
		roundi(GameState.playtime_sec), GameState.money, GameState.rank(), String(GameState.ending),
	])


## จดช่วงที่เล่นอยู่ตอนนี้แล้วเริ่มช่วงใหม่ (ก่อนส่งออก)
func flush(reason: StringName = &"export") -> void:
	if _in_game:
		end_session(reason)
		_begin()


# ---------------------------------------------------------------- ส่งออก


## ไฟล์ที่จะใส่ zip: [[ชื่อใน zip, path]]
static func collect() -> Array:
	var out: Array = []
	if DirAccess.dir_exists_absolute(DIR):
		for f in DirAccess.get_files_at(DIR):
			if f.get_extension() == "csv":
				out.append(["playlog/" + f, DIR.path_join(f)])
	for p in LEGACY + EXTRA:
		if FileAccess.file_exists(p):
			out.append(["old/" + p.get_file() if p in LEGACY else p.get_file(), p])
	return out


static func has_data() -> bool:
	return not collect().is_empty()


## รวมข้อมูลเป็น zip → { ok, path, folder, msg } · เดสก์ท็อป = โฟลเดอร์เอกสาร (ไม่ได้ = โฟลเดอร์ข้อมูลเกม) · เว็บ = ดาวน์โหลด
func export_zip(dest_dir := "") -> Dictionary:
	flush()
	var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_")
	var zname := "BakChangKhom_playlog_%s.zip" % stamp
	var web := OS.has_feature("web")
	var folder := dest_dir
	if folder == "":
		folder = "user://" if web else OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if folder == "" or not DirAccess.dir_exists_absolute(folder):
		folder = ProjectSettings.globalize_path("user://")
	var path := folder.path_join(zname)
	var z := ZIPPacker.new()
	if z.open(path) != OK:
		folder = ProjectSettings.globalize_path("user://")
		path = folder.path_join(zname)
		if z.open(path) != OK:
			return { "ok": false, "path": "", "folder": "", "msg": "บันทึกไฟล์ไม่ได้ · ลองปิดโปรแกรมที่เปิดไฟล์อยู่แล้วกดใหม่" }
	var n := 0
	for e in collect():
		z.start_file(String(e[0]))
		z.write_file(FileAccess.get_file_as_bytes(String(e[1])))
		z.close_file()
		n += 1
	z.start_file("info.txt")
	z.write_file(("game_version=%s\nexported=%s\nplaytime_sec=%d\nos=%s\nfiles=%d\n" % [
		game_version(), Time.get_datetime_string_from_system(), roundi(GameState.playtime_sec), OS.get_name(), n,
	]).to_utf8_buffer())
	z.close_file()
	z.close()
	if web:
		JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path), zname, "application/zip")
		return { "ok": true, "path": zname, "folder": "", "msg": "ดาวน์โหลด %s แล้ว" % zname }
	return { "ok": true, "path": path, "folder": folder, "msg": "บันทึก %s ไว้ที่ %s แล้ว" % [zname, folder] }


## ปุ่มส่งออก (เมนูหลัก · เมนูพัก) → ส่งออก + เปิดโฟลเดอร์ · คืนข้อความสั้นสำหรับปุ่ม
func export_and_show() -> String:
	var r := export_zip()
	if r.ok and String(r.folder) != "" and not DisplayServer.get_name() == "headless":
		OS.shell_show_in_file_manager(String(r.path))
	return String(r.msg)
