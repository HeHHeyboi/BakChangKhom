class_name ItemDef extends ShopItem
## ของ 1 ชนิดที่ซื้อเก็บเข้าคลังได้ (อะไหล่ · ของสิ้นเปลือง · อัปเกรดคลัง) — Docs/STORAGE_SHOP_ECO.md ข้อ 1–2
## สร้าง .tres ใน Resources/Shop/ แล้วลากใส่ MarketStall.items ใน Inspector (ใช้แทน ShopItem ได้เลย เพราะ extends ShopItem)
## [Claude 13 ต.ค. 2569]

enum Kind {
	PART, ## อะไหล่: 1 ชิ้น = 1 ช่อง (ไม่ซ้อน)
	SUPPLY, ## ของสิ้นเปลือง: ซ้อนในช่องเดียว นับเป็น "ครั้ง"
	UPGRADE, ## อัปเกรดคลัง/ชั้นวางเครื่อง: ไม่กินช่อง ซื้อครั้งเดียว
}

@export var kind: Kind = Kind.PART
## ไอคอนสำรองตอนยังไม่มีรูป (icon ว่าง)
@export var emoji := ""
## สภาพอะไหล่ (PART)
@export_enum("used", "new") var condition := "used"
## SUPPLY: ได้กี่ครั้งต่อ 1 แพ็ก
@export var uses := 0
## ตลาดมีของกี่ชิ้นต่อรอบ (0 = ไม่จำกัด) · [0.4.0] 1 รอบ = EconomyConfig.market_restock_days วันเปิดร้าน (วันที่ 4 และ 18) · ชื่อเดิมคงไว้ให้ .tres เก่าใช้ได้
@export var weekly_stock := 0
## ยศช่างขั้นต่ำที่ซื้อได้ (GameState.rank())
@export var unlock_rank := 0
## UPGRADE: ขยายคลังเป็นกี่ช่อง
@export var storage_slots_to := 0
## [0.3.0] UPGRADE: ขยายชั้นวางเครื่อง (รับเครื่องไว้ซ่อม) เป็นกี่ช่อง
@export var shelf_slots_to := 0

@export_group("ร้านออนไลน์ (0.4.0)")
## ราคาในร้านออนไลน์ (ขมOS) · 0 = เท่าราคาตลาด (price)
@export var online_price := 0
## วางขายในร้านออนไลน์ไหม (อัปเกรดคลัง/ชั้นวาง = ไม่ขาย)
@export var online := true
## ขายในตลาดหมู่บ้านไหม (false = สั่งออนไลน์อย่างเดียว เช่น การ์ดจอมือสอง)
@export var market := true
## [0.4.0] อะไหล่ชิ้นนี้ใช้ชดใช้ของลูกค้าที่ทำเสียใน Part ไหน (part_gpu …) · ว่าง = ไม่ใช่ของชดใช้
@export var replaces: StringName


## [0.4.0] ราคาร้านออนไลน์
func online_cost() -> int:
	return online_price if online_price > 0 else price


func condition_text() -> String:
	if kind != Kind.PART:
		return ""
	return "ใหม่" if condition == "new" else "มือสอง"


## ข้อความบนการ์ดในร้าน (บรรทัดล่างชื่อ)
func card_badge() -> String:
	match kind:
		Kind.PART:
			return "ใหม่" if condition == "new" else "มือสอง"
		Kind.SUPPLY:
			return "%d ครั้ง" % uses
		Kind.UPGRADE:
			return ("ชั้นวาง %d เครื่อง" % shelf_slots_to) if shelf_slots_to > 0 else ("คลัง %d ช่อง" % storage_slots_to)
	return ""
