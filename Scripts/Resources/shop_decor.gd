class_name ShopDecor
extends Resource
## [Claude 16 พ.ย. 2569 · 0.8.0 ขั้น F–G] ของตกแต่งในร้าน — รางวัลใบประกาศ (from_achievement) หรือของขวัญเดือน 12 (from_npc)
## ไม่มีผลกับตัวเลข · [0.9.0] ไม่แสดงในห้องแล้ว — ใช้เป็นข้อมูลของขวัญส่งท้ายปี (รายการท้ายหน้าความสำเร็จในเมนูพัก)
## ข้อมูล Resources/Decor/*.tres · ข้อความห้ามมี , หรือ : (ใช้ในบทของขวัญ)

enum Spot { SHELF, WALL, CEILING, TITLE }

@export var id: StringName
@export var title: String
@export_multiline var desc: String
## ปลดจากใบประกาศนี้ (ว่าง = ไม่ใช่รางวัลใบประกาศ)
@export var from_achievement: StringName
## ของขวัญจาก NPC นี้ (ว่าง = ไม่ใช่ของขวัญ)
@export var from_npc: StringName
## บรรทัดตอนให้ของขวัญ (คนให้พูด · 1–2 ประโยค)
@export_multiline var gift_line: String
@export var spot: Spot = Spot.SHELF
@export var icon: StringName = &"star"
@export var tint := Color.WHITE
@export var texture: Texture2D


func image() -> Texture2D:
	return texture if texture else Icons.tex(icon)
