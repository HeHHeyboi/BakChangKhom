class_name DesktopMinigame extends PartMinigame
## ขมOS — มินิเกมงานบนจอ Lv1 (LEVEL_DESIGN ข้อ 3) · ซีน Scene/MiniGame/Desktop/desktop_window.tscn
## ข้อมูลงานมาจาก DesktopTask (CustomerCase.desktop_task) · ไม่มี = ใช้ช่อง task ใน Inspector (เปิดซีนเล่นเดี่ยว F6)
## ขั้นของงาน: 1 ฟัง (เลือกคำถาม) → 2–3 ดู/ลงมือในหน้าต่าง → 4 ลองใช้ให้ลูกค้าดู (เช็ก) → 5 บอก (เลือกคำอธิบาย) → สรุป
## คะแนน 100: ทำงานสำเร็จ 40 · ปลอดภัย 30 · ฟังลูกค้า 20 · อธิบาย 10 (หักตามกับดักใน DesktopTask.traps)
## หน้าตาเหมือน Windows แต่เป็นของเกมทั้งหมด (ชื่อ/ไอคอนวาดใหม่ ไม่ใช้โลโก้ของจริง)
## logic (ask · delete_file · install_app · uninstall · check …) แยกจาก UI → Test/desktop_test.gd เรียกตรงได้
## [Claude 9 ต.ค. 2569]

enum Step { LISTEN, WORK, EXPLAIN, SUMMARY, DONE }

const PIB_PATH := "res://Assets/Dialog/MiniGame/Desktop_Pib.txt"
const CAP := { &"fix": 40, &"safety": 30, &"listen": 20, &"explain": 10 }
const CAT_NAMES := { &"fix": "ทำงานสำเร็จ", &"safety": "ปลอดภัย", &"listen": "ฟังลูกค้า", &"explain": "อธิบาย" }
const SCREEN := Vector2(1152, 648)
const TASKBAR_H := 44
const ADWARE_SIZE_MB := 120
const MAX_POPUPS := 3

const DIR := "res://Assets/MiniGame/Desktop/"
const TEX_WALL := preload(DIR + "os_wallpaper.jpg")
const TEX_START := preload(DIR + "os_start.png")
const TEX_NOTE := preload(DIR + "os_sticky_note.png")
const TEX_FOLDER := preload(DIR + "os_icon_folder.png")
const TEX_PICTURES := preload(DIR + "os_icon_pictures.png")
const TEX_DOWNLOADS := preload(DIR + "os_icon_downloads.png")
const TEX_TRASH := preload(DIR + "os_icon_trash_empty.png")
const TEX_TRASH_FULL := preload(DIR + "os_icon_trash_full.png")
const TEX_BROWSER := preload(DIR + "os_icon_browser.png")
const TEX_SETTINGS := preload(DIR + "os_icon_settings.png")
const TEX_CHAT := preload(DIR + "os_icon_chat.png")
const TEX_ADWARE := preload(DIR + "os_icon_adware.png")
const TEX_EXE := preload(DIR + "os_icon_file_exe.png")
const TEX_IMAGE := preload(DIR + "os_icon_file_image.png")
const TEX_DOC := preload(DIR + "os_icon_file_doc.png")
const TEX_WARN := preload(DIR + "os_icon_file_warn.png")

const C_INK := Color(0.23, 0.16, 0.11)
const C_AD := Color(1.0, 0.45, 0.2)

## งานที่ใช้ตอนเปิดซีนเดี่ยว ๆ (ไม่มี work_order)
@export var task: DesktopTask
## วินาทีระหว่างหน้าต่างโฆษณาเด้ง (ตอนมีโปรแกรมโฆษณาในเครื่อง)
@export var popup_every := 7.0
## คอมของขมเอง (กดคอมในร้าน) — ไม่มีลูกค้า ไม่มีขั้นฟัง/เช็ก/คะแนน · ปิดได้จากปุ่มเริ่ม → ปิดเครื่อง
@export var free_mode := false
## ทำความรู้จัก OS (เปิดจากบทฝึกประกอบคอมหลังกดเปิดเครื่อง) — ทำตามขั้นใน TOUR ทีละข้อ แล้วปิดเครื่อง → tour_finished
## เป็นลูกของมินิเกมอื่น: ไม่แตะ Global/SceneRouter ตอนปิด (มินิเกมแม่จัดการเอง)
@export var tour_mode := false
## ชั้นของหน้าจอ OS (tour ต้องอยู่เหนือ UI ของบทฝึก)
@export var ui_layer := 5

signal tour_finished(skipped: bool)

## ขั้นของ tour: id · บอกให้ทำ · ปิ๊บอธิบายหลังทำเสร็จ
const TOUR := [
	{ "id": "open_docs", "text": "เปิดโฟลเดอร์เอกสาร", "how": "ดับเบิลคลิกไอคอน \"เอกสาร\" บนเดสก์ท็อป",
		"done": "นี่คือหน้าต่างไฟล์ ไฟล์ทุกอย่างในเครื่องแยกเก็บเป็นโฟลเดอร์ เหมือนลิ้นชัก" },
	{ "id": "open_browser", "text": "เปิดเบราว์เซอร์", "how": "กดรูปลูกโลกที่แถบงานด้านล่าง",
		"done": "เบราว์เซอร์ใช้เปิดเว็บ ปุ่มสีจัดที่เขียนว่าโฆษณาอย่าไปกดนะ" },
	{ "id": "open_settings", "text": "ดูพื้นที่ในหน้าตั้งค่า", "how": "กดรูปเฟืองที่แถบงาน",
		"done": "หน้าตั้งค่าบอกพื้นที่เหลือ และเป็นที่ถอนโปรแกรมด้วย" },
	{ "id": "delete_file", "text": "ลบไฟล์ทดสอบ", "how": "คลิกขวาที่ \"ไฟล์ทดสอบ.doc\" บนเดสก์ท็อป → ลบ",
		"done": "ไฟล์ที่ลบยังไม่หายจริงนะ มันไปอยู่ในถังขยะ" },
	{ "id": "empty_trash", "text": "ล้างถังขยะ", "how": "ดับเบิลคลิกถังขยะ → กด \"ล้างถังขยะ\"",
		"done": "ล้างถังขยะแล้วไฟล์ถึงหายจริง พื้นที่ก็กลับมา" },
	{ "id": "shutdown", "text": "ปิดเครื่อง", "how": "กดปุ่มเริ่มมุมซ้ายล่าง → ปิดเครื่อง",
		"done": "" },
]

var tour_done: Dictionary = { } # id → true
var _tour_ring: Panel
var _tour_t := 0.0
var _start_btn: Button
var _task_btns: Dictionary = { } # "browser" · "settings" → Button

signal step_changed(step: Step)

var step: Step = Step.LISTEN
var customer_name := "ลูกค้า"
## สำเนาไฟล์/โปรแกรมจาก task + สถานะ (trashed · gone · inspected · asked · installed · icon)
var files: Array[Dictionary] = []
var programs: Array[Dictionary] = []
var free_mb := 0
var app_installed := false
var lost_user_file := false
var check_fails := 0
## บันทึกสิ่งที่พลาด → โชว์ในหน้าสรุป
var notes: PackedStringArray = []
var _trap_hit: Dictionary = { }
var _popup_seq := 0

# ---- UI
var _ui: Control
var _icons: Control
var _win_layer: Control
var _modal: ColorRect
var _bubble: PanelContainer
var _bubble_name: Label
var _bubble_text: Label
var _bubble_tw: Tween
var _note_checks: Array[Label] = []
var _check_btn: Button
var _disk_label: Label
var _clock_label: Label
var _start_menu: PopupMenu
var _icon_menu: PopupMenu
var _icon_menu_target: Dictionary = { }
var _selected_icon: Control
var _windows: Dictionary = { } # key → OsWindow
var _explorer_folder := "เดสก์ท็อป"
var _explorer_list: ItemList
var _explorer_path: Label
var _explorer_status: Label
var _trash_list: ItemList
var _browser_addr: LineEdit
var _browser_page: VBoxContainer
var _settings_rows: VBoxContainer
var _settings_disk: ProgressBar
var _settings_disk_label: Label
var _popup_timer: Timer


