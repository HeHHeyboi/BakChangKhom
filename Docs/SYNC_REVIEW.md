# SYNC_REVIEW.md — เทียบโค้ดบน GitHub กับดีไซน์ (21 ก.ย. 2569)

> local = `origin/main` = commit **`1c9040a`** ("Update game") — ไม่มี commit ค้าง ไม่มีอะไร ahead/behind
> เอกสารนี้ **ไม่แก้โค้ดให้** — บอกว่าต้องแก้อะไรและแก้ยังไง เอาไปทำเองในโปรเจกต์
> เอกสารคู่กัน: `Docs/REPAIR_FLOW.md` · `Docs/MINIGAME1_DESIGN.md` · `Docs/ASSET_GUIDE.md`

---

## 0. สรุป 30 วินาที

| ระดับ                          | เรื่อง                                                                                                          | จำนวน  |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------- | ------ |
| 🔴 ต้องแก้ก่อนทำงานต่อ         | `.import` ไม่ตรงชื่อไฟล์ · ซีนชี้พาธเก่า · `in_minigame` ค้าง                                                   | 3      |
| 🟡 บั๊กเดิมที่ยังไม่แก้        | tutorial `curIndex` · `.scn` binary · `match clikTime`                                                          | 3      |
| 🟢 ข้อเสนอปรับโครง             | `trigger_step` เป็น data-driven · `minigame_end` เปราะ · find-item ยังไม่ใช่การค้นหาจริง · quest เป็นภาษาอังกฤษ | 4      |
| 📄 เอกสารที่ล้าสมัยตามโค้ดใหม่ | แก้ให้แล้วในรอบนี้                                                                                              | 3 ไฟล์ |
| ✍️ Text                        | แก้ของเดิม 3 · ไฟล์บทใหม่ที่ต้องเพิ่ม 8                                                                         | 11     |

**ข่าวดี:** บั๊ก **B1** (room.gd instantiate ซ้ำ) **หายไปแล้ว** เพราะ `Scripts/Room/room.gd` ถูกลบ และย้ายไป instantiate สด ๆ ใน `EventManager.trigger_step()` ทุกครั้ง — ตรงกับที่ดีไซน์แนะนำพอดี

---

## 0.1 ✅ สถานะการแก้ (อัปเดต 21 ก.ย. 2569)

**แก้ให้แล้วในรีโป — 9 รายการ**

