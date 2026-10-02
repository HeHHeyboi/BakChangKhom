extends Phase2D
## Phase 2 · BRIEFING — ปิ๊บเล่าว่า BIOS คืออะไร ทำไมเครื่องมาค้างตรงนี้ (ไม่ใช่ดิสก์เสีย)
## [Claude 2 ต.ค. 2569]


func init():
	show()
	if get_child_count() == 0:
		PhaseUI.make_frame(self, "ซ่อมเครื่องค้าง BIOS — ขั้นที่ 2/8 · BIOS คืออะไร")
		PhaseUI.set_goal(self, "ฟังปิ๊บเล่าเรื่อง BIOS")
	allow([node("BootPanel")]) # กันคลิก (allow ว่าง = ทุกชิ้น)
	stage().user_camera = false
	nav_enabled = false
	cam(&"Bios")
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("BRIEFING")


func _on_pib_done() -> void:
	if not visible:
		return
	finish()
