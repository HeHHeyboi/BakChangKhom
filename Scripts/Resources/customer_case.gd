@tool
class_name CustomerCase extends Resource
## ลูกค้า 1 คน = งานซ่อม 1 งาน · แก้ทุกช่องได้ใน Inspector (ดับเบิลคลิกไฟล์ใน Resources/Customers/)
## DayLoop เอาไปทำการ์ดลูกค้า → บทพูด → มินิเกม → การ์ดผลงาน · ดู Docs/WEEK1_CUSTOMERS.md
## [Claude 5 ต.ค. 2569]

## มินิเกมของแต่ละ Core Part
const PART_SCENES := {
	"part_ram": "res://Scene/MiniGame/PartRam/part_ram.tscn",
	"part_mainboard": "res://Scene/MiniGame/PartMainboard/part_mainboard.tscn",
	"part_gpu": "res://Scene/MiniGame/PartGpu/part_gpu.tscn",
	"part_front_panel": "res://Scene/MiniGame/PartFrontPanel/part_front_panel.tscn",
	"part_bios": "res://Scene/MiniGame/PartBios/part_bios.tscn",
	"part_desktop": "res://Scene/MiniGame/Desktop/desktop_window2.tscn", # ขมOS งานบนจอ Lv1 → ใส่ desktop_task ด้วย · [13 พ.ย. 0.3.0] ใช้ขมOS ชุดใหม่ (desktop_minigame2 วางใน Editor) · ตัวเดิม desktop_window.tscn ยังใช้ในบทฝึกประกอบคอม/คอมเล่นอิสระ
	"part_bench": "res://Scene/MiniGame/Bench/back_bench.tscn", # โต๊ะหลังเครื่อง Lv2 → ใส่ bench_task ด้วย [10 ต.ค.]
}

const PART_RAM = "part_ram"
const PART_MAINBOARD = "part_mainboard"
const PART_GPU = "part_gpu"
const PART_FRONT_PANEL = "part_front_panel"
const PART_BIOS = "part_bios"
const PART_DESKTOP = "part_desktop"
const PART_BENCH = "part_bench"

@export_group("ลูกค้า")
## รหัสงาน (ไม่ซ้ำกัน) เช่น w1_d1_amnuay
@export var id: StringName
## ชื่อตัวละคร — ต้องตรงกับ key ใน Global._CharacterMap (Scene/Global.tscn) เช่น ลุงอำนวย · ครู · เด็กหญิง
@export var customer: String = "ลุงอำนวย"
## เหตุผลที่ลูกค้ามาร้านขม (บังคับกรอก) — โชว์บนการ์ดลูกค้า เช่น "ยายเล่าว่าขมกลับมาเปิดร้าน"
@export_multiline var reason: String
## เครื่องของลูกค้า เช่น "คอมตั้งโต๊ะเครื่องเก่า ใช้มา 6 ปี"
@export var device: String
## อาการที่ลูกค้าเล่า
@export_multiline var symptom: String

@export_group("ระดับงาน (LEVEL_DESIGN ข้อ 2 · 7.2)")
## 1 ง่าย · 2 ปกติ · 3 ปานกลาง · 4 ยาก · 5 ชำนาญ — ค่าจ้าง/XP จาก economy.tres
@export_range(1, 5) var level := 2
## เวลาที่ประเมินบนการ์ด (ช่อง 30 นาที) · 0 = ใช้ค่าเฉลี่ยของระดับ
@export_range(0, 14) var est_slots := 0
## ต้องรับภายในกี่กะ · 0 = ภายในกะนี้ · หมดเขต = ลูกค้าเดินออก
@export_range(0, 10) var due_shifts := 1
## [0.2.5] เดือนที่ลูกค้าคนนี้มาได้ (1 = ม.ค. … 12 = ธ.ค.) · ว่าง = ทุกเดือน · ใช้กับงานตามฤดู เช่น หน้าร้อนการ์ดจอร้อน (เม.ย.–พ.ค.) หน้าฝนแรมขึ้นสนิม
@export var months: PackedInt32Array = []

