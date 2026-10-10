class_name OsExtra extends RefCounted
## ขมOS ส่วนเสริม — งาน Lv1 1-4 … 1-10 และ Lv2 บนจอ (LEVEL_DESIGN ข้อ 3) · [Claude 10 ต.ค. 2569]
## DesktopMinigame สร้างไว้ที่ m.extra · ตรรกะเรียกจากเทสต์ได้ทุกฟังก์ชัน (ไม่ต้องกด UI)
##   ตัวจัดการงาน (Ctrl+Shift+Esc / ปุ่มเริ่ม): จบงานโปรแกรมค้าง · ปิดโปรแกรมเปิดพร้อมเครื่อง
##   ตั้งค่า → เครื่องพิมพ์ · เสียง · Wi-Fi · จอภาพ · อัปเดต · ขมการ์ด (สแกนไวรัส + ล้างไฟล์ชั่วคราว)
##   หน้าต่างไฟล์: USB (E:) คัดลอก/ย้าย/ถอดอย่างปลอดภัย

const C_INK := Color(0.23, 0.16, 0.11)
const C_DIM := Color(0.4, 0.35, 0.3)
const C_BAD := Color(0.75, 0.2, 0.12)
const C_OK := Color(0.15, 0.5, 0.2)
const BOOT_BASE_S := 8

var m # DesktopMinigame (ไม่ใส่ชนิด กัน cyclic)
var task: DesktopTask

# ---- สถานะ
var procs: Array[Dictionary] = []
var installed_printers: Array[Dictionary] = []
var default_printer := ""
var printed_ok := false
var sound_dev := 0
var muted := true
var volume := 0
var sound_tested := false
var wifi_connected := ""
var usb_ejected := false
var update_state := 0 # 0 ยังไม่ตรวจ · 1 เจออัปเดต · 2 กำลังติดตั้ง · 3 รอรีสตาร์ต · 4 เสร็จ · -1 พัง (ต้องเริ่มใหม่)
var doc_saved := true
var scanned := false
var protection_on := true
var threat_state: Dictionary = { } # name → "found" | "quarantine" | "allowed"
var temp_cleaned := false
var res_i := 0
var scale_pct := 100
var _pending_res := -1

# ---- UI
var _tm_list: VBoxContainer
var _tm_tab := "proc"
var _hang_win: Control
var _doc_win: Control


func _init(p_m) -> void:
	m = p_m
	task = m.task


func load_state() -> void:
	procs.clear()
	for p in task.processes:
		var d: Dictionary = p.duplicate(true)
		d.merge({ "kind": "app", "startup": false, "boot_s": 2, "cpu": 1 })
		d["running"] = true
		d["startup_on"] = bool(d.startup)
		procs.append(d)
	sound_dev = clampi(task.sound_device, 0, maxi(task.sound_devices.size() - 1, 0))
	muted = task.sound_muted
	volume = task.sound_volume
	res_i = clampi(task.display_res, 0, maxi(task.resolutions.size() - 1, 0))
	scale_pct = task.display_scale
	doc_saved = task.unsaved_doc == ""
	for t in task.threats:
		threat_state[String(t.name)] = "hidden"


