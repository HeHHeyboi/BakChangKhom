extends Phase2D
## Phase 3 · SAFETY — ปิดเครื่อง → ถอดปลั๊ก → แตะโครงเคส (ตามลำดับ) → เลือกที่วางชิ้นส่วนที่จะถอด
## ข้ามขั้น −8 safety (PART_MAINBOARD_DESIGN.md หัวข้อ 9) · [Claude 2 ต.ค. 2569]

enum Step { SHUTDOWN, UNPLUG, TOUCH_CASE, SURFACE, DONE }

const SURFACES := [
	["แผ่นรองกันไฟฟ้าสถิต (ESD)", true],
	["บนโต๊ะไม้เปล่า ๆ", false],
	["บนกล่องโฟม", false],
]

var step := Step.SHUTDOWN
var _built := false
var _checks: Array[Label] = []
var _surface_box: VBoxContainer


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเมนบอร์ด — ขั้นที่ 3/8 · ตัดไฟ + กันไฟฟ้าสถิต")
		PhaseUI.label(rail, "ขั้นตอน (ต้องเรียงลำดับ)", 20, PhaseUI.COL_OK)
		for t in ["กด Shut down บนจอ", "ถอดปลั๊กที่ปลั๊กพ่วง", "แตะโครงเคสโลหะ", "เลือกที่วางชิ้นส่วน"]:
			_checks.append(PhaseUI.check_item(rail, t))
		_surface_box = VBoxContainer.new()
		rail.add_child(_surface_box)
		PhaseUI.label(_surface_box, "ชิ้นที่ถอดออกมาจะวางบน…", 16, PhaseUI.COL_OK)
		for s in SURFACES:
			rail_button(_surface_box, s[0], _on_surface.bind(s[1]))
	step = Step.SHUTDOWN
	for c in _checks:
		PhaseUI.set_check(c, false)
	_surface_box.hide()
	show()
	allow([node("Monitor"), node("Plug"), node("CaseFrame")])
	cam(&"Monitor")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("SAFETY_INTRO")
	_step_hint()


func _step_hint() -> void:
	match step:
		Step.SHUTDOWN: hint(node("Monitor"), "กด Shut down", 5.0)
		Step.UNPLUG: hint(node("Plug"), "ถอดปลั๊กตรงนี้", 4.0)
		Step.TOUCH_CASE: hint(node("CaseFrame"), "แตะโครงเคส", 4.0)
		_: clear_hint()


func _on_clicked(p: Item2D) -> void:
	if step >= Step.SURFACE:
		return
	if p == node("Monitor"):
		if step == Step.SHUTDOWN:
			(p as Item2D).set_state("off")
			owner.set_led(false)
			toast("SAFETY_SHUTDOWN")
			_next(&"Rear")
	elif p == node("Plug"):
		if step == Step.UNPLUG:
			owner.plugged = false
			(p as Item2D).set_state("out")
			toast("SAFETY_UNPLUG")
			_next(&"Board")
		elif step == Step.SHUTDOWN:
			toast("UNSAFE_UNPLUG")
			mistake.emit(&"safety", 8)
	elif p == node("CaseFrame"):
		if step == Step.TOUCH_CASE:
			toast("SAFETY_TOUCH_CASE")
			(p as Item2D).tint(Color(0.6, 0.8, 1))
			get_tree().create_timer(1.0).timeout.connect(p.clear_tint)
			_next(&"")
			_surface_box.show()
			PhaseUI.refresh(self)
		else:
			toast("UNSAFE_TOUCH_CASE")
			mistake.emit(&"safety", 8)


func _next(view: StringName) -> void:
	PhaseUI.set_check(_checks[step], true)
	step = (step + 1) as Step
	if view != &"":
		cam(view)
	_step_hint()


func _on_surface(ok: bool) -> void:
	if step != Step.SURFACE:
		return
	if not ok:
		mistake.emit(&"safety", 8)
		say("SAFETY_MAT_WRONG", PibHint.Mood.WORRY)
		return
	PhaseUI.set_check(_checks[Step.SURFACE], true)
	step = Step.DONE
	_surface_box.hide()
	PhaseUI.refresh(self)
	cam(&"Mat")
	say("SAFETY_MAT", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if visible and step == Step.DONE:
		finish()
