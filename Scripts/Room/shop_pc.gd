@tool
extends SceneHotspot
## คอมของขมบนโต๊ะร้าน — กดแล้วเปิดขมOS แบบเล่นอิสระ (ไม่มีลูกค้า ไม่คิดคะแนน/เงิน)
## ไฟล์/โปรแกรมในเครื่องแก้ได้ที่ Resources/Desktop/Free/khom_pc.tres · [Claude 9 ต.ค. 2569]
## [15 พ.ย. 2569 · 0.3.0] ย้ายไปขมOS ชุดใหม่ (desktop_window2 · DesktopMinigameV2) + แอป "งานซ่อม" (ตารางใบรับเครื่อง)

const DESKTOP_SCENE := "res://Scene/MiniGame/Desktop/desktop_window2.tscn"
const WORK_APP_SCENE := preload("res://Scene/UI/work_order_app.tscn")
const WORK_APP_NAME := "งานซ่อม"
## กว้างไม่ทับโน้ตงานมุมขวาบนของขมOS
const WORK_APP_SIZE := Vector2(470, 440)
## เปิดชิดซ้ายบน ถัดจากไอคอนเดสก์ท็อป
const WORK_APP_POS := Vector2(205, 24)
## [0.4.0 ขั้น E] แอปร้านออนไลน์ (สั่งอะไหล่ มาถึงวันเปิดร้านถัดไป)
const SHOP_APP_SCENE := preload("res://Scene/UI/online_shop_app.tscn")
const SHOP_APP_NAME := "ร้านออนไลน์"
const SHOP_APP_SIZE := Vector2(470, 450)
const SHOP_APP_POS := Vector2(205, 40)
## [0.5.0 ขั้น D] แอปสมุดลูกค้า (ความสนิท · เคยซ่อมอะไร · เรื่องที่เคยฟัง)
const BOOK_APP_SCENE := preload("res://Scene/UI/customer_book_app.tscn")
const BOOK_APP_NAME := "สมุดลูกค้า"
const BOOK_APP_SIZE := Vector2(470, 450)
const BOOK_APP_POS := Vector2(205, 56)
## [0.5.0] แอปสอบช่าง (สอบเลื่อนยศเมื่อ XP ครบ)
const EXAM_APP_SCENE := preload("res://Scene/UI/rank_exam_app.tscn")
const EXAM_APP_NAME := "สอบช่าง"
const EXAM_APP_SIZE := Vector2(430, 400)
const EXAM_APP_POS := Vector2(205, 72)
## [0.7.0 ขั้น J] แอปใบประกาศ (Achievement)
const ACH_APP_SCENE := preload("res://Scene/UI/achievement_app.tscn")
const ACH_APP_NAME := "ใบประกาศ"
const ACH_APP_SIZE := Vector2(470, 450)
const ACH_APP_POS := Vector2(205, 88)
## ข้อมูลเครื่อง (DesktopTask)
@export var task: DesktopTask = preload("res://Resources/Desktop/Free/khom_pc.tres")


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		pressed.connect(open_pc)


## เปิดขมOS · คืน null ถ้าเปิดไม่ได้ (กำลังมีบท/มินิเกม)
func open_pc() -> Node:
	if Global.isDialogShown() or Global.isInMinigame():
		return null
	var ps := load(DESKTOP_SCENE) as PackedScene
	if ps == null or task == null:
		push_error("shop_pc: เปิดขมOS ไม่ได้ (%s)" % DESKTOP_SCENE)
		return null
	var m := ps.instantiate()
	m.set("task", task)
	m.set("free_mode", true)
	if m.has_method(&"add_custom_app"):
		m.ready.connect(func() -> void:
			m.add_custom_app(WORK_APP_NAME, Icons.tex(&"clipboard"), WORK_APP_SCENE, WORK_APP_SIZE, WORK_APP_POS)
			m.add_custom_app(SHOP_APP_NAME, Icons.tex(&"cart"), SHOP_APP_SCENE, SHOP_APP_SIZE, SHOP_APP_POS)
			m.add_custom_app(BOOK_APP_NAME, Icons.tex(&"book"), BOOK_APP_SCENE, BOOK_APP_SIZE, BOOK_APP_POS)
			m.add_custom_app(EXAM_APP_NAME, Icons.tex(&"star"), EXAM_APP_SCENE, EXAM_APP_SIZE, EXAM_APP_POS)
			m.add_custom_app(ACH_APP_NAME, Icons.tex(&"trophy"), ACH_APP_SCENE, ACH_APP_SIZE, ACH_APP_POS), CONNECT_ONE_SHOT)
	Global.in_minigame = true
	SceneRouter.push_node(m)
	return m
