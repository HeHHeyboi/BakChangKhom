# [Claude 2 ต.ค. 2569] สร้างสีหน้าใหม่ของตัวละครจากภาพเดิม: ลบตา/ปาก/คิ้วด้วยสีผิว แล้ววาดใหม่ (วาดใหญ่ 4 เท่าแล้วย่อให้เส้นเนียน)
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = 'Assets/CharacterSprite/'  # รันจากโฟลเดอร์โปรเจกต์
OUT = 'Assets/CharacterSprite/'
INK = (34, 24, 20, 255)
BROW = (45, 23, 9, 255)  # สีคิ้วขม/มิ้น
SS = 4


def load(n):
    return Image.open(SRC + n + '.png').convert('RGBA')


def skin_at(img, box):
    a = np.array(img).astype(int)
    x0, y0, x1, y1 = box
    ring = np.concatenate([a[y0 - 4:y0 - 1, x0:x1].reshape(-1, 4), a[y1 + 1:y1 + 4, x0:x1].reshape(-1, 4),
                           a[y0:y1, x0 - 4:x0 - 1].reshape(-1, 4), a[y0:y1, x1 + 1:x1 + 4].reshape(-1, 4)])
    ring = ring[(ring[:, :3].sum(1) > 380) & (ring[:, 3] > 200)]
    return tuple(int(v) for v in np.median(ring, 0)[:3]) + (255,)