func _ready() -> void:
	_mistakes = { &"fix": 0, &"safety": 0, &"listen": 0, &"explain": 0 }
	if dialog_path.is_empty():
		dialog_path = PIB_PATH
	part_id = &"part_desktop"
	minigame_finished.connect(_on_minigame_finished)
	_resolve_task()
	if tour_mode:
		free_mode = true
	super._ready()
	if task == null:
		push_error("DesktopMinigame: ไม่มี DesktopTask (ใส่ใน CustomerCase.desktop_task หรือช่อง task ของซีน)")
		_finish.call_deferred(false)
		return
	_load_state()
	if free_mode:
		customer_name = "ขม"
		_build_ui()
		_set_step(Step.WORK)
		_pib_lines(task.pib_intro)
		if tour_mode:
			_tour_build()
		return
	_build_ui()
	_set_step(Step.LISTEN)
	_open_ask()


func _resolve_task() -> void:
	if has_meta("work_order"):
		var order = get_meta("work_order")
		if order is CustomerCase:
			customer_name = order.customer
			if order.get("desktop_task") is DesktopTask:
				task = order.desktop_task


func _load_state() -> void:
	files.clear()
	for f in task.files:
		var d: Dictionary = f.duplicate(true)
		d.merge({ "size_mb": 1, "kind": "junk", "note": "", "dup_of": "" })
		d.merge({ "trashed": false, "gone": false, "inspected": false, "asked": false }, true)
		files.append(d)
	programs.clear()
	for p in task.programs:
		var d: Dictionary = p.duplicate(true)
		d.merge({ "publisher": "", "size_mb": 100, "adware": false, "system": false, "desktop_icon": false, "app": false })
		d["installed"] = true
		d["icon"] = bool(d.desktop_icon)
		programs.append(d)
		if d.app and d.name == task.install_name:
			app_installed = true
	free_mb = task.disk_free_mb


func _on_minigame_finished(_score: Dictionary) -> void:
	Global.in_minigame = false
	Global.cur_pib = null
	EventManager.minigame_end()
	call_deferred("queue_free")


func repair_damaged() -> bool:
	return lost_user_file


func _set_step(s: Step) -> void:
	step = s
	step_changed.emit(s)
	_refresh_note()

# ================================================================ logic (เรียกจาก UI และ Test)


## หักคะแนนหมวด cat ไม่เกินเพดานของหมวด · note = บันทึกในหน้าสรุป
func lose(cat: StringName, pts: int, note := "") -> void:
	var cur: int = _mistakes.get(cat, 0)
	var add := mini(pts, int(CAP.get(cat, 100)) - cur)
	if add > 0:
		_on_mistake(cat, add)
	if note != "" and not notes.has(note):
		notes.append(note)


## กับดัก: หักครั้งเดียวต่อ key · ไม่อยู่ใน task.traps = ไม่หัก (ผลในเกมยังเกิด)
func _trap(id: StringName, key: String, cat: StringName, pts: int, note: String) -> void:
	if task == null or not task.traps.has(id) or _trap_hit.has(key):
		return
	_trap_hit[key] = true
	lose(cat, pts, note)


func score_of(cat: StringName) -> int:
	return int(CAP.get(cat, 0)) - int(_mistakes.get(cat, 0))


## ขั้น 1 — เลือกคำถาม · คืนคำตอบของลูกค้า
func ask(i: int) -> String:
	if step != Step.LISTEN:
		return ""
	var good := i == task.ask_best
	if not good:
		lose(&"listen", 10, "ถามลูกค้าไม่ตรงประเด็น")
	_set_step(Step.WORK)
	return task.ask_answer if good else task.ask_answer_wrong


