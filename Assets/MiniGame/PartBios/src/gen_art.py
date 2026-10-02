# วาดภาพ Part BIOS — SVG ต้นฉบับ + PNG (ใช้ครั้งเดียว · ผลลัพธ์ใน out/) · ตัวอักษรในภาพเป็นภาษาอังกฤษแบบหน้าจอจริงเท่านั้น
# ค่าที่เปลี่ยนตามการเล่น (แรม/ดิสก์/ลำดับบูต) เป็น Label ในซีน ไม่ฝังในภาพ
import os
import cairosvg

OUT = '/home/claude/bios/out/'
os.makedirs(OUT + 'src', exist_ok=True)
INK = '#2C1810'
MONO = 'DejaVu Sans Mono'
SANS = 'DejaVu Sans'


def save_svg(name, svg, w, h):
    open(OUT + 'src/' + name + '.svg', 'w').write(svg)
    cairosvg.svg2png(bytestring=svg.encode(), write_to=OUT + name + '.png', output_width=w, output_height=h)


def frame(inner, screen='#1d3f8f'):
    # จอใหญ่เต็มมุม 1152×420 · พื้นที่จอ x170–982 y18–402
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1152" height="420" viewBox="0 0 1152 420">
<rect width="1152" height="420" fill="#6b4a33"/>
{''.join(f'<path d="M0 {y} H1152" stroke="#4e3524" stroke-width="2" opacity=".5"/>' for y in range(24, 420, 52))}
<rect x="150" y="0" width="852" height="420" rx="18" fill="#1b1c20" stroke="{INK}" stroke-width="6"/>
<rect x="170" y="18" width="812" height="384" rx="6" fill="{screen}"/>
{inner}
<rect x="170" y="18" width="812" height="384" rx="6" fill="none" stroke="#000" stroke-width="3" opacity=".5"/>
</svg>'''


def panel(x, y, w, h, title):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="#16316f" stroke="#7fa4ff" stroke-width="2"/>'
            f'<rect x="{x}" y="{y}" width="{w}" height="26" rx="6" fill="#2b55b8"/>'
            f'<text x="{x + 12}" y="{y + 19}" font-family="{MONO}" font-size="15" font-weight="bold" fill="#e8f0ff">{title}</text>')


def bios_view():
    inner = (f'<rect x="170" y="18" width="812" height="34" fill="#c9ccd2"/>'
             f'<text x="576" y="42" font-family="{MONO}" font-size="19" font-weight="bold" fill="#1d3f8f" text-anchor="middle">UEFI BIOS UTILITY  -  EZ MODE</text>'
             + panel(186, 64, 380, 190, 'System Information')
             + panel(586, 64, 380, 268, 'Boot Priority')
             + panel(186, 266, 380, 66, 'Memory Profile (XMP)')
             + f'<rect x="170" y="344" width="812" height="58" fill="#12285c"/>'
             + f'<text x="776" y="324" font-family="{MONO}" font-size="12" fill="#9fb8ff" text-anchor="middle">click two items to swap</text>')
    save_svg('bios_view', frame(inner), 1152, 420)


def install_view():
    inner = (f'<rect x="170" y="18" width="812" height="384" rx="6" fill="#3a2a7a"/>'
             f'<rect x="230" y="50" width="692" height="320" rx="8" fill="#f2f2f6" stroke="{INK}" stroke-width="3"/>'
             f'<rect x="230" y="50" width="692" height="34" rx="8" fill="#5b4bc4"/>'
             f'<text x="250" y="73" font-family="{SANS}" font-size="16" fill="#fff" font-weight="bold">Windows Setup</text>'
             f'<text x="256" y="114" font-family="{SANS}" font-size="18" fill="#2b2b38">Where do you want to install Windows?</text>'
             f'<path d="M256 124 H896" stroke="#c9c9d6" stroke-width="2"/>')
    save_svg('bios_install_view', frame(inner, '#3a2a7a'), 1152, 420)


def chart_view():
    # กระดานกราฟแท่ง 4 แท่ง (ไม่มีตัวหนังสือ — ชื่อ/ค่าเป็น Label) · ฐานแท่ง y 330 · ช่องแท่ง x 290/430/570/710 กว้าง 90
    grid = ''.join(f'<path d="M250 {y} H880" stroke="#c9c2b0" stroke-width="2" stroke-dasharray="8 6"/>' for y in (130, 196, 262))
    inner = (f'<rect x="170" y="18" width="812" height="384" rx="6" fill="#f6f0dc"/>'
             f'{grid}<path d="M250 70 V330 H880" stroke="{INK}" stroke-width="4" fill="none"/>')
    save_svg('bios_chart_view', frame(inner, '#f6f0dc'), 1152, 420)
    bar = f'''<svg xmlns="http://www.w3.org/2000/svg" width="64" height="256" viewBox="0 0 64 256">
