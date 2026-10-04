extends Phase2D
## Phase 1 · INSPECT — เครื่องค้างอยู่ที่หน้าจอ BIOS · คลิกอ่าน 3 แถบ (Boot Priority · Memory · Storage) ครบแล้วกด "เริ่มซ่อม"
## [Claude 2 ต.ค. 2569]

const SPOTS := {
	"BootPanel": ["boot", "INSPECT_BOOT"],
	"MemPanel": ["mem", "INSPECT_MEMORY"],
	"StoragePanel": ["disk", "INSPECT_STORAGE"],
}

var _built := false
var _checks := {}
var _seen := {}
var _start_btn: Button


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเครื่องค้าง BIOS — ขั้นที่ 1/8 · อ่านหน้าจอ")
		PhaseUI.label(rail, "แถบที่ต้องอ่าน", 20, PhaseUI.COL_OK)
		_checks["boot"] = PhaseUI.check_item(rail, "Boot Priority (ลำดับบูต)")
		_checks["mem"] = PhaseUI.check_item(rail, "Memory (แรม)")
		_checks["disk"] = PhaseUI.check_item(rail, "Storage (ดิสก์)")
		_start_btn = PhaseUI.rail_button(rail, "เริ่มซ่อม ►", _on_start)
	_seen.clear()
	for k in _checks:
		PhaseUI.set_check(_checks[k], false)
	_start_btn.hide()
	show()
	allow([node("BootPanel"), node("MemPanel"), node("StoragePanel")])
	cam(&"Bios")
	listen(stage().part_clicked, _on_clicked)
	say("INSPECT_INTRO")
	_next_hint()


func _on_clicked(p: Item2D) -> void:
	var key := String(p.name)
	if not SPOTS.has(key):
		return
	var spot: Array = SPOTS[key]
	if not _seen.has(spot[0]):
		_seen[spot[0]] = true
		PhaseUI.set_check(_checks[spot[0]], true)
	say(spot[1])
	_next_hint()
	if _seen.size() >= SPOTS.size() and not _start_btn.visible:
		_start_btn.show()
		PhaseUI.refresh(self)


func _next_hint() -> void:
	if not _seen.has("boot"):
		hint(node("BootPanel"), "ลำดับบูต", 5.0)
	elif not _seen.has("mem"):
		hint(node("MemPanel"), "แถบแรม", 4.0)
	elif not _seen.has("disk"):
		hint(node("StoragePanel"), "แถบดิสก์", 4.0)
	else:
		clear_hint()


func _on_start() -> void:
	if not visible:
		return
	_start_btn.hide()
	finish()