| #      | รายการ                                                                                 | ไฟล์ที่แตะ                               |
| ------ | -------------------------------------------------------------------------------------- | ---------------------------------------- |
| 2.1    | ลบ `.import` กำพร้า 39 ไฟล์ (`mg1_*` – `mg5_*`)                                        | `Assets/MiniGame/Part*/`                 |
| 2.2    | ซีน find-item ชี้ `PartRam/ram_eraser.png` แล้ว (ตัด `uid` เก่าออกให้ Godot เขียนใหม่) | `Scene/MiniGame/find_item_minigame.tscn` |
| 2.3    | เพิ่ม `Global.in_minigame = false` ตอนออกจากมินิเกมขัดแรม                              | `Scripts/MiniGame/minigame1.gd`          |
| B2a    | เพิ่ม `TutorialSlides.reset()` + กัน `_slides` ว่าง + ลบ `print_rich`                  | `Scripts/Resources/tutorial_slides.gd`   |
| B2b    | `show_tutorial()` guard state ที่ยังไม่มีสไลด์ (เดิม crash) + เรียก `reset()`          | `Scripts/EventManager/tutorial.gd`       |
| B4a    | `match clikTime` → `if/elif >=`                                                        | `Scripts/MiniGame/minigame1.gd`          |
| B4b    | เปลี่ยนไปใช้ texture ชุด `PartRam/ram_dirty                                            | better                                   |
| 7.1(1) | แก้ชื่อตัวละคร `ชม,` → `ขม,`                                                           | `Assets/Dialog/MainQuest/GoToRoom.txt`   |
| 7.1(2) | แก้ข้อความ find-item (สะกดถูก + ใช้ครบทุกบรรทัด + ขึ้นข้อความเปิดเรื่องตั้งแต่เข้าฉาก) | `Scripts/MiniGame/find_item_minigame.gd` |
| 7.1(3) | quest บน QuestBoard เป็นภาษาไทย                                                        | `Resources/main.tres`                    |

**⚠️ เหลือ 2 ขั้นที่ต้องทำใน Godot เอง (สั่งจากนอกโปรแกรมไม่ได้)**

1. **เปิด Godot หนึ่งรอบ** เพื่อ import รูป 39 ไฟล์ในโฟลเดอร์ `Part*` (ตอนนี้ยังไม่มี `.import`)
   → เปิดแล้วเซฟ `find_item_minigame.tscn` ซ้ำหนึ่งครั้ง เพื่อให้ Godot เขียน `uid` ใหม่ลงซีน
   → แล้ว `git add Assets/MiniGame/Part*/*.import`
   **ก่อนทำขั้นนี้ มินิเกมขัดแรมจะยังไม่มีรูปแรม** เพราะ `minigame1.gd` ชี้ไปที่ไฟล์ชุดใหม่แล้ว
2. **B3** — Save As `Scene/MiniGame/Minigame1.scn` → `Scene/MiniGame/PartRam.tscn` แล้วแก้
   `Constant.MINIGAME1_SCENE = "res://Scene/MiniGame/PartRam.tscn"` *(ยังไม่ได้แก้ให้ เพราะต้องมีไฟล์ `.tscn` จริงก่อน ไม่งั้นเกมพัง)*

**✅ ทำแล้วเพิ่มใน commit `7c291e5` (23 ก.ย. 2569):** ข้อ 4.1 `QuestStep` resource (มี `isDone`/`set_done()`/`reset()`) · ข้อ 4.2 `minigame_end()` เปลี่ยนเป็น data-driven เต็มรูปแบบ (อ่านจาก `data.isDone`/`data.action` ของ task ปัจจุบัน แทน hardcode เลข task — ไม่ได้ใช้ signature `(success, score)` ตามที่เสนอไว้เดิม แต่แก้ปัญหาความเปราะเดียวกัน) · `main.tres` ครบ 5 task แล้ว (ดู `Docs/BUG_LIST.md` BUG-28 ถึง BUG-31)

**ยังไม่ทำ (เป็นข้อเสนอ ไม่ใช่บั๊ก):** ข้อ 4.3 สุ่มกล่องเป้าหมายใน find-item · ย้าย `box*.png` เข้า `PartRam/` — **อัปเดต:** `Assets/MiniGame/PartRam/ram_box_normal.png` / `ram_box_hover.png` มีไฟล์และ `.import` แล้ว (commit `7c291e5`) แต่ `Scene/MiniGame/find_item_minigame.tscn` ยังอ้าง `Assets/MiniGame/box.png` / `box_on_hover.png` ตัวเก่าอยู่ — ต้องเปิดซีนแล้วสลับ texture ไปใช้ไฟล์ใหม่ให้จบงานนี้

---

## 1. สิ่งที่เปลี่ยนใน repo ตั้งแต่ commit `4a89e7e`

| commit    | เนื้อหา                                                                                      |
| --------- | -------------------------------------------------------------------------------------------- |
| `6d37f54` | key event tracking by EventID — `sendUpdatedEvent` เปลี่ยน signature เป็น `(EventID, Event)` |
| `1e81773` | change function                                                                              |
| `b49267d` | **เพิ่มมินิเกมใหม่: find-item** (หายางลบในกล่อง) + `search_box.gd`                           |
| `e5d5203` | **รวม trigger ของทุก quest step ไว้ที่ `EventManager.trigger_step()`** + จบ flow หายางลบ     |
| `46a5a7b` | remove unused code — `Global.MiniGames` / `ReturnMiniGame()` ถูกลบ                           |
| `1c9040a` | Update game — commit asset ชุด Part เข้ามา                                                   |

**โครงใหม่ที่เกิดขึ้น (ดีมาก เก็บไว้):**

```
CautionMarker._on_pressed()
      └─ emit caution_press(id, event)
            └─ EventManager.trigger_step(id, event)   ← ตารางปฏิกิริยาต่อ step รวมศูนย์
                  ├─ step 0: คุยกับยาย
                  ├─ step 1: เข้าห้อง → dialog → (on_dialog_finish) → find-item minigame
                  └─ step 3: tutorial ขัดแรม → Minigame1
                        └─ minigame → EventManager.minigame_end() → update_event()
```

`main.tres` ตอนนี้มี 4 task: `Talk to Grandma` → `Go to your Room and Inspect the Computer` → `Find the Eraser inside Box` → `Clean a Ram`

---

## 2. 🔴 ต้องแก้ทันที

### 2.1 ไฟล์ `.import` ไม่ตรงกับชื่อรูป — 39 คู่

ผลข้างเคียงจากการ rename `Tier* → Part*` รอบที่แล้ว: commit `1c9040a` มี **รูปชื่อใหม่** กับ **`.import` ชื่อเก่า** อยู่ด้วยกัน

```
Assets/MiniGame/PartRam/
├── ram_eraser.png            ← รูปชื่อใหม่ (ยังไม่มี .import)
├── mg1_eraser.png.import     ← .import กำพร้า ชี้ไปยังรูปที่ไม่มีแล้ว
```

ครบทุกโฟลเดอร์: PartRam 4 · PartMainboard 10 · PartGpu 10 · PartFrontPanel 9 · PartBios 6 = **39 คู่**

**ทำไมอันตราย:** Godot ยังหา texture เจอชั่วคราวเพราะ cache ใน `.godot/imported/` แต่พอใครลบ `.godot/` หรือ clone ใหม่ **uid จะตายทั้งหมด** → ซีนที่อ้าง uid เหล่านี้จะขึ้น texture ว่าง

**วิธีแก้ (ทำตามลำดับ):**

```bash
# 1. ลบ .import กำพร้าทั้งหมด (ชื่อขึ้นต้นด้วย mg1_ ถึง mg5_)
git rm Assets/MiniGame/Part*/mg[1-5]_*.import

