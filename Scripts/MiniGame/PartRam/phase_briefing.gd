extends Phase3D
## Phase 2 · BRIEFING — ปิ๊บสอนเรื่องแรม · กล้องเลื่อนไปมาช้า ๆ อัตโนมัติ · แรมเรืองแสงให้รู้ว่ากำลังพูดถึงชิ้นไหน
## [Claude 29 ก.ย. 2569] ภาพประกอบ 2D (ram_diagram_*) ยังไม่มี — ใส่ทีหลังเป็น TextureRect ใน rail ได้


func init():
	show()
	if get_child_count() == 0:
		PhaseUI.make_frame(self, "ซ่อมแรม — ขั้นที่ 2/8 · รู้จักแรม")
		PhaseUI.set_goal(self, "ฟังปิ๊บ · แตะกล่องข้อความเพื่อไปต่อ") # [Claude 30 ก.ย.] บทยาวย้ายไปสมุดคู่มือ
	allow([])
	stage().user_camera = false
	nav_enabled = false # [Claude 30 ก.ย.] ช่วงปิ๊บสอน ไม่ต้องสลับมุม
	cam(&"Slots")
	(node("RamA2") as PartBody3D).set_hover(true)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say(MinigameHeader.BRIEFING)


var _t := 0.0


func _process(delta: float) -> void:
	if visible and not stage().user_camera:
		_t += delta
		stage().pan(cos(_t * 0.6) * delta * 0.25) # เลื่อนกล้องไปมาช้า ๆ ระหว่างปิ๊บสอน (แนวด้านข้าง)


func _on_pib_done() -> void:
	if not visible:
		return
	(node("RamA2") as PartBody3D).set_hover(false)
	finish()
