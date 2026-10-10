class_name LocationDoor extends SceneHotspot
## จุดกดเปลี่ยนฉาก (ประตู · ป้าย · ทางเดิน) — ใส่รูปได้ (texture_normal/hover) หรือไม่ใส่ก็ได้ (กรอบเรืองแสงตอนชี้)
## [Claude 9 ต.ค. 2569] ใช้ใน Home (ประตูหน้าบ้าน) · Village (กลับบ้าน · ป้ายไปร้าน) · Room (ออกหน้าบ้าน)

## ฉากที่จะไป
@export var target: SceneRouter.LocationID = SceneRouter.LocationID.HOME


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint() and not pressed.is_connected(_go):
		pressed.connect(_go)


func _go() -> void:
	# ห้ามเปลี่ยนฉากระหว่างบทสนทนาหรือมินิเกม (ฉากใต้ UI จะถูกปล่อยทิ้ง)
	if Global.isDialogShown() or Global.isInMinigame():
		return
	SceneRouter.go(target)
