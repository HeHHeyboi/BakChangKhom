# โต๊ะคอม (มุมหน้าจอ/ปุ่มเปิดเครื่อง) วาดใหม่แบบเวกเตอร์ โดยยึดตำแหน่งจาก desk_pc.png เดิม · [Claude 10 ต.ค. 2569]
# ตำแหน่งต้องตรงกับโหนดในซีน (พิกัด 1152×420): จอ Monitor (452,57)-(768,240) · PowerButton กลาง (335,183) · PowerLed กลาง (318,137)
# ใช้: python3 gen_desk.py <out.png>  → 2304×840 (ใช้ bg_scale 0.5)
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mouse_art import bezier, make_mouse  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1]
S = 2
W, H = 1152 * S, 420 * S
INK = (28, 20, 14, 255)
LW = 3 * S


def r(*v):
    return [round(x * S) for x in v]


def lerp(a, b, t):
    return a + (b - a) * t


def quad_pt(q, u, v):
    # q = (บนซ้าย, บนขวา, ล่างขวา, ล่างซ้าย)
    tl, tr, br, bl = q
    top = (lerp(tl[0], tr[0], u), lerp(tl[1], tr[1], u))
    bot = (lerp(bl[0], br[0], u), lerp(bl[1], br[1], u))
    return (lerp(top[0], bot[0], v), lerp(top[1], bot[1], v))


# ---------------------------------------------------------------- โต๊ะไม้
img = Image.new("RGBA", (W, H), (150, 94, 54, 255))
grad = Image.new("L", (W, H), 0)
gd = ImageDraw.Draw(grad)
gd.ellipse(r(180, 40, 980, 520), fill=255)
grad = grad.filter(ImageFilter.GaussianBlur(120 * S))
img = Image.composite(Image.new("RGBA", (W, H), (178, 116, 68, 255)), img, grad)
d = ImageDraw.Draw(img)
# ขอบหลังโต๊ะ (แถบบน)
d.rectangle(r(0, 0, 1152, 24), fill=(104, 62, 34, 255))
d.line(r(0, 24, 1152, 24), fill=(196, 138, 86, 255), width=3 * S)
d.line(r(0, 27, 1152, 27), fill=(88, 52, 28, 255), width=S)
# ร่องไม้ + ลายไม้
for y in [118, 222, 330]:
    d.line(r(0, y, 1152, y), fill=(112, 66, 36, 255), width=2 * S)
    d.line(r(0, y + 2, 1152, y + 2), fill=(186, 128, 78, 255), width=S)
for x0, y, x1 in [(40, 70, 220), (700, 60, 980), (900, 160, 1120), (60, 180, 240), (460, 300, 640), (960, 280, 1110), (120, 380, 330), (880, 395, 1060), (520, 160, 600)]:
    d.arc(r(x0, y - 6, x1, y + 6), 200, 340, fill=(132, 80, 44, 255), width=S)

# ---------------------------------------------------------------- เงา
sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(sh)
sd.rectangle(r(286, 290, 444, 312), fill=(0, 0, 0, 120))       # ใต้เคส
sd.rectangle(r(445, 254, 790, 268), fill=(0, 0, 0, 70))        # ใต้จอ
sd.ellipse(r(548, 288, 664, 312), fill=(0, 0, 0, 120))         # ใต้ขาตั้ง
sd.polygon(r(370, 352, 812, 352, 820, 404, 356, 404), fill=(0, 0, 0, 110))  # ใต้คีย์บอร์ด
sd.ellipse(r(818, 344, 896, 384), fill=(0, 0, 0, 120))         # ใต้เมาส์
sd.ellipse(r(150, 292, 236, 312), fill=(0, 0, 0, 110))         # ใต้แก้ว
sd.ellipse(r(968, 290, 1060, 314), fill=(0, 0, 0, 110))        # ใต้กระถาง
img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(7 * S)))
d = ImageDraw.Draw(img)

