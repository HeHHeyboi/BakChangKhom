class_name DecorBook
## [Claude 16 พ.ย. 2569 · 0.8.0 ขั้น F–G] ของตกแต่งในร้าน (Resources/Decor/*.tres) + ของขวัญเดือน 12
## มีของ = ได้ใบประกาศที่ผูกไว้ หรือได้รับของขวัญจาก NPC (GameState.gifts_received) · ไม่มีผลกับตัวเลข

const DIR := "res://Resources/Decor/"
## ความสนิทที่มาให้ของขวัญเอง · ต่ำกว่านี้แต่ถึง CARD_AT = ฝากการ์ดอวยพร
const GIFT_AT := 80
const CARD_AT := 60
const GIFT_TITLE := "ของขวัญส่งท้ายปี"

static var _all: Array[ShopDecor] = []


static func all() -> Array[ShopDecor]:
	if _all.is_empty():
		var files := Array(DirAccess.get_files_at(DIR))
		files.sort()
		for f in files:
			var path: String = DIR + String(f).trim_suffix(".remap")
			if not path.ends_with(".tres"):
				continue
			var d := load(path) as ShopDecor
			if d and not _all.has(d):
				_all.append(d)
	return _all


static func by_id(id: StringName) -> ShopDecor:
	for d in all():
		if d.id == id:
			return d
	return null


static func gift_of(npc: StringName) -> ShopDecor:
	for d in all():
		if d.from_npc == npc:
			return d
	return null


static func is_owned(d: ShopDecor) -> bool:
	if d.from_achievement != &"" and GameState.achievements.has(String(d.from_achievement)):
		return true
	return d.from_npc != &"" and GameState.gifts_received.has(String(d.from_npc))


static func owned(spot: int = -1) -> Array[ShopDecor]:
	var out: Array[ShopDecor] = []
	for d in all():
		if (spot < 0 or d.spot == spot) and is_owned(d):
			out.append(d)
	return out


## ฉายาของขม (ของตกแต่งชนิด TITLE ที่มี) · ว่าง = ยังไม่มี
static func title_text() -> String:
	var t := owned(ShopDecor.Spot.TITLE)
	return t[0].title.trim_prefix("ฉายา ") if not t.is_empty() else ""


## ของขวัญสิ้นปี: { gifts: [{npc, decor}], cards: [ชื่อ] } · ยายให้เสมอ (ครอบครัว) · คนอื่นต้องสนิท ≥ GIFT_AT · 60–79 ฝากการ์ด
## กลุ่มไม่นับ (ให้ของผ่านสมาชิกที่ผูกของขวัญไว้ เช่น บิว = แก๊งสามเกลอ · ภูมิ = ชมรม)
static func year_gifts() -> Dictionary:
	var gifts: Array = []
	var cards: Array = []
	for n in NpcBook.all():
		if n.is_group():
			continue
		var d := gift_of(n.id)
		var a := GameState.affinity(n.id) if n.has_affinity else 100
		if not n.has_affinity and n.id != &"yai":
			continue
		if a >= GIFT_AT and d:
			gifts.append({ "npc": n, "decor": d })
		elif a >= CARD_AT and n.has_affinity:
			cards.append(n.display_name)
	return { "gifts": gifts, "cards": cards }


## รับของขวัญทั้งหมด → GameState.gifts_received { npc_id: decor_id }
static func grant(list: Dictionary) -> void:
	for g in list.get("gifts", []):
		GameState.gifts_received[String((g.npc as CustomerNPC).id)] = String((g.decor as ShopDecor).id)
	GameState.story_flags["gifts_done"] = true


## บทของขวัญ (เขียนไฟล์ชั่วคราวใน user://) · คืน path
static func gift_dialog(list: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("คำบรรยาย,วันเปิดร้านวันสุดท้ายของปี เช้านี้มีคนมายืนรอหน้าร้านตั้งแต่ยังไม่เปิด")
	for g in list.get("gifts", []):
		var n: CustomerNPC = g.npc
		var d: ShopDecor = g.decor
		lines.append("%s,%s" % [n.char_key, _clean(d.gift_line)])
		lines.append("คำบรรยาย,ได้รับ %s" % _clean(d.title))
	var cards: Array = list.get("cards", [])
	if not cards.is_empty():
		lines.append("ยาย,แล้วก็มีการ์ดอวยพรฝากมาจาก %s ด้วยนะลูก" % _clean(" ".join(cards)))
	if (list.get("gifts", []) as Array).size() <= 1:
		lines.append("ยาย,ปีหน้าค่อย ๆ รู้จักคนเพิ่มนะลูก คนที่เราใส่ใจเขาจำเราได้เสมอ")
	lines.append("ขม (ยิ้ม),ขอบคุณทุกคนครับ ผมจะตั้งไว้ในร้านให้ทุกคนเห็นเลย")
	var path := "user://dialog_tmp_gifts.txt"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string("\n".join(lines) + "\n")
	f.close()
	return path


static func _clean(t: String) -> String:
	return t.replace(",", " ").replace(":", " ").replace("\n", " ")