@export_group("งานซ่อม")
## Core Part ที่ต้องซ่อม → เปิดมินิเกมตัวนั้น
@export_enum(
	PART_RAM,
	PART_MAINBOARD,
	PART_GPU,
	PART_FRONT_PANEL,
	PART_BIOS,
	PART_DESKTOP,
	PART_BENCH,
) var part_id: String = PART_RAM
## งานบนจอ (part_desktop) — ข้อมูลเครื่อง/ไฟล์/กับดักในขมOS (Resources/Desktop/*.tres) · [Claude 9 ต.ค. 2569]
@export var desktop_task: DesktopTask
## งานโต๊ะหลังเครื่อง (part_bench) — สาย/ช่อง/คีย์บอร์ดสกปรก (Resources/Bench/*.tres) · [Claude 10 ต.ค. 2569]
@export var bench_task: BenchTask
## ชื่องานบนการ์ดผลงาน เช่น "ทำความสะอาดแรม" (การ์ดบนกระดานไม่โชว์ — ผู้เล่นต้องวินิจฉัยเอง)
@export var job_title: String
## ค่าซ่อม (บาท) · −1 = ใช้ค่าจาก Resources/Balance/economy.tres
@export var fee := -1
## มินิเกมอื่นแทนของ part_id (ปกติเว้นว่าง)
@export_file("*.tscn") var scene_override: String
## [0.3.0] ยืนรอหน้าประตูได้กี่เทิร์น · 0 = ค่าเริ่ม (EconomyConfig.door_patience_slots = 2) · ผู้สูงอายุ 3 · คนรีบ 1
@export_range(0, 6) var patience := 0

@export_group("อะไหล่ (0.4.0 · PLAN_0_4_0 ข้อ 2)")
## อะไหล่ที่ต้องเปลี่ยน (id ใน Resources/Shop/) · ว่าง = ไม่ต้องใช้ · มีแล้วต้องมีของในคลังก่อนถึงซ่อมได้
@export var needs_part: StringName
## ใช้ของแทนได้ (เช่น แรมใหม่แทนมือสอง) — ลองตามลำดับหลัง needs_part
@export var part_alternatives: Array[StringName] = []
## ปิ๊บสรุปบนการ์ด เช่น "ถ่าน CMOS หมด เวลาเครื่องเลยเพี้ยน" · ว่าง = "ต้องเปลี่ยน: ชื่ออะไหล่"
@export var part_hint: String
## ของสิ้นเปลืองที่ใช้ { id: ครั้ง } · ว่าง = ใช้ค่าตาม Part (EconomyConfig.part_supplies)
@export var supplies: Dictionary[StringName, int] = {}

@export_group("บทพูด")
## บทตอนลูกค้าเข้าร้าน (รูปแบบเดียวกับ Assets/Dialog — ชื่อ,ข้อความ)
@export_file("*.txt") var arrive_dialog: String
## ฉากหลังของบท · ว่าง = ร้านขม
@export_file("*.png", "*.jpg") var bg: String = "res://Assets/Background/bg_shop_open.jpg"
## ลูกค้าพูดตอนรับเครื่อง ถ้าซ่อมผ่าน (โชว์บนการ์ดผลงาน)
@export_multiline var thanks_text: String
## ลูกค้าพูดตอนรับเครื่อง ถ้าซ่อมไม่ผ่าน
@export_multiline var complain_text: String

@export_group("Event")
## event บังคับ: บทลูกค้าเล่นเองทันทีที่เข้าร้าน · ปฏิเสธงาน/ปิดร้านไม่ได้ (ใช้กับลูกค้าคนแรกหลัง Tutorial)
@export var forced := false


