extends Phase2D
## Phase 2 · BRIEFING — ปิ๊บสอนเรื่องแรม · กล้องเลื่อนไปมาช้า ๆ อัตโนมัติ · แรมเรืองแสงให้รู้ว่ากำลังพูดถึงชิ้นไหน
## [Claude 29 ก.ย. 2569] ภาพประกอบ 2D (ram_diagram_*) ยังไม่มี — ใส่ทีหลังเป็น TextureRect ใน rail ได้


func init():
	show()
	if get_child_count() == 0:
		PhaseUI.make_frame(self, "ซ่อมแรม — ขั้นที่ 2/8 · รู้จักแรม")
		PhaseUI.set_goal(self, "ฟังปิ๊บเล่าเรื่องแรม A2")
	allow([])
	stage().user_camera = false
	nav_enabled = false # [Claude 30 ก.ย.] ช่วงปิ๊บสอน ไม่ต้องสลับมุม
	cam(&"Slots")
	(node("RamA2") as Item2D).set_hover(true)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say(MinigameHeader.BRIEFING)


# [Claude 1 ต.ค.] เอากล้องเลื่อนไปมาออก — ภาพนิ่งดูง่ายกว่า แถวอื่นหรี่ไว้แล้วเหลือ A2 สว่างแถวเดียว


func _on_pib_done() -> void:
	if not visible:
		return
	(node("RamA2") as Item2D).set_hover(false)
	finish()
