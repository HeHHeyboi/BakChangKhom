extends Phase2D
## Phase 3 · POWER_TEST — กดปุ่มเปิดเครื่องหน้าเคส → ไฟ LED ติด → จอขึ้นโลโก้/บูตผ่าน

var _built := false
var _on := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ประกอบคอม — ขั้นที่ 3/4 · ทดสอบเปิดเครื่อง")
		PhaseUI.check_item(rail, "กดปุ่มเปิดเครื่องหน้าเคส")
	_on = false
	show()
	allow([node("PowerButton")])
	cam(&"Front")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("ASM_BUILD_DONE")
	hint(node("PowerButton"), "กดเปิดเครื่อง", 3.0)


func _on_clicked(p: Item2D) -> void:
	if p != node("PowerButton") or _on:
		return
	_on = true
	clear_hint()
	p.pivot_offset = p.size / 2.0
	var tw := create_tween()
	tw.tween_property(p, "scale", Vector2.ONE * 0.85, 0.08) # ปุ่มยุบลง
	tw.tween_property(p, "scale", Vector2.ONE, 0.08)
	(node("PowerLed") as Item2D).set_state("on")
	PhaseUI.set_check((get_meta("rail_box") as Node).get_child(0), true)
	cam(&"Monitor")
	await wait(0.8)
	(node("Monitor") as Item2D).set_state("boot_ok")
	say("ASM_POWER_OK", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if visible and _on:
		finish()
