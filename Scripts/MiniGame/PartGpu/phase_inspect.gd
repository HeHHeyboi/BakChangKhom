extends Phase2D
## Phase 1 · INSPECT — คลิกดู 3 จุด (สาย HDMI ท้ายเคส · ไฟบนการ์ด · หัว 8-pin ห้อยว่าง) ครบแล้วกด "เริ่มซ่อม"
## [Claude 2 ต.ค. 2569]

const SPOTS := {
	"HdmiCable": ["hdmi", "INSPECT_HDMI"],
	"GpuLed": ["led", "INSPECT_LED"],
	"LooseCable": ["cable", "INSPECT_CABLE"],
}

var _built := false
var _checks := {}
var _seen := {}
var _start_btn: Button


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมการ์ดจอ — ขั้นที่ 1/8 · ตรวจสภาพ")
		PhaseUI.label(rail, "จุดที่ต้องดู", 20, PhaseUI.COL_OK)
		_checks["hdmi"] = PhaseUI.check_item(rail, "สายจอท้ายเคส")
		_checks["led"] = PhaseUI.check_item(rail, "ไฟบนการ์ดจอ")
		_checks["cable"] = PhaseUI.check_item(rail, "สายไฟจาก PSU")
		_start_btn = rail_button(rail, "เริ่มซ่อม ►", _on_start)
	_seen.clear()
	for k in _checks:
		PhaseUI.set_check(_checks[k], false)
	_start_btn.hide()
	show()
	allow([node("HdmiCable"), node("GpuLed"), node("LooseCable")])
	cam(&"Overview")
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
		(p as Item2D).tint(Color(1, 0.85, 0.4))
		get_tree().create_timer(0.6).timeout.connect(p.clear_tint)
	say(spot[1])
	_next_hint()
	if _seen.size() >= SPOTS.size() and not _start_btn.visible:
		_start_btn.show()
		PhaseUI.refresh(self)


func _next_hint() -> void:
	if not _seen.has("hdmi"):
		hint(node("HdmiCable"), "สายจอเสียบตรงไหน", 5.0)
	elif not _seen.has("led"):
		hint(node("GpuLed"), "ไฟบนการ์ด", 4.0)
	elif not _seen.has("cable"):
		hint(node("LooseCable"), "สายที่ห้อยอยู่", 4.0)
	else:
		clear_hint()


func _on_start() -> void:
	if not visible:
		return
	_start_btn.hide()
	finish()