# 2. เปิด Godot ให้ import รูปชื่อใหม่ (จะสร้าง .import + uid ใหม่)

# 3. commit .import ชุดใหม่
git add Assets/MiniGame/Part*/*.import
```

> ⚠️ ทำ **ข้อ 2.2 พร้อมกัน** เพราะ uid ใหม่จะทำให้ซีนที่อ้าง uid เก่าพัง

### 2.2 `find_item_minigame.tscn` ชี้พาธเก่าที่ไม่มีแล้ว

`Scene/MiniGame/find_item_minigame.tscn` บรรทัด 8:

```gdscript
[ext_resource type="Texture2D" uid="uid://b7hvifd3sv78t"
  path="res://Assets/MiniGame/Tier1Ram/mg1_eraser.png" id="6_kt573"]
```

โฟลเดอร์ `Tier1Ram/` และไฟล์ `mg1_eraser.png` **ไม่มีอยู่แล้ว** — ตอนนี้คือ `Assets/MiniGame/PartRam/ram_eraser.png`

**วิธีแก้ (เลือกทางใดทางหนึ่ง):**

* **ทางที่แนะนำ** — เปิด `find_item_minigame.tscn` ใน Godot หลังทำข้อ 2.1 เสร็จ แล้วลาก `ram_eraser.png` ไปใส่ node `Eraser` ใหม่ → Godot เขียน uid ใหม่ให้เอง
* หรือแก้ข้อความในไฟล์ `.tscn` ตรง ๆ ให้ path เป็น `res://Assets/MiniGame/PartRam/ram_eraser.png` แล้ว **ลบ attribute `uid="..."` ออก** ให้ Godot resolve จาก path แทน

> เป็นซีนเดียวในโปรเจกต์ที่ยังอ้างพาธเก่า (ตรวจด้วย `grep -rn "Tier[0-9]\|mg[1-5]_" Scene Scripts Resources` แล้ว)

### 2.3 `Global.in_minigame` ค้างเป็น `true` หลังจบมินิเกมขัดแรม

`Scripts/MiniGame/minigame1.gd` — `_on_return_pressed()` ไม่ได้รีเซ็ต flag ที่ `trigger_step()` ตั้งไว้

```gdscript
# ตอนนี้
func _on_return_pressed() -> void:
    EventManager.next_period.emit()
    EventManager.showUI()
    EventManager.minigame_end()
    queue_free()

# ควรเป็น
func _on_return_pressed() -> void:
    Global.in_minigame = false          # ← เพิ่มบรรทัดนี้
    EventManager.next_period.emit()
    EventManager.showUI()
    EventManager.minigame_end()
    queue_free()
```

เทียบกับ `find_item_minigame.gd::_timeout()` ที่ทำถูกแล้ว (`Global.in_minigame = false` ก่อน `queue_free()`)

> **ทางที่ยั่งยืนกว่า:** ย้ายการตั้ง/เคลียร์ flag ไปไว้ที่ `EventManager` ที่เดียว — ตั้ง `true` ตอน `add_child(minigame)` และเคลียร์ใน `minigame_end()` มินิเกมจะได้ไม่ต้องจำเอง

---

## 3. 🟡 บั๊กเดิมที่ยังไม่ถูกแก้

### B2 · `TutorialSlides.curIndex` ไม่รีเซ็ต + `print_rich` ค้าง

`Scripts/Resources/tutorial_slides.gd` — `TutorialSlides` เป็น Resource ที่แชร์กัน เปิด tutorial เดิมซ้ำจะเริ่มที่สไลด์สุดท้าย ปุ่มขึ้น Close ทันที

```gdscript
# tutorial_slides.gd — เพิ่ม
func reset() -> void:
    curIndex = 0

func get_cur_slide() -> Texture2D:
    return _slides[curIndex]        # ← ลบ print_rich(_slides) ออก
```

```gdscript
# tutorial.gd — เรียก reset ตอนเปิด
func show_tutorial(tutor_index: TutorialState) -> void:
    self.visible = true
    self._finished = false
    self.process_mode = Node.PROCESS_MODE_INHERIT
    if not _slides.has(tutor_index):        # ← กัน crash ถ้า state ยังไม่มีสไลด์
        push_warning("ยังไม่มีสไลด์ของ state %d" % tutor_index)
        self.visible = false
        on_tutorial_end.emit()
        return
    cur_slide = _slides[tutor_index]
    cur_slide.reset()                       # ← เพิ่ม
    slide_show.texture = cur_slide.get_cur_slide()
```

> guard `_slides.has()` สำคัญมาก เพราะตอนนี้มีสไลด์แค่ state 0 กับ 2 จาก 7 — เรียก state อื่น = crash

### B3 · `Scene/MiniGame/Minigame1.scn` ยังเป็นไฟล์ binary

`Constant.MINIGAME1_SCENE` ชี้ไปที่ `.scn` ซึ่ง diff/merge ไม่ได้ → เปิดใน Godot แล้ว **Save As** เป็น `Scene/MiniGame/PartRam.tscn` แล้วแก้ค่าคงที่:

```gdscript
const MINIGAME1_SCENE = "res://Scene/MiniGame/PartRam.tscn"
```

### B4 · `match clikTime` เทียบค่าเป๊ะ

`minigame1.gd::_physics_process()` เปลี่ยน texture เฉพาะตอนค่าเท่ากับ 0/10/15 พอดี ถ้าโค้ดอนาคตเพิ่มทีละ 2 ภาพจะไม่เปลี่ยนเลย

```gdscript
# ควรเป็น
if clikTime >= RamStatus.CLEAN:
    ram.texture = RamIMG[2]
elif clikTime >= RamStatus.BETTER:
    ram.texture = RamIMG[1]
else:
    ram.texture = RamIMG[0]
```

และตรง `_on_button_pressed()` ก็ควรเป็น `if clikTime >= RamStatus.CLEAN and not isFinish:`

> เพิ่มเติม: `minigame1.gd` ยังโหลด texture จาก `Assets/MiniGame/ramDirty.png` ชุดเก่า (ขนาด 597/593/589 ไม่เท่ากัน) — ควรเปลี่ยนไปใช้ `Assets/MiniGame/PartRam/ram_dirty|better|clean.png` (600×214 เท่ากันทุกใบ) หลังทำข้อ 2.1 เสร็จ

---

## 4. 🟢 ข้อเสนอปรับโครง (ไม่ด่วน แต่ตอนนี้คือจังหวะที่ถูก)

### 4.1 `trigger_step()` แบบ hardcode → data-driven

ตอนนี้:

```gdscript
match event.currentTask:
    0: ...คุยกับยาย
    1: ...เข้าห้อง
    3: ...ขัดแรม
```

โครงนี้ใช้ได้ดีกับ quest เส้นเดียว แต่พอทำลูปงานซ่อมที่มีลูกค้าหลายเคส (`Docs/REPAIR_FLOW.md`) จะกลายเป็น `match` ยาวเป็นร้อยบรรทัด **ข้อเสนอ:** ย้ายปฏิกิริยาของแต่ละ step ไปเป็น Resource

```gdscript
# Scripts/Resources/quest_step.gd
class_name QuestStep extends Resource

enum Action { DIALOG, MINIGAME, TUTORIAL, SCENE_CHANGE }

@export var action: Action
@export var title: String                # ชื่อที่โชว์บน DialogScene
@export var dialog_file: String
@export var bg_name: String
@export var chars: Array[String] = []
@export var scene_path: String           # มินิเกม/ซีนที่จะโหลด
@export var tutorial_state: int = -1
@export_multiline var quest_text_th: String   # ข้อความบน QuestBoard
```

แล้ว `Event.Tasks` เปลี่ยนจาก `Array[String]` เป็น `Array[QuestStep]` — `trigger_step()` เหลือ ~15 บรรทัดที่อ่าน resource แล้วทำตาม `action` เดียว

### 4.2 `minigame_end()` อิงเลข task — เปราะ

```gdscript
func minigame_end() -> void:
    if currentEvent == EventID.MAIN:
        var task = eventMap[currentEvent].currentTask
        if [2, 3].has(task):     # ← hardcode
            update_event(currentEvent)
```

ถ้าแทรก task ใหม่ตรงกลางเมื่อไร ตัวเลขนี้พังทันที **ข้อเสนอ:** ให้มินิเกมส่งผลลัพธ์กลับมาแทน

```gdscript
func minigame_end(success: bool = true, score: Dictionary = {}) -> void:
    Global.in_minigame = false
    if success:
        update_event(currentEvent)
```

### 4.3 find-item minigame ยังไม่ใช่ "การค้นหา" จริง

ตอนนี้กดกล่องไหนก็ได้ 3 ครั้งแล้วเจอยางลบเสมอ (`search_box.gd` แค่ disable ตัวเอง) ผู้เล่นไม่ได้ตัดสินใจอะไร

**ข้อเสนอเล็ก ๆ ที่ทำได้ทันที:** สุ่มกล่องเป้าหมายตอน `_ready()` แล้วให้ข้อความต่างกันตามระยะ (ใกล้/ไกล) — ยังใช้ asset ชุดเดิม ไม่ต้องเพิ่มงานศิลป์

```gdscript
var target_box: int = randi() % 3
# กดถูกกล่อง → "เจอแล้ว!" · กดผิด → สุ่มข้อความจาก dialog_arr
```

### 4.4 ข้อความ QuestBoard เป็นภาษาอังกฤษปนเกมภาษาไทย

`main.tres` → `["Talk to Grandma", "Go to your Room and Inspect the Computer", "Find the Eraser inside Box", "Clean a Ram"]`
ทั้งเกมเป็นภาษาไทยหมด ควรเปลี่ยน (ข้อความที่เสนออยู่ในหัวข้อ 7.1)

---

## 5. 📄 เอกสารดีไซน์ที่ล้าสมัย — แก้ให้แล้วในรอบนี้

| ไฟล์                                     | สิ่งที่ล้าสมัย                                    | แก้เป็น                                                                     |
| ---------------------------------------- | ------------------------------------------------- | --------------------------------------------------------------------------- |
| `MINIGAME1_DESIGN.md`                    | บั๊ก B1 (room.gd)                                 | ทำเครื่องหมายว่า **แก้แล้ว** — room.gd ถูกลบ                                |
| `MINIGAME1_DESIGN.md`                    | ตัวอย่างโค้ด `Global.ReturnMiniGame("MiniGame1")` | เปลี่ยนเป็น `load(Constant.MINIGAME1_SCENE).instantiate()`                  |
| `MINIGAME1_DESIGN.md` · `REPAIR_FLOW.md` | `Global.MiniGames` dict                           | ถูกลบจากโค้ดแล้ว — ใช้ค่าคงที่ใน `constant.gd` แทน                          |
| `REPAIR_FLOW.md`                         | `sendUpdatedEvent(Event)`                         | signature ใหม่คือ `sendUpdatedEvent(EventID, Event)`                        |
| `REPAIR_FLOW.md`                         | ไม่รู้จัก `trigger_step` / `minigame_end`         | เพิ่มหมายเหตุว่า `RepairManager` ควรต่อยอดจากโครงนี้ ไม่ใช่เขียนใหม่ทั้งหมด |
| `ASSET_GUIDE.md`                         | ไม่มี asset ของ find-item minigame                | เพิ่มหัวข้อ 3.9                                                             |

---

## 6. 🎨 Asset — สิ่งที่เพิ่มเข้า `ASSET_GUIDE.md` แล้ว (หัวข้อ 3.9)

**ของใหม่ที่เข้ามาใน repo แต่ยังไม่อยู่ในคู่มือ:**

| ไฟล์                               | ขนาด    | ใช้ที่ไหน                       |
| ---------------------------------- | ------- | ------------------------------- |
| `Assets/MiniGame/box.png`          | 256×256 | กล่องค้นหาใน find-item minigame |
| `Assets/MiniGame/box_on_hover.png` | 256×256 | state hover (ขนาดเท่ากัน ✅)     |

**ข้อสังเกต / สิ่งที่ควรทำกับ asset:**

1. `box*.png` วางไว้ที่ราก `Assets/MiniGame/` — ควรย้ายเข้า `Assets/MiniGame/PartRam/` และตั้งชื่อ `ram_box_normal.png` / `ram_box_hover.png` ให้เข้าชุด **ทำพร้อมรอบ reimport ข้อ 2.1 ทีเดียวเลย** จะได้ไม่ต้องแก้ uid สองรอบ
2. ยังมี asset ชุดเก่าซ้ำกับชุดใหม่ที่ควรลบหลังเปลี่ยนโค้ดไปใช้ชุดใหม่แล้ว — `Assets/MiniGame/ram.png`, `ramDirty.png`, `ramSligtDirty.png`, `eraser.png`
3. find-item minigame ใช้ `RoomBG.jpg` (1920×1080) เป็นพื้นหลัง — ควรย่อเป็น 1152×648 ตามกฎในคู่มือ
4. asset ที่ยังขาดเหมือนเดิม: **tutorial slides 7 state · เครื่องมือ 21 ชิ้น · Normal Part 8 ชิ้น · Scene S1/S2/S4/S5 · Audio ทั้งหมด**

---

## 7. ✍️ Text — สิ่งที่ต้องแก้และไฟล์บทที่ต้องเพิ่ม

### 7.1 แก้ของเดิม 3 จุด

**(1) `Assets/Dialog/MainQuest/GoToRoom.txt` บรรทัด 4 — ชื่อตัวละครสะกดผิด**

```diff
- ชม, ว่าแต่ "ยางลบอยู่ตรงไหนนะ"
+ ขม, ว่าแต่ "ยางลบอยู่ตรงไหนนะ"
```

ตอนนี้ยังไม่ crash เพราะ step 1 เรียก `show_dialog()` โดยไม่ส่ง `chars` — แต่ NameBox จะขึ้นว่า "ชม" และถ้าวันหลังใส่ `chars` เมื่อไร `_CharacterMap["ชม"]` จะ **crash ทันที**

**(2) `Scripts/MiniGame/find_item_minigame.gd` — ข้อความสะกดผิดและมีบรรทัดที่ไม่ถูกใช้**

```gdscript
var dialog_arr = ["หาไม่เจอ", "อยู่ใหนนะ?", "หรือว่าอยู่ในกล่องนั้น"]
```

* `"อยู่ใหนนะ?"` → `"อยู่ไหนนะ?"`
* `text.text = dialog_arr[-box_click_count]` ทำให้ index 0 (`"หาไม่เจอ"`) **ไม่เคยถูกแสดงเลย** — ถ้าตั้งใจให้แสดงต้องเริ่ม `box_click_count = 3` หรือเปลี่ยนวิธี index
* ข้อความควรย้ายออกจากสคริปต์ไปเป็นไฟล์ `.txt` ตามระบบเดิม จะได้แก้บทโดยไม่ต้องแตะโค้ด

**(3) `Resources/main.tres` — ข้อความ quest เป็นภาษาอังกฤษ**

```gdscript
Tasks = Array[String]([
    "คุยกับยาย",
    "กลับไปที่ห้องแล้วลองเปิดคอมเครื่องเก่า",
    "หายางลบในกล่องเก็บของ",
    "ขัดทำความสะอาดแรม",
])
```

### 7.2 ไฟล์บทใหม่ที่ต้องเพิ่ม (ตามดีไซน์ Part / ลูปงานซ่อม)

| ไฟล์                                               | เนื้อหา                                                       | อ้างอิงบทที่เขียนไว้แล้ว                        |
| -------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------- |
| `Assets/Dialog/MiniGame/Ram_Pib.txt`               | บทปิ๊บทุก phase ของมินิเกมขัดแรม                              | `MINIGAME1_DESIGN.md` หัวข้อ 4.3, 5, 6, 7, 14.6 |
| `Assets/Dialog/MiniGame/FindEraser.txt`            | บทตอนหายางลบ (ย้ายออกจาก `dialog_arr`)                        | ใหม่                                            |
| `Assets/Dialog/Case/Case_C01.txt`                  | เคสลูกค้า C01 แรมสกปรก                                        | `REPAIR_FLOW.md` หัวข้อ 3.5                     |
| `Assets/Dialog/Case/Case_C02.txt` … `Case_C06.txt` | อีก 5 เคส                                                     | `REPAIR_FLOW.md` หัวข้อ 3.5                     |
| `Assets/Dialog/Common/Pib_Safety.txt`              | บทเตือนความปลอดภัยที่ใช้ซ้ำทุก Part (ตัดไฟ/ESD/เครื่องมือผิด) | `REPAIR_FLOW.md` หัวข้อ 4.3                     |

> **สำคัญ:** export preset กรองด้วย `include_filter="*.txt"` — ไฟล์บทต้องเป็น `.txt` และอยู่ใต้ `Assets/` เท่านั้น ไม่งั้นหายตอน export

### 7.3 ตัวอย่างไฟล์พร้อมใช้ — `Assets/Dialog/MiniGame/FindEraser.txt`

```
# ข้อความตอนหายางลบ — ใช้แทน dialog_arr ใน find_item_minigame.gd
# บรรทัดขึ้นต้นด้วย # คือคอมเมนต์ parser ข้ามให้

ขม, ยางลบอยู่ไหนนะ ลองหาในกล่องดูก่อน
ขม, ไม่มีในกล่องนี้แฮะ
ขม, หรือว่าอยู่ในกล่องนั้น
ขม, เจอแล้ว! ยางลบสีขาวพอดีเลย
```

### 7.4 กติกาของ parser ที่ต้องระวังตอนเขียนบท

จาก `dialog_scene.gd::parse_text()` และ `read_file()`

| กฎ                                                                           | เหตุผล                                    |
| ---------------------------------------------------------------------------- | ----------------------------------------- |
| ทุกบรรทัดต้องมี `,` คั่นชื่อกับข้อความ                                       | ไม่มี `,` → `parse_text()` guard แล้ว (`push_error` + คืน `null`), ไม่ crash แต่บรรทัดนั้นหาย |
| **ห้ามใช้ `:` ในบรรทัดบทปกติ**                                               | parser มองว่าเป็น header ของ choice block |
| ชื่อก่อน `,` ต้องตรงกับ key ใน `_CharacterMap` เป๊ะ                          | ไม่ตรง → crash ตอนสร้าง sprite            |
| บรรทัดว่าง = จบ block                                                        | ใช้คั่นระหว่าง choice branch              |
| choice เขียนว่า `Choice: ตัวเลือก1,ตัวเลือก2` แล้วตามด้วย block `ตัวเลือก1:` | ดูตัวอย่างใน `Chapter5Quiet.txt`          |
| ชื่อแบบ `ขม (ยิ้ม)` จะถูกมองเป็นคนละตัวละคร                                  | ต้องแก้ parser ก่อนถึงจะใช้ได้            |

---

## 8. ลำดับที่แนะนำให้ทำ

- [ ] **1** ลบ `.import` กำพร้า 39 ไฟล์ → เปิด Godot ให้ import ใหม่ → commit `.import` (ข้อ 2.1)
- [ ] **2** แก้ `find_item_minigame.tscn` ให้ชี้ `PartRam/ram_eraser.png` (ข้อ 2.2) + ย้าย `box*.png` เข้า `PartRam/` ในรอบเดียวกัน
- [ ] **3** เพิ่ม `Global.in_minigame = false` ใน `minigame1.gd` (ข้อ 2.3)
- [ ] **4** แก้ B2 — `TutorialSlides.reset()` + guard `_slides.has()` + ลบ `print_rich` (ข้อ 3)
- [ ] **5** แก้ข้อความ 3 จุดในหัวข้อ 7.1 (ชื่อ "ชม", quest ภาษาไทย, ข้อความ find-item)
- [ ] **6** Save As `Minigame1.scn` → `PartRam.tscn` + แก้ `Constant.MINIGAME1_SCENE` (B3)
- [ ] **7** แก้ `match clikTime` เป็น `>=` + เปลี่ยนไปใช้ texture ชุด `PartRam/` (B4)
- [ ] **8** เริ่มงานใหญ่: `QuestStep` resource (ข้อ 4.1) → แล้วค่อยต่อ `RepairManager` ตาม `REPAIR_FLOW.md`

---

## 10. 🐛 บั๊กฉาก Room — "กดเข้าห้องแล้วเหลือแต่ห้องเปล่า" (แก้แล้ว)

### อาการ

เดินเข้าห้องของขมแล้วไม่มีปุ่ม `!` (caution) ขึ้นมาเลย เหลือแต่พื้นหลังห้องกับประตู ทำอะไรต่อไม่ได้

### สาเหตุ — key type ของ `trackEvents` ใน `Room.tscn` ไม่ตรงกับที่สคริปต์ประกาศ

`Scripts/caution_marker.gd` ประกาศไว้ว่า

```gdscript
@export var trackEvents: Dictionary[EventManager.EventID, PackedByteArray]
```

แต่ใน `Scene/Location/Room.tscn` ค่าที่เซฟไว้เป็น **`Dictionary[Variant, ...]`**

```gdscript
# ก่อนแก้ — key เป็น Variant
trackEvents = Dictionary[Variant, PackedByteArray]({ 1: PackedByteArray(1, 3) })

# หลังแก้ — key เป็น int ตรงกับ enum EventID
trackEvents = Dictionary[int, PackedByteArray]({ 1: PackedByteArray(1, 3) })
```

Godot 4 เข้มเรื่อง typed dictionary — พอ key type ไม่ตรง ค่าจะ **ไม่ถูก assign** property เลยว่างเปล่า
ผลคือ `checkTrackEvent()` ได้ `trackEvents.has(id) == false` ตลอด → `visible = false` ตลอด → ปุ่ม `!` ไม่เคยโผล่

**หลักฐานว่าเป็นไฟล์นี้ไฟล์เดียว:** `Home.tscn` (marker 2 ตัว), `event_manager.tscn`, `Tutorial.tscn` เซฟเป็น `Dictionary[int, ...]` ถูกหมด มีแต่ `Room.tscn` ที่เป็น `Variant` — น่าจะหลุดมาตอน refactor commit `6d37f54`

> ⚠️ เวลาแก้ dictionary แบบนี้ใน Godot Inspector ให้เช็กบรรทัดในไฟล์ `.tscn` ทุกครั้งว่าเป็น `Dictionary[int, ...]`
> ถ้าเผลอเซฟเป็น `Variant` อีก ปุ่มจะหายเงียบ ๆ โดยไม่มี error ให้เห็นชัด

### แก้เพิ่มอีก 3 จุดที่เกี่ยวข้อง

| ไฟล์                        | แก้อะไร                                                  | เหตุผล                                                                               |
| --------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `Scripts/caution_marker.gd` | guard `eventMap.has(cur_id)` ใน `_on_pressed()`          | `cur_id` เริ่มที่ `NONE` ถ้า marker ถูกกดก่อนผูก event จะ crash ที่ `eventMap[NONE]` |
| `Scripts/Home/door.gd`      | ไม่เปลี่ยนฉากถ้า `isDialogShown()` หรือ `isInMinigame()` | กดประตูระหว่างบทสนทนา/มินิเกม → ฉากเดิมถูกปล่อยทิ้ง เหลือมินิเกมลอยอยู่บน root       |
| `Scripts/Room/door.gd`      | เงื่อนไขเดียวกัน                                         | เหมือนกัน                                                                            |

### ยังเหลือเป็นข้อสังเกต (ยังไม่แก้)

1. **ไม่มี Player ในเกมเลย** — `project.godot` ตั้ง main scene เป็น `Start_Scene.tscn` และ flow คือ Start → tutorial → `change_scene_to_file(Home.tscn)` ส่วน `MainGame.tscn` (ที่มี `Player` + `SimpleNpc`) **ไม่เคยถูกโหลด** ทั้งที่ `CLAUDE.md` ระบุว่าเป็น main scene → ต้องตัดสินใจว่าจะเอาการเดินกลับมามั้ย หรือเล่นแบบ point-and-click ทั้งเกม
2. **tutorial กับมินิเกมขึ้นพร้อมกัน** — `trigger_step` case 3 เรียก `show_tutorial()` แล้ว `add_child(minigame)` ในเฟรมเดียวกัน · tutorial เป็น CanvasLayer 120 อยู่บน แต่ `minigame1.gd::_input()` รับคลิกทุกคลิก → กด Next บน tutorial ก็ไปสตาร์ตมินิเกมข้างล่างด้วย ควรรอ `on_tutorial_end` ก่อนค่อย add มินิเกม
3. **มินิเกมถูก `add_child` ที่ `get_tree().root`** ไม่ใช่ใต้ฉากปัจจุบัน → ไม่บล็อกอินพุตของฉากข้างล่าง และไม่ถูกลบตอนเปลี่ยนฉาก (ข้อ 3 ในตารางด้านบนช่วยกันได้ระดับหนึ่ง)

---

## 9. ประวัติเอกสาร

| วันที่           | การเปลี่ยนแปลง                                                                                                                                                                                         |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 23 ก.ย. 2569 (2) | working-tree (ยังไม่ commit): ปิด BUG-18 — `parse_text()` guard บรรทัดไม่มี `,` แล้ว (ดูหัวข้อ 7.4) · ปิด BUG-24 — `QuesetBoard` → `QuestBoard` ทั้ง `quest_board.gd`/`event_manager.gd` · พบแล้วแก้กลับ: `Scene/Location/Room.tscn` เคยมี diff เผลอเปลี่ยน `trackEvents` จาก `Dictionary[int, …]` เป็น `Dictionary[Variant, …]` (น่าจะ Godot Editor เซฟทับตอนเปิดซีน) ซึ่งจะรีโอเพน BUG-01 — revert กลับเป็น `Dictionary[int, …]` แล้ว ไฟล์ตรงกับ HEAD เป๊ะ ไม่มี diff ค้าง |
| 23 ก.ย. 2569     | commit `7c291e5` ปิดงานค้างข้อ 4.1/4.2 (หัวข้อ 0.1) — `QuestStep.isDone` + `EmitType` ทำให้ quest รอ action ของตัวเองจบจริงก่อนเดินต่อ, `Event.reset()` ถูกเรียกใน `EventManager._ready()`, `main.tres` ครบ 5 task, และแก้ `DialogScene.show_dialog()` ที่เคย prefix `BackgroundDir` ซ้ำกับ `bg_name` ที่เป็น uid/absolute path อยู่แล้ว — ดูรายละเอียดที่ `Docs/BUG_LIST.md` (BUG-28 ถึง BUG-31, BUG-20, BUG-26) |
| 21 ก.ย. 2569 (3) | หาและแก้บั๊กฉาก Room — `trackEvents` เซฟเป็น `Dictionary[Variant,…]` ทำให้ปุ่ม `!` ไม่ขึ้น + guard อีก 3 จุด (หัวข้อ 10)                                                                               |
| 21 ก.ย. 2569 (2) | ลงมือแก้ 🔴 + 🟡 + ข้อความ รวม 9 รายการ เหลือ 2 ขั้นที่ต้องทำใน Godot (import รอบใหม่ + แปลง `.scn` → `.tscn`)                                                                                         |
| 21 ก.ย. 2569     | สร้างเอกสาร — เทียบ commit `1c9040a` กับดีไซน์ พบปัญหา `.import` ไม่ตรงชื่อ 39 คู่, ซีน find-item ชี้พาธเก่า, `in_minigame` ค้าง, บั๊กเดิม B2–B4 ยังอยู่ (B1 หายแล้ว) และสรุปงาน text ที่ต้องแก้/เพิ่ม |
