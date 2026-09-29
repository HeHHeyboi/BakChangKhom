extends Phase3D
## Phase 7 · VERIFY — เสียบปลั๊กที่ปลั๊กพ่วง → กดปุ่มเปิดหน้าเคส → รอ 2 วิ ดูจอ
## [Claude 29–30 ก.ย. 2569] ปลั๊กอยู่ที่ปลั๊กพ่วงบนโต๊ะ (มุม Rear) · ผลขึ้นกับ owner.ram_damaged (CLEAN) และ owner.ram_seated (INSTALL) · ใส่ไม่สุด −10 tidiness
## VERIFY_NO_POWER_CUT ไม่ใช้ — Power Off บังคับลำดับไว้แล้ว

const BOOT_TIME := 2.0

var _stage := 0 # 0 รอเสียบปลั๊ก · 1 รอกดเปิด · 2 กำลังบูต · 3 แสดงผลแล้ว
var _built := false
var _chk: Array[Label] = []
var _result: Label


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมแรม — ขั้นที่ 7/8 · ตรวจผล")
		PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
		for t in ["เสียบปลั๊กที่ปลั๊กพ่วง", "กดปุ่มเปิดหน้าเคส", "ดูผลที่จอ"]:
			_chk.append(PhaseUI.check_item(rail, t))
		_result = PhaseUI.label(rail, "", 20)
	_stage = 0
	_result.text = ""
	for c in _chk:
		PhaseUI.set_check(c, false)
	show()
	allow([node("Plug"), node("PowerButton")])
	cam(&"Rear")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say_text(["ใส่กลับเรียบร้อยแล้ว เสียบปลั๊กแล้วลองเปิดเครื่องดูกัน"])


func _on_clicked(p: PartBody3D) -> void:
	if p == node("Plug") and _stage == 0:
		_stage = 1
		owner.plugged = true
		var plug := p as Node3D
		var home: Vector3 = plug.get_meta("home", plug.position)
		var tw := create_tween()
		tw.tween_property(plug, "position", home + Vector3(0, 0.35, 0), 0.3)
		tw.tween_property(plug, "position", home, 0.2).set_trans(Tween.TRANS_BACK)
		PhaseUI.set_check(_chk[0], true)
		await tw.finished
		cam(&"Front")
	elif p == node("PowerButton"):
		if _stage == 0:
			say_text(["ยังไม่ได้เสียบปลั๊กเลยนะขม"], PibHint.Mood.WORRY)
		elif _stage == 1:
			_boot()


func _boot() -> void:
	_stage = 2
	PhaseUI.set_check(_chk[1], true)
	owner.set_led(true)
	var btn := node("PowerButton") as Node3D
	var tw := create_tween()
	tw.tween_property(btn, "position:z", btn.position.z - 0.02, 0.06) # ปุ่มยุบลง
	tw.tween_property(btn, "position:z", btn.position.z, 0.06)
	cam(&"Monitor")
	await wait(BOOT_TIME)
	_stage = 3
	PhaseUI.set_check(_chk[2], true)
	var ok: bool = not owner.ram_damaged and owner.ram_seated
	var mon := node("Monitor") as PartBody3D
	if ok:
		mon.set_texture(owner.TEX_BOOT_OK)
		_result.text = "ไม่มีเสียงบี๊บ ✓ ผ่าน"
		_result.add_theme_color_override("font_color", PhaseUI.COL_OK)
		say(MinigameHeader.VERIFY, PibHint.Mood.HAPPY)
		return
	mon.set_texture(owner.TEX_GLITCH)
	_result.text = "ยังบี๊บ ✗ ไม่ผ่าน"
	_result.add_theme_color_override("font_color", PhaseUI.COL_BAD)
	var lines: Array = []
	if not owner.ram_seated:
		mistake.emit(&"tidiness", 10)
		lines.append("สลักยังไม่ล็อกเลย แรมเลยลงไม่สุด ขาทองไม่แตะหน้าสัมผัสครบ")
	if owner.ram_damaged:
		lines.append("ขาทองเป็นรอยจากตอนทำความสะอาด สัญญาณเลยยังวิ่งไม่ครบ")
	lines.append("ครั้งหน้าลองแก้ตรงนี้ดูนะ งานซ่อมจริงต้องย้อนกลับไปทำใหม่จนผ่าน")
	say_text(lines, PibHint.Mood.WORRY)


func _on_pib_done() -> void:
	if visible and _stage == 3:
		finish()
