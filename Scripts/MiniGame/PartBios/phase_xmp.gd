extends Phase2D
## Phase 5 · XMP — คลิกสวิตช์ XMP วน ปิด → Profile 1 (3200) → Profile 2 (3000) · ดูแถบ Memory เปลี่ยนตาม
##   ไม่เปิดเลย −5 xmp (ครั้งเดียว) · Profile 1 เคยทำบูตไม่ขึ้นแล้ว ปิ๊บเตือนให้ลอง Profile 2 · [Claude 2 ต.ค. 2569]

var _built := false
var _chk: Label
var _next_btn: Button
var _done := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเครื่องค้าง BIOS — ขั้นที่ 5/8 · เปิด XMP")
		_chk = PhaseUI.check_item(rail, "เปิดโปรไฟล์ XMP (คลิกสวิตช์)")
		_next_btn = rail_button(rail, "ต่อไป ►", _on_next)
	_done = false
	PhaseUI.set_check(_chk, owner.xmp > 0)
	show()
	allow([node("XmpToggle")])
	cam(&"Bios")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	if owner.xmp_p1_unstable:
		say("XMP_RETRY")
	else:
		say("XMP")
	hint(node("XmpToggle"), "สวิตช์ XMP", 4.0)


func _on_clicked(p: Item2D) -> void:
	if _done or p != node("XmpToggle"):
		return
	clear_hint()
	owner.xmp = (owner.xmp + 1) % 3
	owner.refresh_bios()
	PhaseUI.set_check(_chk, owner.xmp > 0)
	if owner.xmp == 1 and owner.xmp_p1_unstable:
		toast("XMP_P1_UNSTABLE")


func _on_next() -> void:
	if _done:
		return
	_done = true
	_next_btn.hide()
	if owner.xmp == 0 and not owner.has_meta("xmp_skip"):
		owner.set_meta("xmp_skip", true)
		mistake.emit(&"xmp", 5)
		say("XMP_SKIPPED", PibHint.Mood.WORRY)
		return
	_next_btn.show()
	finish()


func _on_pib_done() -> void:
	if visible and _done:
		_next_btn.show()
		finish()