func visible_files(folder: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f in files:
		if f.folder == folder and not f.trashed and not f.gone:
			out.append(f)
	return out


func trashed_files() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f in files:
		if f.trashed and not f.gone:
			out.append(f)
	return out


func find_file(file_name: String) -> Dictionary:
	for f in files:
		if f.name == file_name and not f.gone:
			return f
	return { }


func find_program(prog_name: String) -> Dictionary:
	for p in programs:
		if p.name == prog_name:
			return p
	return { }


## เปิดไฟล์ · คืนข้อความที่โชว์ (ตัวติดตั้ง = เปิดวิซาร์ด/ติดโปรแกรมโฆษณา)
func open_file(f: Dictionary) -> String:
	if f.is_empty():
		return ""
	f.inspected = true
	match String(f.kind):
		"installer":
			_open_wizard()
			return ""
		"fake_installer":
			_trap(&"fake_download", "run_fake", &"safety", 5, "เปิดไฟล์จากปุ่มโฆษณา")
			install_adware()
			_pib(&"FAKE_RUN", PibHint.Mood.WORRY)
			return "กำลังติดตั้ง… (ไม่มีหน้าให้เลือกอะไรเลย!)"
		"dup":
			return f.note if f.note != "" else "เปิดดูแล้ว — เหมือนกับ \"%s\" ทุกอย่าง" % f.dup_of
		"user":
			return f.note if f.note != "" else "ไฟล์ของลูกค้า"
		"system":
			return f.note if f.note != "" else "ไฟล์ระบบของขมOS — เครื่องต้องใช้ตอนเปิด"
	return f.note if f.note != "" else "ไฟล์ทั่วไป"


## ถามลูกค้าเรื่องไฟล์นี้ (ไม่เสียคะแนน)
func ask_about(f: Dictionary) -> String:
	if f.is_empty():
		return ""
	f.inspected = true
	f.asked = true
	if f.has("reply") and String(f.reply) != "":
		return f.reply
	match String(f.kind):
		"dup":
			return "อันนั้นก๊อปไว้ซ้ำแหละ ลบได้เลย"
		"user":
			return "อันนั้นอย่าลบนะ! ของสำคัญเลย"
		"system":
			return "ไม่รู้เหมือนกัน มันมีมากับเครื่อง"
		"junk":
			return "ไม่รู้จักเลย ไม่เคยใช้"
	return "อันนั้นโหลดมาเอง"


## ลบไฟล์ → ถังขยะ · ไฟล์ระบบ: ปิ๊บคว้าไว้ ไม่ลบ (คืน false)
func delete_file(f: Dictionary) -> bool:
	if f.is_empty() or f.trashed or f.gone:
		return false
	match String(f.kind):
		"system":
			_trap(&"delete_system", "sys_" + String(f.name), &"safety", 15, "เกือบลบไฟล์ระบบ (%s)" % f.name)
			_pib(&"SYSTEM_GRAB", PibHint.Mood.WORRY)
			return false
		"user":
			if not free_mode:
				_trap(&"delete_user", "user_" + String(f.name), &"safety", 10, "ลบของลูกค้า (%s)" % f.name)
				_pib_toast(&"USER_DELETE")
		"dup":
			if not f.inspected:
				lose(&"listen", 3, "ลบไฟล์ก่อนเปิดดูว่าซ้ำจริง")
	f.trashed = true
	_refresh_all()
	tour_event("delete_file")
	return true


func restore_file(f: Dictionary) -> void:
	if f.is_empty() or f.gone:
		return
	f.trashed = false
	_refresh_all()


## ล้างถังขยะ → ได้พื้นที่คืน · ของลูกค้าที่อยู่ในถัง = หายถาวร (ซ่อมไม่ผ่าน + หักเงิน)
func empty_trash() -> int:
	var freed := 0
	for f in trashed_files():
		f.gone = true
		freed += int(f.size_mb)
		if f.kind == "user":
			lost_user_file = true
			if not notes.has("ล้างถังขยะทั้งที่มีของลูกค้าอยู่ — หายถาวร"):
				notes.append("ล้างถังขยะทั้งที่มีของลูกค้าอยู่ — หายถาวร")
	free_mb += freed
	_refresh_all()
	if freed > 0:
		tour_event("empty_trash")
	return freed


## เบราว์เซอร์: กดปุ่มโฆษณา DOWNLOAD NOW → ได้ไฟล์ติดตั้งปลอมในดาวน์โหลด
func click_download_ad() -> Dictionary:
	_trap(&"fake_download", "ad_button", &"safety", 10, "กดปุ่มดาวน์โหลดที่เป็นโฆษณา")
	var f := find_file("DOWNLOAD_NOW_ฟรี.exe")
	if f.is_empty() or f.trashed:
		f = { "name": "DOWNLOAD_NOW_ฟรี.exe", "size_mb": 3, "folder": "ดาวน์โหลด", "kind": "fake_installer",
			"note": "", "dup_of": "", "trashed": false, "gone": false, "inspected": false, "asked": false }
		files.append(f)
	_pib_toast(&"FAKE_DOWNLOAD")
	_refresh_all()
	return f


## เบราว์เซอร์: ดาวน์โหลดจากเว็บทางการ
func download_official() -> Dictionary:
	var fname := "setup_%s.exe" % task.install_name
	var f := find_file(fname)
	if f.is_empty() or f.trashed:
		f = { "name": fname, "size_mb": 95, "folder": "ดาวน์โหลด", "kind": "installer", "note": "", "dup_of": "",
			"trashed": false, "gone": false, "inspected": false, "asked": false }
		files.append(f)
	_refresh_all()
	return f


## วิซาร์ดติดตั้งจบ · with_bundle = ไม่ได้เอาติ๊กโปรแกรมแถมออก
func install_app(with_bundle: bool) -> void:
	if not app_installed:
		app_installed = true
		free_mb -= task.install_size_mb
		var p := find_program(task.install_name)
		if p.is_empty():
			programs.append({ "name": task.install_name, "publisher": task.install_site, "size_mb": task.install_size_mb,
				"adware": false, "system": false, "desktop_icon": true, "app": true, "installed": true, "icon": true })
		else:
			p.installed = true
			p.icon = true
	if with_bundle:
		_trap(&"bundle", "bundle", &"safety", 10, "ลืมเอาติ๊กโปรแกรมแถมออกตอนติดตั้ง")
		install_adware()
	_refresh_all()


func install_adware() -> void:
	var p := find_program(task.bundle_name)
	if p.is_empty():
		programs.append({ "name": task.bundle_name, "publisher": "Super Deal Co.", "size_mb": ADWARE_SIZE_MB,
			"adware": true, "system": false, "desktop_icon": true, "app": false, "installed": true, "icon": true })
		free_mb -= ADWARE_SIZE_MB
	elif not p.installed:
		p.installed = true
		p.icon = true
		free_mb -= int(p.size_mb)
	_refresh_all()


## ถอนผ่านหน้าตั้งค่า (วิธีที่ถูก) · ของระบบ = ถอนไม่ได้
func uninstall(p: Dictionary) -> bool:
	if p.is_empty() or not p.installed:
		return false
	if p.system:
		_trap(&"delete_system", "unsys_" + String(p.name), &"safety", 10, "พยายามถอนโปรแกรมของระบบ (%s)" % p.name)
		_pib(&"SYSTEM_GRAB", PibHint.Mood.WORRY)
		return false
	p.installed = false
	p.icon = false
	free_mb += int(p.size_mb)
	if p.get("app", false):
		app_installed = false
	_close_popups_if_clean()
	_refresh_all()
	return true


## ลบแค่ไอคอนบนเดสก์ท็อป (โปรแกรมยังอยู่)
func remove_icon(p: Dictionary) -> void:
	if p.is_empty():
		return
	p.icon = false
	if p.adware and p.installed:
		_trap(&"icon_only", "icon_" + String(p.name), &"fix", 5, "ลบแค่ไอคอน โปรแกรมโฆษณายังอยู่")
	_refresh_all()


func has_adware() -> bool:
	for p in programs:
		if p.adware and p.installed:
			return true
	return false


## คลิกในหน้าต่างโฆษณา (ไม่ใช่ปุ่มปิด)
func click_ad_popup() -> void:
	_trap(&"click_ad", "click_ad", &"safety", 5, "คลิกในหน้าต่างโฆษณา")
	_pib_toast(&"CLICK_AD")
	_spawn_popup()


## ขั้น 4 — ลองใช้ให้ลูกค้าดู · "" = ผ่าน · ไม่ผ่าน = เหตุผล (หัก 10 ทำใหม่ได้)
func check() -> String:
	if step != Step.WORK:
		return "ยังไม่ถึงขั้นนี้"
	var why := _check_reason()
	if why != "":
		check_fails += 1
		lose(&"fix", 10, "ส่งงานแล้วยังไม่เรียบร้อย %d ครั้ง" % check_fails)
		return why
	_set_step(Step.EXPLAIN)
	return ""


func _check_reason() -> String:
	match task.goal:
		DesktopTask.Goal.INSTALL:
			if not app_installed:
				return "ยังไม่มีโปรแกรม %s ในเครื่องเลย" % task.install_name
			if has_adware():
				return "เปิดเครื่องมามีโฆษณาเด้ง! มีโปรแกรมแถมติดมา ต้องถอนออกก่อน"
		DesktopTask.Goal.UNINSTALL:
			for p in programs:
				if p.adware and p.installed:
					if not p.icon:
						return "ไอคอนหายแล้ว แต่โฆษณายังเด้งอยู่เลย — โปรแกรมยังไม่ได้ถอนจริง"
					return "โฆษณายังเด้งอยู่เลย"
		DesktopTask.Goal.FREE_SPACE:
			for f in trashed_files():
				if f.kind == "user":
					return "\"%s\" ของลูกค้าหายไปจากโฟลเดอร์! (อยู่ในถังขยะ)" % f.name
			if free_mb < task.free_space_target_mb:
				return "ยังเซฟไม่ได้ พื้นที่เหลือ %s (ต้อง %s) — ลบแล้วอย่าลืมล้างถังขยะ" % [
					size_text(free_mb), size_text(task.free_space_target_mb)]
	return ""


## ขั้น 5 — เลือกคำอธิบายให้ลูกค้า
func explain(i: int) -> void:
	if step != Step.EXPLAIN:
		return
	if i != task.explain_best:
		lose(&"explain", 10, "อธิบายให้ลูกค้าไม่ตรง")
	_set_step(Step.SUMMARY)


## ส่งเครื่องคืน → คะแนนเข้า GameState (งานลูกค้า) → ปิดมินิเกม
func finish() -> void:
	if step == Step.DONE:
		return
	_set_step(Step.DONE)
	if is_instance_valid(_popup_timer):
		_popup_timer.stop()
	_finish(true)


## ปิดเครื่อง (เฉพาะ free_mode) — กลับฉากเดิม ไม่ส่งคะแนน ไม่เดินเควสต์
func shut_down() -> void:
	if not free_mode or step == Step.DONE:
		return
	if tour_mode:
		if _tour_current() != "shutdown":
			_tour_say("ยังเหลืออีกนิด — " + String(_tour_step(_tour_current()).how))
			return
		tour_event("shutdown")
		_end_tour(false)
		return
	step = Step.DONE
	_finished = true
	if is_instance_valid(_popup_timer):
		_popup_timer.stop()
	Global.in_minigame = false
	Global.cur_pib = null
	EventManager.showUI()
	if SceneRouter._stack.has(self):
		SceneRouter.pop()
	else:
		queue_free()


# ---------------------------------------------------------------- ทำความรู้จัก OS (tour_mode)


func _tour_build() -> void:
	_tour_ring = Panel.new()
	_tour_ring.name = "TourRing"
	_tour_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.86, 0.3, 0.12)
	sb.border_color = Color(1, 0.86, 0.3)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	_tour_ring.add_theme_stylebox_override("panel", sb)
	_ui.add_child(_tour_ring)
	_refresh_note()
	_tour_hint_later()


## ขั้นแรกที่ยังไม่เสร็จ ("" = ครบ)
func _tour_current() -> String:
	for st in TOUR:
		if not tour_done.has(st.id):
			return st.id
	return ""


func _tour_step(id: String) -> Dictionary:
	for st in TOUR:
		if st.id == id:
			return st
	return { }


## เหตุการณ์ใน OS (เปิดหน้าต่าง · ลบไฟล์ …) — นับเฉพาะตอน tour และทำได้ไม่เรียงก็นับ
func tour_event(id: String) -> void:
	if not tour_mode or tour_done.has(id) or _tour_step(id).is_empty():
		return
	tour_done[id] = true
	_refresh_note()
	var st := _tour_step(id)
	if String(st.done) != "":
		_tour_say(st.done)
	_tour_hint_later()


func _tour_hint_later() -> void:
	var cur := _tour_current()
	if cur == "":
		return
	await get_tree().create_timer(3.8).timeout
	if is_inside_tree() and _tour_current() == cur:
		_tour_say("ต่อไป " + String(_tour_step(cur).how))


func _tour_say(text: String) -> void:
	if is_instance_valid(pib):
		pib.toast(DialogToken.new(PibHint.DEFAULT_SPEAKER, text), 3.6, PibHint.Mood.POINT)


