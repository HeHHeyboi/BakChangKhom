# ไอคอนเล็กแทนอีโมจิ (เว็บไม่มีฟอนต์อีโมจิ) · โทนเดียวกับ ui_icon_storage: เส้นขอบน้ำตาลเข้ม สีอุ่น แบน
# ใช้: python3 gen_icons.py <โฟลเดอร์ออก>  → <id>.svg (src) + icon_<id>.png 64×64
# pip install cairosvg · [Claude 20 ต.ค. 2569]
import math
import os
import sys

import cairosvg

OUT = sys.argv[1] if len(sys.argv) > 1 else ".."
SRC = os.path.dirname(os.path.abspath(__file__))
INK = "#3b2716"
SW = 3.5
CREAM = "#f6ead0"
ORANGE = "#e0913a"
GOLD = "#f5c542"
BROWN = "#b07a45"
GREEN = "#6db04f"
RED = "#c4553b"
METAL = "#c9c2b4"


def svg(body: str) -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">'
            f'<g stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>')


def star_pts(cx, cy, ro, ri, n=5):
    pts = []
    for i in range(n * 2):
        r = ro if i % 2 == 0 else ri
        a = -math.pi / 2 + i * math.pi / n
        pts.append(f"{cx + r * math.cos(a):.2f},{cy + r * math.sin(a):.2f}")
    return " ".join(pts)