## หน้าต่างที่มีอยู่ตั้งแต่เปิดเครื่อง (โปรแกรมค้าง · งานที่ยังไม่บันทึก) + ผลของจอภาพ
func build_ui() -> void:
	var hang := hang_proc()
	if not hang.is_empty():
		var w = m.open_window("hang", "%s (ไม่ตอบสนอง)" % hang.name, m.TEX_EXE, Vector2(460, 260))
		w.closable = false
		w.close_btn.disabled = true
		var l = m._label("กำลังทำงาน…\nโปรแกรมนี้ไม่ตอบสนอง กดอะไรก็ไม่ขยับ", 17, C_DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		w.body.add_child(l)
		w.modulate = Color(0.85, 0.85, 0.85)
		_hang_win = w
	if task.unsaved_doc != "":
		var w2 = m.open_window("doc", task.unsaved_doc + " *ยังไม่บันทึก", m.TEX_DOC, Vector2(420, 220))
		var l2 = m._label("ยอดขาย ข้าวสาร 12 ถุง · น้ำปลา 30 ขวด · …\n(ลูกค้าพิมพ์ค้างไว้ ยังไม่ได้กดบันทึก)", 15, C_INK)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		w2.body.add_child(l2)
		var b := Button.new()
		b.name = "SaveDoc"
		b.text = "บันทึก"
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.pressed.connect(save_doc)
		w2.body.add_child(b)
		_doc_win = w2
	if task.goal == DesktopTask.Goal.DISPLAY:
		_apply_display()


func pib_say(text: String, mood := PibHint.Mood.NORMAL, secs := 4.0) -> void:
	if is_instance_valid(m.pib):
		m.pib.toast(DialogToken.new(PibHint.DEFAULT_SPEAKER, text), secs, mood)

# ================================================================ ตัวจัดการงาน (1-4 · 1-9)


func hang_proc() -> Dictionary:
	for p in procs:
		if p.kind == "hang" and p.running:
			return p
	return { }


func find_proc(n: String) -> Dictionary:
	for p in procs:
		if p.name == n:
			return p
	return { }


## จบงาน (Task Manager) · ของระบบ = จอฟ้า เครื่องรีสตาร์ตเอง (หักคะแนน) · งานลูกค้าที่ยังไม่บันทึก = หาย
func end_task(p: Dictionary) -> bool:
	if p.is_empty() or not p.running:
		return false
	match String(p.kind):
		"system":
			m._trap(&"kill_system", "kill_" + String(p.name), &"safety", 10, "ปิดโปรแกรมของระบบ (%s) เครื่องจอฟ้า" % p.name)
			m._show_info("จอฟ้า!", "ปิด \"%s\" แล้วเครื่องค้างจอฟ้า ต้องรีสตาร์ตใหม่\nโปรแกรมของระบบอย่าไปปิดนะ" % p.name, m.TEX_WARN)
			pib_say("อันนั้นของระบบ! ปิดแล้วเครื่องล่มเลย ดูคอลัมน์ประเภทก่อนนะ", PibHint.Mood.WORRY)
			return false
		"unsaved":
			m._trap(&"kill_unsaved", "kill_" + String(p.name), &"listen", 10, "ปิดงานที่ลูกค้ายังไม่บันทึก (%s)" % p.name)
			m.lost_user_file = true
			pib_say("อ๊ะ! อันนั้นลูกค้ายังใช้อยู่ ข้อมูลที่ยังไม่บันทึกหายหมดแล้ว", PibHint.Mood.WORRY)
	p.running = false
	if p.kind == "hang" and is_instance_valid(_hang_win):
		_hang_win.queue_free()
		pib_say("ปิดได้แล้ว เปิดโปรแกรมใหม่ก็ใช้ได้ปกติ")
	_refresh_tm()
	return true


func boot_time() -> int:
	var t := BOOT_BASE_S
	for p in procs:
		if p.startup and p.startup_on:
			t += int(p.boot_s)
	return t


## เปิด/ปิดโปรแกรมเปิดพร้อมเครื่อง · ของระบบ (แอนตี้ไวรัส · ไดรเวอร์) ห้ามปิด
func set_startup(p: Dictionary, on: bool) -> void:
	if p.is_empty() or not p.startup:
		return
	if not on and p.kind == "system":
		m._trap(&"disable_system", "nostart_" + String(p.name), &"safety", 10, "ปิด %s ไม่ให้เปิดพร้อมเครื่อง" % p.name)
		pib_say("%s ต้องเปิดพร้อมเครื่องนะ ไม่งั้นเครื่องไม่ปลอดภัย" % p.name, PibHint.Mood.WORRY)
	p.startup_on = on
	_refresh_tm()


func open_task_manager() -> void:
	var w = m.open_window("taskman", "ตัวจัดการงาน", m.TEX_SETTINGS, Vector2(600, 380))
	if w.body.get_child_count() == 0:
		var tabs := HBoxContainer.new()
		w.body.add_child(tabs)
		for t in [["proc", "โปรแกรมที่ทำงาน"], ["startup", "เปิดพร้อมเครื่อง"]]:
			var b := Button.new()
			b.name = "Tab_" + t[0]
			b.text = t[1]
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(func():
				_tm_tab = t[0]
				_refresh_tm())
			tabs.add_child(b)
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		w.body.add_child(scroll)
		_tm_list = VBoxContainer.new()
		_tm_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(_tm_list)
	_refresh_tm()


func _refresh_tm() -> void:
	if not is_instance_valid(_tm_list):
		return
	for c in _tm_list.get_children():
		c.queue_free()
	if _tm_tab == "proc":
		_tm_list.add_child(m._label("ชื่อ · สถานะ · ประเภท · ซีพียู", 14, C_DIM))
		for p in procs:
			if not p.running:
				continue
			var row := HBoxContainer.new()
			row.name = "Proc_" + String(p.name).validate_node_name()
			var st := "ไม่ตอบสนอง" if p.kind == "hang" else "กำลังทำงาน"
			var kind := "ระบบ" if p.kind == "system" else "แอป"
			var l = m._label("%s\n%s · %s · ซีพียู %d%%" % [p.name, st, kind, int(p.cpu)], 14, C_BAD if p.kind == "hang" else C_INK)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
			var b := Button.new()
			b.text = "จบงาน"
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(end_task.bind(p))
			row.add_child(b)
			_tm_list.add_child(row)
	else:
		_tm_list.add_child(m._label("เปิดเครื่องใช้เวลา ~%d วินาที" % boot_time(), 15, C_INK))
		for p in procs:
			if not p.startup:
				continue
			var row := HBoxContainer.new()
			row.name = "Start_" + String(p.name).validate_node_name()
			var impact := "สูง" if int(p.boot_s) >= 6 else ("กลาง" if int(p.boot_s) >= 3 else "ต่ำ")
			var l = m._label("%s%s\nผลต่อการเปิดเครื่อง: %s · %s" % [p.name, "  (ระบบ)" if p.kind == "system" else "", impact, "เปิดอยู่" if p.startup_on else "ปิดแล้ว"], 14, C_INK)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
			var b := Button.new()
			b.text = "ปิด" if p.startup_on else "เปิด"
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(func(): set_startup(p, not p.startup_on))
			row.add_child(b)
			_tm_list.add_child(row)

# ================================================================ ตั้งค่า → หมวดต่าง ๆ


## ปุ่มหมวดบนหน้าตั้งค่า
func settings_sections() -> Array:
	return [
		["เครื่องพิมพ์", open_printers],
		["เสียง", open_sound],
		["Wi-Fi", open_wifi],
		["จอภาพ", open_display],
		["อัปเดต", open_update],
		["ขมการ์ด", open_security],
	]

# ---------------------------------------------------------------- เครื่องพิมพ์ (1-5)


func add_printer(p: Dictionary) -> void:
	if p.is_empty() or installed_printers.has(p):
		return
	if not p.get("right", false):
		m._trap(&"wrong_printer", "printer_" + String(p.name), &"fix", 10, "เพิ่มเครื่องพิมพ์ผิดเครื่อง (%s)" % p.name)
		pib_say("เครื่องนั้นไม่ใช่ของห้องนี้นะ ดูชื่อให้ตรงกับที่ลูกค้าบอก", PibHint.Mood.WORRY)
	installed_printers.append(p)
	if default_printer == "":
		default_printer = p.name
	_open_or_refresh("printers")


func remove_printer(p: Dictionary) -> void:
	installed_printers.erase(p)
	if default_printer == p.name:
		default_printer = installed_printers[0].name if not installed_printers.is_empty() else ""
	_open_or_refresh("printers")


func set_default_printer(p: Dictionary) -> void:
	if installed_printers.has(p):
		default_printer = p.name
	_open_or_refresh("printers")


func _printer(n: String) -> Dictionary:
	for p in task.printers:
		if p.name == n:
			return p
	return { }


## พิมพ์หน้าทดสอบไปเครื่องค่าเริ่มต้น · คืนข้อความผล
func print_test() -> String:
	if default_printer == "":
		return "ยังไม่มีเครื่องพิมพ์ในเครื่องเลย"
	var p := _printer(default_printer)
	printed_ok = p.get("right", false)
	return "พิมพ์หน้าทดสอบที่ \"%s\" แล้ว — %s" % [default_printer, "ออกกระดาษที่โต๊ะลูกค้า!" if printed_ok else "กระดาษไปออกที่ห้องอื่น…"]


func open_printers() -> void:
	var w = m.open_window("printers", "ตั้งค่า › เครื่องพิมพ์", m.TEX_SETTINGS, Vector2(560, 380))
	for c in w.body.get_children():
		c.queue_free()
	w.body.add_child(m._label("เครื่องพิมพ์ในเครื่องนี้", 17, C_INK))
	if installed_printers.is_empty():
		w.body.add_child(m._label("(ยังไม่มี)", 14, C_DIM))
	for p in installed_printers:
		var row := HBoxContainer.new()
		row.name = "Inst_" + String(p.name).validate_node_name()
		var l = m._label(p.name + ("  ✓ ค่าเริ่มต้น" if p.name == default_printer else ""), 15, C_INK)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(_btn("ตั้งเป็นค่าเริ่มต้น", set_default_printer.bind(p)))
		row.add_child(_btn("ลบ", remove_printer.bind(p)))
		w.body.add_child(row)
	w.body.add_child(HSeparator.new())
	w.body.add_child(m._label("เครื่องพิมพ์ที่ค้นเจอในเครือข่าย", 17, C_INK))
	for p in task.printers:
		if installed_printers.has(p):
			continue
		var row := HBoxContainer.new()
		row.name = "Found_" + String(p.name).validate_node_name()
		var l = m._label("%s\n%s" % [p.name, p.get("note", "")], 14, C_INK)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(_btn("เพิ่ม", add_printer.bind(p)))
		w.body.add_child(row)
	var res = m._label("", 14, C_DIM)
	res.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w.body.add_child(_btn("พิมพ์หน้าทดสอบ", func(): res.text = print_test()))
	w.body.add_child(res)

# ---------------------------------------------------------------- เสียง (1-6)


func sound_ok() -> bool:
	if task.sound_devices.is_empty():
		return true
	var dev: Dictionary = task.sound_devices[sound_dev]
	return dev.get("works", false) and not muted and volume >= 20 and _driver_ok()


func _driver_ok() -> bool:
	var p = m.find_program("ไดรเวอร์เสียง")
	return p.is_empty() or p.installed


func set_sound_device(i: int) -> void:
	sound_dev = clampi(i, 0, task.sound_devices.size() - 1)
	_open_or_refresh("sound")


func set_muted(on: bool) -> void:
	muted = on
	_open_or_refresh("sound")


func set_volume(v: int) -> void:
	volume = clampi(v, 0, 100)


func test_sound() -> String:
	sound_tested = true
	if not _driver_ok():
		return "ไม่มีไดรเวอร์เสียง เครื่องไม่รู้จักลำโพงเลย"
	if sound_ok():
		return "♪ ติ๊ง! มีเสียงออกลำโพงแล้ว"
	if muted:
		return "เงียบ… (ปิดเสียงอยู่)"
	if volume < 20:
		return "เบามากจนไม่ได้ยิน"
	return "เงียบ… เสียงไปออกที่ \"%s\"" % task.sound_devices[sound_dev].name


func open_sound() -> void:
	var w = m.open_window("sound", "ตั้งค่า › เสียง", m.TEX_SETTINGS, Vector2(520, 330))
	for c in w.body.get_children():
		c.queue_free()
	w.body.add_child(m._label("อุปกรณ์ส่งเสียงออก", 16, C_INK))
	var opt := OptionButton.new()
	opt.name = "Device"
	opt.focus_mode = Control.FOCUS_NONE
	for d in task.sound_devices:
		opt.add_item(d.name)
	if not task.sound_devices.is_empty():
		opt.select(sound_dev)
	opt.item_selected.connect(set_sound_device)
	w.body.add_child(opt)
	var mute := CheckBox.new()
	mute.name = "Mute"
	mute.text = "ปิดเสียง"
	mute.button_pressed = muted
	mute.focus_mode = Control.FOCUS_NONE
	mute.toggled.connect(set_muted)
	w.body.add_child(mute)
	var row := HBoxContainer.new()
	w.body.add_child(row)
	row.add_child(m._label("ระดับเสียง", 15, C_INK))
	var sl := HSlider.new()
	sl.name = "Volume"
	sl.max_value = 100
	sl.value = volume
	sl.custom_minimum_size.x = 260
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var vl = m._label("%d" % volume, 15, C_INK)
	sl.value_changed.connect(func(v):
		set_volume(int(v))
		vl.text = "%d" % volume)
	row.add_child(sl)
	row.add_child(vl)
	var res = m._label("", 15, C_DIM)
	w.body.add_child(_btn("ทดสอบเสียง", func(): res.text = test_sound()))
	w.body.add_child(res)

# ---------------------------------------------------------------- Wi-Fi (1-7)


func _net(n: String) -> Dictionary:
	for x in task.wifi:
		if x.name == n:
			return x
	return { }


## ต่อเครือข่าย · คืน "" = ต่อได้ · อื่น ๆ = เหตุที่ต่อไม่ได้
func connect_wifi(n: String, password := "") -> String:
	var net := _net(n)
	if net.is_empty():
		return "ไม่พบเครือข่าย"
	if net.get("locked", false):
		if password != String(net.get("password", "")):
			return "รหัสผ่านไม่ถูกต้อง"
	elif not net.get("right", false):
		m._trap(&"open_wifi", "wifi_" + n, &"safety", 10, "ต่อ Wi-Fi สาธารณะที่ไม่มีรหัส (%s)" % n)
		pib_say("เน็ตฟรีไม่มีรหัสแบบนี้ ใครก็แอบดูข้อมูลได้ ใช้เน็ตบ้านลูกค้าดีกว่า", PibHint.Mood.WORRY)
	wifi_connected = n
	_open_or_refresh("wifi")
	return ""


func open_wifi() -> void:
	var w = m.open_window("wifi", "ตั้งค่า › Wi-Fi", m.TEX_SETTINGS, Vector2(520, 360))
	for c in w.body.get_children():
		c.queue_free()
	w.body.add_child(m._label("เชื่อมต่ออยู่: %s" % (wifi_connected if wifi_connected != "" else "ไม่ได้เชื่อมต่อ"), 16, C_OK if wifi_connected != "" else C_BAD))
	var msg = m._label("", 14, C_BAD)
	for net in task.wifi:
		var row := HBoxContainer.new()
		row.name = "Net_" + String(net.name).validate_node_name()
		var bars := "▮".repeat(clampi(int(net.get("signal", 2)), 1, 3))
		var l = m._label("%s  %s\n%s" % [net.name, bars, "ต้องใส่รหัส" if net.get("locked", false) else "ไม่มีรหัส (สาธารณะ)"], 14, C_INK)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if net.get("locked", false):
			var pw := LineEdit.new()
			pw.name = "Password"
			pw.placeholder_text = "รหัสผ่าน"
			pw.custom_minimum_size.x = 140
			row.add_child(pw)
			row.add_child(_btn("เชื่อมต่อ", func(): msg.text = connect_wifi(net.name, pw.text)))
		else:
			row.add_child(_btn("เชื่อมต่อ", func(): msg.text = connect_wifi(net.name)))
		w.body.add_child(row)
	w.body.add_child(msg)

# ---------------------------------------------------------------- USB (1-8)


func usb_present() -> bool:
	return task.usb_drive and not usb_ejected


func usb_used_mb() -> int:
	var t := 0
	for f in m.files:
		if f.folder == DesktopTask.USB and not f.gone:
			t += int(f.size_mb)
	return t


## คัดลอกไฟล์ลง USB (ต้นฉบับยังอยู่ในเครื่อง)
func copy_to_usb(f: Dictionary) -> String:
	if not usb_present():
		return "ไม่มี USB เสียบอยู่"
	if f.is_empty() or f.folder == DesktopTask.USB:
		return ""
	if usb_used_mb() + int(f.size_mb) > task.usb_mb:
		return "USB เต็ม"
	for g in m.files:
		if g.folder == DesktopTask.USB and g.name == f.name and not g.gone:
			return "มีไฟล์นี้ใน USB แล้ว"
	var c: Dictionary = f.duplicate(true)
	c.folder = DesktopTask.USB
	c["copy_of"] = f.name
	m.files.append(c)
	m._refresh_all()
	return "คัดลอก \"%s\" ลง USB แล้ว" % f.name


## ย้ายไฟล์ไป USB (ต้นฉบับหายจากเครื่อง) — ของลูกค้า = กับดัก
func move_to_usb(f: Dictionary) -> String:
	if not usb_present():
		return "ไม่มี USB เสียบอยู่"
	if f.is_empty() or f.folder == DesktopTask.USB:
		return ""
	if usb_used_mb() + int(f.size_mb) > task.usb_mb:
		return "USB เต็ม"
	if f.kind == "user":
		m._trap(&"move_not_copy", "move_" + String(f.name), &"safety", 10, "\"ย้าย\" รูปลูกค้าออกจากเครื่อง (ควร \"คัดลอก\")")
		pib_say("ย้าย = ไฟล์ออกจากเครื่องไปอยู่ใน USB อย่างเดียวนะ สำรองต้อง \"คัดลอก\" ให้มีสองที่", PibHint.Mood.WORRY)
	f["moved_from"] = f.folder
	f.folder = DesktopTask.USB
	m._refresh_all()
	return "ย้าย \"%s\" ไป USB แล้ว" % f.name


func eject_usb() -> String:
	if not usb_present():
		return ""
	usb_ejected = true
	if m._explorer_folder == DesktopTask.USB:
		m._explorer_folder = "เดสก์ท็อป"
	m._refresh_all()
	return "ถอด USB ได้อย่างปลอดภัยแล้ว"


## ไฟล์ลูกค้าที่ยังไม่มีสำเนาครบ (ต้องอยู่ทั้งในเครื่องและใน USB)
func backup_missing() -> Array[String]:
	var out: Array[String] = []
	for f in task.files:
		if f.get("folder", "") != task.backup_folder or f.get("kind", "") != "user":
			continue
		var on_pc := false
		var on_usb := false
		for g in m.files:
			if g.gone or g.trashed or g.name != f.name:
				continue
			if g.folder == DesktopTask.USB:
				on_usb = true
			elif g.folder == task.backup_folder:
				on_pc = true
		if not (on_pc and on_usb):
			out.append(String(f.name))
	return out

# ---------------------------------------------------------------- อัปเดต (1-10)


func save_doc() -> void:
	doc_saved = true
	if is_instance_valid(_doc_win):
		_doc_win.title_label.text = task.unsaved_doc + " (บันทึกแล้ว)"
	pib_say("บันทึกงานลูกค้าก่อน ค่อยรีสตาร์ต ถูกต้อง!", PibHint.Mood.HAPPY, 2.5)


func check_update() -> void:
	if update_state <= 0:
		update_state = 1
	_open_or_refresh("update")


## เริ่มติดตั้ง (UI เดินแถบ 3 วิ · เทสต์เรียก finish_install() ต่อได้เลย)
func start_install() -> void:
	if update_state != 1:
		return
	update_state = 2
	_open_or_refresh("update")
	var tw = m.create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(finish_install)


func finish_install() -> void:
	if update_state == 2:
		update_state = 3
		_open_or_refresh("update")


## ปิดเครื่องกลางอัปเดต = อัปเดตพัง ต้องเริ่มใหม่
func power_off_during_update() -> void:
	if update_state != 2:
		return
	m._trap(&"interrupt_update", "interrupt", &"safety", 10, "ปิดเครื่องตอนกำลังอัปเดต")
	update_state = -1
	pib_say("ห้ามปิดเครื่องตอนอัปเดตเด็ดขาด! ระบบเสียหายได้ ต้องตรวจหาใหม่", PibHint.Mood.WORRY)
	_open_or_refresh("update")


func restart_now() -> void:
	if update_state != 3:
		return
	if not doc_saved:
		m._trap(&"unsaved_work", "unsaved", &"listen", 10, "รีสตาร์ตทั้งที่งานลูกค้ายังไม่บันทึก")
		m.lost_user_file = true
		pib_say("งานที่ลูกค้าพิมพ์ค้างไว้หายหมดเลย… ต้องกดบันทึกก่อนรีสตาร์ตทุกครั้ง", PibHint.Mood.WORRY)
	if is_instance_valid(_doc_win):
		_doc_win.queue_free()
	update_state = 4
	if m.boot_screen and m.is_inside_tree():
		m._build_boot()
	_open_or_refresh("update")


func open_update() -> void:
	var w = m.open_window("update", "ตั้งค่า › อัปเดต", m.TEX_SETTINGS, Vector2(520, 300))
	for c in w.body.get_children():
		c.queue_free()
	var txt := ""
	match update_state:
		0:
			txt = "ยังไม่ได้ตรวจหาอัปเดต"
		1:
			txt = "พบอัปเดตความปลอดภัย ขนาด %s" % m.size_text(task.update_mb)
		2:
			txt = "กำลังติดตั้ง… ห้ามปิดเครื่อง"
		3:
			txt = "ติดตั้งเสร็จ ต้องรีสตาร์ตเพื่อให้ใช้งานได้"
		4:
			txt = "เครื่องเป็นเวอร์ชันล่าสุดแล้ว ✓"
		-1:
			txt = "อัปเดตล้มเหลว (เครื่องถูกปิดระหว่างติดตั้ง) — ตรวจหาใหม่"
	w.body.add_child(m._label(txt, 17, C_INK))
	if update_state in [0, -1]:
		w.body.add_child(_btn("ตรวจหาอัปเดต", func():
			update_state = 0
			check_update()))
	if update_state == 1:
		w.body.add_child(_btn("ดาวน์โหลดและติดตั้ง", start_install))
	if update_state == 2:
		var pb := ProgressBar.new()
		pb.custom_minimum_size.y = 18
		pb.show_percentage = false
		w.body.add_child(pb)
		m.create_tween().tween_property(pb, "value", 100.0, 3.0)
		w.body.add_child(_btn("ปิดเครื่องเลย (ไม่รอ)", power_off_during_update))
	if update_state == 3:
		w.body.add_child(_btn("รีสตาร์ตตอนนี้", restart_now))

# ---------------------------------------------------------------- ขมการ์ด: สแกนไวรัส + ล้างไฟล์ชั่วคราว (Lv2)


func scan_now() -> int:
	if not protection_on:
		return 0
	scanned = true
	var n := 0
	for k in threat_state:
		if threat_state[k] == "hidden":
			threat_state[k] = "found"
		if threat_state[k] == "found":
			n += 1
	_open_or_refresh("security")
	return n


func quarantine(t_name: String) -> void:
	if threat_state.get(t_name, "") == "found":
		threat_state[t_name] = "quarantine"
	_open_or_refresh("security")


func allow_threat(t_name: String) -> void:
	if threat_state.get(t_name, "") == "found":
		m._trap(&"allow_threat", "allow_" + t_name, &"safety", 10, "กดอนุญาตไวรัส (%s)" % t_name)
		pib_say("อนุญาต = ปล่อยให้ไวรัสอยู่ต่อนะ! ต้องกักกัน", PibHint.Mood.WORRY)
		threat_state[t_name] = "allowed"
	_open_or_refresh("security")


func set_protection(on: bool) -> void:
	if not on and protection_on:
		m._trap(&"disable_antivirus", "noav", &"safety", 10, "ปิดการป้องกันไวรัสเพื่อให้เครื่องเร็ว")
		pib_say("ปิดแอนตี้ไวรัสไม่ได้ทำให้หายอืดหรอก แถมเครื่องไม่ปลอดภัยด้วย", PibHint.Mood.WORRY)
	protection_on = on
	_open_or_refresh("security")


func clean_temp() -> int:
	if temp_cleaned or task.temp_mb <= 0:
		return 0
	temp_cleaned = true
	m.free_mb += task.temp_mb
	m._refresh_all()
	_open_or_refresh("security")
	return task.temp_mb


func threats_left() -> int:
	var n := 0
	for k in threat_state:
		if threat_state[k] in ["hidden", "found", "allowed"]:
			n += 1
	return n


func open_security() -> void:
	var w = m.open_window("security", "ขมการ์ด — ความปลอดภัย", m.TEX_SETTINGS, Vector2(560, 400))
	for c in w.body.get_children():
		c.queue_free()
	var prot := CheckBox.new()
	prot.name = "Protection"
	prot.text = "ป้องกันไวรัสตลอดเวลา (ปิดแล้วเครื่องเร็วขึ้น!?)"
	prot.button_pressed = protection_on
	prot.focus_mode = Control.FOCUS_NONE
	prot.toggled.connect(set_protection)
	w.body.add_child(prot)
	w.body.add_child(_btn("สแกนทั้งเครื่อง", func(): scan_now()))
	if scanned:
		for t in task.threats:
			var st: String = threat_state.get(String(t.name), "")
			var row := HBoxContainer.new()
			row.name = "Threat_" + String(t.name).validate_node_name()
			var l = m._label("%s\n%s · %s" % [t.name, t.get("where", ""), {"found": "พบ!", "quarantine": "กักกันแล้ว", "allowed": "อนุญาตแล้ว"}.get(st, "")], 14, C_BAD if st != "quarantine" else C_OK)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
			if st == "found":
				row.add_child(_btn("กักกัน", quarantine.bind(String(t.name))))
				row.add_child(_btn("อนุญาต", allow_threat.bind(String(t.name))))
			w.body.add_child(row)
	w.body.add_child(HSeparator.new())
	w.body.add_child(m._label("ไฟล์ชั่วคราว: %s" % ("ล้างแล้ว" if temp_cleaned else m.size_text(task.temp_mb)), 15, C_INK))
	if not temp_cleaned and task.temp_mb > 0:
		w.body.add_child(_btn("ล้างไฟล์ชั่วคราว", func(): clean_temp()))

# ---------------------------------------------------------------- จอภาพ (Lv2)


## เลือกความละเอียด · จอไม่รองรับ = ขึ้นถาม "เก็บค่านี้ไหม" (ต้องกด keep_resolution)
func set_resolution(i: int) -> bool:
	if i < 0 or i >= task.resolutions.size():
		return false
	if not task.resolutions[i].get("ok", true):
		_pending_res = i
		_open_or_refresh("display")
		return false
	res_i = i
	_apply_display()
	_open_or_refresh("display")
	return true


func keep_resolution(keep: bool) -> void:
	if _pending_res < 0:
		return
	if keep:
		m._trap(&"bad_resolution", "badres", &"fix", 10, "เก็บความละเอียดที่จอไม่รองรับ (จอดำ)")
		pib_say("จอดำเลย! ความละเอียดที่จอไม่รองรับต้องกดคืนค่าเดิม เลือกอันที่มีคำว่าแนะนำ", PibHint.Mood.WORRY)
	_pending_res = -1
	_open_or_refresh("display")


func set_scale(pct: int) -> void:
	scale_pct = pct
	_apply_display()
	_open_or_refresh("display")


func display_ok() -> bool:
	return task.resolutions.is_empty() or (task.resolutions[res_i].get("best", false) and scale_pct == task.display_scale_best)


## ไอคอน/ตัวหนังสือบนเดสก์ท็อปใหญ่ตามความละเอียดต่ำ + ขนาด %
func _apply_display() -> void:
	if task.goal != DesktopTask.Goal.DISPLAY or not is_instance_valid(m._icons):
		return
	var f := scale_pct / 100.0
	if not task.resolutions.is_empty() and not task.resolutions[res_i].get("best", false):
		f *= 1.35
	m._icons.scale = Vector2.ONE * clampf(f, 1.0, 2.2)


func open_display() -> void:
	var w = m.open_window("display", "ตั้งค่า › จอภาพ", m.TEX_SETTINGS, Vector2(520, 330))
	for c in w.body.get_children():
		c.queue_free()
	if _pending_res >= 0:
		w.body.add_child(m._label("จอดับ… \"%s\" — จอนี้แสดงไม่ได้\nจะเก็บค่านี้ไว้ไหม?" % task.resolutions[_pending_res].name, 17, C_BAD))
		var row := HBoxContainer.new()
		w.body.add_child(row)
		row.add_child(_btn("เก็บค่านี้", keep_resolution.bind(true)))
		row.add_child(_btn("คืนค่าเดิม", keep_resolution.bind(false)))
		return
	w.body.add_child(m._label("ความละเอียดหน้าจอ", 16, C_INK))
	var opt := OptionButton.new()
	opt.name = "Resolution"
	opt.focus_mode = Control.FOCUS_NONE
	for r in task.resolutions:
		opt.add_item(String(r.name) + ("  (แนะนำ)" if r.get("best", false) else ""))
	if not task.resolutions.is_empty():
		opt.select(res_i)
	opt.item_selected.connect(func(i): set_resolution(i))
	w.body.add_child(opt)
	w.body.add_child(m._label("ขนาดตัวหนังสือและไอคอน", 16, C_INK))
	var opt2 := OptionButton.new()
	opt2.name = "Scale"
	opt2.focus_mode = Control.FOCUS_NONE
	var scales := [100, 125, 150, 200]
	for sc in scales:
		opt2.add_item("%d%%%s" % [sc, "  (แนะนำ)" if sc == task.display_scale_best else ""])
	opt2.select(maxi(scales.find(scale_pct), 0))
	opt2.item_selected.connect(func(i): set_scale(scales[i]))
	w.body.add_child(opt2)

# ================================================================ ตรวจงาน


func check_reason() -> String:
	match task.goal:
		DesktopTask.Goal.CLOSE_HANG:
			if not hang_proc().is_empty():
				return "\"%s\" ยังค้างอยู่เลย กดอะไรก็ไม่ขยับ" % hang_proc().name
		DesktopTask.Goal.STARTUP:
			for p in procs:
				if p.kind == "system" and p.startup and not p.startup_on:
					return "%s ไม่เปิดพร้อมเครื่อง เครื่องไม่ปลอดภัย" % p.name
			if boot_time() > task.boot_target_s:
				return "เปิดเครื่องยังช้าอยู่ (~%d วินาที) ลูกค้ารอนานเกิน" % boot_time()
		DesktopTask.Goal.PRINTER:
			if not printed_ok:
				return "สั่งพิมพ์แล้วกระดาษไม่ออกที่โต๊ะลูกค้า" if default_printer != "" else "ยังพิมพ์ไม่ได้ ไม่มีเครื่องพิมพ์ในเครื่อง"
			if not _printer(default_printer).get("right", false):
				return "สั่งพิมพ์แล้วไปออกที่เครื่อง \"%s\"" % default_printer
		DesktopTask.Goal.SOUND:
			if not sound_ok():
				return "เปิดเพลงแล้วยังเงียบ — " + test_sound()
		DesktopTask.Goal.WIFI:
			var net := _net(wifi_connected)
			if wifi_connected == "":
				return "ยังเข้าเน็ตไม่ได้เลย"
			if not net.get("right", false):
				return "เข้าเน็ตได้ แต่เป็นเน็ตสาธารณะ ไม่ใช่เน็ตบ้านลูกค้า"
		DesktopTask.Goal.BACKUP:
			var miss := backup_missing()
			if not miss.is_empty():
				return "รูปยังไม่ครบสองที่ (ในเครื่อง + USB): %s" % ", ".join(miss)
			if not usb_ejected:
				return "ยังไม่ได้กด \"ถอด USB อย่างปลอดภัย\" ดึงออกเลยไฟล์อาจเสีย"
		DesktopTask.Goal.UPDATE:
			if update_state != 4:
				return "เครื่องยังไม่ได้อัปเดต" if update_state < 3 else "ติดตั้งแล้วแต่ยังไม่ได้รีสตาร์ต"
		DesktopTask.Goal.VIRUS_SCAN:
			if not protection_on:
				return "การป้องกันไวรัสถูกปิดอยู่ เครื่องไม่ปลอดภัย"
			if not scanned or threats_left() > 0:
				return "ยังมีไวรัสอยู่ในเครื่อง (สแกนแล้วกักกันให้หมด)"
			if task.temp_mb > 0 and not temp_cleaned:
				return "ยังอืดอยู่ ไฟล์ชั่วคราวเต็มเครื่อง"
		DesktopTask.Goal.DISPLAY:
			if _pending_res >= 0:
				return "จอดำอยู่!"
			if not display_ok():
				return "จอยังดูแปลก ๆ ตัวหนังสือใหญ่/แตกอยู่"
	return ""

# ================================================================ ช่วย


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.name = "Btn_" + text.validate_node_name()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(cb)
	return b


## ถ้าหน้าต่างเปิดอยู่ วาดใหม่ (ปุ่มกดแล้วสถานะเปลี่ยน) · ปิดอยู่ไม่ต้องเปิด
func _open_or_refresh(key: String) -> void:
	if not m._windows.has(key) or not is_instance_valid(m._windows[key]):
		return
	match key:
		"printers":
			open_printers.call_deferred()
		"sound":
			open_sound.call_deferred()
		"wifi":
			open_wifi.call_deferred()
		"update":
			open_update.call_deferred()
		"security":
			open_security.call_deferred()
		"display":
			open_display.call_deferred()
