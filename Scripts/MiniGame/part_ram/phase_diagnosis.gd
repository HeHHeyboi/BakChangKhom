extends Control
@onready var notebook = $"ClueNotebook" as VBoxContainer
@onready var choices = $"CauseChoices" as VBoxContainer

enum Clue {
	SCREEN,
	SPEAKER,
	CASE,
}
var clues = [Clue.SCREEN, Clue.SPEAKER, Clue.CASE]
var show_choices = false


func _process(delta: float) -> void:
	if show_choices:
		return

	if clues.is_empty():
		show_choices = true
		print("find all clues")


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