@export_group("แยกคนกับงาน (0.6.0 · PLAN_0_6_0 ข้อ 2)")
## ชนิดเรื่องที่ลูกค้าเอามา · REPAIR = งานซ่อม (เดิม) · CONSULT/FAVOR = คำขอ 1 เทิร์น (ขั้น G)
@export_enum("REPAIR", "CONSULT", "FAVOR") var kind := 0
## [0.6.0] งานกลาง: เว้น customer ว่าง แล้วใส่ป้ายว่าคนแบบไหนเอามาได้ (ตรงกับ CustomerNPC.tags) · "any" = ใครก็ได้
## ตอนสุ่ม DayLoop เลือกคนก่อน แล้ว instance_for(npc) ใส่ชื่อ/เครื่องของคนนั้น ({npc} {device} ในข้อความ)
@export var npc_tags: PackedStringArray = []
## ความสนิทขั้นต่ำของคนที่จะเอางานนี้มา (เช่น เรื่องที่เล่าเฉพาะคนสนิท)
@export_range(0, 100) var min_affinity := 0
## กลุ่มนักเรียนเอามาได้ (ขั้น I)
@export var group_ok := false
## จำนวนเครื่อง (กลุ่ม 2 เครื่อง = มินิเกม 2 รอบ · ขั้น I)
@export_range(1, 2) var device_count := 1
## [0.6.0] ใช้ตัวสุ่มอาการของ Part นี้ (ขั้น C) · false = อาการตามเคสเดิม
@export var use_scenario := false
## ยศขั้นต่ำที่งานนี้จะมา (GameState.rank_level) · เช่น กลุ่ม 2 เครื่อง = ยศประจำหมู่บ้าน (2)
@export_range(0, 4) var min_rank := 0

const KIND_REPAIR := 0
const KIND_CONSULT := 1
const KIND_FAVOR := 2


## [0.6.0] งานกลาง (ไม่ผูกคน) — รอใส่ชื่อตอนสุ่ม
func is_generic() -> bool:
	return customer.strip_edges() == ""


## [0.6.0] เคสต้นแบบ (ไฟล์ใน Resources/Customers/) — เคสที่ใส่ชื่อแล้วจำต้นแบบไว้ใน meta "template"
func template() -> CustomerCase:
	if has_meta("template"):
		var t = get_meta("template")
		if t is CustomerCase:
			return t
	return self


## [0.6.0] งานกลางที่ใส่ชื่อคนนี้แล้ว (สำเนา) · customer = char_key → NpcBook.of_case / npc_id / ประวัติเครื่อง ใช้ได้เหมือนเดิม
## งานที่ผูกคนอยู่แล้ว → คืนตัวเดิม
func instance_for(npc: CustomerNPC, device_text := "") -> CustomerCase:
	if not is_generic() or npc == null:
		return self
	var c := duplicate() as CustomerCase
	c.set_meta("template", self)
	c.customer = npc.char_key
	var dev := device_text if device_text != "" else (npc.devices[0] if not npc.devices.is_empty() else "")
	if dev != "":
		c.device = dev if c.device.strip_edges() == "" or c.device.contains("{device}") else c.device
	if npc.is_group(): # [0.6.0 ขั้น I] กลุ่ม = คุยกันหลายคน +1 เทิร์น
		c.est_slots = (est_slots if est_slots > 0 else [2, 3, 5, 7, 10][clampi(level, 1, 5) - 1]) + 1
	var vars := { "npc": npc.display_name, "name": npc.display_name, "device": dev if dev != "" else c.device }
	for f in ["reason", "symptom", "job_title", "thanks_text", "complain_text", "device", "part_hint"]:
		c.set(f, fill_vars(String(c.get(f)), vars))
	return c


