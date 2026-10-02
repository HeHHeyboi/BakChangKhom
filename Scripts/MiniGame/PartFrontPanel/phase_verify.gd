extends Phase2D
## Phase 8 · VERIFY — เสียบปลั๊ก → กดปุ่มหน้าเคส → เข้า BIOS ดูบรรทัด Memory
##   แรมแถวไหนยังไม่ลงสุด → BIOS เห็นแค่ 8GB Single → −5 verify แล้วกลับไปขั้น DUAL_CHANNEL · [Claude 2 ต.ค. 2569]

enum Step { PLUG, PRESS, RESULT, DONE }

var step := Step.PLUG
var _built := false
var _chk: Array[Label] = []
var _back := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมปุ่มหน้าเคส — ขั้นที่ 8/8 · บูตเข้า BIOS")
		for t in ["เสียบปลั๊กไฟ", "กดปุ่มเปิดเครื่อง", "อ่านบรรทัด Memory ใน BIOS"]:
			_chk.append(PhaseUI.check_item(rail, t))
	step = Step.PLUG
	_back = false
	for c in _chk:
		PhaseUI.set_check(c, false)
	(node("MemLabel") as Label).hide()
	show()
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	if owner.plugged:
		_plugged()
	else:
		allow([node("PowerCord")])
		cam(&"Rear")
		hint(node("PowerCord"), "เสียบปลั๊ก", 3.0)
	toast("VERIFY_INTRO")


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
				_boot()


func _plugged() -> void:
	PhaseUI.set_check(_chk[0], true)
	step = Step.PRESS
	allow([node("PowerButton")])
	cam(&"Monitor")
	hint(node("PowerButton"), "กดเปิดเครื่อง", 3.0)


func _boot() -> void:
	step = Step.RESULT
	allow([node("PowerLed")])
	clear_hint()
	PhaseUI.set_check(_chk[1], true)
	owner.set_front_leds(true, true)
	var mon := node("Monitor") as Item2D
	mon.set_state("boot")
	await wait(1.0)
	mon.set_state("bios")
	owner.set_front_leds(true, false)
	var locked: Array = owner.ram_slots().filter(func(s): return owner.ram[s] == "locked")
	var dual: bool = locked.size() == 2 and owner.is_dual()
	owner.channel_result = "Dual" if dual else "Single"
	var lbl := node("MemLabel") as Label
	lbl.text = "Memory : %dGB  %s Channel" % [8 * locked.size(), owner.channel_result]
	lbl.add_theme_color_override("font_color", Color(0.55, 1, 0.65) if dual else Color(1, 0.7, 0.35))
	await wait(0.3)
	lbl.show()
	PhaseUI.set_check(_chk[2], true)
	step = Step.DONE
	if dual:
		say("VERIFY", PibHint.Mood.HAPPY)
	else:
		mistake.emit(&"verify", 5)
		_back = true
		say("DUAL_CHANNEL_NOT_LOCKED", PibHint.Mood.WORRY)


func _on_pib_done() -> void:
	if not visible or step != Step.DONE:
		return
	if _back:
		_back = false
		(node("MemLabel") as Label).hide()
		owner.go_phase(PartFrontPanel.PhaseState.DUAL_CHANNEL)
		return
	finish()
