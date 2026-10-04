extends Phase2D
## Phase 8 · AIRFLOW + VERIFY — เก็บสาย 3 เส้นที่พาดหน้าพัดลม → รัดเคเบิลไท · ตั้งทิศพัดลม 3 ตัว (คลิกลูกศรสลับเข้า/ออก)
## → ย้ายสาย HDMI ไปที่การ์ดจอ → เสียบปลั๊ก → กดเปิดเครื่อง → ดูภาพ + อุณหภูมิการ์ด
## หัวสายไฟยังไม่คลิก → เครื่องดับกลางคัน แล้วกลับไปขั้น POWER
## คะแนน airflow (20): ไม่เก็บสายเลย −8 · เก็บไม่ครบ/ไม่รัด −3 · ทิศพัดลมผิด −5/ตัว · [Claude 2 ต.ค. 2569]

enum Step { ARRANGE, PLUG, POWER, RESULT, DONE }

const MESS := ["Mess1", "Mess2", "Mess3"]
const BASE_TEMP := 62.0

var step := Step.ARRANGE
var _tidied := 0
var _tied := false
var _hdmi_moved := false
var _built := false
var _chk: Array[Label] = []
var _test_btn: Button
var _said_cables := false
var _scored := false # คิดคะแนนครั้งเดียว — ถ้าถูกส่งกลับไปแก้สายไฟแล้ววนมาใหม่ ไม่หักซ้ำ


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมการ์ดจอ — ขั้นที่ 8/8 · จัดสาย + ทดสอบ")
		for t in ["เก็บสายหลังถาดเมนบอร์ด 3 เส้น", "รัดเคเบิลไท", "ตั้งทิศพัดลม (หน้าเข้า · หลัง/บนออก)", "ย้ายสาย HDMI ไปที่การ์ดจอ", "เสียบปลั๊ก แล้วเปิดเครื่อง"]:
			_chk.append(PhaseUI.check_item(rail, t))
		_test_btn = PhaseUI.rail_button(rail, "ทดสอบเปิดเครื่อง ►", start_test)
	step = Step.ARRANGE
	_tidied = 0
	_tied = false
	_said_cables = false
	for c in _chk:
		PhaseUI.set_check(c, false)
	for m in MESS:
		(node(m) as Item2D).set_state("")
	(node("TidyBundle") as Item2D).set_state("off")
	_hdmi_moved = (node("HdmiCable") as Item2D).has_meta("on_gpu")
	if _hdmi_moved:
		PhaseUI.set_check(_chk[3], true)
	_test_btn.show()
	(node("TempLabel") as Label).hide()
	owner.apply_fans()
	_refresh_fan_check()
	show()
	_allow_arrange()
	cam(&"Case")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("AIRFLOW")


func _allow_arrange() -> void:
	var a: Array = [node("FanFront"), node("FanRear"), node("FanTop"), node("CableTie"), node("HdmiCable")]
	for m in MESS:
		a.append(node(m))
	allow(a)


func _refresh_fan_check() -> void:
	PhaseUI.set_check(_chk[2], owner.fans_wrong() == 0)


func _on_clicked(p: Item2D) -> void:
	match step:
		Step.ARRANGE:
			_arrange_click(p)
		Step.PLUG:
			if p == node("PowerCord"):
				p.set_state("")
				owner.plugged = true
				step = Step.POWER
				allow([node("PowerButton")])
				cam(&"Monitor")
				hint(node("PowerButton"), "กดเปิดเครื่อง", 3.0)
		Step.POWER:
			if p == node("PowerButton"):
				_power_on()