## ของที่ต้องกดในขั้นนี้ (ไว้วาดกรอบกะพริบ)
func _tour_target() -> Control:
	match _tour_current():
		"open_docs":
			return _icon_named("เอกสาร")
		"open_browser":
			return _task_btns.get("เบราว์เซอร์")
		"open_settings":
			return _task_btns.get("ตั้งค่า")
		"delete_file":
			return _icon_named("ไฟล์ทดสอบ.doc")
		"empty_trash":
			if _windows.has("trash") and is_instance_valid(_windows.trash) and _windows.trash.visible:
				return _windows.trash.body.get_child(_windows.trash.body.get_child_count() - 1).get_child(1)
			return _icon_named("ถังขยะ")
		"shutdown":
			return _start_btn
	return null


func _icon_named(label: String) -> Control:
	if not is_instance_valid(_icons):
		return null
	for c in _icons.get_children():
		if not c.is_queued_for_deletion() and c.has_meta("data") and String(c.get_meta("data").label) == label:
			return c
	return null


func _tour_update_ring(delta: float) -> void:
	if not is_instance_valid(_tour_ring):
		return
	_tour_t += delta
	var t := _tour_target()
	if t == null or not t.is_visible_in_tree() or step == Step.DONE:
		_tour_ring.hide()
		return
	var r := t.get_global_rect().grow(6.0 + 3.0 * sin(_tour_t * 6.0))
	_tour_ring.show()
	_tour_ring.global_position = r.position
	_tour_ring.size = r.size
	_tour_ring.move_to_front()


## จบ tour (ปิดเครื่องครบ หรือกดข้าม) — ไม่แตะ Global/SceneRouter · มินิเกมแม่รอ tour_finished
func _end_tour(skipped: bool) -> void:
	if step == Step.DONE:
		return
	step = Step.DONE
	_finished = true
	if is_instance_valid(_popup_timer):
		_popup_timer.stop()
	if is_instance_valid(_tour_ring):
		_tour_ring.hide()
	tour_finished.emit(skipped)
	queue_free()


static func size_text(mb: int) -> String:
	if absi(mb) >= 1000:
		return "%.1f GB" % (mb / 1000.0)
	return "%d MB" % mb

# ================================================================ ปิ๊บ / ลูกค้าพูด


func _pib(section: StringName, mood := PibHint.Mood.NORMAL) -> void:
	if is_instance_valid(pib) and dialog_dict.has(String(section)):
		pib.say(dialog_dict[String(section)], mood)


func _pib_toast(section: StringName, secs := 3.5) -> void:
	if is_instance_valid(pib) and dialog_dict.has(String(section)):
		pib.toast(dialog_dict[String(section)][0], secs)


func _pib_lines(lines: PackedStringArray, mood := PibHint.Mood.NORMAL) -> void:
	if is_instance_valid(pib) and not lines.is_empty():
		pib.say(Array(lines), mood)


func customer_say(text: String, secs := 5.0) -> void:
	if not is_instance_valid(_bubble) or text == "":
		return
	_bubble_name.text = customer_name
	_bubble_text.text = text
	_bubble.show()
	_bubble.modulate.a = 1.0
	if _bubble_tw:
		_bubble_tw.kill()
	_bubble_tw = create_tween()
	_bubble_tw.tween_interval(secs)
	_bubble_tw.tween_property(_bubble, "modulate:a", 0.0, 0.4)
	_bubble_tw.tween_callback(_bubble.hide)

# ================================================================ UI


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Os"
	layer.layer = ui_layer
	add_child(layer)
	_ui = Control.new()
	_ui.name = "Screen"
	_ui.size = SCREEN
	_ui.theme = _make_theme()
	layer.add_child(_ui)

	var wall := TextureRect.new()
	wall.texture = TEX_WALL
	wall.size = SCREEN
	wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wall.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wall.mouse_filter = Control.MOUSE_FILTER_STOP
	wall.gui_input.connect(_on_wall_input)
	_ui.add_child(wall)

	_icons = Control.new()
	_icons.name = "Icons"
	_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icons.size = SCREEN
	_ui.add_child(_icons)

	_build_note()

	_win_layer = Control.new()
	_win_layer.name = "Windows"
	_win_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win_layer.size = Vector2(SCREEN.x, SCREEN.y - TASKBAR_H)
	_ui.add_child(_win_layer)

	_build_taskbar()
	_build_bubble()

	_modal = ColorRect.new()
	_modal.name = "Modal"
	_modal.color = Color(0, 0, 0, 0.45)
	_modal.size = SCREEN
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.hide()
	_ui.add_child(_modal)

	_icon_menu = PopupMenu.new()
	_icon_menu.add_item("เปิด", 0)
	_icon_menu.add_item("ลบ", 1)
	_icon_menu.id_pressed.connect(_on_icon_menu)
	_ui.add_child(_icon_menu)

	_popup_timer = Timer.new()
	_popup_timer.wait_time = popup_every
	_popup_timer.timeout.connect(_on_popup_timer)
	add_child(_popup_timer)
	_popup_timer.start()

	_refresh_all()


## ธีมของขมOS: ปุ่มสีอ่อนตัวหนังสือเข้ม (ธีมหลักของเกมเป็นตัวหนังสือสีขาว อ่านไม่ออกบนหน้าต่างสีครีม)
func _make_theme() -> Theme:
	var th := Theme.new()
	var ink := C_INK
	for t in ["Button", "CheckBox", "MenuButton"]:
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			th.set_color(c, t, ink)
		th.set_color("font_disabled_color", t, Color(ink, 0.45))
		th.set_font_size("font_size", t, 16)
	var states := {
		"normal": Color(0.93, 0.91, 0.86), "hover": Color(0.85, 0.92, 1.0),
		"pressed": Color(0.72, 0.84, 0.97), "disabled": Color(0.9, 0.89, 0.86), "focus": Color(0, 0, 0, 0),
	}
	for st in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[st]
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(6)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		if st != "focus":
			sb.border_color = Color(ink, 0.55)
			sb.set_border_width_all(2)
		else:
			sb.draw_center = false
		th.set_stylebox(st, "Button", sb)
	var flat := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		th.set_stylebox(st, "CheckBox", flat)
	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color.WHITE
	list_bg.border_color = Color(ink, 0.35)
	list_bg.set_border_width_all(1)
	list_bg.set_content_margin_all(4)
	th.set_stylebox("panel", "ItemList", list_bg)
	th.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	var sel := StyleBoxFlat.new()
	sel.bg_color = Color(0.72, 0.84, 0.97)
	sel.set_corner_radius_all(4)
	for st in ["selected", "selected_focus", "hovered_selected", "hovered_selected_focus"]:
		th.set_stylebox(st, "ItemList", sel)
	var hov := StyleBoxFlat.new()
	hov.bg_color = Color(0.9, 0.95, 1.0)
	th.set_stylebox("hovered", "ItemList", hov)
	for c in ["font_color", "font_selected_color", "font_hovered_color", "font_hovered_selected_color"]:
		th.set_color(c, "ItemList", ink)
	th.set_font_size("font_size", "ItemList", 16)
	th.set_constant("v_separation", "ItemList", 6)
	var le := StyleBoxFlat.new()
	le.bg_color = Color.WHITE
	le.border_color = Color(ink, 0.35)
	le.set_border_width_all(1)
	le.set_corner_radius_all(12)
	le.set_content_margin_all(6)
	le.content_margin_left = 12
	th.set_stylebox("normal", "LineEdit", le)
	th.set_stylebox("read_only", "LineEdit", le)
	th.set_color("font_color", "LineEdit", ink)
	th.set_color("font_uneditable_color", "LineEdit", Color(0.25, 0.3, 0.35))
	th.set_color("font_color", "LinkButton", Color(0.1, 0.3, 0.75))
	th.set_color("font_hover_color", "LinkButton", Color(0.2, 0.45, 0.95))
	th.set_color("font_pressed_color", "LinkButton", Color(0.4, 0.2, 0.6))
	th.set_color("font_color", "Label", ink)
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.85, 0.84, 0.8)
	pb_bg.set_corner_radius_all(6)
	th.set_stylebox("background", "ProgressBar", pb_bg)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = Color(0.29, 0.55, 0.85)
	pb_fill.set_corner_radius_all(6)
	th.set_stylebox("fill", "ProgressBar", pb_fill)
	th.set_color("font_color", "ProgressBar", ink)
	return th


