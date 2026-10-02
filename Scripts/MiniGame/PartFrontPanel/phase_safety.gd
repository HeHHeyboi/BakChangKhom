extends Phase2D
## Phase 3 · SAFETY — ถอดปลั๊กไฟท้ายเคส (ไฟเมนบอร์ดดับ) → แตะโครงเคส ก่อนยุ่งกับแผงพิน
## แตะเคสก่อนถอดปลั๊ก −5 safety · [Claude 2 ต.ค. 2569]

enum Step { UNPLUG, TOUCH_CASE, DONE }

var step := Step.UNPLUG
var _built := false
var _checks: Array[Label] = []


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมปุ่มหน้าเคส — ขั้นที่ 3/8 · ตัดไฟ")
		PhaseUI.label(rail, "ขั้นตอน (ต้องเรียงลำดับ)", 20, PhaseUI.COL_OK)
		for t in ["ถอดปลั๊กไฟท้ายเคส", "แตะโครงเคสโลหะ"]:
			_checks.append(PhaseUI.check_item(rail, t))
	step = Step.UNPLUG
	for c in _checks:
		PhaseUI.set_check(c, false)
	show()
	allow([node("PowerCord"), node("CaseFrame")])
	cam(&"Rear")
	listen(stage().part_clicked, _on_clicked)
	say("SAFETY_INTRO")
	_step_hint()


func _step_hint() -> void:
	match step:
		Step.UNPLUG: hint(node("PowerCord"), "ถอดปลั๊กตรงนี้", 4.0)
		Step.TOUCH_CASE: hint(node("CaseFrame"), "แตะโครงเคส", 4.0)
		_: clear_hint()


func _on_clicked(p: Item2D) -> void:
	if step >= Step.DONE:
		return
	if p == node("PowerCord") and step == Step.UNPLUG:
		owner.plugged = false
		p.set_state("out")
		(node("MbLed") as Item2D).set_state("off")
		toast("SAFETY_UNPLUG")
		_next(&"Case")
	elif p == node("CaseFrame"):
		if step == Step.TOUCH_CASE:
			toast("SAFETY_TOUCH_CASE")
			p.tint(Color(0.6, 0.8, 1))
			_next(&"")
			await wait(1.0)
			p.clear_tint()
			finish()
		else:
			toast("UNSAFE_TOUCH_CASE")
			mistake.emit(&"safety", 5)


func _next(view: StringName) -> void:
	PhaseUI.set_check(_checks[step], true)
	step = (step + 1) as Step
	if view != &"":
		cam(view)
	_step_hint()
