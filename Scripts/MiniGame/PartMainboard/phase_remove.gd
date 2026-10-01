extends Phase2D
## Phase 4 · REMOVE — คลายน็อตฮีตซิงก์ 4 ตัว (แบบไขว้ดีที่สุด) → เลือก "หมุนเบา ๆ แล้วยก" (ดึงตรง ๆ ปิ๊บห้าม)
## ระบบจำลำดับน็อต · ไม่ไขว้ −3 screws · ดึงตรง −5 cpu · [Claude 2 ต.ค. 2569]

var _order: Array[int] = []
var _built := false
var _chk: Array[Label] = []
var _lift_box: VBoxContainer
var _done := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเมนบอร์ด — ขั้นที่ 4/8 · ถอดฮีตซิงก์")
		PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
		for t in ["คลายน็อต 4 ตัว (ทแยงมุม)", "ยกฮีตซิงก์ออก"]:
			_chk.append(PhaseUI.check_item(rail, t))
		_lift_box = VBoxContainer.new()
		rail.add_child(_lift_box)
		PhaseUI.label(_lift_box, "จะยกยังไงดี", 16, PhaseUI.COL_OK)
		rail_button(_lift_box, "หมุนซ้าย-ขวาเบา ๆ แล้วยก", _on_lift.bind(true))
		rail_button(_lift_box, "ดึงขึ้นตรง ๆ", _on_lift.bind(false))
	_order.clear()
	_done = false
	for c in _chk:
		PhaseUI.set_check(c, false)
	_lift_box.hide()
	for s in owner.screws():
		s.set_state("")
		s.rotation_degrees = 0
		s.modulate = Color.WHITE
	show()
	allow(owner.screws())
	cam(&"Socket")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("REMOVE_COOLER")
	_hint_next()


func _hint_next() -> void:
	if _order.size() < 4:
		for s in owner.screws():
			if not _order.has(_num(s)):
				hint(s, "คลายน็อต", 5.0)
				return
	clear_hint()


func _num(s: Item2D) -> int:
	return String(s.name).right(1).to_int()


func _on_clicked(p: Item2D) -> void:
	if not owner.screws().has(p) or _order.has(_num(p)) or _done:
		return
	_order.append(_num(p))
	var tw := create_tween()
	tw.tween_property(p, "rotation_degrees", -540.0, 0.45)
	tw.parallel().tween_property(p, "modulate", Color(0.75, 0.75, 0.8), 0.45)
	_hint_next()
	if _order.size() == 4:
		PhaseUI.set_check(_chk[0], true)
		if not PartMainboard.is_diagonal(_order):
			mistake.emit(&"screws", 3)
			toast("REMOVE_WRONG_ORDER")
		allow([])
		_lift_box.show()
		PhaseUI.refresh(self)


func _on_lift(twist: bool) -> void:
	if _done or _order.size() < 4:
		return
	if not twist:
		mistake.emit(&"cpu", 5)
		say("REMOVE_PULL_STRAIGHT", PibHint.Mood.WORRY)
		return
	_done = true
	_lift_box.hide()
	PhaseUI.refresh(self)
	var cooler := node("CoolerTop") as Item2D
	var tw := create_tween()
	for i in 2:
		tw.tween_property(cooler, "rotation_degrees", 6.0, 0.12)
		tw.tween_property(cooler, "rotation_degrees", -6.0, 0.12)
	tw.tween_property(cooler, "rotation_degrees", 0.0, 0.08)
	await tw.finished
	cooler.set_state("off")
	for s in owner.screws():
		s.set_state("off")
	(node("HeatsinkBase") as Item2D).set_state("dirty")
	PhaseUI.set_check(_chk[1], true)
	say("REMOVE_DONE")


func _on_pib_done() -> void:
	if visible and _done:
		finish()
