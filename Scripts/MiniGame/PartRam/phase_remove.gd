extends Phase2D
## Phase 4 · REMOVE — เปิดฝากระจก → ปลดสลักสองข้าง → ลากแรมไปวางบนขาตั้งบนแผ่น ESD
## [Claude 29 ก.ย. 2569] โค้ด + ฉาก 2.5D · ดึงตอนสลักล็อก −5 handling (ครั้งเดียว)

var _warned_force := false
var _built := false
var _chk: Array[Label] = []


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมแรม — ขั้นที่ 4/8 · ถอดแรม")
		PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
		for t in ["เปิดฝาข้าง (คลิกกระจก)", "ปลดสลักสองข้าง", "ถอดแรมไปวางบนแผ่นกันไฟฟ้าสถิต"]:
			_chk.append(PhaseUI.check_item(rail, t))
		PhaseUI.label(rail, "ลากแรมด้วยคลิกซ้าย · คลิกขวาลากหมุนกล้อง", 14)
	_warned_force = false
	for c in _chk:
		PhaseUI.set_check(c, false)
	show()
	listen(stage().part_clicked, _on_clicked)
	listen(stage().part_toggled, _on_toggled)
	listen(stage().part_installed, _on_installed)
	listen(stage().part_returned, func(_p): cam(&"Slots"))
	listen(stage().drop_rejected, _on_rejected)
	allow_sockets([node("MatSocket")])
	if owner.panel_open:
		_after_panel()
	else:
		allow([node("GlassPanel")])
		cam(&"Inside")


func _on_clicked(p: Item2D) -> void:
	if p == node("GlassPanel") and not owner.panel_open:
		owner.panel_open = true
		p.set_state("open") # รูปฝากระจกจางหาย เห็นในเคส (crossfade)
		p.mode = Item2D.Mode.STATIC
		_after_panel()


func _after_panel() -> void:
	PhaseUI.set_check(_chk[0], true)
	var parts: Array = [node("RamA2")]
	parts.append_array(owner.ram_clips())
	allow(parts)
	cam(&"Slots")
	say(MinigameHeader.REMOVE)


func _on_toggled(_p: Item2D, _on: bool) -> void:
	var s: Socket2D = node("SlotA2")
	PhaseUI.set_check(_chk[1], not s.is_locked())


func _on_rejected(_p: Item2D, _s: Socket2D, reason: Socket2D.Result) -> void:
	if reason == Socket2D.Result.LOCKED:
		toast(MinigameHeader.REMOVE_FORCE)
		if not _warned_force:
			_warned_force = true
			mistake.emit(&"handling", 5)


func _on_installed(p: Item2D, s: Socket2D) -> void:
	if p == node("RamA2") and s == node("MatSocket"):
		PhaseUI.set_check(_chk[2], true)
		cam(&"Mat")
		await wait(0.6)
		finish()
	else:
		cam(&"Slots")
