# วาดภาพ Part GPU — SVG ต้นฉบับ + PNG (ใช้ครั้งเดียว · ผลลัพธ์ใน out/)
import os, random
import cairosvg
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = '/mnt/user-data/uploads/BakChangKhom/Assets/'
OUT = '/home/claude/gpu/out/'
os.makedirs(OUT + 'src', exist_ok=True)
INK = '#2C1810'
random.seed(11)


def save_svg(name, svg, w, h):
    open(OUT + 'src/' + name + '.svg', 'w').write(svg)
    cairosvg.svg2png(bytestring=svg.encode(), write_to=OUT + name + '.png', output_width=w, output_height=h)


def fan(cx, cy, r, blades=7):
    b = ''.join(
        f'<path transform="rotate({i * 360 / blades} {cx} {cy})" d="M{cx} {cy} q{r * 0.55} {-r * 0.25} {r * 0.85} {-r * 0.05} q{-r * 0.2} {r * 0.35} {-r * 0.85} {r * 0.05} z" fill="#3c3f46" stroke="{INK}" stroke-width="2"/>'
        for i in range(blades))
    return (f'<circle cx="{cx}" cy="{cy}" r="{r + 8}" fill="#1f2025" stroke="{INK}" stroke-width="5"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#2a2c31"/>{b}'
            f'<circle cx="{cx}" cy="{cy}" r="{r * 0.25}" fill="#55585f" stroke="{INK}" stroke-width="3"/>')


