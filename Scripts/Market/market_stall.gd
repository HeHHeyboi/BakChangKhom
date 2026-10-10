@tool
class_name MarketStall extends SceneHotspot
## แผงในตลาด — ชี้แล้วเรืองแสง + ป้ายชื่อ (label_text) · กดแล้วเปิดหน้าต่างร้านค้า (ShopPanel) แสดง items
## [Claude 10 ต.ค. 2569] ใช้ใน Scene/Location/Market.tscn · ต่อไปเปลี่ยนเป็นเปิดร้านค้า/อัปเกรดได้ที่ _on_pressed

## คำทักของร้าน (ขึ้นบนหน้าต่างร้านค้า)
@export_multiline var message := "ร้านนี้ยังไม่มีของขายนะ"
## [10 ต.ค.] ของที่ขาย (ShopItem · Resources/Shop/) — ว่าง = หน้าต่างบอก "ยังไม่มีของขาย จะเพิ่มในอนาคต"
@export var items: Array[ShopItem] = []


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint() and not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if Global.isDialogShown() or Global.isInMinigame():
		return
	var m := owner
	if m and m.has_method(&"open_shop"):
		m.open_shop(label_text, items, message)
	elif m and m.has_method(&"say"):
		m.say(message)
