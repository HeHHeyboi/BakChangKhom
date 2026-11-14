# ไอคอนของอัปเกรดชั้นวางเครื่อง (0.3.0 ขั้น F) · โทนเดียวกับ item_storage_*.png (128×128 เส้นน้ำตาลเข้ม แบน)
# ใช้: python3 gen_shelf_items.py  → ../item_shelf_4.png · ../item_shelf_6.png · pip install cairosvg · [Claude 15 พ.ย. 2569]
import os
import cairosvg

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
INK = "#3b2716"
WOOD = "#c58f57"
WOOD_D = "#9a6a3c"
METAL = "#c9c2b4"
CREAM = "#f6ead0"
GREEN = "#6db04f"
ORANGE = "#e0913a"


def pc(x, y, w, h, light):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="{METAL if light else CREAM}"/>'
            f'<circle cx="{x + w / 2:.1f}" cy="{y + 6}" r="2.2" fill="{GREEN if light else ORANGE}" stroke-width="1.5"/>'
            f'<line x1="{x + 4}" y1="{y + h - 6}" x2="{x + w - 4}" y2="{y + h - 6}" stroke-width="2"/>')


def shelf(tiers):
    top, bottom = 14, 116
    gap = (bottom - top) / tiers
    body = f'<rect x="16" y="{top}" width="8" height="{bottom - top + 4}" rx="2" fill="{WOOD_D}"/>'
    body += f'<rect x="104" y="{top}" width="8" height="{bottom - top + 4}" rx="2" fill="{WOOD_D}"/>'
    for t in range(tiers):
        board = top + gap * (t + 1)
        h = gap - 14
        body += pc(30, board - h - 2, 30, h, t % 2 == 0)
        body += pc(68, board - h - 2, 30, h, t % 2 == 1)
        body += f'<rect x="12" y="{board - 2:.1f}" width="104" height="8" rx="2" fill="{WOOD}"/>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">'
            f'<g stroke="{INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>')


for tiers, name in [(2, "item_shelf_4"), (3, "item_shelf_6")]:
    cairosvg.svg2png(bytestring=shelf(tiers).encode(), write_to=os.path.join(OUT, name + ".png"), output_width=128, output_height=128)
print("ok")