<rect x="3" y="3" width="58" height="250" rx="8" fill="#ffffff" stroke="{INK}" stroke-width="5"/>
<rect x="10" y="10" width="12" height="236" rx="4" fill="#ffffff" opacity=".45"/></svg>'''
    save_svg('bios_bar', bar, 64, 256)


def buttons():
    for name, label, col in [('save', 'Save &amp; Exit', '#3f9a52'), ('discard', 'Discard &amp; Exit', '#b0453b'), ('default', 'Load Defaults', '#c08a2a')]:
        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="240" height="44" viewBox="0 0 240 44">
<rect x="2" y="2" width="236" height="40" rx="8" fill="{col}" stroke="#0d1530" stroke-width="3"/>
<rect x="8" y="6" width="224" height="10" rx="5" fill="#fff" opacity=".18"/>
<text x="120" y="29" font-family="{SANS}" font-size="18" font-weight="bold" fill="#fff" text-anchor="middle">{label}</text></svg>'''
        save_svg('bios_btn_' + name, svg, 240, 44)


def drives():
    def base(body):
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="180" height="140" viewBox="0 0 180 140">{body}</svg>'
    ssd = base(f'<rect x="20" y="30" width="140" height="84" rx="8" fill="#2a2c31" stroke="{INK}" stroke-width="5"/>'
               f'<rect x="36" y="46" width="70" height="40" rx="4" fill="#4a90d9"/><path d="M36 98 H144" stroke="#55585f" stroke-width="6"/>'
               f'<rect x="150" y="56" width="18" height="30" rx="2" fill="#b9bcc3" stroke="{INK}" stroke-width="3"/>')
    hdd = base(f'<rect x="20" y="20" width="140" height="104" rx="8" fill="#b9bcc3" stroke="{INK}" stroke-width="5"/>'
               f'<circle cx="80" cy="70" r="36" fill="#d9dce2" stroke="{INK}" stroke-width="4"/><circle cx="80" cy="70" r="8" fill="#55585f"/>'
               f'<path d="M80 70 L134 104" stroke="#55585f" stroke-width="7" stroke-linecap="round"/>'
               f'<circle cx="36" cy="34" r="4" fill="#55585f"/><circle cx="144" cy="110" r="4" fill="#55585f"/>')
    usb = base(f'<rect x="30" y="44" width="100" height="52" rx="10" fill="#2a2c31" stroke="{INK}" stroke-width="5"/>'
               f'<rect x="128" y="54" width="34" height="32" rx="2" fill="#c9ccd2" stroke="{INK}" stroke-width="4"/>'
               f'<rect x="140" y="62" width="8" height="6" fill="{INK}"/><rect x="140" y="74" width="8" height="6" fill="{INK}"/>'
               f'<rect x="44" y="56" width="50" height="10" rx="4" fill="#4a90d9"/>')
    for n, s in (('ssd', ssd), ('hdd', hdd), ('usb', usb)):
        save_svg('bios_drive_' + n, s, 180, 140)


