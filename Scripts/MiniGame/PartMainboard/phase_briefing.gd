extends Phase2D
## Phase 2 · BRIEFING — ปิ๊บเล่าว่าความร้อนออกจาก CPU ยังไง ซิลิโคนมีไว้ทำอะไร
## [Claude 2 ต.ค. 2569]


func init():
	show()
	if get_child_count() == 0:
		PhaseUI.make_frame(self, "ซ่อมเมนบอร์ด — ขั้นที่ 2/8 · ความร้อนกับซิลิโคน")
		PhaseUI.set_goal(self, "ฟังปิ๊บเล่าเรื่องความร้อน")
	allow([])
	stage().user_camera = false
	nav_enabled = false
	cam(&"Board")
	(node("Cooler") as Item2D).set_hover(true)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("BRIEFING")


func _on_pib_done() -> void:
	if not visible:
		return
	(node("Cooler") as Item2D).set_hover(false)
	finish()
