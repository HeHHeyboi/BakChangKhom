extends Phase2D
## Phase 6 · TEST_BUTTON — เสียบปลั๊ก → กดปุ่มหน้าเคส → ดูอาการ
##   POWER SW ผิดคู่ → เงียบ (TEST_FAIL_POWER · สลับกับ RESET = TEST_SWAPPED) · POWER LED ผิด → เครื่องติดแต่ไฟหน้าเคสดับ
##   HDD LED ผิด → ไฟดิสก์ไม่กะพริบ · ผิดข้อใดก็ตาม −7 connect แล้วถอดปลั๊กย้อนไปขั้น CONNECT · [Claude 2 ต.ค. 2569]

enum Step { PLUG, PRESS, RESULT, DONE }

var step := Step.PLUG
var _built := false
var _chk: Array[Label] = []
var _back := false
var _blink: Tween


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมปุ่มหน้าเคส — ขั้นที่ 6/8 · ทดสอบปุ่ม")
		for t in ["เสียบปลั๊กไฟท้ายเคส", "กดปุ่มเปิดเครื่องหน้าเคส", "ดูไฟ POWER + ไฟ HDD"]:
			_chk.append(PhaseUI.check_item(rail, t))
	step = Step.PLUG
	_back = false
	for c in _chk:
		PhaseUI.set_check(c, false)
	show()
	if owner.plugged:
		_plugged()
	else:
		allow([node("PowerCord")])
		cam(&"Rear")
		hint(node("PowerCord"), "เสียบปลั๊ก", 3.0)
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("TEST_INTRO")


func _on_clicked(p: Item2D) -> void:
	match step:
		Step.PLUG:
			if p == node("PowerCord"):
				p.set_state("")
				owner.plugged = true
				(node("MbLed") as Item2D).set_state("")
				_plugged()
		Step.PRESS:
			if p == node("PowerButton"):
				_press()


func _plugged() -> void:
	PhaseUI.set_check(_chk[0], true)
	step = Step.PRESS
	allow([node("PowerButton")])
	cam(&"Monitor")
	hint(node("PowerButton"), "กดปุ่มเปิดเครื่อง", 3.0)


func _press() -> void:
	step = Step.RESULT
	allow([])
	clear_hint()
	PhaseUI.set_check(_chk[1], true)
	var pl: Dictionary = owner.placement
	if pl["power_sw"] != "pwr":
		await wait(1.0)
		_fail("TEST_SWAPPED" if pl["power_sw"] == "rst" and pl["reset_sw"] == "pwr" else "TEST_FAIL_POWER")
		return
	var led_ok: bool = owner.conn_ok("power_led")
	var hdd_ok: bool = owner.conn_ok("hdd_led")
	(node("Monitor") as Item2D).set_state("boot")
	owner.set_front_leds(led_ok, false)
	if hdd_ok:
		_start_blink()
	await wait(1.6)
	PhaseUI.set_check(_chk[2], led_ok and hdd_ok)
	if not led_ok:
		_fail("TEST_FAIL_LED")
	elif not hdd_ok:
		_fail("CONNECT_POLARITY" if owner.placement["hdd_led"] == "hdd" else "TEST_FAIL_HDD")
	else:
		(node("Monitor") as Item2D).set_state("desktop")
		step = Step.DONE
		say("TEST_PASS", PibHint.Mood.HAPPY)


func _start_blink() -> void:
	var h := node("HddLed") as Item2D
	_blink = create_tween().set_loops(6)
	_blink.tween_callback(h.set_state.bind("on"))
	_blink.tween_interval(0.12)
	_blink.tween_callback(h.set_state.bind("off"))
	_blink.tween_interval(0.2)


func _fail(header: String) -> void:
	mistake.emit(&"connect", 7)
	step = Step.DONE
	_back = true
	say(header, PibHint.Mood.WORRY)


## ปิดเครื่อง + ถอดปลั๊กก่อนกลับไปแก้หัวต่อ
func _shutdown() -> void:
	if _blink and _blink.is_valid():
		_blink.kill()
	(node("Monitor") as Item2D).set_state("off")
	owner.set_front_leds(false, false)
	owner.plugged = false
	(node("PowerCord") as Item2D).set_state("out")
	(node("MbLed") as Item2D).set_state("off")


func _on_pib_done() -> void:
	if not visible or step != Step.DONE:
		return
	if _back:
		_back = false
		_shutdown()
		owner.go_phase(PartFrontPanel.PhaseState.CONNECT)
		return
	finish()
