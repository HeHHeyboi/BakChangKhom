# Scripts/MiniGame/phase_clean.gd
enum CleanStep {
	DUST_BOARD,
	SCRUB_CONTACTS,
	CLEAN_SLOT,
} # S1 S2 S3

signal step_completed(step: CleanStep)
signal clean_finished(penalty: int)

const TRAY_SIZE := 6
var _tools: Array[CleanTool] # โหลดจาก Resources/MiniGame/Tools/*.tres
var _blocked_once: Dictionary = { } # tool_id -> true (เลือก ❌ ไปแล้วรอบหนึ่ง)


func _build_tray(step: CleanStep) -> Array[CleanTool]:
	return []


func _on_tool_used(tool: CleanTool, step: CleanStep) -> void:
	match tool.fit_per_step.get(step, CleanTool.Fit.FORBIDDEN):
		CleanTool.Fit.IDEAL:
			pass
		# _progress(step, 1.0)
		# Pib.say([tool.line_ideal], PibHint.Mood.HAPPY)
		CleanTool.Fit.LIMITED:
			pass
		# _progress(step, 0.5)
		# Pib.say([tool.line_limited], PibHint.Mood.NORMAL)
		CleanTool.Fit.FORBIDDEN:
			if _blocked_once.has(tool.id):
				pass
			# _apply_damage(step, tool)
			else:
				_blocked_once[tool.id] = true
			# Pib.say([tool.line_forbidden], PibHint.Mood.WORRY)
