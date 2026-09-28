extends Phase


func init():
	self.show()
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.BRIEFING))


func _on_pib_hint_all_lines_finished() -> void:
	# [Claude 29 ก.ย.] BUG-36: PibHint ส่งสัญญาณถึงทุก phase — ทำงานเฉพาะตอนเป็น phase ที่แสดงอยู่
	if not visible:
		return
	self.hide()
	phase_completed.emit()
