class_name PhasePoweroff extends Phase2D
## Phase 3 · POWER_OFF — กด Shut down บนจอ → ถอดปลั๊กที่ปลั๊กพ่วง → แตะโครงเคส (ตามลำดับ)
## [Claude 29 ก.ย. 2569] ย้ายจากปุ่ม 2D เป็นคลิกของจริงในฉาก 2.5D · กล้องเลื่อนไปจุดถัดไปเองหลังทำถูก · กดผิดลำดับ −12 safety

enum Step { SHUTDOWN, UNPLUGGED, TOUCH_CASE, DONE }

var step := Step.SHUTDOWN
var _built := false
var _checks: Array[Label] = []


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมแรม — ขั้นที่ 3/8 · ตัดไฟ")
		PhaseUI.label(rail, "ขั้นตอน (ต้องเรียงลำดับ)", 20, PhaseUI.COL_OK)
		for t in ["กด Shut down บนจอ", "ถอดปลั๊กที่ปลั๊กพ่วง", "แตะโครงเคสโลหะ"]:
			_checks.append(PhaseUI.check_item(rail, t))
	step = Step.SHUTDOWN
	for c in _checks:
		PhaseUI.set_check(c, false)
	(node("Monitor") as Item2D).set_state("desktop")
	show()
	allow([node("Monitor"), node("Plug"), node("CaseFrame")])
	cam(&"Monitor")
	listen(stage().part_clicked, _on_clicked)
	_step_hint()


## [Claude 30 ก.ย.] ไกด์ชี้ชิ้นของขั้นปัจจุบันถ้าผู้เล่นรอนาน
func _step_hint() -> void:
	match step:
		Step.SHUTDOWN: hint(node("Monitor"), "กด Shut down", 5.0)
		Step.UNPLUGGED: hint(node("Plug"), "ถอดปลั๊กตรงนี้", 4.0)
		Step.TOUCH_CASE: hint(node("CaseFrame"), "แตะโครงเคส", 4.0)
		_: clear_hint()


func _on_clicked(p: Item2D) -> void:
	if step == Step.DONE:
		return
	if p == node("Monitor"):
		if step == Step.SHUTDOWN:
			(node("Monitor") as Item2D).set_state("off") # จอดับ (crossfade)
			owner.set_led(false)
			toast(MinigameHeader.SAFETY_SHUTDOWN)
			_next(&"Rear")
	elif p == node("Plug"):
		if step == Step.UNPLUGGED:
			_unplug()
			toast(MinigameHeader.SAFETY_UNPLUG)
			_next(&"Inside")
		elif step == Step.SHUTDOWN:
			toast(MinigameHeader.UNSAFE_UNPLUG)
			mistake.emit(&"safety", 12)
	elif p == node("CaseFrame"):
		if step == Step.TOUCH_CASE:
			toast(MinigameHeader.SAFETY_TOUCH_CASE)
			(p as Item2D).tint(Color(0.6, 0.8, 1))
			_next(&"")
			await wait(1.2)
			p.clear_tint()
			finish()
		else:
			toast(MinigameHeader.UNSAFE_TOUCH_CASE)
			mistake.emit(&"safety", 12)


func _next(view: StringName) -> void:
	PhaseUI.set_check(_checks[step], true)
	step = (step + 1) as Step
	if view != &"":
		cam(view)
	_step_hint()


func _unplug() -> void:
	# ดึงปลั๊กออกจากปลั๊กพ่วง (ตำแหน่งเดิมเก็บไว้ให้ VERIFY เสียบคืน)
	owner.plugged = false
	(node("Plug") as Item2D).set_state("out") # รูปปลั๊กเสียบ → รูปปลั๊กหลุดวางข้าง ๆ (crossfade)