func _build_note() -> void:
	var note := TextureRect.new()
	note.name = "StickyNote"
	note.texture = TEX_NOTE
	note.position = Vector2(860, 14)
	note.size = Vector2(280, 220)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(note)
	var box := VBoxContainer.new()
	box.position = Vector2(26, 26)
	box.size = Vector2(232, 180)
	box.add_theme_constant_override("separation", 2)
	note.add_child(box)
	var t := _label(task.title, 18, C_INK)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(t)
	var r := _label(task.request, 13, Color(0.4, 0.3, 0.2))
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(r)
	_note_checks.clear()
	var lines: Array = ["ฟังลูกค้า", "ดูอาการ + ลงมือ", "ลองใช้ให้ลูกค้าดู", "อธิบายให้ลูกค้าฟัง"]
	if tour_mode:
		lines = []
		for st in TOUR:
			lines.append(st.text)
	elif free_mode:
		lines = []
		for tip in ["• ดับเบิลคลิกไอคอน = เปิด", "• คลิกขวาไอคอน = เมนู/ลบ", "• ถอนโปรแกรม = ตั้งค่า"]:
			box.add_child(_label(tip, 14, C_INK))
	for s in lines:
		var l := _label("☐ " + s, 15, C_INK)
		l.set_meta("text", s)
		box.add_child(l)
		_note_checks.append(l)
	_check_btn = Button.new()
	_check_btn.name = "CheckButton"
	_check_btn.text = "✔ ลองใช้ให้ลูกค้าดู"
	_check_btn.focus_mode = Control.FOCUS_NONE
	_check_btn.add_theme_font_size_override("font_size", 17)
	_check_btn.position = Vector2(900, 240)
	_check_btn.custom_minimum_size = Vector2(210, 40)
	if tour_mode:
		_check_btn.name = "SkipTour"
		_check_btn.text = "ข้ามการแนะนำ ►"
		_check_btn.pressed.connect(func(): _end_tour(true))
	elif free_mode:
		_check_btn.name = "PowerButton"
		_check_btn.text = "ปิดเครื่อง"
		_check_btn.pressed.connect(shut_down)
	else:
		_check_btn.pressed.connect(_on_check_pressed)
	_ui.add_child(_check_btn)


func _on_wall_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_select_icon(null)


func _refresh_note() -> void:
	if tour_mode:
		for i in _note_checks.size():
			var id: String = TOUR[i].id
			_note_checks[i].text = ("☑ " if tour_done.has(id) else ("▶ " if id == _tour_current() else "☐ ")) + String(_note_checks[i].get_meta("text"))
		return
	if free_mode:
		if is_instance_valid(_check_btn):
			_check_btn.disabled = step == Step.DONE
		return
	if _note_checks.is_empty():
		return
	var done := [step > Step.LISTEN, step > Step.WORK, step > Step.WORK, step > Step.EXPLAIN]
	for i in _note_checks.size():
		_note_checks[i].text = ("☑ " if done[i] else "☐ ") + String(_note_checks[i].get_meta("text"))
	if is_instance_valid(_check_btn):
		_check_btn.disabled = step != Step.WORK


func _build_taskbar() -> void:
	var bar := Panel.new()
	bar.name = "Taskbar"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.2, 0.26, 0.94)
	sb.border_color = C_INK
	sb.border_width_top = 2
	bar.add_theme_stylebox_override("panel", sb)
	bar.position = Vector2(0, SCREEN.y - TASKBAR_H)
	bar.size = Vector2(SCREEN.x, TASKBAR_H)
	_ui.add_child(bar)
	var row := HBoxContainer.new()
	row.position = Vector2(6, 2)
	row.size = Vector2(SCREEN.x - 12, TASKBAR_H - 4)
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)

	var start := _task_button(TEX_START, "เริ่ม")
	start.name = "Start"
	_start_btn = start
	start.pressed.connect(_show_start_menu.bind(start))
	row.add_child(start)
	var quick := [
		[TEX_FOLDER, "ไฟล์", func(): open_explorer("เดสก์ท็อป")],
		[TEX_BROWSER, "เบราว์เซอร์", func(): open_browser()],
		[TEX_SETTINGS, "ตั้งค่า", func(): open_settings()],
	]
	for q in quick:
		var b := _task_button(q[0], q[1])
		b.pressed.connect(q[2])
		row.add_child(b)
		_task_btns[q[1]] = b
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	_disk_label = _label("", 15, Color.WHITE)
	_disk_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_disk_label)
	_clock_label = _label(_clock_text(), 15, Color.WHITE)
	_clock_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_clock_label.custom_minimum_size.x = 60
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_clock_label)

	_start_menu = PopupMenu.new()
	_start_menu.name = "StartMenu"
	var items := [
		["เอกสาร", TEX_FOLDER], ["รูปภาพ", TEX_PICTURES], ["ดาวน์โหลด", TEX_DOWNLOADS],
		["เบราว์เซอร์", TEX_BROWSER], ["ตั้งค่า", TEX_SETTINGS], ["ถังขยะ", TEX_TRASH],
	]
	for i in items.size():
		_start_menu.add_icon_item(_small(items[i][1]), items[i][0], i)
	_start_menu.add_separator()
	_start_menu.add_item("ปิดเครื่อง" if free_mode else "ปิดเครื่อง (งานยังไม่เสร็จ)", 99)
	_start_menu.set_item_disabled(_start_menu.get_item_index(99), not free_mode)
	_start_menu.id_pressed.connect(_on_start_menu)
	_ui.add_child(_start_menu)


func _task_button(tex: Texture2D, tip: String) -> Button:
	var b := Button.new()
	b.icon = tex
	b.expand_icon = true
	b.flat = true
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(40, 40)
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.18 if st in ["hover", "pressed", "hover_pressed"] else 0.0)
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(3)
		b.add_theme_stylebox_override(st, sb)
	return b


