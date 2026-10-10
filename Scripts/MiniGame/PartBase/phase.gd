class_name Phase extends Control

@warning_ignore("unused_signal") ## [Claude 10 ต.ค. 2569] emit จากสคริปต์อื่น/ลูก
signal phase_completed
signal pib_toggle(data: PibHint.Data)
## แจ้งหักคะแนน: category = "diagnosis" / "safety" / "tools" / "handling" / "tidiness" · points = คะแนนที่หัก (บวก)
signal mistake(category: StringName, points: int)


func init():
	pass


## เก็บ phase ทิ้งกลางคัน (ใช้กับ debug jump) — ไม่ emit phase_completed
func abort():
	hide()
