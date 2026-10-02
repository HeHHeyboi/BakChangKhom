extends Phase2D
## Phase 2 · BRIEFING — ปิ๊บสอนว่าปุ่ม power หน้าเคสแค่ "แตะขา 2 ขา" บนเมนบอร์ด (ไม่มีไฟวิ่งผ่านปุ่ม)
## [Claude 2 ต.ค. 2569]


func init():
	show()
	if get_child_count() == 0:
		PhaseUI.make_frame(self, "ซ่อมปุ่มหน้าเคส — ขั้นที่ 2/8 · ปุ่มทำงานยังไง")
		PhaseUI.set_goal(self, "ฟังปิ๊บเล่าเรื่องปุ่มหน้าเคส")
	allow([])
	stage().user_camera = false
	nav_enabled = false
	cam(&"Pins")
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("BRIEFING")


func _on_pib_done() -> void:
	if not visible:
		return
	finish()
