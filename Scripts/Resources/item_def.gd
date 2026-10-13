class_name ItemDef extends ShopItem
## ของ 1 ชนิดที่ซื้อเก็บเข้าคลังได้ (อะไหล่ · ของสิ้นเปลือง · อัปเกรดคลัง) — Docs/STORAGE_SHOP_ECO.md ข้อ 1–2
## สร้าง .tres ใน Resources/Shop/ แล้วลากใส่ MarketStall.items ใน Inspector (ใช้แทน ShopItem ได้เลย เพราะ extends ShopItem)
## [Claude 13 ต.ค. 2569]

enum Kind {
	PART, ## อะไหล่: 1 ชิ้น = 1 ช่อง (ไม่ซ้อน)
	SUPPLY, ## ของสิ้นเปลือง: ซ้อนในช่องเดียว นับเป็น "ครั้ง"
	UPGRADE, ## อัปเกรดคลัง: ไม่กินช่อง ซื้อครั้งเดียว
}

@export var kind: Kind = Kind.PART
## ไอคอนสำรองตอนยังไม่มีรูป (icon ว่าง)
@export var emoji := ""
## สภาพอะไหล่ (PART)
@export_enum("used", "new") var condition := "used"
## SUPPLY: ได้กี่ครั้งต่อ 1 แพ็ก
@export var uses := 0
## ร้านมีของกี่ชิ้นต่อสัปดาห์ (0 = ไม่จำกัด) · รีทุกต้นสัปดาห์
@export var weekly_stock := 0
## ยศช่างขั้นต่ำที่ซื้อได้ (GameState.rank())
@export var unlock_rank := 0
## UPGRADE: ขยายคลังเป็นกี่ช่อง
@export var storage_slots_to := 0


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
			return "คลัง %d ช่อง" % storage_slots_to
	return ""
