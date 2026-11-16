extends Node
## [Claude 16 พ.ย. 2569 · 0.9.0 ขั้น A] ข้อมูลการเล่นสำหรับเล่มรายงาน (autoload Playlog) — ดู claude/PLAN_0_9_0.md ข้อ 2.1–2.2
## - ทุกไฟล์ CSV ใน user://playlog/ ขึ้นต้นด้วย time · tester_id · game_version (append) · หัวตารางเก่าไม่ตรง = ย้ายไฟล์เก่าเป็น *_old_<เวลา>.csv
## - session.csv = ช่วงที่เล่นจริง (ออกจากเมนูหลัก → กลับเมนู/ปิดเกม/ส่งออก) · นับเวลาเฉพาะตอนหน้าต่างโฟกัสและไม่พักเกม → GameState.playtime_sec
## - รหัสผู้ทดสอบ (GameState.tester_id · เข้าเซฟ v10) · บิลด์ผู้ทดสอบ = feature tag "tester" หรือรันด้วย -- --tester
## - export_zip() รวม playlog + เซฟ + โปรไฟล์ใบประกาศ เป็น zip ในโฟลเดอร์เอกสาร (เว็บ = ดาวน์โหลด)
## - [ขั้น B] ฟอร์มก่อน/หลังเล่น (Google Form · ลิงก์ใน Resources/tester_config.tres) — หน้าก่อนเล่นหลังกรอกรหัส · ป๊อปอัปหลังเล่นเมื่อครบ post_after_months เดือน
## บอท/เทสต์ (DayLoop.quiet หรือซีนใน res://Test/) ไม่เขียน session.csv · allow_in_tests = true ให้ playlog_test

const DIR := "user://playlog"
## ไฟล์จากเวอร์ชันก่อน 0.9.0 ที่อยู่นอกโฟลเดอร์ playlog (ใส่ zip ด้วยถ้ามี)
const LEGACY := ["user://learn_log.csv", "user://scenario_log.csv"]
const EXTRA := ["user://save.json", "user://achievements.cfg"]
const ID_PATTERN := "^[A-Z]{1,3}[0-9]{1,3}$"
const CONFIG_PATH := "res://Resources/tester_config.tres"
const SESSION_COLS := ["start", "seconds", "reason", "chapter", "date", "shift", "total_playtime", "money", "rank", "ending"]

static var allow_in_tests := false

var _in_game := false
var _seg_start := ""
var _seg_sec := 0.0
var _focused := true
var _ask_layer: CanvasLayer
var _post_snoozed := false
var _check_t := 0.0
## เทสต์ปิดการเปิดเบราว์เซอร์จริง (จดลิงก์ที่จะเปิดไว้แทน)
var open_urls := true
var last_opened_url := ""
var config: TesterConfig


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	config = load(CONFIG_PATH) as TesterConfig if ResourceLoader.exists(CONFIG_PATH) else null
	if config == null:
		config = TesterConfig.new()


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
	_check_t += delta
	if _check_t >= 1.0:
		_check_t = 0.0
		if tester_build() and post_ready() and not _post_snoozed and _safe_moment():
			show_post_form()


# ---------------------------------------------------------------- ผู้ทดสอบ


## บิลด์ผู้ทดสอบ (export preset "Windows Tester" ใส่ feature tag tester) · ทีมลองได้ด้วย godot --path . -- --tester
static func tester_build() -> bool:
	return OS.has_feature("tester") or OS.get_cmdline_user_args().has("--tester")


## รหัสที่ใช้ได้ → ตัวพิมพ์ใหญ่ · ใช้ไม่ได้ = ""
static func normalize_id(s: String) -> String:
	var t := s.strip_edges().to_upper().replace(" ", "")
	var re := RegEx.create_from_string(ID_PATTERN)
	return t if re.search(t) else ""


static func game_version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "dev"))


## กล่องกลางจอ (CanvasLayer 125 · หยุดเกมไว้ระหว่างเปิด) → คืน VBox ไว้ใส่ของ
func _open_modal(title: String, body: String) -> VBoxContainer:
	close_modal()
	_ask_layer = CanvasLayer.new()
	_ask_layer.name = "TesterLayer"
	_ask_layer.layer = 125
	_ask_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ask_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ask_layer.add_child(dim)
	var p := PanelContainer.new()
	p.name = "Panel"
	p.custom_minimum_size = Vector2(520, 0)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.97, 0.9)
	sb.border_color = Color(0.6, 0.42, 0.2)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(20)
	p.add_theme_stylebox_override(&"panel", sb)
	_ask_layer.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	p.add_child(box)
	var head := Label.new()
	head.name = "Head"
	head.text = title
	head.add_theme_font_size_override(&"font_size", 26)
	head.add_theme_color_override(&"font_color", Color(0.35, 0.2, 0.08))
	box.add_child(head)
	var info := Label.new()
	info.name = "Body"
	info.text = body
	info.custom_minimum_size = Vector2(480, 0)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override(&"font_size", 17)
	info.add_theme_color_override(&"font_color", Color(0.4, 0.3, 0.2))
	box.add_child(info)
	return box


