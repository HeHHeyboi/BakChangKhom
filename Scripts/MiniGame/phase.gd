class_name Phase extends Control

signal phase_completed
signal pib_toggle(data: PibHint.Data)
## แจ้งหักคะแนน: category = "diagnosis" / "safety" / "tools" / "handling" / "tidiness" · points = คะแนนที่หัก (บวก)
signal mistake(category: StringName, points: int)


func init():
	pass
