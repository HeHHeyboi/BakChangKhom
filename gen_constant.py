"""
gen_constant.py — สคริปต์สร้างไฟล์ constant รายชื่อ phase (@SECTION_NAME)
จากไฟล์บทปิ๊บ เพื่อกันการพิมพ์ชื่อ section ผิดตอนเรียกใช้ใน GDScript

Input  (target_dir): โฟลเดอร์ไฟล์บทปิ๊บ เช่น Assets/Dialog/MiniGame/
  - ไล่อ่านทุกไฟล์ในโฟลเดอร์นี้ (ทุกไฟล์ ไม่กรองนามสกุล)
  - หาเฉพาะบรรทัดที่ขึ้นต้นด้วย "@" (หัวข้อ phase ตามฟอร์แมตที่
    Scripts/MiniGame/phase_dialog_parser.gd ใช้อ่าน) แล้วตัด "@" กับ
    ตัวขึ้นบรรทัดใหม่ท้ายบรรทัดออก เหลือแค่ชื่อ section เช่น "BRIEFING"
  - เก็บชื่อ section ที่เจอทั้งหมดลง set เพื่อกันชื่อซ้ำ (ไฟล์ต่างกันมี
    phase ชื่อเดียวกันได้ เช่น "BRIEFING" ในทุกไฟล์ Pib)

Output (output.gd): ไฟล์ GDScript เช่น Scripts/MiniGame/minigame_header.gd
  - เขียน class_name MinigameHeader ไว้บรรทัดแรก
  - ตามด้วย const ชื่อ section แต่ละอันแบบ SECTION = "SECTION" หนึ่งบรรทัดต่อหนึ่ง
    section (ลำดับไม่คงที่ เพราะมาจาก set)
  - สคริปต์มินิเกมเรียกใช้เป็น MinigameHeader.BRIEFING แทนการพิมพ์
    สตริง "BRIEFING" ตรง ๆ — พิมพ์ชื่อ section ผิดจะเป็น error ตอน
    compile แทนที่จะเงียบ ๆ หาไม่เจอตอนรันเกม

วิธีใช้: python gen_constant.py [target_dir] [output].gd
หมายเหตุ: เปิดไฟล์ output ด้วยโหมด "x" (exclusive create) — ถ้าไฟล์
output มีอยู่แล้วสคริปต์จะ error ทันที ต้องลบไฟล์เก่าก่อนรันซ้ำ
"""

import sys
import pathlib as path

if len(sys.argv) < 3:
    raise Exception("Usage: python gen_constant.py [target_dir] [output].gd")

dir = path.Path(sys.argv[1])
file = open(sys.argv[2], 'w')
file.write("class_name MinigameHeader\n")

header_set = set()

for child in dir.iterdir():
    p = path.Path(child)
    lines = []
    with p.open() as f:
        lines = f.readlines()
    for line in lines:
        if line.startswith("@"):
            header_set.add(line[1:len(line) - 1])

for header in header_set:
    file.write(f"const {header} = \"{header}\"\n")

file.close()
