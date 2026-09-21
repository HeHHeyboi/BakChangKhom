# ASSET_TODO.md — เช็กลิสต์ asset ที่ต้องทำ (เรียงตามลำดับที่ควรทำ)

> อัปเดต 21 ก.ย. 2569 · สเปกเต็มอยู่ใน `Docs/ASSET_GUIDE.md` · เอกสารนี้คือ **รายการสั่งงาน** เอาไว้ไล่ทำทีละชุด
> ✅ = มีในรีโปแล้ว · ⬜ = ต้องทำใหม่

## กฎ 5 ข้อ (ย้ำก่อนเริ่ม)

1. **จอเกม 1152 × 648** — ภาพเต็มจอต้องเป๊ะขนาดนี้
2. พื้นโปร่ง → **PNG 32-bit** · เต็มจอ → **JPG** คุณภาพ 85
3. ชื่อไฟล์ **ASCII snake_case ห้ามเว้นวรรค ห้ามภาษาไทย**
4. **ทุก state ของชิ้นเดียวกันต้องขนาด canvas เท่ากันเป๊ะ** (normal/hover/press)
5. **ห้ามฝังตัวอักษรไทยในภาพ** — เว้นที่ว่างไว้ แล้วพิมพ์ทับด้วย Label ในเกม

**Base prompt (ต่อท้ายทุกอัน):**
```
2D hand-drawn game art, thick dark brown outlines, flat colors,
warm earthy color palette, bright and cheerful,
Don't Starve inspired but colorful, Gravity Falls art style,
clean cartoon style, no gradients, cel-shaded, simple two-tone shadows
```
**Negative prompt:**
```
photorealistic, 3D render, anime, gradient shading, text, watermark,
signature, ui frame, border, drop shadow blur, blurry, deformed hands
```
**พาเลตต์:** `#E8A854` ส้มอบอุ่น · `#6BAF52` เขียว · `#4A90D9` ฟ้า · `#2C1810` เส้นขอบ · `#F5E6C8` / `#D4956A` พื้นหลัง
**สถานะ:** สำเร็จ `#6BAF52` · เตือน `#E8A854` · ผิดพลาด `#C0453B` · disabled `#9A8F82`

---

# ชุด A · Tutorial slides — **ทำก่อนอันดับแรก** (7 ไฟล์)

ของเดิมมี 2 สไลด์แต่ **ผิดขนาด ชื่อไฟล์ภาษาไทย และไฟล์ใหญ่ 2 MB** ต้องทำใหม่ทับ
ทุกไฟล์ **1152 × 648 PNG ≤ 500 KB** · เว้นแถบว่างด้านบน ~120 px ไว้ใส่ข้อความไทย

### `Assets/Tutorial/BasicStart/` — แทนไฟล์ `Tutorial สอนเล่น.png` เดิม

| ⬜ | ไฟล์ | เนื้อหาในภาพ |
|---|---|---|
| ⬜ | `tut_start_01.png` | มือกำลังคลิกจุดสีเหลืองบนหน้าจอเกม สื่อว่า "คลิกเพื่อโต้ตอบ" |
| ⬜ | `tut_start_02.png` | ปุ่ม `!` สีเหลืองลอยอยู่เหนือของในฉาก + ลูกศรชี้ สื่อว่า "ตรงไหนมี ! ให้ไปกด" |
| ⬜ | `tut_start_03.png` | มุมขวาบนมีกระดานเควสต์กับแถบเวลา เช้า/เที่ยง/เย็น |

### `Assets/Tutorial/RamCleaning/` — แทนไฟล์ `Tutorial ขัดแรม.png` เดิม

