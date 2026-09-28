class_name PhasePoweroff extends Phase

enum Step {
	SHUTDOWN,
	UNPLUGGED,
	TOUCH_CASE,
}

var step = [Step.SHUTDOWN, Step.UNPLUGGED, Step.TOUCH_CASE]


func _on_shutdown_pressed() -> void:
	if step.front() == Step.SHUTDOWN:
		step.pop_front()
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.SAFETY_SHUTDOWN))


func _on_unplugged_pressed() -> void:
	if step.front() == Step.UNPLUGGED:
		step.pop_front()
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.SAFETY_UNPLUG))
	else:
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.UNSAFE_UNPLUG))


func _on_touch_case_pressed() -> void:
	if step.front() == Step.TOUCH_CASE:
		step.pop_front()
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.SAFETY_TOUCH_CASE))
		phase_completed.emit()
	else:
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.UNSAFE_TOUCH_CASE))
