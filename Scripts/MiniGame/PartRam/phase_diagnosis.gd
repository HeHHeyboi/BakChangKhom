class_name PhaseDiagnosis extends Phase2D
## Phase 1 · DIAGNOSIS — ดูอาการ 3 จุดในฉาก 2.5D (จอ · ลำโพงบนเมนบอร์ด · ในเคส) แล้วเลือกสาเหตุ
## [Claude 29 ก.ย. 2569] ย้ายจากปุ่ม 2D ของเดิมเป็นจุดคลิกในฉาก 2.5D · กติกาเดิม (ครบ 3 จุดถึงเลือกได้ · ผิด −10 · ผิด 3 ครั้งใบ้)

const CHOICES := [
	["แรมหน้าสัมผัสไม่ดี", "correct"],
	["จอเสีย", "screen"],
	["พาวเวอร์ซัพพลายจ่ายไฟไม่พอ", "psu"],
	["ติดไวรัส", "virus"],
]

var _seen := {}
var _wrong_count := 0
var is_correct := false
var _built := false
var _checks := {}
var _choice_box: VBoxContainer


func init():
	if not _built:
		_build()
	_seen.clear()
	_wrong_count = 0
	is_correct = false
	for k in _checks:
		PhaseUI.set_check(_checks[k], false)
	_choice_box.hide()
	show()
	allow([node("Monitor"), node("Speaker"), node("GlassPanel")])
	cam(&"Overview")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say(MinigameHeader.DIAGNOSIS_INTRO)
	_next_hint()


func _build() -> void:
	_built = true
	var rail := PhaseUI.make_frame(self, "ซ่อมแรม — ขั้นที่ 1/8 · ดูอาการ")
	PhaseUI.label(rail, "สมุดจดอาการ", 20, PhaseUI.COL_OK)
	_checks["screen"] = PhaseUI.check_item(rail, "จอ — คลิกที่จอ")
	_checks["speaker"] = PhaseUI.check_item(rail, "เสียง — คลิกลำโพงบนเมนบอร์ด")
	_checks["dust"] = PhaseUI.check_item(rail, "ในเคส — คลิกฝากระจก")
	_choice_box = VBoxContainer.new()
	rail.add_child(_choice_box)
	PhaseUI.label(_choice_box, "สาเหตุน่าจะเป็น…", 18, PhaseUI.COL_OK)
	for c in CHOICES:
		rail_button(_choice_box, c[0], _on_choice.bind(c[1]))


func _on_clicked(p: Item2D) -> void:
	if p == node("Monitor"):
		_clue("screen", &"Monitor", MinigameHeader.DIAGNOSIS_CLUE_SCREEN)
	elif p == node("Speaker"):
		_clue("speaker", &"Speaker", MinigameHeader.DIAGNOSIS_CLUE_SPEAKER)
		_beep()
	elif p == node("GlassPanel"):
		_clue("dust", &"Inside", MinigameHeader.DIAGNOSIS_CLUE_DUST)


func _clue(key: String, view: StringName, header: String) -> void:
	cam(view)
	_seen[key] = true
	PhaseUI.set_check(_checks[key], true)
	say(header)
	_next_hint()


## [Claude 30 ก.ย.] ไกด์ชี้จุดถัดไปถ้าผู้เล่นหาไม่เจอ · ลำดับ จอ → ในเคส → ลำโพง
## เปิดฝาแล้วเอาฝาออกจากรายการคลิก ให้คลิกทะลุไปโดนลำโพงได้ (เดิมกระจกบังลำโพง)
func _next_hint() -> void:
	if _seen.has("dust"):
		allow([node("Monitor"), node("Speaker")])
	if not _seen.has("screen"):
		hint(node("Monitor"), "ดูจอก่อน", 5.0)
	elif not _seen.has("dust"):
		hint(node("GlassPanel"), "ส่องในเคส", 4.0, &"Overview")
	elif not _seen.has("speaker"):
		hint(node("Speaker"), "ฟังเสียงลำโพงตรงนี้", 3.0, &"Speaker")
	else:
		clear_hint()


func _beep() -> void:
	var fx := node("BeepFx") as Control
	fx.pivot_offset = fx.size / 2.0
	fx.show()
	fx.scale = Vector2.ONE * 0.6
	var tw := create_tween().set_loops(3)
	tw.tween_property(fx, "scale", Vector2.ONE * 1.2, 0.25)
	tw.tween_property(fx, "scale", Vector2.ONE * 0.6, 0.05)
	tw.finished.connect(fx.hide)


func _on_choice(data: String) -> void:
	for b in _choice_box.get_children():
		if b is Button:
			b.disabled = true
	if data == "correct":
		is_correct = true
		say(MinigameHeader.DIAGNOSIS_CORRECT, PibHint.Mood.HAPPY)
		return
	mistake.emit(&"diagnosis", 10)
	_wrong_count += 1
	match data:
		"screen":
			say(MinigameHeader.DIAGNOSIS_WRONG_SCREEN)
		"psu":
			say(MinigameHeader.DIAGNOSIS_WRONG_PSU)
		"virus":
			say(MinigameHeader.DIAGNOSIS_WRONG_VIRUS)
	if _wrong_count == 3:
		say(MinigameHeader.DIAGNOSIS_HINT)


func _on_pib_done() -> void:
	if not visible:
		return
	if is_correct:
		finish()
		return
	for b in _choice_box.get_children():
		if b is Button:
			b.disabled = false
	if _seen.size() >= 3 and not _choice_box.visible:
		_choice_box.show()
		PhaseUI.refresh(self) # [Claude 30 ก.ย.] มีปุ่มให้เลือกแล้ว → โชว์แผงข้าง
		cam(&"Overview")