## [0.6.0 ขั้น C] ใส่สถานการณ์จากตัวสุ่ม (ScenarioBook.roll) ลงเคสที่เป็นสำเนา · roll = { scenario · trait · condition }
## เปลี่ยนอาการ · ชื่องาน · อะไหล่ · เครื่อง (+สภาพ) · ลูกค้ารีบ = รอได้ 1 เทิร์น · งบน้อย = ค่าแรง × budget_fee_mult (0.9)
func apply_scenario(roll: Dictionary, econ: EconomyConfig = null) -> void:
	var sc: RepairScenario = roll.get("scenario")
	if sc == null:
		return
	set_meta("scenario", sc)
	if not has_meta("base_device"):
		set_meta("base_device", device)
	set_meta("trait", StringName(roll.get("trait", &"normal")))
	set_meta("condition", StringName(roll.get("condition", &"old")))
	symptom = sc.symptom
	if sc.job_title != "":
		job_title = sc.job_title
	needs_part = sc.needs_part
	part_alternatives = sc.part_alternatives.duplicate()
	part_hint = sc.part_hint
	var cond := String(ScenarioBook.CONDITION_NAMES.get(get_meta("condition"), ""))
	if cond != "" and not device.contains(cond):
		device = "%s (%s)" % [device, cond]
	match get_meta("trait"):
		&"rushed":
			patience = 1
		&"budget":
			var base: int = fee if fee >= 0 else (econ.fee_for_level(level) if econ else [60, 150, 300, 420, 750][clampi(level, 1, 5) - 1])
			fee = int(round(base * (econ.budget_fee_mult if econ else 0.9)))


## [0.6.0 ขั้น G] ใส่คำขอ (ขอคำปรึกษา/ขอให้ช่วย) ลงสำเนา any_request · 1 เทิร์น · ไม่มีมินิเกม
func apply_request(r: RequestTask) -> void:
	if r == null:
		return
	set_meta("request", r)
	kind = KIND_CONSULT if r.is_consult() else KIND_FAVOR
	job_title = "%s · %s" % [r.kind_name(), r.title]
	symptom = r.ask
	fee = r.fee
	est_slots = 1
	if r.thanks != "":
		thanks_text = r.thanks


func request() -> RequestTask:
	return get_meta("request") if has_meta("request") else null


func is_request() -> bool:
	return kind != KIND_REPAIR


func scenario() -> RepairScenario:
	return get_meta("scenario") if has_meta("scenario") else null


func scenario_roll() -> Dictionary:
	if not has_meta("scenario"):
		return { }
	return { "scenario": get_meta("scenario"), "trait": get_meta("trait", &"normal"), "condition": get_meta("condition", &"old") }


## [0.6.0 ขั้น H] ค่าแรงตามคน (นักเรียน ×0.6) · เคสผูกคนทำสำเนาก่อน (ต้นแบบไม่เปลี่ยน) · คืนเคสที่ใช้ต่อ
func with_fee_mult(npc: CustomerNPC, econ: EconomyConfig = null) -> CustomerCase:
	if npc == null or is_equal_approx(npc.fee_mult, 1.0) or kind != KIND_REPAIR or has_meta("fee_mult"):
		return self
	var c := self
	if template() == self:
		c = duplicate() as CustomerCase
		c.set_meta("template", self)
	var base: int = fee if fee >= 0 else (econ.fee_for_level(level) if econ else [60, 150, 300, 420, 750][clampi(level, 1, 5) - 1])
	c.fee = maxi(1, roundi(base * npc.fee_mult))
	c.set_meta("fee_mult", npc.fee_mult)
	return c


## แทน {key} ในข้อความ
static func fill_vars(text: String, vars: Dictionary) -> String:
	if not text.contains("{"):
		return text
	var out := text
	for k in vars:
		out = out.replace("{%s}" % k, String(vars[k]))
	return out