func _small(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img == null:
		return tex
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.resize(24, 24, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _show_start_menu(from: Control) -> void:
	_start_menu.reset_size()
	_start_menu.popup(Rect2i(Vector2i(from.global_position) - Vector2i(0, _start_menu.size.y + 4), Vector2i.ZERO))


func _on_start_menu(id: int) -> void:
	match id:
		0:
			open_explorer("เอกสาร")
		1:
			open_explorer("รูปภาพ")
		2:
			open_explorer("ดาวน์โหลด")
		3:
			open_browser()
		4:
			open_settings()
		5:
			open_trash()
		99:
			shut_down()


func _clock_text() -> String:
	var em := get_node_or_null(^"/root/EventManager")
	var ts = em.get("time_system") if em else null
	if ts is TimeSystem and is_instance_valid(ts):
		return TimeSystem.clock_text(ts.current_minute)
	return "09:00"


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	_bubble.name = "CustomerBubble"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.98, 0.92)
	sb.border_color = C_INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(12)
	_bubble.add_theme_stylebox_override("panel", sb)
	_bubble.position = Vector2(700, 440)
	_bubble.custom_minimum_size = Vector2(430, 0)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.hide()
	_ui.add_child(_bubble)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(col)
	_bubble_name = _label("", 15, Color(0.75, 0.35, 0.1))
	col.add_child(_bubble_name)
	_bubble_text = _label("", 18, C_INK)
	_bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text.custom_minimum_size.x = 400
	col.add_child(_bubble_text)


func _label(t: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _refresh_all() -> void:
	if not is_instance_valid(_ui):
		return
	_rebuild_icons()
	_refresh_explorer()
	_refresh_trash()
	_refresh_settings()
	if is_instance_valid(_disk_label):
		_disk_label.text = "พื้นที่เหลือ %s" % size_text(free_mb)
		_disk_label.add_theme_color_override("font_color", Color(1, 0.55, 0.5) if free_mb < 1000 else Color.WHITE)


func _process(delta: float) -> void:
	if tour_mode:
		_tour_update_ring(delta)
	if is_instance_valid(_clock_label) and Engine.get_process_frames() % 30 == 0:
		_clock_label.text = _clock_text()

# ---------------------------------------------------------------- ไอคอนบนเดสก์ท็อป


func _rebuild_icons() -> void:
	for c in _icons.get_children():
		c.queue_free()
	_selected_icon = null
	var list: Array = [
		{ "label": "เอกสาร", "tex": TEX_FOLDER, "open": func(): open_explorer("เอกสาร") },
		{ "label": "รูปภาพ", "tex": TEX_PICTURES, "open": func(): open_explorer("รูปภาพ") },
		{ "label": "ดาวน์โหลด", "tex": TEX_DOWNLOADS, "open": func(): open_explorer("ดาวน์โหลด") },
		{ "label": "ถังขยะ", "tex": TEX_TRASH_FULL if not trashed_files().is_empty() else TEX_TRASH,
			"open": func(): open_trash() },
		{ "label": "เบราว์เซอร์", "tex": TEX_BROWSER, "open": func(): open_browser() },
	]
	for p in programs:
		if p.installed and p.icon:
			list.append({ "label": p.name, "tex": TEX_ADWARE if p.adware else TEX_CHAT, "program": p,
				"open": _open_program.bind(p) })
	for f in visible_files("เดสก์ท็อป"):
		list.append({ "label": f.name, "tex": _file_tex(f), "file": f, "open": _open_file_ui.bind(f) })
	var per_col := 5
	for i in list.size():
		var ic := _make_icon(list[i])
		ic.position = Vector2(14 + floori(i / float(per_col)) * 100, 12 + (i % per_col) * 108)
		_icons.add_child(ic)


func _make_icon(d: Dictionary) -> Control:
	var root := Panel.new()
	root.name = "Icon_" + String(d.label).validate_node_name()
	root.custom_minimum_size = Vector2(92, 100)
	root.size = Vector2(92, 100)
	root.tooltip_text = d.label
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0)
	sb.set_corner_radius_all(6)
	root.add_theme_stylebox_override("panel", sb)
	root.set_meta("data", d)
	root.set_meta("style", sb)
	var ic := TextureRect.new()
	ic.texture = d.tex
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = Vector2(18, 4)
	ic.size = Vector2(56, 56)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ic)
	var l := _label(d.label, 13, Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	l.max_lines_visible = 2
	l.position = Vector2(0, 60)
	l.size = Vector2(92, 40)
	root.add_child(l)
	root.gui_input.connect(_on_icon_input.bind(root))
	return root


func _on_icon_input(e: InputEvent, ic: Control) -> void:
	if not (e is InputEventMouseButton and e.pressed):
		return
	var d: Dictionary = ic.get_meta("data")
	if e.button_index == MOUSE_BUTTON_LEFT:
		_select_icon(ic)
		if e.double_click:
			d.open.call()
	elif e.button_index == MOUSE_BUTTON_RIGHT:
		_select_icon(ic)
		_icon_menu_target = d
		var can_delete := d.has("program") or d.has("file")
		_icon_menu.set_item_disabled(1, not can_delete)
		_icon_menu.set_item_text(1, "ลบไอคอน" if d.has("program") else "ลบ")
		_icon_menu.popup(Rect2i(Vector2i(e.global_position), Vector2i.ZERO))


func _select_icon(ic: Control) -> void:
	if is_instance_valid(_selected_icon):
		(_selected_icon.get_meta("style") as StyleBoxFlat).bg_color = Color(1, 1, 1, 0)
	_selected_icon = ic
	if is_instance_valid(ic):
		(ic.get_meta("style") as StyleBoxFlat).bg_color = Color(0.6, 0.8, 1, 0.35)


func _on_icon_menu(id: int) -> void:
	var d := _icon_menu_target
	if d.is_empty():
		return
	if id == 0:
		d.open.call()
	else:
		_delete_icon_data(d)


func _delete_icon_data(d: Dictionary) -> void:
	if d.has("program"):
		remove_icon(d.program)
	elif d.has("file"):
		delete_file(d.file)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_DELETE:
		if is_instance_valid(_selected_icon) and step == Step.WORK:
			_delete_icon_data(_selected_icon.get_meta("data"))
			get_viewport().set_input_as_handled()


func _file_tex(f: Dictionary) -> Texture2D:
	match String(f.kind):
		"installer":
			return TEX_EXE
		"fake_installer":
			return TEX_WARN
		"system":
			return TEX_FOLDER
	var n := String(f.name).to_lower()
	if n.ends_with(".jpg") or n.ends_with(".png") or n.begins_with("รูป"):
		return TEX_IMAGE if n.contains(".") else TEX_PICTURES
	if not n.contains("."):
		return TEX_FOLDER
	return TEX_DOC


func _open_program(p: Dictionary) -> void:
	if p.adware:
		_spawn_popup()
	elif p.get("app", false):
		if free_mode:
			_show_info(String(p.name), "ยังไม่มีข้อความใหม่\nล่าสุด: ยายส่งสติกเกอร์รูปดอกไม้มา \"กินข้าวยังลูก\"", TEX_CHAT)
		else:
			customer_say("เปิดได้แล้ว! เดี๋ยวคืนนี้โทรหาหลานเลย", 3.0)
	else:
		_pib_toast(&"PROGRAM_OPEN")


func _open_file_ui(f: Dictionary) -> void:
	var msg := open_file(f)
	if msg != "":
		_show_info("เปิด " + String(f.name), msg, _file_tex(f))

# ---------------------------------------------------------------- หน้าต่าง


func open_window(key: String, title: String, icon: Texture2D, size: Vector2) -> OsWindow:
	if _windows.has(key) and is_instance_valid(_windows[key]):
		var w: OsWindow = _windows[key]
		w.restore()
		return w
	var nw := OsWindow.make(key, title, icon, size)
	var n := _windows.size()
	nw.position = Vector2(130 + (n % 5) * 34, 40 + (n % 5) * 28)
	nw.position = nw.position.clamp(Vector2.ZERO, _win_layer.size - size)
	nw.closed.connect(func(): _windows.erase(key))
	_win_layer.add_child(nw)
	_windows[key] = nw
	return nw


func _show_info(title: String, text: String, icon: Texture2D) -> void:
	var w := open_window("info", title, icon, Vector2(420, 190))
	w.title_label.text = title
	for c in w.body.get_children():
		c.queue_free()
	var l := _label(text, 17, C_INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	w.body.add_child(l)
	var ok := Button.new()
	ok.text = "ตกลง"
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	ok.pressed.connect(w.close)
	w.body.add_child(ok)


## หน้าต่างไฟล์ (Explorer)
func open_explorer(folder: String) -> void:
	_explorer_folder = folder
	var w := open_window("explorer", "ไฟล์ — " + task.pc_name, TEX_FOLDER, Vector2(640, 380))
	tour_event("open_docs")
	if w.body.get_child_count() == 0:
		var row := HBoxContainer.new()
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		w.body.add_child(row)
		var side := VBoxContainer.new()
		side.custom_minimum_size.x = 140
		row.add_child(side)
		for fo in DesktopTask.FOLDERS:
			var b := Button.new()
			b.text = fo
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(func():
				_explorer_folder = fo
				_refresh_explorer())
			side.add_child(b)
		var tb := Button.new()
		tb.text = "ถังขยะ"
		tb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tb.focus_mode = Control.FOCUS_NONE
		tb.pressed.connect(open_trash)
		side.add_child(tb)
		var right := VBoxContainer.new()
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(right)
		_explorer_path = _label("", 15, Color(0.35, 0.35, 0.4))
		right.add_child(_explorer_path)
		_explorer_list = ItemList.new()
		_explorer_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_explorer_list.fixed_icon_size = Vector2i(28, 28)
		_explorer_list.item_activated.connect(func(i): _open_file_ui(_explorer_file(i)))
		_explorer_list.gui_input.connect(_on_explorer_key)
		right.add_child(_explorer_list)
		var bar := HBoxContainer.new()
		right.add_child(bar)
		var acts := [["เปิด", "open"], ["ลบ", "delete"]] if free_mode else [["เปิด", "open"], ["ถามลูกค้า", "ask"], ["ลบ", "delete"]]
		for a in acts:
			var b := Button.new()
			b.text = a[0]
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(_explorer_action.bind(a[1]))
			bar.add_child(b)
		_explorer_status = _label("", 14, Color(0.35, 0.35, 0.4))
		_explorer_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_explorer_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bar.add_child(_explorer_status)
	_refresh_explorer()


func _explorer_file(i: int) -> Dictionary:
	if not is_instance_valid(_explorer_list) or i < 0 or i >= _explorer_list.item_count:
		return { }
	return _explorer_list.get_item_metadata(i)


func _explorer_selected() -> Dictionary:
	if not is_instance_valid(_explorer_list):
		return { }
	var sel := _explorer_list.get_selected_items()
	return _explorer_file(sel[0]) if not sel.is_empty() else { }


func _explorer_action(what: String) -> void:
	var f := _explorer_selected()
	if f.is_empty():
		_pib_toast(&"SELECT_FIRST", 2.5)
		return
	match what:
		"open":
			_open_file_ui(f)
		"ask":
			customer_say(ask_about(f))
		"delete":
			delete_file(f)


func _on_explorer_key(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_DELETE:
		_explorer_action("delete")
		_explorer_list.accept_event()


func _refresh_explorer() -> void:
	if not is_instance_valid(_explorer_list):
		return
	_explorer_list.clear()
	_explorer_path.text = "เครื่องนี้ › " + _explorer_folder
	var list := visible_files(_explorer_folder)
	for f in list:
		var i := _explorer_list.add_item("%s      %s" % [f.name, size_text(int(f.size_mb))], _file_tex(f))
		_explorer_list.set_item_metadata(i, f)
		if f.kind == "fake_installer":
			_explorer_list.set_item_custom_fg_color(i, Color(0.8, 0.3, 0.1))
	_explorer_status.text = "%d รายการ · เหลือ %s" % [list.size(), size_text(free_mb)]


## ถังขยะ
func open_trash() -> void:
	var w := open_window("trash", "ถังขยะ", TEX_TRASH, Vector2(480, 320))
	if w.body.get_child_count() == 0:
		_trash_list = ItemList.new()
		_trash_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_trash_list.fixed_icon_size = Vector2i(28, 28)
		w.body.add_child(_trash_list)
		var bar := HBoxContainer.new()
		w.body.add_child(bar)
		var rb := Button.new()
		rb.text = "กู้คืน"
		rb.focus_mode = Control.FOCUS_NONE
		rb.pressed.connect(func():
			var sel := _trash_list.get_selected_items()
			if not sel.is_empty():
				restore_file(_trash_list.get_item_metadata(sel[0])))
		bar.add_child(rb)
		var eb := Button.new()
		eb.text = "ล้างถังขยะ"
		eb.focus_mode = Control.FOCUS_NONE
		eb.pressed.connect(func():
			var freed := empty_trash()
			if freed > 0:
				_pib_toast(&"TRASH_EMPTIED", 2.5))
		bar.add_child(eb)
	_refresh_trash()


func _refresh_trash() -> void:
	if not is_instance_valid(_trash_list):
		return
	_trash_list.clear()
	for f in trashed_files():
		var i := _trash_list.add_item("%s      %s   (จาก %s)" % [f.name, size_text(int(f.size_mb)), f.folder], _file_tex(f))
		_trash_list.set_item_metadata(i, f)


## เบราว์เซอร์
func open_browser() -> void:
	var w := open_window("browser", "เบราว์เซอร์", TEX_BROWSER, Vector2(660, 420))
	tour_event("open_browser")
	if w.body.get_child_count() == 0:
		var top := HBoxContainer.new()
		w.body.add_child(top)
		var home := Button.new()
		home.text = "⌂"
		home.focus_mode = Control.FOCUS_NONE
		home.pressed.connect(_browser_show.bind("home"))
		top.add_child(home)
		_browser_addr = LineEdit.new()
		_browser_addr.editable = false
		_browser_addr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(_browser_addr)
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		w.body.add_child(scroll)
		_browser_page = VBoxContainer.new()
		_browser_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_browser_page.add_theme_constant_override("separation", 10)
		scroll.add_child(_browser_page)
	_browser_show("home")


func _browser_show(page: String) -> void:
	if not is_instance_valid(_browser_page):
		return
	for c in _browser_page.get_children():
		c.queue_free()
	var is_install := task.goal == DesktopTask.Goal.INSTALL and not free_mode
	if page == "official":
		_browser_addr.text = "🔒 https://" + task.install_site
		_browser_page.add_child(_label(task.install_name, 30, Color(0.2, 0.55, 0.35)))
		var d := _label("โปรแกรมคุยกับครอบครัวและเพื่อน ส่งข้อความ โทรเห็นหน้า ฟรี\nเว็บนี้เป็นของผู้พัฒนาเอง", 16, C_INK)
		_browser_page.add_child(d)
		var b := Button.new()
		b.name = "OfficialDownload"
		b.text = "ดาวน์โหลดสำหรับคอมพิวเตอร์"
		b.custom_minimum_size = Vector2(300, 46)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.pressed.connect(func():
			download_official()
			_pib_toast(&"OFFICIAL_DONE", 3.0)
			open_explorer("ดาวน์โหลด"))
		_browser_page.add_child(b)
		return
	_browser_addr.text = "https://ค้นหา.ขม/?q=" + ("ดาวน์โหลด " + task.install_name if is_install else "ข่าววันนี้")
	if task.browser_ad:
		var ad := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 0.93, 0.6)
		sb.set_content_margin_all(8)
		ad.add_theme_stylebox_override("panel", sb)
		var col := VBoxContainer.new()
		ad.add_child(col)
		col.add_child(_label("โฆษณา", 11, Color(0.5, 0.45, 0.3)))
		var big := Button.new()
		big.name = "AdDownload"
		big.text = "⬇  DOWNLOAD NOW — ฟรี! เร็วกว่า 10 เท่า!!"
		big.custom_minimum_size = Vector2(0, 58)
		big.add_theme_font_size_override("font_size", 22)
		big.add_theme_color_override("font_color", Color.WHITE)
		var bs := StyleBoxFlat.new()
		bs.bg_color = C_AD
		bs.set_corner_radius_all(8)
		big.add_theme_stylebox_override("normal", bs)
		big.add_theme_stylebox_override("hover", bs)
		big.pressed.connect(func():
			click_download_ad()
			open_explorer("ดาวน์โหลด"))
		col.add_child(big)
		_browser_page.add_child(ad)
	if is_install:
		var link := LinkButton.new()
		link.name = "OfficialLink"
		link.text = "%s — ดาวน์โหลดโปรแกรม (เว็บทางการ)" % task.install_name
		link.add_theme_font_size_override("font_size", 19)
		link.pressed.connect(_browser_show.bind("official"))
		_browser_page.add_child(link)
		_browser_page.add_child(_label(task.install_site, 14, Color(0.2, 0.5, 0.25)))
		var other := LinkButton.new()
		other.text = "รวมโปรแกรมฟรี 2569 โหลดได้ทุกตัว!!"
		other.add_theme_font_size_override("font_size", 19)
		other.pressed.connect(func():
			click_download_ad()
			open_explorer("ดาวน์โหลด"))
		_browser_page.add_child(other)
		_browser_page.add_child(_label("freeprogram-zz.biz/โหลดฟรี", 14, Color(0.2, 0.5, 0.25)))
	else:
		_browser_page.add_child(_label("ข่าววันนี้: ตลาดนัดหน้าวัดเลื่อนเป็นวันเสาร์", 17, C_INK))
		_browser_page.add_child(_label("พยากรณ์อากาศ: ฝนตกบ่าย ๆ เก็บผ้าด้วย", 17, C_INK))


## วิซาร์ดติดตั้ง (เปิดจากไฟล์ setup_*.exe)
func _open_wizard() -> void:
	var w := open_window("wizard", "ติดตั้ง " + task.install_name, TEX_EXE, Vector2(460, 280))
	_wizard_page(w, 0, true)


func _wizard_page(w: OsWindow, page: int, bundle: bool) -> void:
	if not is_instance_valid(w):
		return
	for c in w.body.get_children():
		c.queue_free()
	var next := Button.new()
	next.size_flags_horizontal = Control.SIZE_SHRINK_END
	next.custom_minimum_size = Vector2(120, 36)
	match page:
		0:
			w.body.add_child(_label("ยินดีต้อนรับสู่ตัวติดตั้ง %s" % task.install_name, 20, C_INK))
			var l := _label("ตัวติดตั้งจะพาไปทีละขั้น อ่านทุกหน้าก่อนกดถัดไปนะ", 15, C_INK)
			l.size_flags_vertical = Control.SIZE_EXPAND_FILL
			w.body.add_child(l)
			next.text = "ถัดไป ›"
			next.pressed.connect(_wizard_page.bind(w, 1, true))
		1:
			w.body.add_child(_label("เลือกส่วนประกอบ", 20, C_INK))
			var c1 := CheckBox.new()
			c1.text = "%s (จำเป็น)" % task.install_name
			c1.button_pressed = true
			c1.disabled = true
			w.body.add_child(c1)
			var c2 := CheckBox.new()
			c2.name = "BundleCheck"
			c2.text = "ติดตั้ง \"%s\" ด้วย (แนะนำ!) — ผู้สนับสนุน" % task.bundle_name
			c2.button_pressed = true
			c2.size_flags_vertical = Control.SIZE_EXPAND_FILL
			w.body.add_child(c2)
			next.text = "ติดตั้ง"
			next.pressed.connect(func(): _wizard_page(w, 2, c2.button_pressed))
		2:
			w.body.add_child(_label("กำลังติดตั้ง…", 20, C_INK))
			var bar := ProgressBar.new()
			bar.custom_minimum_size.y = 26
			w.body.add_child(bar)
			w.closable = false
			var tw := create_tween()
			tw.tween_property(bar, "value", 100.0, 1.2)
			tw.tween_callback(func():
				install_app(bundle)
				w.closable = true
				_wizard_page(w, 3, bundle))
			return
		3:
			var l := _label("ติดตั้ง %s เสร็จแล้ว" % task.install_name, 20, C_INK)
			l.size_flags_vertical = Control.SIZE_EXPAND_FILL
			w.body.add_child(l)
			next.text = "เสร็จ"
			next.pressed.connect(w.close)
	w.body.add_child(next)


## ตั้งค่า → แอป (ถอนการติดตั้ง) + พื้นที่จัดเก็บ
func open_settings() -> void:
	var w := open_window("settings", "ตั้งค่า", TEX_SETTINGS, Vector2(560, 400))
	tour_event("open_settings")
	if w.body.get_child_count() == 0:
		w.body.add_child(_label("พื้นที่จัดเก็บ", 18, C_INK))
		_settings_disk = ProgressBar.new()
		_settings_disk.show_percentage = false
		_settings_disk.custom_minimum_size.y = 18
		w.body.add_child(_settings_disk)
		_settings_disk_label = _label("", 14, Color(0.35, 0.35, 0.4))
		w.body.add_child(_settings_disk_label)
		w.body.add_child(HSeparator.new())
		w.body.add_child(_label("แอปที่ติดตั้ง", 18, C_INK))
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		w.body.add_child(scroll)
		_settings_rows = VBoxContainer.new()
		_settings_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(_settings_rows)
	_refresh_settings()


func _refresh_settings() -> void:
	if not is_instance_valid(_settings_rows):
		return
	var used := task.disk_total_mb - free_mb
	_settings_disk.max_value = task.disk_total_mb
	_settings_disk.value = used
	_settings_disk_label.text = "ใช้ไป %s จาก %s · เหลือ %s" % [size_text(used), size_text(task.disk_total_mb), size_text(free_mb)]
	for c in _settings_rows.get_children():
		c.queue_free()
	for p in programs:
		if not p.installed:
			continue
		var row := HBoxContainer.new()
		row.name = "App_" + String(p.name).validate_node_name()
		var ic := TextureRect.new()
		ic.texture = TEX_ADWARE if p.adware else (TEX_SETTINGS if p.system else TEX_CHAT)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.custom_minimum_size = Vector2(28, 28)
		row.add_child(ic)
		var t := _label("%s\n%s · %s" % [p.name, p.publisher, size_text(int(p.size_mb))], 14, C_INK)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(t)
		var b := Button.new()
		b.text = "ถอนการติดตั้ง"
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func():
			if uninstall(p):
				_pib_toast(&"UNINSTALLED", 2.5))
		row.add_child(b)
		_settings_rows.add_child(row)

# ---------------------------------------------------------------- โฆษณาเด้ง


func _on_popup_timer() -> void:
	if step == Step.WORK and has_adware():
		_spawn_popup()


func _spawn_popup() -> void:
	var count := 0
	for k in _windows:
		if String(k).begins_with("ad") and is_instance_valid(_windows[k]):
			count += 1
	if count >= MAX_POPUPS or not is_instance_valid(_win_layer):
		return
	_popup_seq += 1
	var key := "ad%d" % _popup_seq
	var w := open_window(key, "ข้อเสนอพิเศษ!!", TEX_ADWARE, Vector2(320, 190))
	w.position = Vector2(randf_range(150, 520), randf_range(60, 330))
	var l := _label("ยินดีด้วย! คุณคือผู้โชคดีคนที่ 1,000,000", 17, Color(0.8, 0.15, 0.1))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w.body.add_child(l)
	var b := Button.new()
	b.text = "กดรับรางวัลเลย!!"
	b.custom_minimum_size.y = 46
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(func():
		w.close()
		click_ad_popup())
	w.body.add_child(b)


func _close_popups_if_clean() -> void:
	if has_adware():
		return
	for k in _windows.keys():
		if String(k).begins_with("ad") and is_instance_valid(_windows[k]):
			_windows[k].close()

# ---------------------------------------------------------------- ขั้น ฟัง / เช็ก / บอก / สรุป


func _modal_window(title: String, size: Vector2) -> OsWindow:
	for c in _modal.get_children():
		c.queue_free()
	var w := OsWindow.make("modal", title, TEX_CHAT, size)
	w.closable = false
	w.close_btn.hide()
	w.min_btn.hide()
	w.position = (SCREEN - size) / 2.0 - Vector2(0, 30)
	_modal.add_child(w)
	_modal.show()
	return w


func _close_modal() -> void:
	for c in _modal.get_children():
		c.queue_free()
	_modal.hide()


func _open_ask() -> void:
	var w := _modal_window("คุยกับ" + customer_name, Vector2(560, 300))
	var req := _label("%s: \"%s\"" % [customer_name, task.request], 18, C_INK)
	req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w.body.add_child(req)
	w.body.add_child(_label("ก่อนลงมือ ถามอะไรลูกค้าก่อนดี?", 16, Color(0.4, 0.35, 0.3)))
	for i in task.ask_options.size():
		var b := Button.new()
		b.name = "Ask%d" % i
		b.text = task.ask_options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 40
		b.pressed.connect(func():
			var ans := ask(i)
			_close_modal()
			customer_say(ans, 7.0)
			_pib_lines(task.pib_intro))
		w.body.add_child(b)


func _on_check_pressed() -> void:
	var why := check()
	if why != "":
		customer_say(why, 5.0)
		_pib_toast(&"CHECK_FAIL", 3.0)
		return
	_close_popups_if_clean()
	_open_explain()


func _open_explain() -> void:
	var w := _modal_window("อธิบายให้%sฟัง" % customer_name, Vector2(600, 300))
	w.body.add_child(_label("ใช้ได้แล้ว! บอกลูกค้าว่าอะไรดี?", 18, C_INK))
	for i in task.explain_options.size():
		var b := Button.new()
		b.name = "Explain%d" % i
		b.text = task.explain_options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(560, 44)
		b.pressed.connect(func():
			explain(i)
			_open_summary()
			_pib_lines(task.pib_lesson, PibHint.Mood.HAPPY))
		w.body.add_child(b)


func _open_summary() -> void:
	var score := final_score()
	var w := _modal_window("สรุปงาน — " + task.title, Vector2(520, 400))
	var grade := "⭐⭐⭐" if score >= 90 else ("⭐⭐" if score >= 75 else ("⭐" if score >= 60 else "ไม่ผ่าน"))
	if lost_user_file:
		grade = "ไม่ผ่าน (ของลูกค้าหาย)"
	w.body.add_child(_label("คะแนน %d / 100   %s" % [score, grade], 24, C_INK))
	for cat in [&"fix", &"safety", &"listen", &"explain"]:
		w.body.add_child(_label("• %s  %d / %d" % [CAT_NAMES[cat], score_of(cat), CAP[cat]], 17, C_INK))
	if not notes.is_empty():
		w.body.add_child(HSeparator.new())
		for n in notes:
			var l := _label("– " + n, 14, Color(0.6, 0.25, 0.15))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			w.body.add_child(l)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	w.body.add_child(sp)
	var b := Button.new()
	b.name = "Finish"
	b.text = "ส่งเครื่องคืนลูกค้า"
	b.custom_minimum_size = Vector2(200, 42)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.pressed.connect(finish)
	w.body.add_child(b)
