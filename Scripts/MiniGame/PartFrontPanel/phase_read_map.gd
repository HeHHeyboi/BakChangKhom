extends Phase2D
## Phase 4 · READ_MAP — หยิบไฟฉายส่องอ่านผังพินข้างแผง F_PANEL (ป้ายชื่อขา + ขั้ว +/− โผล่)
## กด "ข้าม" = เสียบแบบเดา −10 map และป้ายไม่โผล่ · [Claude 2 ต.ค. 2569]

var _built := false
var _chk: Label
var _skip_btn: Button
var _next_btn: Button
var _done := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมปุ่มหน้าเคส — ขั้นที่ 4/8 · อ่านผังพิน")
		_chk = PhaseUI.check_item(rail, "ส่องไฟฉายอ่านตัวหนังสือข้างแผงพิน")
		_next_btn = rail_button(rail, "ต่อไป ►", _on_next)
		_skip_btn = rail_button(rail, "ข้าม (เดาเอา)", _on_skip)
	_done = false
	PhaseUI.set_check(_chk, owner.map_revealed)
	_next_btn.visible = owner.map_revealed
	_skip_btn.visible = not owner.map_revealed
	show()
	allow([node("Flashlight")])
	cam(&"Pins")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("READ_MAP")
	hint(node("Flashlight"), "หยิบไฟฉาย", 4.0)


func _on_clicked(p: Item2D) -> void:
	if p != node("Flashlight") or owner.map_revealed:
		return
	owner.map_revealed = true
	clear_hint()
	var beam := node("Beam") as Control
	beam.modulate.a = 0.0
	beam.show()
	create_tween().tween_property(beam, "modulate:a", 1.0, 0.3)
	(node("PinLabels") as Item2D).set_state("")
	p.hide()
	PhaseUI.set_check(_chk, true)
	_skip_btn.hide()
	_next_btn.show()
	PhaseUI.refresh(self)
	say("READ_MAP_LIT", PibHint.Mood.HAPPY)


func _on_skip() -> void:
	if _done or owner.map_revealed:
		return
	_done = true
	_skip_btn.hide()
	mistake.emit(&"map", 10)
	clear_hint()
	say("READ_MAP_SKIPPED", PibHint.Mood.WORRY)


func _on_next() -> void:
	if _done:
		return
	_done = true
	_next_btn.hide()
	finish()


func _on_pib_done() -> void:
	if visible and _done and not owner.map_revealed:
		finish()
