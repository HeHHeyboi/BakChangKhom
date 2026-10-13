class_name GiveUpLayer extends CanvasLayer
## [Claude 13 ต.ค. 2569] ปุ่ม "ยอมแพ้งานนี้" ในมินิเกมงานลูกค้า (playtest 12 ต.ค.: ทำพลาดจนไปต่อไม่ได้ ต้องออกเกม)
## โหนดทั้งหมดอยู่ใน Scene/MiniGame/PartBase/give_up_layer.tscn — ปรับตำแหน่ง/ข้อความใน Inspector ได้
## PartMinigame สร้างให้เองเฉพาะงานลูกค้า (meta work_order) · ขมOS มีปุ่ม "ส่งงานตามสภาพ" ของตัวเองแล้ว จึงไม่ใส่

signal confirmed

@onready var open_button: Button = %GiveUpButton
@onready var confirm: Control = %Confirm
@onready var yes_button: Button = %Yes
@onready var no_button: Button = %No


func _ready() -> void:
	confirm.hide()
	open_button.pressed.connect(_ask)
	no_button.pressed.connect(confirm.hide)
	yes_button.pressed.connect(_on_yes)


func _ask() -> void:
	confirm.show()


func _on_yes() -> void:
	confirm.hide()
	open_button.disabled = true
	confirmed.emit()