## [0.6.0] เก็บลงเซฟ: ไฟล์ต้นแบบ + ชื่อคน (งานกลาง) · เคสผูกคน = path อย่างเดียวเหมือนเซฟเก่า
static func to_ref(c: CustomerCase) -> Variant:
	if c == null:
		return ""
	var t := c.template()
	if t == c:
		return c.resource_path
	var n := NpcBook.of_case(c)
	var d := { "path": t.resource_path, "npc": String(n.id) if n else "", "device": c.device, "fee": c.fee }
	if c.request():
		d["request"] = String(c.request().id)
	if c.scenario():
		d["scenario"] = String(c.scenario().id)
		d["trait"] = String(c.get_meta("trait", &"normal"))
		d["condition"] = String(c.get_meta("condition", &"old"))
		d["device"] = String(c.get_meta("base_device", c.device))
	return d


## อ่านจากเซฟ (String = เซฟเก่า/เคสผูกคน · Dictionary = งานกลาง) · null = ไฟล์หาย
static func from_ref(v: Variant) -> CustomerCase:
	var path := ""
	var d := { }
	if v is Dictionary:
		d = v
		path = String(d.get("path", ""))
	else:
		path = String(v)
	if path == "" or not ResourceLoader.exists(path):
		return null
	var t := load(path) as CustomerCase
	if t == null or d.is_empty():
		return t
	if not t.is_generic(): # [0.6.0] เคสผูกคนที่ปรับค่าแรงตามคน (นักเรียน)
		return t.with_fee_mult(NpcBook.by_id(StringName(d.get("npc", ""))), GameState.economy)
	var n := NpcBook.by_id(StringName(d.get("npc", "")))
	if n == null:
		return null
	var c := t.instance_for(n, String(d.get("device", ""))).with_fee_mult(n, GameState.economy)
	var rq := RequestBook.by_id(StringName(d.get("request", "")))
	if rq:
		c.apply_request(rq)
	var sc := ScenarioBook.by_id(StringName(d.get("scenario", "")))
	if sc:
		c.set_meta("base_device", c.device)
		c.apply_scenario({ "scenario": sc, "trait": StringName(d.get("trait", "normal")), "condition": StringName(d.get("condition", "old")) }, GameState.economy if Engine.get_main_loop() else null)
	if d.has("fee"): # ค่าแรงตอนรับเครื่อง (งบน้อย · นักเรียน · กลุ่ม 2 เครื่อง) — ใส่ท้ายสุด ไม่คูณซ้ำ
		c.fee = int(d.fee)
	return c


## [0.2.5] มาได้ในเดือนนี้ไหม
func in_month(m: int) -> bool:
	return months.is_empty() or months.has(m)


func scene_path() -> String:
	return scene_override if scene_override != "" else PART_SCENES.get(part_id, "")


func part() -> StringName:
	return StringName(part_id)


## [0.3.0] งานนี้ต้องรับเครื่องไว้ (ฮาร์ดแวร์ → ใบรับเครื่อง + ชั้นวาง) · งานขมOS ทำต่อหน้าลูกค้าจบในวันเดียว
func takes_machine() -> bool:
	return part_id != PART_DESKTOP and kind == KIND_REPAIR # [0.6.0] คำขอไม่รับเครื่อง


## [0.3.0] รอหน้าประตูได้กี่เทิร์น
func patience_slots(econ: EconomyConfig = null) -> int:
	if patience > 0:
		return patience
	return econ.door_patience_slots if econ else 2


const LEVEL_NAMES := ["ง่าย", "ปกติ", "ปานกลาง", "ยาก", "ชำนาญ"]


func level_name() -> String:
	return "Lv%d %s" % [level, LEVEL_NAMES[clampi(level, 1, 5) - 1]]


## เวลาที่ใช้ (ช่อง) · est_slots หรือค่าเฉลี่ยของระดับ
func slots(econ: EconomyConfig = null) -> int:
	if est_slots > 0:
		return est_slots
	if econ:
		return ceili(econ.avg_slots_for_level(level))
	return [2, 3, 5, 7, 10][clampi(level, 1, 5) - 1]


