# [Claude 15 พ.ย. 2569] ฟอนต์ Supermarket มีกฎ GSUB ภาษาไทยครบ (เลือกวรรณยุกต์ตัวต่ำ/ตัวซ้าย · ตัดหางญ ฐ)
# แต่ผูกไว้กับสคริปต์ 'latn' อย่างเดียว → Godot (HarfBuzz) จัดข้อความไทยโดยไม่ใช้กฎ แล้ววางวรรณยุกต์เอง
# ทำให้วรรณยุกต์หลังสระบน (ิ ี ึ ื ั) จมลงไปทับสระ เช่น "เริ่ม" · สคริปต์นี้คัดลอก LangSys ของ latn ไปให้ 'thai' + 'DFLT'
# ใช้: python3 fix_thai_script.py ../supermarket.ttf  (เขียนทับไฟล์ · รันซ้ำได้ ถ้ามี thai แล้วจะไม่ทำอะไร)
import copy
import sys

from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import otTables as ot

path = sys.argv[1]
f = TTFont(path)
sl = f["GSUB"].table.ScriptList
tags = [r.ScriptTag for r in sl.ScriptRecord]
if "thai" in tags:
    print("มี thai อยู่แล้ว")
    sys.exit(0)
latn = next(r for r in sl.ScriptRecord if r.ScriptTag == "latn")
for tag in ("DFLT", "thai"):
    if tag in tags:
        continue
    r = ot.ScriptRecord()
    r.ScriptTag = tag
    r.Script = copy.deepcopy(latn.Script)
    sl.ScriptRecord.append(r)
sl.ScriptRecord.sort(key=lambda r: r.ScriptTag)
sl.ScriptCount = len(sl.ScriptRecord)
f.save(path)
print("ok", [r.ScriptTag for r in sl.ScriptRecord])
