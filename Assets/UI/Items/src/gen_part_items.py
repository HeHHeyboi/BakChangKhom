# ไอคอนอะไหล่ใหม่ 0.4.0 (ภาพชั่วคราว รออาร์ตจริง) · โทนเดียวกับ item_*.png (128×128 เส้นน้ำตาลเข้ม แบน)
# ใช้: python3 gen_part_items.py → ../item_cmos_cr2032.png · item_fp_switch · item_fan_cpu · item_fan_gpu · item_psu_450w · item_gpu_used · item_mb_used
# pip install cairosvg · ป้าย "มือ2" ใช้ฟอนต์ Sarabun (ติดตั้ง Assets/Fonts/Sarabun-Regular.ttf ในเครื่องก่อน) · [Claude 15 พ.ย. 2569 · 0.4.0 ขั้น B]
import math
import os
import cairosvg

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
INK = "#3b2716"
METAL = "#c9c2b4"
METAL_D = "#9d968a"
CREAM = "#f6ead0"
GREEN = "#6db04f"
PCB = "#4f8a4a"
DARK = "#4a4540"
ORANGE = "#e0913a"
RED = "#c8553d"


def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">'
            f'<g stroke="{INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>')


def fan(cx, cy, r, frame=True):
    b = ""
    if frame:
        b += f'<rect x="{cx - r - 8}" y="{cy - r - 8}" width="{2 * r + 16}" height="{2 * r + 16}" rx="8" fill="{DARK}"/>'
    b += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{METAL_D}"/>'
    for k in range(5):
        a = k * 72
        x1 = cx + math.cos(math.radians(a)) * r * 0.25
        y1 = cy + math.sin(math.radians(a)) * r * 0.25
        x2 = cx + math.cos(math.radians(a + 40)) * r * 0.92
        y2 = cy + math.sin(math.radians(a + 40)) * r * 0.92
        b += f'<path d="M{x1:.1f},{y1:.1f} Q{cx + math.cos(math.radians(a + 5)) * r:.1f},{cy + math.sin(math.radians(a + 5)) * r:.1f} {x2:.1f},{y2:.1f} Z" fill="{METAL}" stroke-width="2"/>'
    b += f'<circle cx="{cx}" cy="{cy}" r="{r * 0.25:.1f}" fill="{CREAM}"/>'
    return b


def cmos():
    return svg(f'<circle cx="64" cy="64" r="44" fill="{METAL}"/><circle cx="64" cy="64" r="34" fill="{CREAM}" stroke-width="2"/>'
               f'<text x="64" y="60" font-family="sans-serif" font-size="18" font-weight="bold" text-anchor="middle" fill="{INK}" stroke="none">CR</text>'
               f'<text x="64" y="80" font-family="sans-serif" font-size="18" font-weight="bold" text-anchor="middle" fill="{INK}" stroke="none">2032</text>'
               f'<text x="96" y="40" font-family="sans-serif" font-size="22" font-weight="bold" text-anchor="middle" fill="{INK}" stroke="none">+</text>')


def switch():
    return svg(f'<rect x="28" y="20" width="72" height="56" rx="10" fill="{METAL}"/><circle cx="64" cy="48" r="20" fill="{CREAM}"/>'
               f'<path d="M56,40 A11,11 0 1,0 72,40" fill="none"/><line x1="64" y1="34" x2="64" y2="48"/>'
               f'<path d="M50,76 C46,96 30,98 22,112" fill="none" stroke="{RED}" stroke-width="4"/><path d="M78,76 C82,96 98,98 106,112" fill="none" stroke="{DARK}" stroke-width="4"/>'
               f'<rect x="14" y="108" width="16" height="10" rx="2" fill="{DARK}"/><rect x="98" y="108" width="16" height="10" rx="2" fill="{DARK}"/>')


def fan_cpu():
    return svg(f'<rect x="18" y="74" width="92" height="38" rx="4" fill="{METAL}"/>'
               + "".join(f'<line x1="{26 + i * 11}" y1="78" x2="{26 + i * 11}" y2="108" stroke-width="2"/>' for i in range(8))
               + fan(64, 48, 30))


def fan_gpu():
    return svg(f'<rect x="8" y="34" width="112" height="60" rx="8" fill="{DARK}"/>' + fan(38, 64, 22, False) + fan(90, 64, 22, False)
               + f'<rect x="14" y="94" width="40" height="8" rx="2" fill="{ORANGE}" stroke-width="2"/>')


def psu():
    return svg(f'<rect x="14" y="26" width="100" height="76" rx="6" fill="{METAL_D}"/>' + fan(56, 64, 26, False)
               + f'<rect x="92" y="38" width="16" height="22" rx="2" fill="{DARK}"/><rect x="94" y="72" width="12" height="16" rx="2" fill="{RED}"/>'
               f'<text x="28" y="22" font-family="sans-serif" font-size="14" font-weight="bold" fill="{INK}" stroke="none">450W</text>')


def gpu_used():
    return svg(f'<rect x="8" y="30" width="112" height="56" rx="6" fill="{DARK}"/>' + fan(40, 58, 20, False) + fan(88, 58, 20, False)
               + f'<rect x="20" y="86" width="64" height="10" fill="{PCB}"/>'
               + "".join(f'<line x1="{24 + i * 6}" y1="88" x2="{24 + i * 6}" y2="96" stroke="{ORANGE}" stroke-width="2"/>' for i in range(10))
               + f'<rect x="84" y="96" width="32" height="20" rx="4" fill="{CREAM}"/><text x="100" y="111" font-family="Sarabun" font-size="12" font-weight="bold" text-anchor="middle" fill="{INK}" stroke="none">มือ2</text>')


def mb_used():
    body = f'<rect x="12" y="12" width="104" height="104" rx="4" fill="{PCB}"/>'
    body += f'<rect x="38" y="30" width="34" height="34" rx="3" fill="{METAL}"/><rect x="46" y="38" width="18" height="18" fill="{CREAM}" stroke-width="2"/>'
    body += "".join(f'<rect x="{82 + i * 9}" y="22" width="5" height="54" fill="{DARK}" stroke-width="2"/>' for i in range(3))
    body += f'<rect x="22" y="80" width="64" height="8" fill="{DARK}" stroke-width="2"/><rect x="22" y="96" width="64" height="8" fill="{DARK}" stroke-width="2"/>'
    body += f'<circle cx="26" cy="30" r="5" fill="{METAL}" stroke-width="2"/>'
    body += f'<rect x="84" y="96" width="32" height="20" rx="4" fill="{CREAM}"/><text x="100" y="111" font-family="Sarabun" font-size="12" font-weight="bold" text-anchor="middle" fill="{INK}" stroke="none">มือ2</text>'
    return svg(body)


for name, fn in [("item_cmos_cr2032", cmos), ("item_fp_switch", switch), ("item_fan_cpu", fan_cpu), ("item_fan_gpu", fan_gpu),
                 ("item_psu_450w", psu), ("item_gpu_used", gpu_used), ("item_mb_used", mb_used)]:
    cairosvg.svg2png(bytestring=fn().encode(), write_to=os.path.join(OUT, name + ".png"), output_width=128, output_height=128)
print("ok")
