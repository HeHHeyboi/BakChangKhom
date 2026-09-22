# BakChangKhom — Storyboard Pack (low-fidelity)

อ้างอิงจาก `D:\LAB\BakChangKhom\Docs\STORYBOARD.md`, `ASSET_GUIDE.md`, และเอกสารออกแบบ Core Part ทั้ง 5 ตัว

## เป้าหมายการผลิต

- ใช้หน้าจอเกมขนาด 1152×648 และ shell เดียวกันทุก Part
- แบ่งเป็น 8 เฟรมต่อ Part: inspect / brief / safety / remove-or-read / clean-or-connect / install-or-test / verify / score
- ใช้ภาพ wireframe ก่อน ไม่สร้างฉากหรือ character pose ใหม่จนกว่าตำแหน่ง UI จะผ่าน
- ใช้ mascot placeholder และกล่องปิ๊บซ้ำทุกเฟรม
- ใช้ asset หลักเฉพาะชิ้นที่ผู้เล่นต้องคลิก/ลากจริง ส่วน background ใช้ shell เดิม

ภาพตัวอย่างที่ทำแล้ว: [RAM storyboard sheet](./ram_storyboard_sheet.png)

## Shell ที่ใช้ซ้ำ

| ส่วน | ตำแหน่ง | ใช้ซ้ำ |
|---|---:|---|
| Title bar | y 0–56 | ชื่อ Part + phase + help/exit |
| Play area | x 0–860, y 56–476 | interactive objects |
| Info rail | x 860–1152, y 56–476 | objective, checklist, held tool |
| Pib bar | y 476–648 | mascot + speech box |
| Confirm | (760, 400) | ทุก Part |
| Tool tray | y 300–476 | เปิดเฉพาะ phase ที่เลือกอุปกรณ์ |

## Sheet 01 — RAM cleaning

| Panel | ภาพหลัก | interaction / feedback | asset ที่ต้องใช้ |
|---:|---|---|---|
| 1 | เคส + 3 hotspot: จอ, ลำโพง, ในเคส | คลิกครบ 3 จุดก่อนเลือกสาเหตุ | ใช้ case/monitor ที่มีอยู่ |
| 2 | การ์ด RAM + ภาพมือ/ปิ๊บอธิบาย | อ่าน briefing; รอบซ้ำกดข้ามได้ | tutorial slide เดียว |
| 3 | ปุ่ม shutdown, ปลั๊ก, โครงเคส | ทำตามลำดับความปลอดภัย | ใช้ icon/UI ซ้ำ |
| 4 | RAM ใน slot + latch ซ้าย/ขวา | กด latch ทั้งสองแล้วลากขึ้นตรง | ram + slot states |
| 5 | RAM ขยาย + tool tray | เลือกเครื่องมือและทำ 3 sub-step | ใช้ tray เดียว + tool icons |
| 6 | RAM ghost + notch | ลากให้ร่องตรง; กลับด้านวางไม่ลง | ram normal/ghost |
| 7 | จอ boot + ปุ่ม power | ตรวจว่าเห็น RAM ครบ | monitor state |
| 8 | ดาว + คะแนน + lesson learned | จบ Part และกลับ Workbench | score UI เดิม |

## Sheet 02 — Mainboard + CPU

| Panel | ภาพหลัก | interaction / feedback | asset ที่ต้องใช้ |
|---:|---|---|---|
| 1 | Mainboard top view + 3 จุดสังเกต | เก็บเบาะแสความร้อน/ซิลิโคน | mb_mainboard, cooler |
| 2 | แผนภาพ CPU → paste → cooler | ปิ๊บสอนความสัมพันธ์ความร้อน | ใช้ภาพ diagram เดียว |
| 3 | shutdown + plug + ESD mat | ทำ safety checklist | ใช้ safety UI เดิม |
| 4 | cooler + จุดขัน 1–4 | ถอดแบบลำดับไขว้ | cooler, screwdriver |
| 5 | ผิว CPU + ฐาน cooler | เลือก IPA/ผ้าที่ถูก; เช็ด 2 จุด | mb_cpu, thermal tools |
| 6 | socket + CPU พร้อม triangle mark | หมุน/วางให้ตรง; ผิดด้านไม่ลง | mb_socket_open/closed, mb_cpu |
| 7 | thermal dot + cooler + น็อต 4 จุด | เลือกปริมาณ paste และขันไขว้ | mb_thermal_tube/dot, cooler |
| 8 | อุณหภูมิขึ้นแล้วนิ่ง + score | verify และสรุปผล | monitor/score UI เดิม |

## Sheet 03 — GPU + Cable Management