| ⬜ | ไฟล์ | เนื้อหาในภาพ |
|---|---|---|
| ⬜ | `tut_ram_01.png` | แรมสกปรก ขาทองหมอง มีลูกศรชี้ที่ขาทองด้านล่าง |
| ⬜ | `tut_ram_02.png` | มือจับยางลบสีขาวถูไปตามแนวขาทอง (ลูกศรบอกทิศซ้าย–ขวา) |
| ⬜ | `tut_ram_03.png` | เปรียบเทียบก่อน/หลัง แรมสกปรก vs แรมสะอาด |
| ⬜ | `tut_ram_04.png` | เครื่องหมายถูกสีเขียว + แรมสะอาดเสียบกลับเข้าสลอต |

---

# ชุด B · เครื่องมือทำความสะอาด 10 ชิ้น (Phase 4 ระบบเลือกอุปกรณ์)

`Assets/MiniGame/PartRam/` · ทุกชิ้น **200 × 200 PNG พื้นโปร่ง** · วางกลางภาพ มุมมองด้านข้าง

| ⬜ | ไฟล์ | subject prompt |
|---|---|---|
| ✅ | `ram_eraser.png` | *(มีแล้ว — ยางลบสีขาว)* |
| ⬜ | `ram_tool_brush.png` | soft anti-static cleaning brush with wooden handle, side view |
| ⬜ | `ram_tool_blower.png` | rubber air blower bulb for electronics, nozzle pointing left |
| ⬜ | `ram_tool_cloth.png` | folded blue microfiber cloth |
| ⬜ | `ram_tool_ipa_swab.png` | small bottle labeled with a droplet icon + cotton swab beside it |
| ⬜ | `ram_tool_eraser_red.png` | hard red-and-blue ink eraser |
| ⬜ | `ram_tool_sandpaper.png` | folded sheet of sandpaper, rough texture |
| ⬜ | `ram_tool_wet_cloth.png` | dripping wet cloth with water droplets falling |
| ⬜ | `ram_tool_hairdryer.png` | cartoon hair dryer with heat waves |
| ⬜ | `ram_tool_vacuum.png` | small household vacuum nozzle with static sparks |

**ของประกอบระบบเลือกอุปกรณ์**

| ⬜ | ไฟล์ | ขนาด | เนื้อหา |
|---|---|---|---|
| ⬜ | `ram_tray.png` | 900 × 220 | ถาด/โต๊ะไม้วางเครื่องมือ มองจากด้านหน้า |
| ⬜ | `ui_tool_card.png` | 320 × 200 | กรอบการ์ดกระดาษสำหรับโชว์คุณสมบัติ (ว่างเปล่า ไม่มีตัวหนังสือ) |
| ⬜ | `ui_meter_pip_on.png` / `ui_meter_pip_off.png` | 24 × 24 | จุดวัดระดับความแข็ง ▮ / ▯ |
| ⬜ | `ram_icon_moisture.png` | 48 × 48 | ไอคอนหยดน้ำ |
| ⬜ | `ram_icon_esd.png` | 48 × 48 | ไอคอนสายฟ้าไฟฟ้าสถิต |
| ⬜ | `ram_icon_residue.png` | 48 × 48 | ไอคอนเศษผงร่วง |
| ⬜ | `ram_icon_narrow.png` | 48 × 48 | ไอคอนช่องแคบ/ซอก |

---

# ชุด C · มินิเกม Part RAM เต็มรูปแบบ 8 phase (21 ไฟล์)

`Assets/MiniGame/PartRam/` — เรียงตาม phase ในเกม

### Phase 0 · วินิจฉัยหน้าเครื่อง

| ⬜ | ไฟล์ | ขนาด | เนื้อหา |
|---|---|---|---|
| ⬜ | `ram_pc_front.png` | 700 × 800 | คอมตั้งโต๊ะเครื่องเก่ามองจากด้านหน้า พื้นโปร่ง |
| ⬜ | `ram_screen_glitch.png` | 520 × 340 | จอค้างเป็นบล็อกสีรบกวน |
| ⬜ | `ram_screen_normal.png` | 520 × 340 | จอปกติ (ใช้คู่กัน ขนาดต้องเท่ากัน) |
| ⬜ | `ram_speaker_icon.png` | 120 × 120 | ลำโพงเล็กในเคส + คลื่นเสียง |
| ⬜ | `ram_case_dusty.png` | 640 × 640 | ในเคสเปิดฝา เห็นฝุ่นจับหนาบนแผงแรม |
| ⬜ | `ram_clue_card.png` | 300 × 90 | การ์ดกระดาษจดเบาะแส (ว่าง) |