func _modal_button(box: VBoxContainer, bname: String, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.name = bname
	b.text = text
	b.custom_minimum_size = Vector2(0, 50)
	b.add_theme_font_size_override(&"font_size", 20)
	if cb.is_valid():
		b.pressed.connect(cb)
	box.add_child(b)
	return b


func modal_open() -> bool:
	return _ask_layer != null and is_instance_valid(_ask_layer)


func close_modal() -> void:
	if modal_open():
		_ask_layer.queue_free()
	_ask_layer = null


## กล่องกรอกรหัสผู้ทดสอบ · ตกลงแล้วเรียก done · ใส่ค่าเดิมไว้ให้
func ask_tester_id(done: Callable) -> void:
	var box := _open_modal("รหัสผู้ทดสอบ", "ใส่รหัสที่ทีมให้ (เช่น T01) · ใช้รหัสเดียวกับที่กรอกในแบบทดสอบ · เกมไม่เก็บชื่อจริง")
	var edit := LineEdit.new()
	edit.name = "IdEdit"
	edit.text = GameState.tester_id
	edit.placeholder_text = "T01"
	edit.max_length = 6
	edit.add_theme_font_size_override(&"font_size", 24)
	box.add_child(edit)
	var err := Label.new()
	err.name = "Error"
	err.add_theme_font_size_override(&"font_size", 15)
	err.add_theme_color_override(&"font_color", Color(0.75, 0.15, 0.1))
	box.add_child(err)
	var submit := func(_t := "") -> void:
		var id := normalize_id(edit.text)
		if id == "":
			err.text = "รหัสไม่ถูกแบบ · ตัวอักษร 1–3 ตัวตามด้วยตัวเลข เช่น T01"
			return
		GameState.tester_id = id
		close_modal()
		done.call()
	_modal_button(box, "Ok", "ตกลง", submit)
	edit.text_submitted.connect(submit)
	edit.grab_focus.call_deferred()


# ---------------------------------------------------------------- ฟอร์มก่อน/หลังเล่น (ขั้น B)


func _open_url(url: String) -> void:
	last_opened_url = url
	if open_urls and url != "":
		OS.shell_open(url)


func pre_url() -> String:
	return TesterConfig.fill(config.pre_form_url, GameState.tester_id)


func post_url() -> String:
	return TesterConfig.fill(config.post_form_url, GameState.tester_id)


## หน้าแบบทดสอบก่อนเล่น (หลังกรอกรหัส · ก่อนเริ่มเกมใหม่) · done.call(opened: bool) · ไม่มีลิงก์ = ข้ามเลย
func show_pre_form(done: Callable) -> void:
	if config.pre_form_url.strip_edges() == "":
		done.call(false)
		return
	var box := _open_modal("แบบทดสอบก่อนเล่น", "ก่อนเริ่มเล่น ช่วยทำแบบทดสอบก่อนเล่น (ประมาณ %d นาที) ในเบราว์เซอร์ก่อนนะ\nรหัส %s ใส่ในฟอร์มให้แล้ว · ทำเสร็จกดส่งแล้วกลับมากด \"ทำแล้ว เริ่มเล่น\"" % [config.pre_minutes, GameState.tester_id])
	var go := _modal_button(box, "Done", "ทำแล้ว เริ่มเล่น", func() -> void:
		close_modal()
		done.call(true))
	go.disabled = true
	var op := _modal_button(box, "Open", "เปิดแบบทดสอบก่อนเล่น", func() -> void:
		_open_url(pre_url())
		go.disabled = false)
	box.move_child(op, go.get_index())


## ถึงเวลาทำแบบทดสอบหลังเล่นแล้ว (ครบเดือน · ยังไม่ได้เปิดฟอร์ม)
func post_ready() -> bool:
	return GameState.month_results.size() >= config.post_after_months and not GameState.form_post_opened


## จังหวะที่ขึ้นป๊อปอัปได้: อยู่ในฉากเมือง/ร้าน · ไม่มีบทพูด มินิเกม หน้าสรุปเดือน เมนูพัก
func _safe_moment() -> bool:
	if not _in_game or get_tree().paused or Global.in_minigame or modal_open() or DayLoop.quiet:
		return false
	if DialogScene.visible:
		return false
	if DayLoop.month_summary and DayLoop.month_summary.visible:
		return false
	var cur := get_tree().current_scene
	return cur != null and cur.scene_file_path.begins_with("res://Scene/Location/")


## ป๊อปอัปหลังเล่น: ส่งออกไฟล์ข้อมูล + เปิดแบบทดสอบหลังเล่น (เปิดซ้ำได้จากเมนูพัก) · เล่นต่อ = ถามใหม่ครั้งหน้าที่เปิดเกม
func show_post_form() -> void:
	var has_url := config.post_form_url.strip_edges() != ""
	var box := _open_modal("ครบ %d เดือนแล้ว" % config.post_after_months,
		("ขอบคุณที่เล่นถึงตรงนี้ ช่วยทำ 2 อย่างนะ\n1) กดส่งออกข้อมูลการเล่น (ได้ไฟล์ zip ในโฟลเดอร์เอกสาร)\n2) ทำแบบทดสอบหลังเล่น + แบบสอบถาม (ประมาณ %d นาที) แล้วแนบไฟล์ zip ในฟอร์ม\nจากนั้นเล่นต่อได้ตามสบาย" % config.post_minutes)
		if has_url else "ขอบคุณที่เล่นถึงตรงนี้ · กดส่งออกข้อมูลการเล่น แล้วส่งไฟล์ zip ให้ทีมนะ (ทำแบบทดสอบหลังเล่นตามที่ทีมแจ้ง)")
	get_tree().paused = true
	var msg := Label.new()
	msg.name = "Msg"
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(480, 0)
	msg.add_theme_font_size_override(&"font_size", 14)
	msg.add_theme_color_override(&"font_color", Color(0.3, 0.45, 0.2))
	var ex := _modal_button(box, "Export", "1) ส่งออกข้อมูลการเล่น", Callable())
	ex.pressed.connect(func() -> void:
		msg.text = export_and_show()
		ex.text = "1) ส่งออกแล้ว ✓")
	if has_url:
		_modal_button(box, "Open", "2) เปิดแบบทดสอบหลังเล่น", func() -> void:
			_open_url(post_url())
			GameState.form_post_opened = true
			DayLoop.autosave())
	box.add_child(msg)
	_modal_button(box, "Close", "เล่นต่อ", func() -> void:
		if not has_url and ex.text.ends_with("✓"):
			GameState.form_post_opened = true # ไม่มีลิงก์ = ส่งไฟล์แล้วถือว่าครบ
		_post_snoozed = true
		close_modal()
		get_tree().paused = false)


# ---------------------------------------------------------------- CSV


## เพิ่มแถวลง user://playlog/<file> · cols/values ไม่รวม time · tester_id · game_version (ใส่ให้เอง)
static func append(file: String, cols: Array, values: Array) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := DIR.path_join(file)
	var header := ",".join(PackedStringArray(["time", "tester_id", "game_version"] + cols.map(func(c) -> String: return String(c))))
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
	var row: PackedStringArray = [Time.get_datetime_string_from_system(), _cell(GameState.tester_id), _cell(game_version())]
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
	var zname := "BakChangKhom_%s_%s.zip" % [GameState.tester_id if GameState.tester_id != "" else "noid", stamp]
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
	z.write_file(("tester_id=%s\ngame_version=%s\nexported=%s\nplaytime_sec=%d\nos=%s\nfiles=%d\n" % [
		GameState.tester_id, game_version(), Time.get_datetime_string_from_system(), roundi(GameState.playtime_sec), OS.get_name(), n,
	]).to_utf8_buffer())
	z.close_file()
	z.close()
	if web:
		JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path), zname, "application/zip")
		return { "ok": true, "path": zname, "folder": "", "msg": "ดาวน์โหลด %s แล้ว · ส่งไฟล์นี้ให้ทีม" % zname }
	return { "ok": true, "path": path, "folder": folder, "msg": "บันทึก %s ไว้ที่ %s แล้ว · ส่งไฟล์นี้ให้ทีม" % [zname, folder] }


## ปุ่มส่งออก (เมนูหลัก · เมนูพัก) → ส่งออก + เปิดโฟลเดอร์ · คืนข้อความสั้นสำหรับปุ่ม
func export_and_show() -> String:
	var r := export_zip()
	if r.ok and String(r.folder) != "" and not DisplayServer.get_name() == "headless":
		OS.shell_show_in_file_manager(String(r.path))
	return String(r.msg)