def popup():
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="460" height="220" viewBox="0 0 460 220">
<rect x="4" y="4" width="452" height="212" rx="12" fill="#fff6e8" stroke="{INK}" stroke-width="6"/>
<rect x="4" y="4" width="452" height="40" rx="12" fill="#c0453b"/><rect x="4" y="30" width="452" height="14" fill="#c0453b"/>
<path d="M60 90 l34 60 h-68 z" fill="#ffd36b" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>
<path d="M60 108 v20" stroke="{INK}" stroke-width="7" stroke-linecap="round"/><circle cx="60" cy="140" r="4" fill="{INK}"/>
</svg>'''
    save_svg('bios_warning', svg, 460, 220)


def screens():
    # จอเล็กบนโต๊ะคอม 512×320
    def scr(body, bg):
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="320" viewBox="0 0 512 320"><rect width="512" height="320" fill="{bg}"/>{body}</svg>'
    t = lambda x, y, s, c='#d8d8d8', fs=17, a='start': f'<text x="{x}" y="{y}" font-family="{MONO}" font-size="{fs}" fill="{c}" text-anchor="{a}">{s}</text>'
    save_svg('bios_scr_noboot', scr(t(24, 60, 'Reboot and Select proper Boot device') + t(24, 90, 'or Insert Boot Media in selected') + t(24, 120, 'Boot device and press a key_'), '#000'), 512, 320)
    save_svg('bios_scr_pxe', scr(t(24, 50, 'Intel(R) Boot Agent GE v1.5.88') + t(24, 84, 'PXE-E53: No boot filename received') + t(24, 118, 'DHCP..... \\ | / - \\ | /', '#ffd36b'), '#000'), 512, 320)
    bios = (f'<rect width="512" height="40" fill="#c9ccd2"/>' + t(256, 28, 'UEFI BIOS UTILITY', '#1d3f8f', 20, 'middle')
            + ''.join(f'<rect x="24" y="{64 + k * 44}" width="210" height="32" rx="4" fill="#16316f" stroke="#7fa4ff" stroke-width="2"/>' for k in range(4))
            + f'<rect x="260" y="64" width="228" height="208" rx="4" fill="#16316f" stroke="#7fa4ff" stroke-width="2"/>')
    save_svg('bios_scr_bios', scr(bios, '#1d3f8f'), 512, 320)
    inst = (f'<rect x="40" y="40" width="432" height="240" rx="6" fill="#f2f2f6"/><rect x="40" y="40" width="432" height="30" rx="6" fill="#5b4bc4"/>'
            + t(56, 61, 'Windows Setup', '#fff', 16) + f'<rect x="70" y="200" width="372" height="22" rx="4" fill="#d6d6e0"/><rect x="70" y="200" width="220" height="22" rx="4" fill="#5b4bc4"/>')
    save_svg('bios_scr_install', scr(inst, '#3a2a7a'), 512, 320)


def small():
    usb = f'''<svg xmlns="http://www.w3.org/2000/svg" width="60" height="44" viewBox="0 0 60 44">
<rect x="4" y="4" width="52" height="36" rx="8" fill="#2a2c31" stroke="{INK}" stroke-width="4"/>
<rect x="12" y="12" width="36" height="20" rx="4" fill="#4a90d9"/><circle cx="48" cy="12" r="4" fill="none" stroke="#c9ccd2" stroke-width="2"/></svg>'''
    save_svg('bios_usb_rear', usb, 60, 44)
    inst = usb.replace('#2a2c31', '#c0453b').replace('#4a90d9', '#ffd36b')  # ตัวติดตั้งของร้าน (สีแดง)
    save_svg('bios_usb_installer_rear', inst, 60, 44)
    cmos = f'''<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
<circle cx="20" cy="20" r="16" fill="#d9dce2" stroke="{INK}" stroke-width="4"/><circle cx="20" cy="20" r="10" fill="none" stroke="#9a9ea6" stroke-width="2"/>
<path d="M15 20 h10 M20 15 v10" stroke="#55585f" stroke-width="3"/></svg>'''
    save_svg('bios_cmos', cmos, 40, 40)
    hole = f'''<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
<circle cx="20" cy="20" r="16" fill="#1f2025" stroke="{INK}" stroke-width="4"/><path d="M8 20 h24" stroke="#b9bcc3" stroke-width="3"/></svg>'''
    save_svg('bios_cmos_empty', hole, 40, 40)


bios_view(); install_view(); chart_view(); buttons(); drives(); popup(); screens(); small()
print(sorted(f for f in os.listdir(OUT) if f.endswith('.png')))