### Phase 1 · ภาพประกอบตอนปิ๊บสอน

| ⬜ | ไฟล์ | ขนาด | เนื้อหา |
|---|---|---|---|
| ⬜ | `ram_diagram_ram_role.png` | 500 × 300 | เปรียบแรมเป็นโต๊ะทำงาน โต๊ะใหญ่วางของได้เยอะ |
| ⬜ | `ram_diagram_gold_contact.png` | 500 × 300 | ซูมขาทอง มีเส้นสัญญาณวิ่งผ่าน |
| ⬜ | `ram_diagram_dust_block.png` | 500 × 300 | ฝุ่นขวางทาง เส้นสัญญาณขาดตอน |

### Phase 2–3 · ตัดไฟและถอด

| ⬜ | ไฟล์ | ขนาด | เนื้อหา |
|---|---|---|---|
| ⬜ | `ram_btn_shutdown.png` | 160 × 160 | ปุ่ม power บนหน้าจอ |
| ⬜ | `ram_plug_in.png` / `ram_plug_out.png` | 260 × 180 | ปลั๊กเสียบ / ถอดออก **ขนาดเท่ากัน** |
| ⬜ | `ram_hand_touch_case.png` | 300 × 300 | มือแตะโครงเคสโลหะ |
| ⬜ | `ram_slot_empty.png` | 560 × 90 | สลอตแรมว่างบนเมนบอร์ด |
| ⬜ | `ram_clip_closed.png` / `ram_clip_open.png` | 70 × 120 | สลักล็อกปิด/กาง **ขนาดเท่ากัน** |

### Phase 5–7 · ใส่กลับ ตรวจผล สรุป

| ⬜ | ไฟล์ | ขนาด | เนื้อหา |
|---|---|---|---|
| ⬜ | `ram_ghost.png` | 600 × 214 | เงาโปร่ง 30% ของแรม ใช้บอกจุดวาง |
| ⬜ | `ram_dust_particle.png` | 32 × 32 | เม็ดฝุ่นเล็ก ๆ สำหรับ particle |
| ⬜ | `ram_spark.png` | 200 × 200 | ประกายไฟตอนข้ามขั้นตัดไฟ |
| ⬜ | `ui_star_full.png` / `ui_star_empty.png` | 96 × 96 | ดาวหน้าสรุปคะแนน |

---

# ชุด D · Scene ลูปงานซ่อม 5 scene (23 ไฟล์)

### S1 ShopCounter — `Assets/Background/` + `Assets/UI/`

| ⬜ | ไฟล์ | ขนาด | เนื้อหา |
|---|---|---|---|
| ⬜ | `bg_shop_counter.jpg` | 1152 × 648 | เคาน์เตอร์ร้านซ่อมคอม มองจากฝั่งเจ้าของร้าน มีเคาน์เตอร์ไม้อยู่หน้าภาพ **ไม่มีคน** |
| ⬜ | `ui_clue_notebook.png` | 360 × 280 | สมุดจดเล่มเล็กเปิดอยู่ (ไม่มีตัวหนังสือ) |
| ⬜ | `ui_clue_slot_empty.png` / `ui_clue_slot_filled.png` | 300 × 70 | ช่องจดเบาะแส ว่าง / มีเครื่องหมายถูก |
| ⬜ | `ui_patience_pip_on.png` / `_off.png` | 32 × 32 | มาตรความอดทนลูกค้า (หัวใจหรือวงกลม) |
| ⬜ | `ui_topic_btn_normal/hover/press.png` | 260 × 72 | ปุ่มหมวดคำถาม 3 state **ขนาดเท่ากัน** |
| ✅ | ตัวละครลูกค้า | — | *(ใช้ `char_amnuay`, `char_teacher`, `char_headman`, `char_girl`, `char_director`, `char_coworker` ที่มีแล้ว)* |

