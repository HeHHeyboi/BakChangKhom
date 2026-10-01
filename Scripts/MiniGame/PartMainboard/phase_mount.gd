extends Phase2D
## Phase 8 · MOUNT + VERIFY — ฮีตซิงก์วางกลับ → ขันน็อต 4 ตัว (ระบบจำลำดับ · ไขว้ 1→3→2→4 ดีที่สุด)
## → เสียบปลั๊ก → กดเปิดเครื่อง → จอโชว์อุณหภูมิ CPU ไต่ขึ้นแล้วนิ่ง
## อุณหภูมิ = BASE_TEMP + ซิลิโคนน้อย 8 + ขันไม่ไขว้ 8 · ≤ 65 ผ่าน · 66–80 ผ่านแบบเตือน
## [Claude 2 ต.ค. 2569]

enum Step { SCREWS, PLUG, POWER, RESULT, DONE }

var step := Step.SCREWS
var _order: Array[int] = []
var _built := false
var _chk: Array[Label] = []


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเมนบอร์ด — ขั้นที่ 8/8 · ประกอบ + ทดสอบ")
		PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
		for t in ["ขันน็อตฮีตซิงก์ 4 ตัว (ทแยงมุม)", "เสียบปลั๊กคืน", "กดเปิดเครื่อง ดูอุณหภูมิ"]:
			_chk.append(PhaseUI.check_item(rail, t))
	step = Step.SCREWS
	_order.clear()
	for c in _chk:
		PhaseUI.set_check(c, false)
	var cooler := node("CoolerTop") as Item2D
	cooler.set_state("")
	cooler.modulate.a = 0.0
	create_tween().tween_property(cooler, "modulate:a", 1.0, 0.35)
	for s in owner.screws():
		s.set_state("")
		s.rotation_degrees = -540.0
		s.modulate = Color(0.75, 0.75, 0.8)
	(node("TempLabel") as Label).hide()
	show()
	allow(owner.screws())
	cam(&"Socket")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("MOUNT")
	_hint_next()


func _num(s: Item2D) -> int:
	return String(s.name).right(1).to_int()


func _hint_next() -> void:
	match step:
		Step.SCREWS:
			for s in owner.screws():
				if not _order.has(_num(s)):
					hint(s, "ขันน็อต", 5.0)
					return
		Step.PLUG:
			hint(node("Plug"), "เสียบปลั๊ก", 4.0, &"Rear")
		Step.POWER:
			hint(node("PowerButton"), "กดเปิดเครื่อง", 4.0, &"Monitor")
		_:
			clear_hint()


func _on_clicked(p: Item2D) -> void:
	match step:
		Step.SCREWS:
			if owner.screws().has(p) and not _order.has(_num(p)):
				_order.append(_num(p))
				var tw := create_tween().set_parallel()
				tw.tween_property(p, "rotation_degrees", 0.0, 0.45)
				tw.tween_property(p, "modulate", Color.WHITE, 0.45)
				if _order.size() == 4:
					PhaseUI.set_check(_chk[0], true)
					owner.screw_diagonal = PartMainboard.is_diagonal(_order)
					if not owner.screw_diagonal:
						mistake.emit(&"screws", 5)
						say("MOUNT_WRONG_ORDER")
					else:
						say("MOUNT_DONE", PibHint.Mood.HAPPY)
					step = Step.PLUG
					allow([node("Plug")])
					cam(&"Rear")
				_hint_next()
		Step.PLUG:
			if p == node("Plug"):
				p.set_state("")
				owner.plugged = true
				PhaseUI.set_check(_chk[1], true)
				step = Step.POWER
				allow([node("PowerButton")])
				cam(&"Monitor")
				_hint_next()
		Step.POWER:
			if p == node("PowerButton"):
				_power_on()


func _power_on() -> void:
	step = Step.RESULT
	allow([])
	clear_hint()
	var btn := node("PowerButton") as Control
	btn.pivot_offset = btn.size / 2.0
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE * 0.85, 0.06)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.06)
	owner.set_led(true)
	(node("Monitor") as Item2D).set_state("temp")
	var temp: float = PartMainboard.BASE_TEMP
	if owner.paste_amount == 0:
		temp += 8.0
	if not owner.screw_diagonal:
		temp += 8.0
	owner.temp_result = temp
	var lbl := node("TempLabel") as Label
	lbl.show()
	var t2 := create_tween()
	t2.tween_method(func(v: float): lbl.text = "%d°C" % int(v), 32.0, temp + 6.0, 1.6)
	t2.tween_method(func(v: float): lbl.text = "%d°C" % int(v), temp + 6.0, temp, 0.8)
	await t2.finished
	lbl.add_theme_color_override("font_color", Color(0.49, 0.94, 0.66) if temp <= 65.0 else Color(1, 0.75, 0.3))
	PhaseUI.set_check(_chk[2], true)
	step = Step.DONE
	say("VERIFY_GOOD" if temp <= 65.0 else "VERIFY_HOT", PibHint.Mood.HAPPY if temp <= 65.0 else PibHint.Mood.WORRY)


func _on_pib_done() -> void:
	if visible and step == Step.DONE:
		finish()
