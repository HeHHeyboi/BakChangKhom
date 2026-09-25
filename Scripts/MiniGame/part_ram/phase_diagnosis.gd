extends Control
signal phase_completed
signal pib_toggle(data: PibHint.Data)

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
	label.text = "Screen"
	notebook.add_child(label)


func _on_clue_speaker_pressed() -> void:
	if !clues.has(Clue.SPEAKER):
		return
	clues.erase(Clue.SPEAKER)
	var label = Label.new()
	label.text = "Speaker"
	notebook.add_child(label)


func _on_clue_case_pressed() -> void:
	if !clues.has(Clue.CASE):
		return
	clues.erase(Clue.CASE)
	var label = Label.new()
	label.text = "Case"
	notebook.add_child(label)


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


func _on_pib_hint_all_lines_finished() -> void:
	if is_correct:
		self.hide()
		phase_completed.emit()
	disable_choice(false)


func disable_choice(disabled: bool) -> void:
	for child in choices.get_children():
		var btn = child as Button
		btn.disabled = disabled
