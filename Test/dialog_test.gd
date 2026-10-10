extends Node
## [Claude 10 ต.ค. 2569] บทที่มีตัวเลือก (Chapter1ReturnHome "ที่นาของยาย") — เลือกแล้วต้องไปต่อจนจบ
## รวมกรณีเปิดบทซ้ำ 2 ครั้ง (กดยายสองที) ซึ่งเคยทำให้ค้าง · เปิด Test/dialog_test.tscn → F6 → "T DONE fails=0"

const FILE := "res://Assets/Dialog/Chapter1ReturnHome.txt"
var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	for twice in [false, true]:
		for pick in [0, 1]:
			var ds = DialogScene
			ds.show_dialog(FILE, "")
			if twice:
				ds.show_dialog(FILE, "")
			var g := 0
			while ds.ChoiceContainer.get_child_count() == 0 and g < 50:
				ds.next_text()
				g += 1
			await get_tree().process_frame
			var tag := "%sตัวเลือก %d" % ["เปิดซ้ำ · " if twice else "", pick + 1]
			_check(ds.ChoiceContainer.get_child_count() == 2 and ds.dialog_stack.size() == 1, tag + ": ถึงตัวเลือก (2 ปุ่ม · บทเดียว)")
			ds.ChoiceContainer.get_child(pick).pressed.emit()
			await get_tree().process_frame
			_check(ds.dialog_stack.size() == 2 and not ds.ChoiceContainer.visible, tag + ": กดแล้วเข้าทางเลือก")
			var n := 0
			while ds.visible and n < 40:
				ds.next_text()
				n += 1
			_check(not ds.visible and n < 40, tag + ": เล่นต่อจนจบบท")
			await get_tree().process_frame
	print("T DONE fails=", fails)
	get_tree().quit()


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("T ", "PASS " if ok else "FAIL ", what)
