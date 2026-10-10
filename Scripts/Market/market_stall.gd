@tool
class_name MarketStall extends SceneHotspot
## แผงในตลาด — ชี้แล้วเรืองแสง + ป้ายชื่อ (label_text) · กดแล้วขมพูด (message) ที่กล่องข้อความล่างจอ
## [Claude 10 ต.ค. 2569] ใช้ใน Scene/Location/Market.tscn · ต่อไปเปลี่ยนเป็นเปิดร้านค้า/อัปเกรดได้ที่ _on_pressed

## ข้อความที่ขึ้นเมื่อกดแผงนี้
@export_multiline var message := "ร้านนี้ยังไม่เปิดนะ"


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint() and not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if Global.isDialogShown() or Global.isInMinigame():
		return
	var m := owner
	if m and m.has_method(&"say"):
		m.say(message)