func _arrange_click(p: Item2D) -> void:
	var nm := String(p.name)
	if MESS.has(nm) and p.state != "off":
		p.set_state("off")
		_tidied += 1
		if not _said_cables:
			_said_cables = true
			say("CABLES")
		PhaseUI.set_check(_chk[0], _tidied >= MESS.size())
	elif nm == "CableTie":
		if _tidied < MESS.size():
			say_text(["เก็บสายให้ครบสามเส้นก่อน แล้วค่อยรัดทีเดียว"])
		elif not _tied:
			_tied = true
			(node("TidyBundle") as Item2D).set_state("")
			PhaseUI.set_check(_chk[1], true)
	elif nm.begins_with("Fan"):
		var f: int = { "FanFront": PartGpu.Fan.FRONT, "FanRear": PartGpu.Fan.REAR, "FanTop": PartGpu.Fan.TOP }[nm]
		owner.fan_intake[f] = not owner.fan_intake[f]
		owner.apply_fans(true)
		_refresh_fan_check()
	elif nm == "HdmiCable" and not _hdmi_moved:
		move_hdmi()


func move_hdmi() -> void:
	var h := node("HdmiCable") as Control
	_hdmi_moved = true
	h.set_meta("on_gpu", true)
	var tw := create_tween()
	tw.tween_property(h, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): h.position = h.get_meta("gpu_pos", h.position))
	tw.tween_property(h, "modulate:a", 1.0, 0.2)
	PhaseUI.set_check(_chk[3], true)


func start_test() -> void:
	if step != Step.ARRANGE:
		return
	if not _hdmi_moved:
		say("HDMI_MOVE")
		cam(&"Rear")
		hint(node("HdmiCable"), "ย้ายสายไปเสียบการ์ดจอ", 1.0)
		return
	# คิดคะแนนตอนกดทดสอบ (เหมือนส่งงาน)
	if not _scored:
		_scored = true
		var wrong: int = owner.fans_wrong()
		if wrong > 0:
			mistake.emit(&"airflow", 5 * wrong)
		if _tidied == 0:
			mistake.emit(&"airflow", 8)
		elif _tidied < MESS.size() or not _tied:
			mistake.emit(&"airflow", 3)
	_test_btn.hide()
	PhaseUI.refresh(self)
	step = Step.PLUG
	allow([node("PowerCord")])
	cam(&"Rear")
	hint(node("PowerCord"), "เสียบปลั๊ก", 3.0)


func _power_on() -> void:
	step = Step.RESULT
	allow([])
	clear_hint()
	owner.set_led(true)
	(node("GpuLed") as Item2D).set_state("on")
	var mon := node("Monitor") as Item2D
	mon.set_state("boot")
	await wait(1.2)
	if not owner.cable_locked:
		# หัวสายไม่สุด — ไฟกระตุกแล้วดับ
		mon.set_state("off")
		owner.set_led(false)
		(node("GpuLed") as Item2D).set_state("off")
		step = Step.DONE
		say("POWER_NOT_CLICKED", PibHint.Mood.WORRY)
		set_meta("back_to_power", true)
		return
	PhaseUI.set_check(_chk[4], true)
	var temp: float = BASE_TEMP + 6.0 * owner.fans_wrong() + (5.0 if _tidied < MESS.size() else 0.0) + (4.0 if owner.cable_molex else 0.0)
	owner.temp_result = temp
	mon.set_state("boot_ok")
	var lbl := node("TempLabel") as Label
	lbl.text = "GPU %d°C" % int(temp)
	lbl.add_theme_color_override("font_color", Color(0.49, 0.94, 0.66) if temp <= 70.0 else Color(1, 0.75, 0.3))
	lbl.show()
	step = Step.DONE
	if owner.fans_wrong() > 0:
		say("AIRFLOW_WRONG", PibHint.Mood.WORRY)
	elif _tidied < MESS.size():
		say("CABLES_MESSY", PibHint.Mood.WORRY)
	else:
		say("VERIFY_GOOD" if temp <= 70.0 else "VERIFY_HOT", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if not visible or step != Step.DONE:
		return
	if has_meta("back_to_power"):
		remove_meta("back_to_power")
		owner.return_to_power()
		return
	finish()
