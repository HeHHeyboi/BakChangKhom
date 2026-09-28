class_name PhaseDiagnosis extends Phase

@onready var notebook = $"ClueNotebook" as VBoxContainer
@onready var choices = $"CauseChoices" as VBoxContainer

enum Clue {
	SCREEN,
	SPEAKER,
	CASE,
}
var clues = [Clue.SCREEN, Clue.SPEAKER, Clue.CASE]
var show_choices = false
var is_correct = false
var _wrong_count := 0 # [Claude 29 ก.ย.] นับตอบผิด ครบ 3 ครั้งปิ๊บใบ้


# [Claude 29 ก.ย.] เพิ่ม init(): รีเซ็ตค่าให้เล่นซ้ำได้ + ปิ๊บพูดบทเปิด DIAGNOSIS_INTRO
func init():
	clues = [Clue.SCREEN, Clue.SPEAKER, Clue.CASE]
	show_choices = false
	is_correct = false
	_wrong_count = 0
	for c in notebook.get_children():
		c.queue_free()
	choices.hide()
	show()
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.DIAGNOSIS_INTRO))


func _on_pib_line_finish() -> void:
	choices.show()
	pass


func _process(delta: float) -> void:
	if show_choices:
		return

	if clues.is_empty():
		show_choices = true
		choices.show()


func _on_clue_screen_pressed() -> void:
	if !clues.has(Clue.SCREEN):
		return
	clues.erase(Clue.SCREEN)
	var label = Label.new()
	label.text = "จอขึ้นบล็อกสีแล้วค้าง" # [Claude 29 ก.ย.] เดิม "Screen" → ภาษาไทย
	notebook.add_child(label)
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.DIAGNOSIS_CLUE_SCREEN)) # [Claude 29 ก.ย.] บทปิ๊บของเบาะแส


func _on_clue_speaker_pressed() -> void:
	if !clues.has(Clue.SPEAKER):
		return
	clues.erase(Clue.SPEAKER)
	var label = Label.new()
	label.text = "ลำโพงบี๊บสั้น ๆ ซ้ำ ๆ" # [Claude 29 ก.ย.] เดิม "Speaker" → ภาษาไทย
	notebook.add_child(label)
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.DIAGNOSIS_CLUE_SPEAKER)) # [Claude 29 ก.ย.] บทปิ๊บของเบาะแส


func _on_clue_case_pressed() -> void:
	if !clues.has(Clue.CASE):
		return
	clues.erase(Clue.CASE)
	var label = Label.new()
	label.text = "ฝุ่นจับหนาที่แผงแรม" # [Claude 29 ก.ย.] เดิม "Case" → ภาษาไทย
	notebook.add_child(label)
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.DIAGNOSIS_CLUE_DUST)) # [Claude 29 ก.ย.] บทปิ๊บของเบาะแส


func _on_choice_select(btn: Button):
	var data = btn.get_meta("choice_meta")
	disable_choice(true)
	if data == null || data is not String:
		push_error("Button has no 'choice_meta'")
		return

	match data:
		"correct":
			is_correct = true
			pib_toggle.emit(PibHint.Data.say(MinigameHeader.DIAGNOSIS_CORRECT))
		"screen":
			pib_toggle.emit(PibHint.Data.say(MinigameHeader.DIAGNOSIS_WRONG_SCREEN))
		"psu":
			pib_toggle.emit(PibHint.Data.say(MinigameHeader.DIAGNOSIS_WRONG_PSU))
		"virus":
			pib_toggle.emit(PibHint.Data.say(MinigameHeader.DIAGNOSIS_WRONG_VIRUS))
	# [Claude 29 ก.ย.] ตอบผิด = หักความแม่นยำ −10 · ผิดครบ 3 ครั้งให้ปิ๊บใบ้ (MINIGAME1_DESIGN.md 4.2 / 9)
	if not is_correct:
		mistake.emit(&"diagnosis", 10)
		_wrong_count += 1
		if _wrong_count == 3:
			pib_toggle.emit(PibHint.Data.say(MinigameHeader.DIAGNOSIS_HINT))


func _on_pib_hint_all_lines_finished() -> void:
	# [Claude 29 ก.ย.] BUG-36: PibHint ส่งสัญญาณถึงทุก phase — ทำงานเฉพาะตอนเป็น phase ที่แสดงอยู่
	if not visible:
		return
	if is_correct:
		self.hide()
		phase_completed.emit()
	disable_choice(false)


func disable_choice(disabled: bool) -> void:
	for child in choices.get_children():
		var btn = child as Button
		btn.disabled = disabled
