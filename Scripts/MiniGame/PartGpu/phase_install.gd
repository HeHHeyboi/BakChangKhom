extends Phase2D
## Phase 6 · INSTALL — คลิกการ์ดบนแผ่น ESD → การ์ดลงไปวางในสล็อต (ยังลอยนิดหนึ่ง) → คลิกการ์ด 2 ครั้งกดลงจนสลักดีดล็อก
## → ไปท้ายเคส ขันน็อตยึดการ์ด · [Claude 2 ต.ค. 2569]

enum Step { PLACE, PRESS, SCREW, DONE }

const PRESS_NEEDED := 2
const RAISED := 12.0

var step := Step.PLACE
var _presses := 0
var _built := false
var _chk: Array[Label] = []


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมการ์ดจอ — ขั้นที่ 6/8 · ใส่การ์ดกลับ")
		PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
		for t in ["วางการ์ดลงสล็อต PCIe", "กดลงจนสลักดีดล็อก", "ขันน็อตยึดท้ายเคส"]:
			_chk.append(PhaseUI.check_item(rail, t))
	step = Step.PLACE
	_presses = 0
	for c in _chk:
		PhaseUI.set_check(c, false)
	show()
	allow([node("GpuCard")])
	cam(&"Mat")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("INSTALL")
	hint(node("GpuCard"), "หยิบการ์ดไปใส่", 5.0)


func _on_clicked(p: Item2D) -> void:
	var side := node("GpuSide") as Item2D
	match step:
		Step.PLACE:
			if p == node("GpuCard"):
				p.set_state("off")
				side.set_state("")
				side.position = owner.GPU_SLOT_POS - Vector2(0, RAISED)
				_next(&"Case")
				allow([side])
				hint(side, "กดลงให้สุด", 4.0)
		Step.PRESS:
			if p == side:
				_presses += 1
				var y: float = owner.GPU_SLOT_POS.y - RAISED * (1.0 - float(_presses) / PRESS_NEEDED)
				var tw := create_tween()
				tw.tween_property(side, "position:y", y + 3.0, 0.06)
				tw.tween_property(side, "position:y", y, 0.06)
				if _presses >= PRESS_NEEDED:
					(node("Latch") as Item2D).set_state("") # คลิก! สลักดีดกลับ
					_next(&"Rear")
					allow([node("BracketScrew")])
					hint(node("BracketScrew"), "ขันน็อต", 4.0)
		Step.SCREW:
			if p == node("BracketScrew"):
				p.set_state("")
				p.rotation_degrees = -540.0
				create_tween().tween_property(p, "rotation_degrees", 0.0, 0.4)
				_next(&"")
				allow([])
				clear_hint()
				say("INSTALL_DONE", PibHint.Mood.HAPPY)


func _next(view: StringName) -> void:
	PhaseUI.set_check(_chk[step], true)
	step = (step + 1) as Step
	if view != &"":
		cam(view)


func _on_pib_done() -> void:
	if visible and step == Step.DONE:
		finish()
