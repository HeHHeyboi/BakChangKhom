extends Phase3D
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


func _on_clicked(p: PartBody3D) -> void:
	if p != node("PowerButton") or _on:
		return
	_on = true
	clear_hint()
	var tw := create_tween()
	tw.tween_property(p, "position:z", p.position.z - 0.03, 0.08)
	tw.tween_property(p, "position:z", p.position.z, 0.08)
	(node("PowerLed") as PartBody3D).color_override = Color(0.2, 1, 0.3)
	PhaseUI.set_check((get_meta("rail_box") as Node).get_child(0), true)
	cam(&"Monitor")
	await wait(0.8)
	(node("Monitor") as PartBody3D).set_texture(owner.TEX_BOOT_OK)
	say("ASM_POWER_OK", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if visible and _on:
		finish()