## ช่องที่ขาด — DayLoop เตือนใน Output ตอนเริ่มเกม
func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if id == &"":
		out.append("ไม่มี id")
	if customer.strip_edges() == "":
		if npc_tags.is_empty():
			out.append("ไม่มีชื่อลูกค้า (customer) — งานกลางต้องใส่ npc_tags")
		if forced:
			out.append("งานบังคับต้องมีชื่อลูกค้า")
	elif use_scenario:
		out.append("use_scenario ใช้ได้เฉพาะงานกลาง (customer ว่าง)")
	elif not Engine.is_editor_hint():
		var g := (Engine.get_main_loop() as SceneTree).root.get_node_or_null(^"Global") if Engine.get_main_loop() is SceneTree else null
		if g and g.has_method("hasCharacter") and not g.hasCharacter(customer):
			out.append("ชื่อ \"%s\" ไม่มีใน Global._CharacterMap (บทจะไม่ขึ้นรูป)" % customer)
	if reason.strip_edges() == "":
		out.append("ไม่มีเหตุผลที่ลูกค้ามา (reason)")
	if symptom.strip_edges() == "":
		out.append("ไม่มีอาการ (symptom)")
	if job_title.strip_edges() == "":
		out.append("ไม่มีชื่องาน (job_title)")
	if fee < -1:
		out.append("fee ติดลบ (ใช้ -1 = ค่าจาก economy)")
	if part_id == "part_desktop" and scene_override == "":
		if desktop_task == null:
			out.append("งานบนจอ (part_desktop) ต้องใส่ desktop_task")
		else:
			out.append_array(desktop_task.problems())
	if part_id == "part_bench" and scene_override == "":
		if bench_task == null:
			out.append("งานโต๊ะหลังเครื่อง (part_bench) ต้องใส่ bench_task")
		else:
			out.append_array(bench_task.problems())
	if scene_path() == "" or not ResourceLoader.exists(scene_path()):
		out.append("ไม่พบมินิเกม %s" % scene_path())
	if arrive_dialog != "":
		if not FileAccess.file_exists(arrive_dialog):
			out.append("ไม่พบบท %s" % arrive_dialog)
		elif not DialogUtil.has_lines(arrive_dialog):
			out.append("บท %s ว่าง (ไม่มีบรรทัด ชื่อ,ข้อความ)" % arrive_dialog.get_file())
		else:
			# DialogScene อ่าน ":" เป็นหัว branch ของ Choice — อารมณ์ให้เขียน "ขม (ยิ้ม),..." ไม่ใช่ "ขม:happy,..."
			for n in DialogUtil.colon_lines(arrive_dialog):
				out.append("%s บรรทัด %d มี \":\" (อารมณ์ให้เขียน \"ชื่อ (ยิ้ม),\")" % [arrive_dialog.get_file(), n])
	if bg != "" and not ResourceLoader.exists(bg):
		out.append("ไม่พบฉากหลัง %s" % bg)
	if thanks_text.strip_edges() == "" or complain_text.strip_edges() == "":
		out.append("ไม่มีคำพูดตอนรับเครื่อง (thanks_text / complain_text)")
	return out


## [0.4.0] อะไหล่ที่ใช้ได้กับงานนี้ (ตัวหลักก่อน แล้วของแทน) · ว่าง = ไม่ต้องใช้อะไหล่
func part_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	if needs_part != &"":
		out.append(needs_part)
		for a in part_alternatives:
			if a != &"" and not out.has(a):
				out.append(a)
	return out


## [0.4.0] ของสิ้นเปลืองที่งานนี้ใช้ { id: ครั้ง }
func supply_need(econ: EconomyConfig = null) -> Dictionary:
	if not supplies.is_empty():
		return supplies
	if econ and econ.part_supplies.has(StringName(part_id)):
		return econ.part_supplies[StringName(part_id)]
	return { }