# ---------------------------------------------------------------- ในเคส (มองด้านข้าง · หน้าเคสอยู่ขวา)
def case_view():
    wood = ''.join(f'<path d="M0 {y} H1152" stroke="#7a4a26" stroke-width="2" opacity=".4"/>' for y in range(20, 420, 46))
    ram = ''.join(f'<rect x="{560 + i * 22}" y="70" width="12" height="120" rx="3" fill="{"#3a4fa8" if i % 2 else "#2b2b30"}" stroke="{INK}" stroke-width="3"/>' for i in range(4))
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1152" height="420" viewBox="0 0 1152 420">
<defs><radialGradient id="lt" cx=".45" cy=".4" r=".75"><stop offset="0" stop-color="#fff2c8" stop-opacity=".16"/><stop offset="1" stop-color="#000" stop-opacity=".5"/></radialGradient></defs>
<rect width="1152" height="420" fill="#a8693a"/>{wood}
<rect x="196" y="6" width="760" height="408" rx="18" fill="#000" opacity=".3"/>
<rect x="186" y="0" width="760" height="404" rx="18" fill="#3b3e45" stroke="{INK}" stroke-width="7"/>
<rect x="206" y="18" width="720" height="368" rx="10" fill="#26282d"/>
<!-- เมนบอร์ด -->
<rect x="250" y="34" width="470" height="290" rx="8" fill="#226a3d" stroke="{INK}" stroke-width="5"/>
{''.join(f'<path d="M{260 + k * 37} 40 v40 l12 12 v30" stroke="#3f9a5c" stroke-width="3" fill="none" opacity=".45"/>' for k in range(12))}
<rect x="320" y="70" width="150" height="120" rx="10" fill="#8d9097" stroke="{INK}" stroke-width="5"/>
{''.join(f'<rect x="{330 + k * 13}" y="80" width="7" height="100" rx="2" fill="#6c7077"/>' for k in range(10))}
{ram}
<rect x="258" y="40" width="40" height="110" rx="5" fill="#55585f" stroke="{INK}" stroke-width="4"/>
<!-- PCIe x16 -->
<rect x="300" y="236" width="380" height="16" rx="3" fill="#1d1e22" stroke="{INK}" stroke-width="3"/>
<rect x="300" y="286" width="230" height="12" rx="3" fill="#1d1e22" stroke="{INK}" stroke-width="2" opacity=".8"/>
<text x="490" y="230" font-family="DejaVu Sans" font-size="13" fill="#cfe8d4" opacity=".6">PCIE_X16</text>
<!-- ช่องร้อยสาย -->
<rect x="736" y="60" width="26" height="90" rx="10" fill="#111" stroke="#55585f" stroke-width="3"/>
<rect x="736" y="190" width="26" height="90" rx="10" fill="#111" stroke="#55585f" stroke-width="3"/>
<!-- PSU shroud -->
<rect x="206" y="330" width="720" height="56" fill="#33353b" stroke="{INK}" stroke-width="4"/>
<rect x="226" y="338" width="210" height="40" rx="6" fill="#1f2025" stroke="{INK}" stroke-width="3"/>
<text x="250" y="365" font-family="DejaVu Sans" font-size="16" fill="#9a9aa2">PSU 650W</text>
<!-- พัดลม -->
{fan(240, 70, 28)}
{fan(860, 110, 52)}
{fan(860, 245, 52)}
{fan(520, 22, 0) if False else ''}
<rect x="430" y="4" width="180" height="22" rx="8" fill="#1f2025" stroke="{INK}" stroke-width="3"/>
{''.join(f'<path d="M{440 + k * 16} 8 v14" stroke="#55585f" stroke-width="4"/>' for k in range(10))}
<text x="200" y="412" font-family="DejaVu Sans" font-size="13" fill="#f6e7c8" opacity=".7">REAR</text>
<text x="900" y="412" font-family="DejaVu Sans" font-size="13" fill="#f6e7c8" opacity=".7">FRONT</text>
<rect width="1152" height="420" fill="url(#lt)"/>
</svg>'''
    save_svg('gpu_case_view', svg, 1152, 420)


def gpu_side():
    # การ์ดจอมองด้านข้าง (เสียบในสล็อตแนวนอน) 420×110 · ไฟ LED เป็นชิ้นแยก
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="440" height="120" viewBox="0 0 440 120">
<rect x="0" y="8" width="18" height="104" rx="3" fill="#b9bcc3" stroke="{INK}" stroke-width="4"/>
<rect x="14" y="14" width="414" height="78" rx="12" fill="#2a2c31" stroke="{INK}" stroke-width="5"/>
<path d="M30 30 h120 l20 14 h240" stroke="#55585f" stroke-width="6" fill="none"/>
<path d="M300 76 l40 -20 h70" stroke="#e8a854" stroke-width="7" fill="none" stroke-linecap="round"/>
<text x="40" y="76" font-family="DejaVu Sans" font-size="22" font-weight="bold" fill="#8d9097">GPU</text>
<rect x="60" y="92" width="300" height="14" fill="#1d6b3a" stroke="{INK}" stroke-width="3"/>
<rect x="110" y="104" width="230" height="10" fill="#d9b04a" stroke="{INK}" stroke-width="2"/>
<rect x="356" y="0" width="56" height="18" rx="3" fill="#1d1e22" stroke="{INK}" stroke-width="3"/>
{''.join(f'<rect x="{362 + k * 12}" y="5" width="6" height="8" fill="#55585f"/>' for k in range(4))}
</svg>'''
    save_svg('gpu_side', svg, 440, 120)
    save_svg('gpu_led_on', f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="24"><rect x="2" y="2" width="60" height="20" rx="8" fill="#6bdcff" stroke="{INK}" stroke-width="3"/><rect x="8" y="7" width="30" height="5" rx="2" fill="#e8fbff"/></svg>', 64, 24)
    save_svg('gpu_led_off', f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="24"><rect x="2" y="2" width="60" height="20" rx="8" fill="#3a3c42" stroke="{INK}" stroke-width="3"/></svg>', 64, 24)


def latch():
    for st, ang in [('locked', 0), ('open', -35)]:
        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="60" height="60" viewBox="0 0 60 60">
<g transform="rotate({ang} 20 46)"><rect x="12" y="8" width="16" height="42" rx="5" fill="#e3e5e9" stroke="{INK}" stroke-width="4"/>
<path d="M14 18 h12 M14 26 h12" stroke="#9a9aa2" stroke-width="3"/></g>
</svg>'''
        save_svg('gpu_latch_' + st, svg, 60, 60)


def cable_svg(path_d, color, head=True, name='', w=360, h=220, hx=0, hy=0):
    hd = ''
    if head:
        hd = (f'<rect x="{hx - 26}" y="{hy - 16}" width="52" height="32" rx="5" fill="#1d1e22" stroke="{INK}" stroke-width="4"/>'
              + ''.join(f'<rect x="{hx - 20 + k * 10}" y="{hy - 10}" width="7" height="7" fill="#55585f"/>' for k in range(4))
              + ''.join(f'<rect x="{hx - 20 + k * 10}" y="{hy + 2}" width="7" height="7" fill="#55585f"/>' for k in range(4)))
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">
<path d="{path_d}" stroke="{INK}" stroke-width="16" fill="none" stroke-linecap="round"/>
<path d="{path_d}" stroke="{color}" stroke-width="9" fill="none" stroke-linecap="round"/>
<path d="{path_d}" stroke="#000" stroke-width="2" fill="none" stroke-dasharray="6 10" opacity=".35"/>
{hd}</svg>'''


def cables():
    # สาย 8-pin ห้อยว่างจาก PSU (ตรวจสภาพ) · สายที่เสียบเข้าการ์ดแล้ว
    save_svg('gpu_cable_loose', cable_svg('M20 200 C40 120 120 140 150 80', '#f2c94c', True, w=200, h=220, hx=150, hy=70), 200, 220)
    save_svg('gpu_cable_plugged', cable_svg('M20 200 C60 120 200 150 330 30', '#f2c94c', True, w=360, h=220, hx=330, hy=24), 360, 220)
    # สายรกพาดหน้าพัดลม 3 เส้น (คนละสี)
    paths = [('M20 30 C120 80 60 180 200 200', '#c0453b'), ('M10 160 C90 40 160 220 210 60', '#f2c94c'), ('M40 10 C10 120 170 90 120 210', '#3a3c42')]
    for i, (d, c) in enumerate(paths):
        save_svg('gpu_mess_%d' % (i + 1), cable_svg(d, c, False, w=220, h=220), 220, 220)


def heads():
    # หัวสาย 4 แบบ 400×160 · ตัวหนังสือบนหัวคือจุดสังเกต
    def base(body, label, col='#1d1e22', wire='#f2c94c'):
        return f'''<svg xmlns="http://www.w3.org/2000/svg" width="400" height="160" viewBox="0 0 400 160">
<path d="M0 60 C80 60 90 100 170 100" stroke="{INK}" stroke-width="40" fill="none"/>
<path d="M0 60 C80 60 90 100 170 100" stroke="{wire}" stroke-width="28" fill="none"/>
<path d="M0 60 C80 60 90 100 170 100" stroke="#111" stroke-width="2" stroke-dasharray="4 8" fill="none" opacity=".5"/>
{body}
<text x="{285}" y="150" font-family="DejaVu Sans" font-size="22" font-weight="bold" fill="{INK}" text-anchor="middle">{label}</text>
</svg>'''
    def pins(x0, y0, cols, rows, shapes):
        s = ''
        for r in range(rows):
            for c in range(cols):
                x, y = x0 + c * 30, y0 + r * 30
                sh = shapes[(r * cols + c) % len(shapes)]
                if sh == 's':
                    s += f'<rect x="{x}" y="{y}" width="20" height="20" rx="2" fill="#55585f" stroke="#0d0d0f" stroke-width="2"/>'
                else:
                    s += f'<path d="M{x} {y + 6} q0 -6 6 -6 h8 q6 0 6 6 v14 h-20 z" fill="#55585f" stroke="#0d0d0f" stroke-width="2"/>'
        return s
    pcie = (f'<rect x="170" y="40" width="80" height="80" rx="6" fill="#1d1e22" stroke="{INK}" stroke-width="5"/>'
            f'<rect x="254" y="40" width="130" height="80" rx="6" fill="#1d1e22" stroke="{INK}" stroke-width="5"/>'
            + pins(180, 50, 2, 2, ['s', 'r']) + pins(262, 50, 4, 2, ['r', 's', 's', 'r'])
            + f'<text x="320" y="34" font-family="DejaVu Sans" font-size="20" font-weight="bold" fill="#f6e7c8" stroke="{INK}" stroke-width="1" text-anchor="middle">PCI-E 6+2</text>')
    cpu = (f'<rect x="170" y="40" width="214" height="80" rx="6" fill="#1d1e22" stroke="{INK}" stroke-width="5"/>'
           + pins(184, 50, 6, 2, ['s', 'r', 'r', 's'])
           + f'<text x="277" y="34" font-family="DejaVu Sans" font-size="20" font-weight="bold" fill="#f6e7c8" stroke="{INK}" stroke-width="1" text-anchor="middle">CPU 8-PIN</text>')
    sata = (f'<path d="M170 60 h200 v40 h-180 v-14 h-20 z" fill="#1d1e22" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
            + ''.join(f'<rect x="{196 + k * 11}" y="70" width="6" height="22" fill="#d9b04a"/>' for k in range(15))
            + f'<text x="270" y="50" font-family="DejaVu Sans" font-size="20" font-weight="bold" fill="#f6e7c8" stroke="{INK}" stroke-width="1" text-anchor="middle">SATA</text>')
    molex = (f'<path d="M180 40 h170 l20 20 v40 l-20 20 h-170 z" fill="#f2efe6" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
             + ''.join(f'<circle cx="{215 + k * 38}" cy="80" r="11" fill="#c9a24a" stroke="{INK}" stroke-width="3"/>' for k in range(4))
             + f'<text x="275" y="34" font-family="DejaVu Sans" font-size="20" font-weight="bold" fill="#f6e7c8" stroke="{INK}" stroke-width="1" text-anchor="middle">MOLEX</text>')
    for n, b, l, w in [('pcie', pcie, 'การ์ดจอ', '#f2c94c'), ('cpu8', cpu, 'ซีพียู', '#f2c94c'), ('sata', sata, 'ฮาร์ดดิสก์', '#3a3c42'), ('molex', molex, 'รุ่นเก่า', '#c0453b')]:
        save_svg('gpu_head_' + n, base(b, '', wire=w), 400, 160)


def rear_view():
    ports = ''
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1152" height="420" viewBox="0 0 1152 420">
<rect width="1152" height="420" fill="#a8693a"/>
{''.join(f'<path d="M0 {y} H1152" stroke="#7a4a26" stroke-width="2" opacity=".4"/>' for y in range(20, 420, 46))}
<rect x="356" y="6" width="450" height="408" rx="14" fill="#000" opacity=".3"/>
<rect x="346" y="0" width="450" height="404" rx="14" fill="#3b3e45" stroke="{INK}" stroke-width="7"/>
<!-- I/O shield -->
<rect x="376" y="24" width="120" height="190" rx="6" fill="#c9ccd2" stroke="{INK}" stroke-width="4"/>
<rect x="392" y="40" width="40" height="22" rx="3" fill="#2a2a2e"/><rect x="440" y="40" width="40" height="22" rx="3" fill="#2a2a2e"/>
<rect x="392" y="76" width="88" height="26" rx="4" fill="#2a2a2e"/>
<path d="M398 118 h76 l-8 22 h-60 z" fill="#2a2a2e" stroke="{INK}" stroke-width="3"/>
<text x="436" y="160" font-family="DejaVu Sans" font-size="13" fill="{INK}" text-anchor="middle">HDMI · MB</text>
{''.join(f'<circle cx="{404 + k * 22}" cy="190" r="8" fill="{c}" stroke="{INK}" stroke-width="2"/>' for k, c in enumerate(["#4a90d9", "#6baf52", "#e88aa0", "#f2c94c"]))}
<!-- พัดลมหลัง -->
{fan(640, 110, 70)}
<!-- ช่องการ์ดเสริม -->
{''.join(f'<rect x="376" y="{238 + k * 26}" width="300" height="18" rx="3" fill="#8d9097" stroke="{INK}" stroke-width="3"/>' for k in range(3))}
<rect x="376" y="238" width="300" height="44" rx="4" fill="#b9bcc3" stroke="{INK}" stroke-width="4"/>
<path d="M430 248 h60 l-6 16 h-48 z" fill="#2a2a2e"/>
<rect x="510" y="246" width="44" height="22" rx="3" fill="#2a2a2e"/><rect x="562" y="246" width="44" height="22" rx="3" fill="#2a2a2e"/>
<text x="460" y="278" font-family="DejaVu Sans" font-size="11" fill="{INK}" text-anchor="middle">HDMI · GPU</text>
<circle cx="700" cy="248" r="10" fill="#55585f" stroke="{INK}" stroke-width="3"/>
<!-- PSU -->
<rect x="376" y="320" width="400" height="70" rx="6" fill="#1f2025" stroke="{INK}" stroke-width="4"/>
{''.join(f'<path d="M{400 + k * 14} 330 v50" stroke="#2f3036" stroke-width="6"/>' for k in range(14))}
<rect x="640" y="334" width="56" height="42" rx="5" fill="#0f0f12" stroke="#55585f" stroke-width="3"/>
<rect x="712" y="338" width="22" height="34" rx="4" fill="#c0453b" stroke="{INK}" stroke-width="3"/>
</svg>'''
    save_svg('gpu_rear_view', svg, 1152, 420)
    # สาย HDMI (หัว + สาย) 160×200 · เสียบที่บอร์ดหรือที่การ์ด ใช้รูปเดียว ย้ายตำแหน่งเอา
    hd = f'''<svg xmlns="http://www.w3.org/2000/svg" width="120" height="200" viewBox="0 0 120 200">
<path d="M60 40 C60 120 100 140 110 200" stroke="{INK}" stroke-width="18" fill="none"/>
<path d="M60 40 C60 120 100 140 110 200" stroke="#3a3c42" stroke-width="10" fill="none"/>
<rect x="34" y="6" width="52" height="40" rx="6" fill="#2a2c31" stroke="{INK}" stroke-width="4"/>
<rect x="40" y="0" width="40" height="12" rx="2" fill="#b9bcc3" stroke="{INK}" stroke-width="2"/>
</svg>'''
    save_svg('gpu_hdmi_cable', hd, 120, 200)
    cord = f'''<svg xmlns="http://www.w3.org/2000/svg" width="200" height="120" viewBox="0 0 200 120">
<path d="M70 50 C120 50 150 100 200 110" stroke="{INK}" stroke-width="18" fill="none"/>
<path d="M70 50 C120 50 150 100 200 110" stroke="#2a2c31" stroke-width="10" fill="none"/>
<rect x="10" y="26" width="64" height="48" rx="8" fill="#2a2c31" stroke="{INK}" stroke-width="5"/>
</svg>'''
    save_svg('gpu_power_cord', cord, 200, 120)


def card_states():
    c = Image.open(SRC + 'MiniGame/PartGpu/gpu_card.png').convert('RGBA')
    a = np.array(c)
    alpha = a[..., 3]
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    gold = (r > 150) & (g > 110) & (b < 110) & (alpha > 0)

    def dust(level):
        lay = Image.new('RGBA', c.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(lay)
        rnd = random.Random(3)
        for _ in range(int(1600 * level)):
            x, y = rnd.uniform(0, c.width), rnd.uniform(0, c.height)
            rr = rnd.uniform(1.5, 4.5)
            gg = rnd.randint(125, 180)
            d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=(gg, gg - 8, gg - 24, rnd.randint(150, 235)))
        la = np.array(lay.filter(ImageFilter.GaussianBlur(0.7)))
        la[..., 3] = np.minimum(la[..., 3], alpha)
        return Image.fromarray(la)

    def dull(img):
        x = np.array(img)
        x[gold, 0] = (x[gold, 0] * 0.55).astype(np.uint8)
        x[gold, 1] = (x[gold, 1] * 0.5).astype(np.uint8)
        x[gold, 2] = (x[gold, 2] * 0.45 + 20).astype(np.uint8)
        return Image.fromarray(x)

    base_dull = dull(c)
    for name, lvl in [('dusty', 1.0), ('fans', 0.45)]:
        im = base_dull.copy()
        im.alpha_composite(dust(lvl))
        im.save(OUT + 'gpu_card_%s.png' % name)
    base_dull.save(OUT + 'gpu_card_fins.png')
    c.save(OUT + 'gpu_card_clean.png')


case_view(); gpu_side(); latch(); cables(); heads(); rear_view(); card_states()
print(sorted(f for f in os.listdir(OUT) if f.endswith('.png')))
