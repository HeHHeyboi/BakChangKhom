# วาดเมาส์ใหม่ทับเมาส์เดิมใน desk_pc_2x.png (เดิมครึ่งขวาโปร่งใส สีหาย) · [Claude 10 ต.ค. 2569]
# ใช้: python3 fix_mouse.py <desk_pc_2x.png>  (เขียนทับไฟล์เดิม)
import sys
from PIL import Image, ImageDraw

P = sys.argv[1]
img = Image.open(P).convert("RGBA")
K = 4  # วาดใหญ่แล้วย่อ ให้ขอบเนียน
w, h = 204, 126
L = Image.new("RGBA", (w * K, h * K), (0, 0, 0, 0))
d = ImageDraw.Draw(L)
INK = (24, 18, 14, 255)
box = [6 * K, 6 * K, (w - 6) * K, (h - 6) * K]
d.ellipse(box, fill=(236, 238, 242, 255))                       # ปุ่มซ้าย/ขวา (ครึ่งบน) สีขาว
d.chord(box, 8, 172, fill=(150, 156, 168, 255))                 # ฝ่ามือ (ครึ่งล่าง) สีเทา
d.ellipse(box, outline=INK, width=5 * K)
d.line([w // 2 * K, 8 * K, w // 2 * K, (h // 2 + 6) * K], fill=INK, width=3 * K)   # ร่องปุ่มซ้าย/ขวา
d.rounded_rectangle([(w // 2 - 7) * K, 18 * K, (w // 2 + 7) * K, 42 * K], 6 * K, fill=(232, 120, 60, 255), outline=INK, width=2 * K)
d.arc([18 * K, 14 * K, (w - 18) * K, (h - 14) * K], 200, 250, fill=(255, 255, 255, 255), width=4 * K)  # ไฮไลต์
L = L.resize((w, h), Image.LANCZOS).rotate(16, expand=True, resample=Image.BICUBIC)
# เงาใต้เมาส์
sh = Image.new("RGBA", L.size, (0, 0, 0, 0))
sh.putalpha(L.getchannel("A").point(lambda a: a * 0.45))
cx, cy = 1672, 696
img.alpha_composite(Image.composite(Image.new("RGBA", L.size, (40, 22, 10, 255)), Image.new("RGBA", L.size, (0, 0, 0, 0)), sh.getchannel("A")), (cx - L.width // 2 + 6, cy - L.height // 2 + 10))
img.alpha_composite(L, (cx - L.width // 2, cy - L.height // 2))
img.save(P)
print("ok")
