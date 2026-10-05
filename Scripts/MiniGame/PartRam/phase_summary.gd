extends Phase2D
## Phase 7 · SUMMARY — การ์ดสรุป ดาว คะแนน 5 หมวด ปุ่มกลับห้อง
## [Claude 29 ก.ย. 2569] โค้ด + UI เบื้องต้นตาม Docs/STORYBOARD.md R7 และ MINIGAME1_DESIGN.md หัวข้อ 7, 9
## กด "กลับไปที่ห้อง" → phase_completed → PartMinigame เห็นว่าเป็น phase สุดท้าย → minigame_finished → part_ram.gd ปิดซีน

const FULL := { &"diagnosis": 30, &"safety": 25, &"tools": 25, &"handling": 10, &"tidiness": 10 }
const NAMES := {
	&"diagnosis": "ความแม่นยำการวินิจฉัย",
	&"safety": "ความปลอดภัย",
	&"tools": "การเลือกอุปกรณ์",
	&"handling": "การจับต้องชิ้นส่วน",
	&"tidiness": "ความเรียบร้อย",
}
const STAR_AT := [60, 80, 95]
const LEARNED := [
	"ขาทองคือหน้าสัมผัสที่ข้อมูลวิ่งผ่าน",
	"ฝุ่นและคราบทำให้สัญญาณขาด เครื่องค้าง",
	"ต้องตัดไฟก่อนจับชิ้นส่วนทุกครั้ง",
]

var _built := false
var _stars: Label
var _total: Label
var _rows: VBoxContainer
var _back: Button
var total := 0


func init():
	if not _built:
		_build()
	total = 0
	for c in _rows.get_children():
		c.queue_free()
	for k in FULL:
		var got: int = max(FULL[k] - int(owner._mistakes.get(k, 0)), 0)
		total += got
		PhaseUI.label(_rows, "%s   %d / %d" % [NAMES[k], got, FULL[k]], 18)
	var stars := 0
	for s in STAR_AT:
		if total >= s:
			stars += 1
	_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	_total.text = "คะแนน %d / 100  ·  %s" % [total, "ผ่าน" if total >= 60 else "ยังไม่ผ่าน"]
	_back.disabled = false
	show()
	allow([])
	stage().user_camera = false
	nav_enabled = false # [Claude 30 ก.ย.] หน้านี้ไม่ต้องสลับมุม
	cam(&"Overview")
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.SUMMARY, PibHint.Mood.HAPPY))


func _build() -> void:
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = PhaseUI.SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# การ์ดสรุป (placeholder ของ ui_quest_panel.png) เต็มพื้นที่เหนือแถบปิ๊บ
	var card := PhaseUI.panel(self, Rect2(96, 24, 960, 440), "Card", Color(0.97, 0.95, 0.9, 0.96))
	var dark := Color(0.15, 0.12, 0.1)
	_stars = PhaseUI.label(card, "", 64, Color(0.95, 0.7, 0.1))
	_stars.position = Vector2(40, 16)
	_total = PhaseUI.label(card, "", 28, dark)
	_total.position = Vector2(300, 40)

	var learned := PhaseUI.label(card, "สิ่งที่เรียนรู้\n• " + "\n• ".join(LEARNED), 18, dark)
	learned.position = Vector2(40, 130)
	learned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	learned.size = Vector2(440, 220)

	var head := PhaseUI.label(card, "ตารางคะแนน", 18, dark)
	head.position = Vector2(520, 130)
	_rows = VBoxContainer.new()
	_rows.position = Vector2(520, 165)
	_rows.size = Vector2(400, 200)
	card.add_child(_rows)
	_rows.set_meta("dark", dark)
	_rows.child_entered_tree.connect(func(n): if n is Label: n.add_theme_color_override("font_color", dark))

	_back = PhaseUI.button(card, "กลับไปที่ห้อง ►", Rect2(720, 370, 210, 52), _on_back)


func _on_back() -> void:
	if not visible:
		return
	_back.disabled = true
	finish()
