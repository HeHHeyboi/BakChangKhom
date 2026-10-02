extends Phase2D
## Phase 6 · SAVE_EXIT — เลือกปุ่มท้ายจอ BIOS แล้วเครื่องรีบูตจริง
##   Save & Exit ✅ · Discard −10 save → ค่าที่ตั้งหาย กลับไปจัดลำดับใหม่ · Load Defaults −5 save → ค่าโรงงาน (XMP หาย)
##   ผลบูต: USB ลูกค้าอันดับ 1 = วนกลับ BIOS · Network = ค้าง PXE · DVD = หาไม่เจอ → −10 boot แล้วกลับขั้น BOOT_ORDER
##   บูตได้เพราะถอด USB แต่ลำดับยังผิด = ผ่านแบบเตือน −8 · Profile 1 ล้ม → ถอดปลั๊ก → ถอดถ่าน CMOS → เสียบปลั๊ก → ขั้น XMP
## [Claude 2 ต.ค. 2569]

enum Step { CHOOSE, BOOTING, RESULT, CMOS_UNPLUG, CMOS_BATTERY, CMOS_REPLUG, DONE }

var step := Step.CHOOSE
var _built := false
var _chk: Array[Label] = []
var _next := -1 # phase ที่จะไปหลังปิ๊บพูดจบ (-1 = finish)


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเครื่องค้าง BIOS — ขั้นที่ 6/8 · บันทึกแล้วรีบูต")
		for t in ["เลือกปุ่มท้ายจอ BIOS", "เครื่องบูตเข้า Windows"]:
			_chk.append(PhaseUI.check_item(rail, t))
	step = Step.CHOOSE
	_next = -1
	for c in _chk:
		PhaseUI.set_check(c, false)
	show()
	allow([node("BtnSave"), node("BtnDiscard"), node("BtnDefault")])
	cam(&"Bios")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("SAVE_EXIT")


func _on_clicked(p: Item2D) -> void:
	match step:
		Step.CHOOSE:
			_choose(String(p.name))
		Step.CMOS_UNPLUG:
			if p == node("PowerCord"):
				owner.plugged = false
				p.set_state("out")
				owner.set_power(false)
				step = Step.CMOS_BATTERY
				allow([node("CmosBattery")])
				cam(&"Case")
				hint(node("CmosBattery"), "แงะถ่าน CMOS ออก", 3.0)
		Step.CMOS_BATTERY:
			if p == node("CmosBattery"):
				_clear_cmos()
		Step.CMOS_REPLUG:
			if p == node("PowerCord"):
				owner.plugged = true
				p.set_state("")
				owner.set_power(true, "bios")
				step = Step.DONE
				_next = PartBios.PhaseState.XMP
				say("CMOS_DONE")


func _choose(n: String) -> void:
	match n:
		"BtnSave":
			owner.save_settings()
		"BtnDiscard":
			mistake.emit(&"save", 10)
			owner.discard()
			step = Step.DONE
			_next = PartBios.PhaseState.BOOT_ORDER
			say("SAVE_DISCARD", PibHint.Mood.WORRY)
			return
		"BtnDefault":
			mistake.emit(&"save", 5)
			owner.load_defaults()
			owner.save_settings()
			toast("SAVE_DEFAULT")
		_:
			return
	PhaseUI.set_check(_chk[0], true)
	_boot()


func _boot() -> void:
	step = Step.BOOTING
	allow([node("BtnSave")])
	cam(&"Monitor")
	owner.set_power(true, "post")
	await wait(1.4)
	if not visible:
		return
	step = Step.RESULT
	var mon := node("Monitor") as Item2D
	if owner.xmp_fails():
		mon.set_state("off") # ไฟเครื่องติด พัดลมหมุน แต่จอดำ
		say("XMP_FAILED", PibHint.Mood.WORRY)
		return
	var dev: String = owner.first_boot_device()
	match dev:
		"hdd":
			mon.set_state("desktop")
			PhaseUI.set_check(_chk[1], true)
			step = Step.DONE
			if owner.saved_order[0] != "hdd" and not owner.has_meta("root_warned"):
				owner.set_meta("root_warned", true)
				mistake.emit(&"boot", 8)
				say("BOOT_ORDER_USB_ONLY", PibHint.Mood.WORRY)
			else:
				say("BOOT_OK", PibHint.Mood.HAPPY)
		"net":
			_fail("pxe", "BOOT_ORDER_NETWORK")
		"dvd":
			_fail("noboot", "BOOT_DVD")
		_:
			_fail("noboot", "BOOT_LOOP")


func _fail(screen: String, header: String) -> void:
	(node("Monitor") as Item2D).set_state(screen)
	mistake.emit(&"boot", 10)
	step = Step.DONE
	_next = PartBios.PhaseState.BOOT_ORDER
	say(header, PibHint.Mood.WORRY)


func _clear_cmos() -> void:
	step = Step.RESULT
	allow([node("CaseFrame")])
	clear_hint()
	var bat := node("CmosBattery") as Item2D
	bat.set_state("out")
	toast("CMOS_WAIT")
	await wait(1.5)
	bat.set_state("")
	owner.load_defaults()
	owner.save_settings()
	step = Step.CMOS_REPLUG
	allow([node("PowerCord")])
	cam(&"Rear")
	hint(node("PowerCord"), "เสียบปลั๊กกลับ", 3.0)


func _on_pib_done() -> void:
	if not visible:
		return
	if step == Step.RESULT and (node("Monitor") as Item2D).state == "off":
		# หลัง XMP_FAILED → เริ่มเคลียร์ CMOS
		step = Step.CMOS_UNPLUG
		allow([node("PowerCord")])
		cam(&"Rear")
		hint(node("PowerCord"), "ถอดปลั๊กก่อน", 3.0)
		return
	if step != Step.DONE:
		return
	if _next >= 0:
		var to := _next
		_next = -1
		owner.set_power(true, "bios")
		owner.go_phase(to)
		return
	finish()
