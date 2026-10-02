extends Phase2D
## Phase 4 · REMOVE — ไขน็อตยึดท้ายเคส (มุม Rear) → กดสลักปลายสล็อต (มุม Case) → คลิกการ์ด = ดึงขึ้นไปวางบนแผ่น ESD
## ดึงทั้งที่สลักยังล็อก = สล็อตเสียหาย −15 (ครั้งเดียว) · ยังไม่ไขน็อต = ปิ๊บเตือนเฉย ๆ · [Claude 2 ต.ค. 2569]

enum Step { SCREW, LATCH, PULL, DONE }

var step := Step.SCREW
var _built := false
var _chk: Array[Label] = []


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมการ์ดจอ — ขั้นที่ 4/8 · ถอดการ์ด")
		PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
		for t in ["ไขน็อตยึดการ์ดท้ายเคส", "กดสลักปลายสล็อต", "ดึงการ์ดขึ้นตรง ๆ"]:
			_chk.append(PhaseUI.check_item(rail, t))
	step = Step.SCREW
	for c in _chk:
		PhaseUI.set_check(c, false)
	show()
	allow([node("BracketScrew"), node("Latch"), node("GpuSide")])
	cam(&"Rear")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("REMOVE")
	_hint()


func _hint() -> void:
	match step:
		Step.SCREW: hint(node("BracketScrew"), "ไขน็อตท้ายเคส", 5.0)
		Step.LATCH: hint(node("Latch"), "กดสลัก", 4.0, &"Case")
		Step.PULL: hint(node("GpuSide"), "ดึงการ์ดขึ้น", 4.0)
		_: clear_hint()


func _on_clicked(p: Item2D) -> void:
	if step == Step.DONE:
		return
	if p == node("BracketScrew") and step == Step.SCREW:
		var tw := create_tween()
		tw.tween_property(p, "rotation_degrees", -540.0, 0.4)
		await tw.finished
		p.set_state("off")
		p.rotation_degrees = 0
		_next()
		cam(&"Case")
	elif p == node("Latch"):
		if step == Step.LATCH:
			p.set_state("open")
			_next()
	elif p == node("GpuSide"):
		match step:
			Step.SCREW:
				toast("REMOVE_SCREW")
			Step.LATCH:
				if not owner.slot_damaged:
					owner.slot_damaged = true
					mistake.emit(&"remove", 15)
				var tw := create_tween()
				for i in 3:
					tw.tween_property(p, "position:y", owner.GPU_SLOT_POS.y - 6, 0.05)
					tw.tween_property(p, "position:y", owner.GPU_SLOT_POS.y, 0.05)
				say("REMOVE_FORCE", PibHint.Mood.WORRY)
			Step.PULL:
				_pull(p)


func _pull(p: Item2D) -> void:
	step = Step.DONE
	PhaseUI.set_check(_chk[2], true)
	clear_hint()
	allow([])
	var tw := create_tween().set_parallel()
	tw.tween_property(p, "position:y", owner.GPU_SLOT_POS.y - 60, 0.3)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	await tw.finished
	p.set_state("off")
	p.position = owner.GPU_SLOT_POS
	p.modulate.a = 1.0
	(node("GpuCard") as Item2D).set_state("dusty")
	cam(&"Mat")
	say("REMOVE_DONE")


func _next() -> void:
	PhaseUI.set_check(_chk[step], true)
	step = (step + 1) as Step
	_hint()


func _on_pib_done() -> void:
	if visible and step == Step.DONE:
		finish()
