extends Phase2D
## Phase 2 · BRIEFING — ปิ๊บสอนว่า PCIe x16 คืออะไร ทำไมการ์ดต้องต่อไฟเพิ่ม
## [Claude 2 ต.ค. 2569]


func init():
	show()
	if get_child_count() == 0:
		PhaseUI.make_frame(self, "ซ่อมการ์ดจอ — ขั้นที่ 2/8 · PCIe กับไฟเลี้ยง")
		PhaseUI.set_goal(self, "ฟังปิ๊บเล่าเรื่องการ์ดจอ")
	allow([])
	stage().user_camera = false
	nav_enabled = false
	cam(&"Case")
	(node("GpuSide") as Item2D).set_hover(true)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("BRIEFING")


func _on_pib_done() -> void:
	if not visible:
		return
	(node("GpuSide") as Item2D).set_hover(false)
	finish()