### S2 Workbench

| ⬜ | ไฟล์ | ขนาด | เนื้อหา |
|---|---|---|---|
| ⬜ | `bg_workbench.jpg` | 1152 × 648 | โต๊ะซ่อมไม้ มีโคมไฟหัวโต๊ะ ผนังแขวนเครื่องมือ **โต๊ะว่าง ไม่มีของวาง** |
| ⬜ | `wb_case_closed.png` | 700 × 820 | เคสคอมปิดฝา มองมุมเฉียง |
| ⬜ | `wb_case_open.png` | 700 × 820 | เคสเดียวกันเปิดฝา เห็นชิ้นส่วนข้างใน **ขนาดเท่ากับปิดฝา** |
| ⬜ | `wb_hotspot_normal/hover/locked.png` | 96 × 96 | จุดคลิกบนชิ้นส่วน 3 state **ขนาดเท่ากัน** |
| ⬜ | `wb_parts_tray.png` | 900 × 260 | โต๊ะข้างวางชิ้นส่วนที่ถอดออกมา |
| ⬜ | `wb_screw_cup.png` | 160 × 160 | ถ้วยแม่เหล็กใส่น็อต |

### Normal Part 8 ชิ้น — `Assets/MiniGame/PartCommon/` (โฟลเดอร์ใหม่)

ทุกชิ้น PNG พื้นโปร่ง มุมมองด้านหน้าตรง

| ⬜ | ไฟล์ | ขนาด |
|---|---|---|
| ⬜ | `part_side_panel.png` | 600 × 700 |
| ⬜ | `part_psu.png` | 420 × 300 |
| ⬜ | `part_case_fan.png` | 300 × 300 |
| ⬜ | `part_cpu_cooler.png` | 350 × 350 |
| ⬜ | `part_storage_hdd.png` | 400 × 260 |
| ⬜ | `part_cmos_battery.png` | 120 × 120 |
| ⬜ | `part_cable_sata.png` | 400 × 120 |
| ⬜ | `part_dust_overlay.png` | 700 × 820 | ชั้นฝุ่นโปร่งแสงวางทับภาพเคส |

### S4 / S5

| ⬜ | ไฟล์ | ขนาด |
|---|---|---|
| ⬜ | `ui_checklist_row.png` | 520 × 64 |
| ⬜ | `ui_bench_test_pass.png` / `_fail.png` | 400 × 400 |
| ⬜ | `ui_invoice.png` | 520 × 700 (ใบเสร็จเปล่า) |

---

# ชุด E · เครื่องมือที่เหลือ 11 ชิ้น (ToolBelt เต็มชุด)

`Assets/MiniGame/PartCommon/` · **200 × 200 PNG** ทุกชิ้น

| ⬜ | ไฟล์ | subject prompt |
|---|---|---|
| ✅ | ไขควงแฉก | *(ใช้ `PartMainboard/mb_screwdriver.png` ได้)* |
| ⬜ | `tool_screwdriver_flat.png` | flathead screwdriver, side view |
| ⬜ | `tool_hex_driver.png` | hex nut driver with 5mm socket |
| ⬜ | `tool_pliers.png` | needle-nose pliers |
| ⬜ | `tool_esd_strap.png` | anti-static wrist strap with coiled cord |
| ⬜ | `tool_esd_mat.png` | grey anti-static mat, top view |
| ⬜ | `tool_flashlight.png` | small desk flashlight with light beam |
| ⬜ | `tool_multimeter.png` | cartoon multimeter with two probes |
| ⬜ | `tool_psu_tester.png` | small PSU tester box with connectors |
| ⬜ | `tool_usb_installer.png` | USB flash drive with a small OS disc icon |
| ⬜ | `tool_thermal_paste.png` | thermal paste tube *(มี `mb_thermal_tube.png` 200×90 แล้ว ทำใหม่ให้เป็น 200×200 ให้เข้าชุด)* |
| ⬜ | `tool_cable_tie.png` | bundle of zip ties *(มี `gpu_cable_tie.png` 120×60 แล้ว ทำใหม่ให้เข้าชุด)* |

