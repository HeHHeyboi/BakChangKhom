class_name PhasePoweroff extends Phase

enum Step {
	SHUTDOWN,
	UNPLUGGED,
	TOUCH_CASE,
}

var step = [Step.SHUTDOWN, Step.UNPLUGGED, Step.TOUCH_CASE]


# [Claude 29 ก.ย.] เพิ่ม init(): รีเซ็ตลำดับขั้นให้เล่นซ้ำได้ (เดิมเล่นรอบสองจะ error front() บน array ว่าง)
func init():
	step = [Step.SHUTDOWN, Step.UNPLUGGED, Step.TOUCH_CASE]
	show()


func _on_shutdown_pressed() -> void:
	if step.is_empty(): return # [Claude 29 ก.ย.] กันกดหลังจบ phase
	if step.front() == Step.SHUTDOWN:
		step.pop_front()
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.SAFETY_SHUTDOWN))


func _on_unplugged_pressed() -> void:
	if step.is_empty(): return # [Claude 29 ก.ย.]
	if step.front() == Step.UNPLUGGED:
		step.pop_front()
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.SAFETY_UNPLUG))
	else:
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.UNSAFE_UNPLUG))
		mistake.emit(&"safety", 12) # [Claude 29 ก.ย.] ข้ามขั้นตัดไฟ −12


func _on_touch_case_pressed() -> void:
	if step.is_empty(): return # [Claude 29 ก.ย.]
	if step.front() == Step.TOUCH_CASE:
		step.pop_front()
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.SAFETY_TOUCH_CASE))
		phase_completed.emit()
	else:
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.UNSAFE_TOUCH_CASE))
		mistake.emit(&"safety", 12) # [Claude 29 ก.ย.] ข้ามขั้นตัดไฟ −12
