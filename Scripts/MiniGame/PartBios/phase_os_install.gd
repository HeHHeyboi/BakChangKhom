extends Phase2D
## Phase 7 · OS_INSTALL — ลูกค้าซื้อ SSD มาด้วย อยากให้ลง Windows ใหม่บน SSD (เก็บ HDD ไว้เป็นที่เก็บข้อมูล)
##   เสียบ USB ตัวติดตั้งของร้าน → กดปุ่มรีสตาร์ต (บูตผ่าน Boot Menu F11 ครั้งเดียว) → เลือกไดรฟ์
##   SSD ✅ · USB −5 (ลงทับตัวติดตั้งไม่ได้) · HDD ลูกค้า: ครั้งแรกปิ๊บหยุดมือ −10 · ยืนยันลงทับ −10 อีก = ข้อมูลลูกค้าหาย
## [Claude 2 ต.ค. 2569]

enum Step { PLUG, RESTART, CHOOSE, CONFIRM, INSTALLING, DONE }

const FILL_W := 572.0

var step := Step.PLUG
var _built := false
var _chk: Array[Label] = []
var _cancel_btn: Button
var _confirm_btn: Button


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเครื่องค้าง BIOS — ขั้นที่ 7/8 · ลง Windows ลง SSD")
		for t in ["เสียบ USB ตัวติดตั้ง (ท้ายเคส)", "รีสตาร์ตเข้าตัวติดตั้ง", "เลือกไดรฟ์ให้ถูก", "รอติดตั้งเสร็จ"]:
			_chk.append(PhaseUI.check_item(rail, t))
		_cancel_btn = PhaseUI.rail_button(rail, "ยกเลิก กลับไปเลือกใหม่", _on_cancel)
		_confirm_btn = PhaseUI.rail_button(rail, "ยืนยันลงทับ HDD", _on_confirm)
	step = Step.PLUG
	for c in _chk:
		PhaseUI.set_check(c, false)
	_popup(false)
	owner.show_progress(false)
	show()
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	if owner.installer_plugged:
		_plugged()
	else:
		allow([node("UsbInstaller")])
		cam(&"Rear")
		hint(node("UsbInstaller"), "เสียบ USB ตัวติดตั้ง", 4.0)
	say("OS_INTRO")


func _popup(on: bool) -> void:
	(node("Popup") as Item2D).set_state("" if on else "off")
	(node("PopupLabel") as Label).visible = on
	_cancel_btn.visible = on
	_confirm_btn.visible = on
	PhaseUI.refresh(self)


func _on_clicked(p: Item2D) -> void:
	match step:
		Step.PLUG:
			if p == node("UsbInstaller"):
				owner.installer_plugged = true
				p.set_state("")
				_plugged()
		Step.RESTART:
			if p == node("PowerButton"):
				_restart()
		Step.CHOOSE:
			_choose(String(p.name))


func _plugged() -> void:
	PhaseUI.set_check(_chk[0], true)
	step = Step.RESTART
	allow([node("PowerButton")])
	cam(&"Monitor")
	hint(node("PowerButton"), "กดรีสตาร์ต", 3.0)


func _restart() -> void:
	step = Step.CHOOSE
	clear_hint()
	PhaseUI.set_check(_chk[1], true)
	owner.set_power(true, "post")
	toast("OS_BOOTMENU")
	await wait(1.0)
	(node("Monitor") as Item2D).set_state("install")
	allow([node("DriveSsd"), node("DriveHdd"), node("DriveUsb")])
	cam(&"Install")


func _choose(n: String) -> void:
	match n:
		"DriveSsd":
			_install("ssd")
		"DriveUsb":
			mistake.emit(&"os", 5)
			toast("OS_USB_NO")
		"DriveHdd":
			step = Step.CONFIRM
			if not owner.has_meta("hdd_warned"):
				owner.set_meta("hdd_warned", true)
				mistake.emit(&"os", 10)
			(node("PopupLabel") as Label).text = "ไดรฟ์นี้มีข้อมูลของลูกค้า 640 GB\n(รูปครอบครัว · เอกสารงาน)\nลง Windows ทับ = ลบทั้งหมด กู้คืนยากมาก"
			_popup(true)
			allow([node("Popup")])
			say("OS_SELECT_CUSTOMER_DISK", PibHint.Mood.WORRY)


func _on_cancel() -> void:
	if step != Step.CONFIRM:
		return
	_popup(false)
	step = Step.CHOOSE
	allow([node("DriveSsd"), node("DriveHdd"), node("DriveUsb")])


func _on_confirm() -> void:
	if step != Step.CONFIRM:
		return
	_popup(false)
	mistake.emit(&"os", 10)
	owner.data_lost = true
	_install("hdd")


func _install(drive: String) -> void:
	step = Step.INSTALLING
	owner.os_drive = drive
	PhaseUI.set_check(_chk[2], drive == "ssd")
	allow([node("Popup")])
	owner.show_progress(true)
	var lbl := node("ProgressLabel") as Label
	_set_progress(0.0)
	say("OS_DATA_LOST" if owner.data_lost else "OS_SELECT_SSD", PibHint.Mood.WORRY if owner.data_lost else PibHint.Mood.HAPPY)
	var tw := create_tween()
	tw.tween_method(_set_progress, 0.0, 1.0, 5.0)
	await tw.finished
	if not visible:
		return
	lbl.text = "Installing Windows... 100%"
	PhaseUI.set_check(_chk[3], true)
	owner.refresh_bios()
	step = Step.DONE
	cam(&"Monitor")
	(node("Monitor") as Item2D).set_state("desktop")
	say("OS_DONE", PibHint.Mood.HAPPY)


func _set_progress(t: float) -> void:
	(node("ProgressFill") as ColorRect).size.x = FILL_W * t
	(node("ProgressLabel") as Label).text = "Installing Windows... %d%%" % int(t * 100.0)


func _on_pib_done() -> void:
	if visible and step == Step.DONE:
		finish()