---

# ชุด F · UI ที่เหลือ (14 ไฟล์)

`Assets/UI/`

| ⬜ | ไฟล์ | ขนาด | เนื้อหา |
|---|---|---|---|
| ⬜ | `ui_icon_morning.png` / `_noon.png` / `_evening.png` | 64 × 64 | พระอาทิตย์ขึ้น / ตั้งฉาก / ตกดิน |
| ⬜ | `ui_icon_coin.png` | 64 × 64 | เหรียญบาท |
| ⬜ | `ui_icon_xp.png` | 64 × 64 | ดาวหรือประกาย XP |
| ⬜ | `ui_rank_1.png` … `ui_rank_5.png` | 64 × 64 | ตราช่าง 5 ระดับ (มือใหม่ → มือโปร) ใช้สีต่างกันชัดเจน |
| ⬜ | `ui_btn_close.png` / `ui_btn_next.png` / `ui_btn_prev.png` | 96 × 96 | ปุ่มกลม ✕ / ▶ / ◀ |
| ⬜ | `ui_btn_map.png` | 128 × 128 | ปุ่มแผนที่พับ |
| ⬜ | `ui_marker_caution_hover.png` / `_press.png` | 250 × 250 | 2 state ที่ขาดของ `ui_marker_caution.png` **ขนาดต้องเท่ากับตัว normal** |

---

# ชุด G · เติมช่องว่าง Part อื่น (3 ไฟล์)

| ⬜ | ไฟล์ | ขนาด | เนื้อหา |
|---|---|---|---|
| ⬜ | `PartMainboard/mb_mainboard_ghost.png` | 800 × 760 | เงาโปร่ง 30% ของเมนบอร์ด (จุดวาง) |
| ⬜ | `PartMainboard/mb_cpu_wrong.png` | 180 × 180 | CPU หันผิดทิศ มีกากบาทแดง |
| ⬜ | `PartBios/bios_bottleneck_chart.png` | 600 × 400 | กราฟแท่งการ์ตูนเทียบ CPU กับ GPU (ไม่มีตัวหนังสือ) |

---

# ชุด H · Ending (3 ไฟล์)

`Assets/Ending/` · 1152 × 648 JPG

| ⬜ | ไฟล์ | เนื้อหา |
|---|---|---|
| ⬜ | `end_stay_village.jpg` | ขมยืนหน้าร้านซ่อมในหมู่บ้าน มีเด็ก ๆ ล้อมรอบ แสงเย็น |
| ⬜ | `end_back_city.jpg` | ขมมองย้อนกลับมาที่หมู่บ้านจากรถโดยสาร โทนเย็น |
| ⬜ | `end_expand_shop.jpg` | ร้านขยายใหญ่ มีลูกศิษย์ช่วยงาน โทนอุ่นสว่าง |

---

# ชุด I · Audio (19 ไฟล์) — **ยังไม่มีเสียงในเกมเลยแม้แต่ไฟล์เดียว**

`Assets/Audio/BGM/` — `.ogg` loop seamless, −16 LUFS

| ⬜ | ไฟล์ | ความยาว | อารมณ์ |
|---|---|---|---|
| ⬜ | `bgm_main_menu.ogg` | 60–90 s | อบอุ่น ช้า เครื่องสายพื้นบ้าน |
| ⬜ | `bgm_home.ogg` | 90 s | สบาย ๆ กลางวัน |
| ⬜ | `bgm_shop.ogg` | 90 s | ขยันขันแข็ง จังหวะเบา |
| ⬜ | `bgm_minigame.ogg` | 60 s | โฟกัส เร่งเล็กน้อย |
| ⬜ | `bgm_emotional.ogg` | 60 s | เปียโนช้า ฉากซึ้ง |

