extends Phase2D
## Phase 1 · INSPECT — คลิกดู 3 จุดในเคส (ครีบฮีตซิงก์ · ขอบ CPU · ใต้เมนบอร์ด) ครบแล้วกด "เริ่มซ่อม"
## [Claude 2 ต.ค. 2569]

const SPOTS := {
	"Cooler": ["fins", "INSPECT_FINS"],
	"PasteEdge": ["paste", "INSPECT_PASTE"],
	"Standoff": ["standoff", "INSPECT_STANDOFF"],
}

var _built := false
var _checks := {}
var _seen := {}
var _start_btn: Button


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเมนบอร์ด — ขั้นที่ 1/8 · ตรวจสภาพ")
		PhaseUI.label(rail, "จุดที่ต้องดู", 20, PhaseUI.COL_OK)
		_checks["fins"] = PhaseUI.check_item(rail, "ครีบฮีตซิงก์")
		_checks["paste"] = PhaseUI.check_item(rail, "ขอบ CPU ใต้ฮีตซิงก์")
		_checks["standoff"] = PhaseUI.check_item(rail, "มุมใต้เมนบอร์ด")
		_start_btn = PhaseUI.rail_button(rail, "เริ่มซ่อม ►", _on_start)
	_seen.clear()
	for k in _checks:
		PhaseUI.set_check(_checks[k], false)
	_start_btn.hide()
	show()
	allow([node("Cooler"), node("PasteEdge"), node("Standoff")])
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
	if not _seen.has("fins"):
		hint(node("Cooler"), "ดูครีบฮีตซิงก์", 5.0)
	elif not _seen.has("paste"):
		hint(node("PasteEdge"), "ขอบ CPU", 4.0)
	elif not _seen.has("standoff"):
		hint(node("Standoff"), "มุมใต้เมนบอร์ด", 4.0)
	else:
		clear_hint()


func _on_start() -> void:
	if not visible:
		return
	_start_btn.hide()
	finish()