| Panel | ภาพหลัก | interaction / feedback | asset ที่ต้องใช้ |
|---:|---|---|---|
| 1 | GPU ในเคส + อาการจอไม่ขึ้น | คลิกดูการ์ด/slot/สาย | gpu_card, slot |
| 2 | แผนภาพ PCIe + airflow | ปิ๊บอธิบายทางไฟและลม | ใช้ diagram เดียว |
| 3 | shutdown + plug + latch | ทำ safety checklist | UI เดิม |
| 4 | GPU + slot latch | ปลดสลักก่อนลากออก | gpu_card, gpu_pcie_slot |
| 5 | พัดลม/ครีบ/ขาทอง + tool tray | ล็อกใบพัดก่อนเป่า; ทำ 3 sub-step | gpu assets + tray เดิม |
| 6 | ช่อง 8-pin + สายหลายแบบ | เลือก PCIe 8-pin; ต้องมี click | gpu_psu, gpu_cable_pcie |
| 7 | เคสด้านข้าง + สาย 3 เส้น + ลูกศรลม | จัดสายและตั้งทิศลม | gpu_cable_tie, airflow_arrow |
| 8 | จอแสดงผลกลับมา + score | verify และสรุป | monitor/score UI เดิม |

## Sheet 04 — Front Panel + Dual Channel

| Panel | ภาพหลัก | interaction / feedback | asset ที่ต้องใช้ |
|---:|---|---|---|
| 1 | หน้าเคสไฟไม่ติด + จุดสังเกต | เก็บอาการก่อนซ่อม | case/front-panel UI |
| 2 | แผนภาพ header/pin | ปิ๊บสอน switch vs LED polarity | diagram เดียว |
| 3 | shutdown + plug + ESD | ทำ safety checklist | UI เดิม |
| 4 | flashlight ส่อง header | จึงจะ unlock pin map | flashlight + header map |
| 5 | 4 หัว: PWR/RST/P-LED/HDD | ลากต่อ; LED มีขั้ว | frontpanel connectors |
| 6 | ปุ่ม power + ไฟ PWR/HDD | กดทดสอบแล้วชี้อาการ ไม่เฉลย | case LEDs |
| 7 | A1/A2/B1/B2 + RAM 2 แถว | วางคู่สีเดียวกันเพื่อ Dual Channel | slot map + RAM reuse |
| 8 | boot result + score | verify และสรุป | monitor/score UI เดิม |

## Sheet 05 — BIOS + OS + Upgrade

| Panel | ภาพหลัก | interaction / feedback | asset ที่ต้องใช้ |
|---:|---|---|---|
| 1 | BIOS screen + 3 จุดสังเกต | อ่าน boot, memory, storage | ใช้ UI BIOS เป็นหลัก |
| 2 | แผนภาพ boot order / bottleneck | ปิ๊บสอนเหตุผล ไม่ต้องมี scene ใหม่ | diagram เดียว |
| 3 | backup/confirm changes | ยืนยัน safety ก่อนแก้ค่า | BIOS UI states |
| 4 | รายการ boot 4 แถว | ลาก USB ลงจากอันดับ 1 | BIOS list rows |
| 5 | XMP OFF/ON + warning | toggle; แสดงความเสี่ยง | toggle + warning UI |
| 6 | Save and Exit / Discard / Defaults | กดยืนยันให้ถูก | BIOS dialog |
| 7 | SSD/HDD/USB ตัวติดตั้ง | เลือก SSD ว่าง; กัน HDD ข้อมูลลูกค้า | drive cards |
| 8 | กราฟ CPU/GPU/RAM/Storage | ชี้ bottleneck และเลือก upgrade | chart + score UI |

## กติกาประหยัด asset

1. ทำ UI shell, Pib bar, info rail, score panel และ tool tray เป็น prefab ชุดเดียวก่อน
2. ใช้ placeholder/shape ใน storyboard; ยังไม่ generate ภาพศิลป์เต็มฉาก
3. สร้างเฉพาะ state ที่เปลี่ยน interaction จริง เช่น `normal`, `highlight`, `disabled`, `locked`
4. ใช้มุมมอง top-down/side-on ตาม `ASSET_GUIDE.md`; canvas ของ state เดียวกันต้องเท่ากัน
5. ภาพ tutorial ใช้ภาพประกอบเดียวต่อ phase และ reuse ใน briefing/tooltip
6. Tool tray ใช้ slot และ card เดิม เปลี่ยนเฉพาะไอคอนเครื่องมือ
7. ใช้ RAM sprite ซ้ำใน Front Panel และ Mainboard ที่ต้องแสดงแรม ไม่ทำ sprite ใหม่
8. ใช้ monitor, score, warning, checklist และ confirm dialog ร่วมกันทั้ง 5 Part

## ลำดับผลิตที่แนะนำ

1. ปิด layout shell ให้ครบ 8 panel ของ RAM แล้วทดสอบที่ 1152×648
2. แตกเป็น Mainboard/GPU/Front Panel/BIOS โดยเปลี่ยนเฉพาะ play-area asset
3. ทำ asset ที่เป็น blocker: Pib, tutorial slides, part states, tool icons
4. ผูก asset เข้า scene/code แล้วเปิดเกมตรวจทุก phase
5. ค่อยทำ art polish หลัง interaction และการ reuse ผ่านแล้ว
