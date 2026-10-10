# เมาส์มีสาย มองจากด้านบนเฉียง (ตัวเทาอ่อน · ขอบล่างขวาสีครีม · ล้อเลื่อนเข้ม) — ใช้ร่วม gen_desk.py / gen_frame.py
# [Claude 10 ต.ค. 2569]
import math
from PIL import Image, ImageChops, ImageDraw

INK = (28, 20, 14, 255)
LINE = (96, 96, 104, 255)
SHELL = (200, 202, 208, 255)
SHELL_HI = (222, 224, 230, 255)
SKIRT = (240, 236, 224, 255)
WHEEL = (58, 58, 64, 255)


def make_mouse(length_px: int, angle_deg: float = -32.0, outline_px: float = 4.0):
    """คืน (ภาพ RGBA, จุดหัวเมาส์สำหรับต่อสาย (x,y) ในภาพ) · หัวเมาส์ชี้ไปทางซ้ายบน"""
    K = 4
    L = length_px * K
    Wd = int(L * 0.66)
    pad = int(L * 0.08)
    img = Image.new("RGBA", (L + pad * 2, Wd + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ow = max(1, int(outline_px * K))
    body = [pad, pad, pad + L, pad + Wd]
    # ฐาน/ขอบล่าง (สีครีม)
    d.ellipse(body, fill=SKIRT)
    # กระดองบน (เลื่อนขึ้นซ้าย เหลือขอบครีมด้านล่างขวา)
    top = Image.new("L", img.size, 0)
    ImageDraw.Draw(top).ellipse([pad - L * 0.02, pad - Wd * 0.04, pad + L * 0.94, pad + Wd * 0.8], fill=255)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse(body, fill=255)
    top = ImageChops.multiply(top, mask)
    img.paste(Image.new("RGBA", img.size, SHELL), (0, 0), top)
    d = ImageDraw.Draw(img)
    lines = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lines)
    # ไฮไลต์บนกระดอง
    d.arc([pad + L * 0.12, pad + Wd * 0.08, pad + L * 0.8, pad + Wd * 0.62], 200, 265, fill=SHELL_HI, width=ow * 2)
    # เส้นขอบกระดอง (เส้นแบ่งกับขอบครีม)
    d.arc([pad - L * 0.02, pad - Wd * 0.04, pad + L * 0.94, pad + Wd * 0.8], 345, 165, fill=LINE, width=max(1, ow * 3 // 4))
    # ปุ่มซ้าย/ขวา: เส้นกลาง + เส้นโค้งท้ายปุ่ม
    cy = pad + Wd * 0.38
    d.line([pad + L * 0.02, cy, pad + L * 0.42, cy], fill=LINE, width=max(1, ow * 3 // 4))
    d.arc([pad - L * 0.2, pad - Wd * 0.22, pad + L * 0.5, pad + Wd * 0.98], 300, 52, fill=LINE, width=max(1, ow * 3 // 4))
    # ล้อเลื่อน
    wx, wy, ww, wh = pad + L * 0.17, cy, L * 0.13, Wd * 0.16
    d.ellipse([wx - ww / 2, wy - wh / 2, wx + ww / 2, wy + wh / 2], fill=WHEEL)
    d.ellipse([wx - ww * 0.28, wy - wh * 0.28, wx + ww * 0.3, wy + wh * 0.24], fill=(150, 150, 156, 255))
    inner = Image.new("L", img.size, 0)
    ImageDraw.Draw(inner).ellipse([pad + ow, pad + ow, pad + L - ow, pad + Wd - ow], fill=255)
    lines.putalpha(ImageChops.multiply(lines.getchannel("A"), inner))
    img.alpha_composite(lines)
    d = ImageDraw.Draw(img)
    # เส้นขอบนอก
    d.ellipse(body, outline=INK, width=ow)
    # หมุน: หัวเมาส์ (ซ้าย) ชี้ขึ้นซ้าย
    tip = (pad + ow, pad + Wd / 2)
    cxy = (img.width / 2, img.height / 2)
    img = img.rotate(angle_deg, expand=True, resample=Image.BICUBIC)
    a = math.radians(angle_deg)
    dx, dy = tip[0] - cxy[0], tip[1] - cxy[1]
    # rotate() หมุนทวนเข็มบนภาพ (แกน y ชี้ลง)
    rx = dx * math.cos(a) + dy * math.sin(a)
    ry = -dx * math.sin(a) + dy * math.cos(a)
    tip2 = (img.width / 2 + rx, img.height / 2 + ry)
    img = img.resize((img.width // K, img.height // K), Image.LANCZOS)
    return img, (tip2[0] / K, tip2[1] / K)


def bezier(p0, p1, p2, p3, n=40):
    """จุดบนเส้นโค้งเบซิเยร์ (ใช้วาดสายเมาส์ให้โค้งนุ่ม)"""
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        pts.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                    u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))
    return pts
