# Scripts/MiniGame/minigame1.gd (เขียนใหม่)
class_name MiniGameRam extends Node2D

enum Phase {
	DIAGNOSIS, # 0 สังเกตอาการ + เลือกสาเหตุ
	BRIEFING, # 1 ปิ๊บสอน
	POWER_OFF, # 2 ปิดเครื่อง/ถอดปลั๊ก/แตะเคส
	REMOVE, # 3 ปลดสลัก + ดึงแรม
	CLEAN, # 4 ขัด (กลไกเดิม)
	INSTALL, # 5 ใส่กลับ
	VERIFY, # 6 เปิดเครื่องตรวจผล
	SUMMARY, # 7 สรุป + คะแนน
}

signal phase_changed(phase: Phase)
signal minigame_finished(score: Dictionary)

var current_phase: Phase = Phase.DIAGNOSIS
var _mistakes := { "diagnosis": 0, "safety": 0, "handling": 0 }
