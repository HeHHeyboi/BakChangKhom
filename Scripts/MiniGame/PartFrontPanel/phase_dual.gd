extends Phase2D
## Phase 7 · DUAL_CHANNEL — ปิดเครื่องถอดปลั๊ก → ย้ายแรม 2 แถวจาก A1+A2 (single) ไปคู่สีเดียวกัน A2+B2 (dual)
##   คลิกแรมที่ล็อกอยู่ = ถอดออกมาถือ · คลิกสล็อตว่าง = วางแรม (ยังไม่ลงสุด) · คลิกแรมที่วางไว้ = กดลงจนสลักดีด
##   ยืนยันแบบ single −8 แล้วต้องแก้ใหม่ · A1+B1 ผ่าน (ปิ๊บบอกว่าคู่มือแนะนำ A2+B2)
##   ลืมกดแรมลงสุด → ขั้น VERIFY จะเจอแล้วส่งกลับมา · [Claude 2 ต.ค. 2569]

enum Step { UNPLUG, ARRANGE, DONE }

var step := Step.UNPLUG
var _built := false
var _chk: Array[Label] = []
var _hand: Label
var _ok_btn: Button
var _said_single := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมปุ่มหน้าเคส — ขั้นที่ 7/8 · จัดแรม Dual Channel")
		for t in ["ปิดเครื่อง ถอดปลั๊ก", "ใส่แรม 2 แถวคนละแชนแนล (A + B)", "กดแรมลงจนสลักล็อก"]:
			_chk.append(PhaseUI.check_item(rail, t))
		_hand = PhaseUI.label(rail, "", 18, PhaseUI.COL_OK)
		_ok_btn = rail_button(rail, "จัดเสร็จแล้ว ►", _on_ok)
	_said_single = false
	for c in _chk:
		PhaseUI.set_check(c, false)
	show()
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	if owner.plugged:
		step = Step.UNPLUG
		_ok_btn.hide()
		allow([node("PowerCord")])
		cam(&"Rear")
		hint(node("PowerCord"), "ถอดปลั๊กก่อนยุ่งกับแรม", 3.0)
		toast("DUAL_UNPLUG")
	else:
		_arrange()


func _arrange() -> void:
	step = Step.ARRANGE
	PhaseUI.set_check(_chk[0], true)
	cam(&"Slots")
	_refresh()
	say("DUAL_CHANNEL")


func _refresh() -> void:
	var a: Array = []
	for s in PartFrontPanel.SLOTS:
		a.append(node(("Ram" if owner.ram[s] != "" else "Slot") + s))
	allow(a)
	_hand.text = "แรมในมือ: %d แถว" % owner.ram_in_hand
	PhaseUI.set_check(_chk[1], owner.is_dual())
	var all_locked := true
	for s in owner.ram_slots():
		all_locked = all_locked and owner.ram[s] == "locked"
	PhaseUI.set_check(_chk[2], all_locked and owner.ram_in_hand == 0)
	_ok_btn.visible = step == Step.ARRANGE
	PhaseUI.refresh(self)


func _on_clicked(p: Item2D) -> void:
	if step == Step.UNPLUG:
		if p == node("PowerCord"):
			(node("Monitor") as Item2D).set_state("off")
			owner.set_front_leds(false, false)
			owner.plugged = false
			p.set_state("out")
			(node("MbLed") as Item2D).set_state("off")
			clear_hint()
			_arrange()
		return
	if step != Step.ARRANGE:
		return
	var nm := String(p.name)
	var s := nm.right(2)
	if not PartFrontPanel.SLOTS.has(s):
		return
	if nm.begins_with("Ram"):
		if owner.ram[s] == "raised":
			owner.ram[s] = "locked" # กดลงจนคลิก
			var tw := create_tween()
			tw.tween_property(p, "scale", Vector2(1, 0.94), 0.05)
			tw.tween_property(p, "scale", Vector2.ONE, 0.08)
		else:
			owner.ram[s] = "" # ง้างสลักแล้วดึงขึ้น
			owner.ram_in_hand += 1
	elif nm.begins_with("Slot"):
		if owner.ram_in_hand <= 0:
			toast("DUAL_HAND_EMPTY")
			return
		owner.ram_in_hand -= 1
		owner.ram[s] = "raised"
	owner.show_ram(s)
	_refresh()


func _on_ok() -> void:
	if step != Step.ARRANGE:
		return
	var used: Array = owner.ram_slots()
	if owner.ram_in_hand > 0 or used.size() != 2:
		toast("DUAL_NEED_TWO")
		return
	if not owner.is_dual():
		if not _said_single:
			mistake.emit(&"dual", 8)
		_said_single = true
		say("DUAL_CHANNEL_SINGLE", PibHint.Mood.WORRY)
		return
	step = Step.DONE
	_ok_btn.hide()
	allow([node("SlotA1")]) # กันคลิก (allow ว่าง = ทุกชิ้น)
	if used.has("A1") and used.has("B1"):
		say("DUAL_CHANNEL_A1B1")
	else:
		say("DUAL_CHANNEL_OK", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if visible and step == Step.DONE:
		finish()