# ---------------------------------------------------------------- สายเมาส์ → เคส (วาดก่อนเคส/จอ/คีย์บอร์ด ให้มุดหลังของ)
m, tip = make_mouse(84 * S, -28.0, 3 * S)                                  # เมาส์มีสาย (mouse_art.py)
mx, my = 856 * S - m.width // 2, 352 * S - m.height // 2
tx, ty = (mx + tip[0]) / S, (my + tip[1]) / S
cable = bezier((tx, ty), (tx - 20, ty - 14), (790, 318), (750, 318))
cable += [(480, 317)]
cable += bezier((480, 317), (446, 316), (428, 302), (418, 284))
d.line([(x * S, y * S) for x, y in cable], fill=(34, 34, 40, 255), width=3 * S, joint="curve")

# ---------------------------------------------------------------- เคส
d.polygon(r(392, 46, 434, 60, 434, 288, 392, 300), fill=(26, 26, 30, 255), outline=INK)
d.line(r(392, 46, 434, 60, 434, 288, 392, 300), fill=INK, width=LW)
d.rounded_rectangle(r(278, 46, 394, 300), 6 * S, fill=(40, 40, 46, 255), outline=INK, width=LW)
d.line(r(284, 52, 284, 294), fill=(64, 64, 72, 255), width=2 * S)          # ไฮไลต์ขอบซ้าย
for y in [70, 93, 116]:                                                   # ช่องไดรฟ์
    d.rounded_rectangle(r(292, y - 4, 378, y + 4), 3 * S, fill=(22, 22, 26, 255), outline=(70, 70, 78, 255), width=S)
d.ellipse(r(313, 132, 323, 142), fill=(110, 220, 120, 255), outline=INK, width=S)   # LED เปิดเครื่อง
d.ellipse(r(338, 132, 348, 142), fill=(200, 140, 230, 255), outline=INK, width=S)   # LED ฮาร์ดดิสก์
d.ellipse(r(321, 169, 349, 197), fill=(222, 224, 230, 255), outline=INK, width=LW)  # ปุ่มเปิดเครื่อง
d.arc(r(328, 176, 342, 190), 300, 240, fill=INK, width=2 * S)
d.line(r(335, 173, 335, 182), fill=INK, width=2 * S)
for y in range(228, 290, 9):                                              # ช่องระบายอากาศ
    d.line(r(296, y, 376, y), fill=(24, 24, 28, 255), width=3 * S)
d.rounded_rectangle(r(290, 298, 310, 304), 2 * S, fill=INK)                # ขาเคส
d.rounded_rectangle(r(362, 298, 382, 304), 2 * S, fill=INK)

# ---------------------------------------------------------------- จอ
d.polygon(r(584, 256, 628, 256, 636, 286, 576, 286), fill=(46, 46, 52, 255))
d.line(r(584, 256, 576, 286), fill=INK, width=LW)
d.line(r(628, 256, 636, 286), fill=INK, width=LW)
d.rounded_rectangle(r(556, 282, 656, 300), 7 * S, fill=(56, 56, 62, 255), outline=INK, width=LW)
d.rounded_rectangle(r(434, 41, 786, 260), 12 * S, fill=(30, 30, 35, 255), outline=INK, width=LW)
d.rounded_rectangle(r(439, 46, 781, 255), 9 * S, outline=(64, 64, 72, 255), width=S)
d.rectangle(r(447, 54, 773, 244), fill=(12, 12, 15, 255), outline=(6, 6, 8, 255), width=S)
gl = Image.new("RGBA", (W, H), (0, 0, 0, 0))                               # เงาสะท้อนบนจอ
ImageDraw.Draw(gl).polygon(r(560, 54, 640, 54, 520, 244, 440, 244), fill=(255, 255, 255, 14))
img.alpha_composite(gl)
d = ImageDraw.Draw(img)
d.ellipse(r(762, 248, 768, 254), fill=(110, 220, 120, 255))

# ---------------------------------------------------------------- สายไฟ (คีย์บอร์ด/เมาส์ → หลังจอ)
d.line(r(590, 334, 596, 316, 610, 300), fill=(34, 34, 40, 255), width=3 * S, joint="curve")

