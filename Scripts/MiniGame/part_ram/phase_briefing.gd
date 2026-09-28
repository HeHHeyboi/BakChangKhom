extends Phase


func init():
	self.show()
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.BRIEFING))


func _on_pib_hint_all_lines_finished() -> void:
	self.hide()
	phase_completed.emit()