`Assets/Audio/SFX/` — `.wav` 16-bit 44.1 kHz mono

| ⬜ | ไฟล์ | ความยาว |
|---|---|---|
| ⬜ | `sfx_dialog_blip.wav` · `sfx_click.wav` · `sfx_hover.wav` | 0.1 s |
| ⬜ | `sfx_rub.wav` · `sfx_click_in.wav` · `sfx_error.wav` | 0.2–0.3 s |
| ⬜ | `sfx_success.wav` | 1.0 s |
| ⬜ | `sfx_rank_up.wav` | 1.5 s |
| ⬜ | `sfx_beep_post.wav` | 1.0 s (บี๊บ POST) |
| ⬜ | `sfx_pc_boot.wav` | 2.0 s |
| ⬜ | `sfx_clip_open.wav` · `sfx_ram_click.wav` · `sfx_screw.wav` · `sfx_panel_off.wav` · `sfx_tool_pick.wav` · `sfx_clue_found.wav` · `sfx_customer_bell.wav` · `sfx_cash.wav` | 0.2–1.0 s |

> ⚠️ ต้องมี autoload `AudioManager` + bus `Master / BGM / SFX` ในโค้ดก่อน ไม่งั้นไฟล์เสียงเอาไปใช้ไม่ได้

---

# งานจัดระเบียบ asset (ไม่ต้อง gen ใหม่)

- [ ] **เปิด Godot 1 รอบ** ให้ import รูป 39 ไฟล์ในโฟลเดอร์ `Part*` แล้ว `git add Assets/MiniGame/Part*/*.import` *(สำคัญที่สุด — ดู `BUG_LIST.md` BUG-09)*
- [ ] ย้าย `Assets/MiniGame/box.png` / `box_on_hover.png` → `PartRam/ram_box_normal.png` / `ram_box_hover.png`
- [ ] ลบ asset ชุดเก่าหลังเปลี่ยนโค้ดไปใช้ชุดใหม่แล้ว: `ram.png` · `ramDirty.png` · `ramSligtDirty.png` · `eraser.png`
- [ ] ย่อ `RoomBG.jpg` · `HomeBG.jpg` · `Market.jpg` · `Chapter2_bg.jpg` จาก 1920×1080 → 1152×648
- [ ] บีบไฟล์ใหญ่เกิน: `mb_mainboard.png` 1.47 MB · `mb_case_open.png` 1.41 MB · `gpu_cable_messy.png` 1.15 MB · `gpu_cable_tidy.png` 887 KB
- [ ] ลบไฟล์ซ้ำ `TileMap/Walk_Khom.png` (ซ้ำกับ `SpriteSheets/`) และ `Assets/Gen/` ที่ว่างแล้ว
- [ ] เลือกให้เหลืออันเดียว: `char_pib_normal.png` vs `char_pib_neutral.png`

---

## สรุปจำนวน

| ชุด | จำนวน | สถานะ |
|---|---|---|
| A · Tutorial slides | 7 | 🔴 ทำก่อน |
| B · เครื่องมือทำความสะอาด + การ์ด | 17 | 🔴 |
| C · มินิเกม Part RAM 8 phase | 21 | 🟡 |
| D · Scene ลูปงานซ่อม | 23 | 🟡 |
| E · เครื่องมือที่เหลือ | 11 | 🟡 |
| F · UI ที่เหลือ | 14 | 🟢 |
| G · เติมช่องว่าง Part อื่น | 3 | 🟢 |
| H · Ending | 3 | 🟢 |
| I · Audio | 19 | 🟢 (ต้องมี AudioManager ก่อน) |
| **รวม** | **118 ไฟล์** | |

## ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 21 ก.ย. 2569 | สร้างเอกสาร — เช็กลิสต์ asset 118 ไฟล์ที่ยังขาด แยกเป็น 9 ชุดตามลำดับที่ควรทำ พร้อม subject prompt และงานจัดระเบียบ asset เดิม |