# ---------------------------------------------------------------- คีย์บอร์ด (มองเฉียง)
kb = [(384, 332), (790, 332), (804, 392), (366, 392)]
d.polygon(r(*[c for p in kb for c in p]), fill=(170, 172, 180, 255))
d.polygon(r(366, 392, 804, 392, 802, 398, 368, 398), fill=(120, 122, 130, 255))      # ขอบหน้า
d.line(r(384, 332, 790, 332, 804, 392, 366, 392, 384, 332), fill=INK, width=LW, joint="curve")
d.line(r(368, 398, 802, 398), fill=INK, width=LW)
d.line(r(366, 392, 368, 398), fill=INK, width=LW)
d.line(r(804, 392, 802, 398), fill=INK, width=LW)
inner = [quad_pt(kb, 0.02, 0.1), quad_pt(kb, 0.98, 0.1), quad_pt(kb, 0.98, 0.92), quad_pt(kb, 0.02, 0.92)]
rows = 5
for ri in range(rows):
    v0, v1 = ri / rows, (ri + 1) / rows
    n = [14, 14, 13, 12, 7][ri]
    widths = [1.0] * n
    if ri == 4:
        widths = [1, 1, 1, 6, 1, 1, 1]                                       # สเปซบาร์
    tot = sum(widths)
    u = 0.0
    for wv in widths:
        u0, u1 = u / tot, (u + wv) / tot
        u += wv
        g = 0.06 / n * 3
        p = [quad_pt(inner, u0 + g / 2, v0 + 0.04), quad_pt(inner, u1 - g / 2, v0 + 0.04),
             quad_pt(inner, u1 - g / 2, v1 - 0.04), quad_pt(inner, u0 + g / 2, v1 - 0.04)]
        d.polygon([c * S for pt in p for c in pt], fill=(248, 248, 250, 255), outline=(86, 86, 94, 255))

# ---------------------------------------------------------------- แผ่นรองเมาส์ + เมาส์
d.polygon(r(808, 322, 902, 322, 912, 384, 802, 384), fill=(54, 86, 110, 255))
d.line(r(808, 322, 902, 322, 912, 384, 802, 384, 808, 322), fill=INK, width=LW, joint="curve")
img.alpha_composite(m, (mx, my))                                          # เมาส์ (สายวาดไว้ก่อนเคสแล้ว)
d = ImageDraw.Draw(img)

# ---------------------------------------------------------------- ของแต่งโต๊ะ (ห่างจากจุดกด)
d.arc(r(212, 254, 240, 284), 270, 90, fill=INK, width=5 * S)                   # แก้วกาแฟ
d.rounded_rectangle(r(160, 240, 226, 304), 9 * S, fill=(214, 122, 72, 255), outline=INK, width=LW)
d.ellipse(r(162, 236, 224, 250), fill=(92, 54, 30, 255), outline=INK, width=2 * S)
d.line(r(170, 254, 170, 294), fill=(238, 164, 112, 255), width=3 * S)
for lx, ly, ex, ey in [(1012, 230, 980, 168), (1014, 228, 1040, 156), (1012, 232, 1060, 196), (1012, 232, 964, 206), (1013, 230, 1010, 140)]:  # ต้นไม้
    d.line(r(lx, ly, ex, ey), fill=(60, 120, 60, 255), width=2 * S)
    d.ellipse(r(ex - 14, ey - 9, ex + 14, ey + 9), fill=(96, 170, 84, 255), outline=INK, width=2 * S)
d.polygon(r(976, 228, 1050, 228, 1042, 300, 984, 300), fill=(196, 104, 62, 255))
d.line(r(976, 228, 1050, 228, 1042, 300, 984, 300, 976, 228), fill=INK, width=LW, joint="curve")
d.rectangle(r(972, 222, 1054, 234), fill=(214, 120, 74, 255), outline=INK, width=LW)

img.save(OUT)
print("ok", img.size)