def erase(img, box, pad=3, color=None):
    x0, y0, x1, y1 = box[0] - pad, box[1] - pad, box[2] + pad, box[3] + pad
    c = color or skin_at(img, (x0, y0, x1, y1))
    m = Image.new('L', img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((x0, y0, x1, y1), radius=6, fill=255)
    m = m.filter(ImageFilter.GaussianBlur(1.2))
    layer = Image.new('RGBA', img.size, c)
    img.paste(layer, (0, 0), m)
    return c


class Pen:
    def __init__(s, img):
        s.img = img
        s.big = Image.new('RGBA', (img.size[0] * SS, img.size[1] * SS), (0, 0, 0, 0))
        s.d = ImageDraw.Draw(s.big)

    def P(s, pts):
        return [(x * SS, y * SS) for x, y in pts]

    def ellipse(s, box, fill=INK, outline=None, w=0):
        s.d.ellipse([v * SS for v in box], fill=fill, outline=outline, width=w * SS)

    def arc(s, box, a0, a1, w=3, fill=INK):
        s.d.arc([v * SS for v in box], a0, a1, fill=fill, width=int(w * SS))

    def line(s, pts, w=3, fill=INK):
        s.d.line(s.P(pts), fill=fill, width=int(w * SS), joint='curve')
        for p in (pts[0], pts[-1]):
            r = w / 2
            s.ellipse((p[0] - r, p[1] - r, p[0] + r, p[1] + r), fill=fill)

    def poly(s, pts, fill):
        s.d.polygon(s.P(pts), fill=fill)

    def done(s):
        small = s.big.resize(s.img.size, Image.LANCZOS)
        s.img.alpha_composite(small)
        return s.img


def eye(p, cx, cy, w=18, h=32, shine=True):
    p.ellipse((cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2))
    if shine:
        p.ellipse((cx - w / 2 + 3, cy - h / 2 + 5, cx - w / 2 + 9, cy - h / 2 + 12), fill=(255, 255, 255, 255))


# ---------------------------------------------------------------- ขม
def khom_surprised():
    im = load('char_khom_normal')
    for b in [(165, 157, 201, 172), (250, 154, 280, 167), (178, 184, 196, 217), (255, 181, 270, 213), (212, 238, 241, 246)]:
        erase(im, b)
    p = Pen(im)
    p.arc((164, 150, 204, 178), 200, 330, 8, BROW)  # คิ้วยกสูง
    p.arc((248, 147, 284, 173), 210, 340, 8, BROW)
    eye(p, 187, 200, 22, 38)
    eye(p, 262, 197, 21, 37)
    p.ellipse((219, 233, 235, 252), fill=(120, 40, 36, 255), outline=INK, w=3)  # ปาก "โอ"
    im = p.done()
    im.save(OUT + 'char_khom_surprised.png')


def khom_tired():
    im = load('char_khom_normal')
    for b in [(165, 157, 201, 172), (250, 154, 280, 167), (178, 184, 196, 217), (255, 181, 270, 213), (212, 238, 241, 246)]:
        erase(im, b)
    p = Pen(im)
    p.line([(167, 172), (184, 167), (201, 170)], 8, BROW)  # คิ้วตก
    p.line([(251, 166), (266, 165), (281, 171)], 8, BROW)
    for cx, cy in ((187, 203), (262, 200)):  # ตาปรือ: ครึ่งล่างของตา + เปลือกตาเส้นตรง
        p.d.chord([v * SS for v in (cx - 10, cy - 14, cx + 10, cy + 14)], 0, 180, fill=INK)
        p.line([(cx - 12, cy), (cx + 12, cy)], 4)
        p.arc((cx - 11, cy + 9, cx + 11, cy + 21), 20, 160, 2, (190, 120, 90, 200))  # ขอบตาคล้ำ
    p.line([(214, 243), (221, 240), (228, 243), (235, 240), (241, 243)], 3)  # ปากหยัก
    p.poly([(286, 178), (280, 194), (292, 194)], (120, 190, 240, 255))  # หยดเหงื่อ
    p.ellipse((279, 189, 293, 203), fill=(120, 190, 240, 255), outline=(40, 80, 140, 255), w=2)
    im = p.done()
    im.save(OUT + 'char_khom_tired.png')


# ---------------------------------------------------------------- ยาย
GREY = (136, 122, 108, 255)


def grandma_smile():
    im = load('char_grandma_normal')
    erase(im, (228, 215, 265, 226))
    p = Pen(im)
    p.d.chord([v * SS for v in (226, 206, 267, 236)], 0, 180, fill=(120, 40, 36, 255), outline=INK, width=3 * SS)  # ยิ้มอ้าปาก
    p.d.chord([v * SS for v in (236, 222, 257, 236)], 0, 180, fill=(220, 110, 110, 255))  # ลิ้น
    p.line([(228, 221), (265, 221)], 3)
    im = p.done()
    im.save(OUT + 'char_grandma_smile.png')


def grandma_worried():
    im = load('char_grandma_normal')
    for b in [(189, 169, 221, 188), (273, 164, 301, 181), (228, 215, 265, 226)]:
        erase(im, b)
    for b in [(186, 131, 217, 147), (274, 125, 301, 139)]:
        erase(im, b, 3)
    p = Pen(im)
    p.line([(188, 144), (203, 140), (217, 131)], 8, GREY)  # คิ้วกังวล (หัวคิ้วชี้ขึ้น)
    p.line([(275, 128), (288, 134), (300, 137)], 8, GREY)
    eye(p, 205, 179, 15, 25)
    eye(p, 287, 173, 15, 25)
    p.arc((232, 220, 262, 238), 200, 340, 4)  # ปากคว่ำ
    im = p.done()
    im.save(OUT + 'char_grandma_worried.png')


# ---------------------------------------------------------------- มิ้น
def min_serious():
    im = load('char_min_normal')
    erase(im, (225, 217, 254, 226))
    erase(im, (267, 127, 294, 138), 1, skin_at(im, (262, 142, 296, 150)))
    p = Pen(im)
    p.line([(266, 140), (281, 135), (295, 133)], 7, BROW)  # คิ้วขมวด (หัวคิ้วต่ำ)
    sk = skin_at(im, (186, 150, 213, 162))
    for cx, top in ((199.5, 160), (276.5, 157)):  # ตาตั้งใจ: ปิดขอบบนตาให้แบน + เส้นเปลือกตา
        p.d.rectangle([v * SS for v in (cx - 12, top - 2, cx + 12, top + 9)], fill=sk)
        p.line([(cx - 12, top + 9), (cx + 12, top + 7)], 4)
    p.line([(229, 223), (250, 223)], 3)  # ปากตรง
    im = p.done()
    im.save(OUT + 'char_min_serious.png')


# ---------------------------------------------------------------- ลุงอำนวย
def amnuay_smile():
    im = load('char_amnuay')
    for b in [(185, 159, 202, 191), (259, 157, 275, 189)]:
        erase(im, b)
    p = Pen(im)
    p.arc((180, 168, 208, 192), 200, 340, 5)  # ตายิ้ม ∩
    p.arc((253, 166, 281, 190), 200, 340, 5)
    p.d.chord([v * SS for v in (220, 232, 250, 252)], 0, 180, fill=(120, 40, 36, 255), outline=INK, width=3 * SS)  # ยิ้มใต้หนวด
    p.ellipse((166, 196, 184, 206), fill=(235, 120, 100, 110))  # แก้มแดง
    p.ellipse((270, 194, 288, 204), fill=(235, 120, 100, 110))
    im = p.done()
    im.save(OUT + 'char_amnuay_smile.png')


import os
os.makedirs(OUT, exist_ok=True)
khom_surprised(); khom_tired(); grandma_smile(); grandma_worried(); min_serious(); amnuay_smile()
print('ok')