ICONS = {
    # 🕘 นาฬิกา (เข็มชี้ 9 โมง)
    "clock": f'''<circle cx="32" cy="33" r="26" fill="{ORANGE}"/>
<circle cx="32" cy="33" r="19" fill="{CREAM}" stroke-width="2.5"/>
<line x1="32" y1="33" x2="32" y2="19"/><line x1="32" y1="33" x2="20" y2="33"/>
<circle cx="32" cy="33" r="2.5" fill="{INK}"/>
<g stroke-width="2.5"><line x1="32" y1="16.5" x2="32" y2="17.5"/><line x1="48.5" y1="33" x2="47.5" y2="33"/><line x1="32" y1="49.5" x2="32" y2="48.5"/><line x1="15.5" y1="33" x2="16.5" y2="33"/></g>''',
    # 📋 คลิปบอร์ด
    "clipboard": f'''<rect x="10" y="9" width="44" height="50" rx="5" fill="{BROWN}"/>
<rect x="16" y="15" width="32" height="38" rx="2" fill="{CREAM}" stroke-width="2.5"/>
<rect x="22" y="5" width="20" height="10" rx="3" fill="{METAL}"/>
<g stroke-width="3"><line x1="22" y1="26" x2="42" y2="26"/><line x1="22" y1="34" x2="42" y2="34"/><line x1="22" y1="42" x2="34" y2="42"/></g>''',
    # 📞 หูโทรศัพท์
    "phone": f'''<path d="M17 8c-4 0-9 4-9 10 0 21 17 38 38 38 6 0 10-5 10-9v-6c0-2-1-3-3-4l-9-3c-2-1-4 0-5 1l-3 4c-8-4-14-10-18-18l4-3c1-1 2-3 1-5l-3-9c-1-2-2-3-4-3z" fill="{ORANGE}"/>
<path d="M14 15c0 0 1-3 4-3" stroke="{CREAM}" stroke-width="2.5" fill="none"/>''',
    # ⭐ ดาว
    "star": f'''<polygon points="{star_pts(32, 34, 28, 12.5)}" fill="{GOLD}"/>
<path d="M27 25l3-7" stroke="#fff6d6" stroke-width="3" fill="none"/>''',
    # 🔒 กุญแจ
    "lock": f'''<path d="M20 30v-8a12 12 0 0 1 24 0v8" fill="none" stroke-width="7" stroke="{INK}"/>
<path d="M20 30v-8a12 12 0 0 1 24 0v8" fill="none" stroke-width="3" stroke="{METAL}"/>
<rect x="12" y="28" width="40" height="30" rx="5" fill="{GOLD}"/>
<circle cx="32" cy="40" r="4" fill="{INK}"/><path d="M32 42v8" stroke-width="4"/>''',
    # ⬇ ดาวน์โหลด
    "download": f'''<path d="M24 6h16v22h11l-19 20-19-20h11z" fill="{GREEN}"/>
<path d="M8 46v8a4 4 0 0 0 4 4h40a4 4 0 0 0 4-4v-8" fill="none" stroke-width="8"/>
<path d="M8 46v8a4 4 0 0 0 4 4h40a4 4 0 0 0 4-4v-8" fill="none" stroke-width="3.5" stroke="{METAL}"/>''',
    # 🔊 ลำโพง
    "speaker": f'''<path d="M6 24h10l14-12v40l-14-12h-10z" fill="{ORANGE}"/>
<g fill="none" stroke-width="7"><path d="M38 24a10 10 0 0 1 0 16"/><path d="M45 17a20 20 0 0 1 0 30"/></g>
<g fill="none" stroke-width="3" stroke="{CREAM}"><path d="M38 24a10 10 0 0 1 0 16"/><path d="M45 17a20 20 0 0 1 0 30"/></g>''',
    # 📖 หนังสือเปิด
    "book": f'''<path d="M4 16v38c10-3 20-2 28 3 8-5 18-6 28-3v-38z" fill="{RED}"/>
<path d="M8 12v36c9-2 17-1 24 4v-36c-7-5-15-6-24-4z" fill="{CREAM}"/>
<path d="M56 12v36c-9-2-17-1-24 4v-36c7-5 15-6 24-4z" fill="{CREAM}"/>
<g stroke-width="2.2"><path d="M13 22c5-1 10 0 14 2M13 30c5-1 10 0 14 2M13 38c5-1 10 0 14 2"/><path d="M51 22c-5-1-10 0-14 2M51 30c-5-1-10 0-14 2M51 38c-5-1-10 0-14 2"/></g>''',
    # [0.3.0] ชั้นวางเครื่อง (ชั้นไม้ 2 ชั้น · เครื่องคอม 2 เครื่อง)
    "shelf": f'''<rect x="8" y="6" width="6" height="54" rx="2" fill="{BROWN}"/><rect x="50" y="6" width="6" height="54" rx="2" fill="{BROWN}"/>
<rect x="15" y="12" width="13" height="17" rx="2" fill="{METAL}"/><circle cx="21.5" cy="17" r="1.6" fill="{GREEN}" stroke-width="1.5"/>
<rect x="31" y="15" width="16" height="14" rx="2" fill="{CREAM}"/><line x1="35" y1="20" x2="43" y2="20" stroke-width="2.5"/>
<rect x="15" y="38" width="16" height="15" rx="2" fill="{CREAM}"/><line x1="19" y1="44" x2="27" y2="44" stroke-width="2.5"/>
<rect x="34" y="35" width="13" height="18" rx="2" fill="{METAL}"/><circle cx="40.5" cy="40" r="1.6" fill="{ORANGE}" stroke-width="1.5"/>
<rect x="6" y="29" width="52" height="6" rx="2" fill="{ORANGE}"/><rect x="6" y="53" width="52" height="6" rx="2" fill="{ORANGE}"/>''',
    # [0.4.0] ร้านออนไลน์: กล่องพัสดุ + รถเข็น
    "cart": f'''<path d="M4 10h8l7 30h32l6-22h-41" fill="none"/>
<rect x="22" y="12" width="26" height="20" rx="2" fill="{BROWN}"/><path d="M22 20h26M35 12v8" stroke-width="2.5"/>
<path d="M19 40h32" fill="none"/><circle cx="24" cy="51" r="5" fill="{CREAM}"/><circle cx="46" cy="51" r="5" fill="{CREAM}"/>''',
    # [0.4.0] รถขายของ (กระบะขายของเร่ + ลำโพง)
    "truck": f'''<rect x="4" y="22" width="34" height="22" rx="3" fill="{ORANGE}"/><path d="M38 28h12l9 9v7h-21z" fill="{CREAM}"/>
<path d="M42 31h7l5 5h-12z" fill="{METAL}" stroke-width="2"/><path d="M8 22l4-10h18l4 10" fill="{GREEN}"/>
<path d="M18 12v-6l-6 -2" fill="none" stroke-width="2.5"/><path d="M12 2l-5 4h-3v4h3l5 4z" fill="{GOLD}" stroke-width="2"/>
<circle cx="14" cy="47" r="6" fill="{METAL}"/><circle cx="48" cy="47" r="6" fill="{METAL}"/>''',
    # [0.7.0] ใบประกาศ/ถ้วยรางวัล (Achievement)
    "trophy": f'''<path d="M18 10h28v14a14 14 0 0 1-28 0z" fill="{GOLD}"/>
<path d="M18 14h-8v4a9 9 0 0 0 9 9M46 14h8v4a9 9 0 0 1-9 9" fill="none"/>
<path d="M28 37h8v9h-8z" fill="{GOLD}" stroke-width="3"/><rect x="18" y="46" width="28" height="10" rx="2" fill="{BROWN}"/>
<path d="M25 15v8" stroke="#fff6d6" stroke-width="3" fill="none"/>''',
    # [0.7.0] ธงแดง (รายงานร้านปลอม · สัญญาณเตือน)
    "flag": f'''<path d="M16 6v54" stroke-width="5"/><path d="M18 9c10-5 18 5 30 0v24c-12 5-20-5-30 0z" fill="{RED}"/>''',
    # [0.7.0] ปฏิทิน (อีเวนต์)
    "calendar": f'''<rect x="8" y="12" width="48" height="44" rx="5" fill="{CREAM}"/><rect x="8" y="12" width="48" height="12" rx="5" fill="{RED}"/>
<path d="M20 6v12M44 6v12" stroke-width="4"/><g stroke-width="0" fill="{INK}"><rect x="16" y="30" width="8" height="7"/><rect x="28" y="30" width="8" height="7"/><rect x="40" y="30" width="8" height="7"/><rect x="16" y="42" width="8" height="7"/><rect x="28" y="42" width="8" height="7" fill="{ORANGE}"/></g>''',
}

os.makedirs(OUT, exist_ok=True)
for name, body in ICONS.items():
    s = svg(body)
    with open(os.path.join(SRC, f"{name}.svg"), "w", encoding="utf-8") as f:
        f.write(s)
    cairosvg.svg2png(bytestring=s.encode(), write_to=os.path.join(OUT, f"icon_{name}.png"), output_width=64, output_height=64)
print("ok", len(ICONS))
